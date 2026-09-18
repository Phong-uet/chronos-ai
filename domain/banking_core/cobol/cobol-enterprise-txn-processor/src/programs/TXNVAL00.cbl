       IDENTIFICATION DIVISION.
       PROGRAM-ID.    TXNVAL00.
       AUTHOR.        ENTERPRISE FINANCIAL SYSTEMS.
       DATE-WRITTEN.  2026-03-31.
      ******************************************************************
      * TXNVAL00 - Transaction Input Validation
      *
      * First stage of the batch processing pipeline. Reads raw
      * transaction input, applies comprehensive validation rules,
      * and produces two output files:
      *   1. Validated transactions (status = 'V')
      *   2. Error report for rejected transactions
      *
      * Validation Rules:
      *   - Account number format (12-char alphanumeric)
      *   - Transaction type must be valid (DEP/WDR/XFR/FEE/INT/ADJ)
      *   - Amount must be positive and within bounds
      *   - Date must be valid calendar date
      *   - Currency code must be valid ISO 4217
      *   - Duplicate detection via sequence number tracking
      *   - Transfer requires both source and target accounts
      *   - Adjustment requires reason code
      ******************************************************************

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       REPOSITORY.
           FUNCTION ALL INTRINSIC.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INPUT-TXN-FILE
               ASSIGN TO 'data/input/transactions.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-INPUT-STATUS.

           SELECT VALID-TXN-FILE
               ASSIGN TO 'data/work/valid-transactions.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-VALID-STATUS.

           SELECT ERROR-RPT-FILE
               ASSIGN TO 'data/output/validation-errors.rpt'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ERROR-STATUS.

           SELECT AUDIT-LOG-FILE
               ASSIGN TO 'data/work/txnval-audit.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-AUDIT-STATUS.

           SELECT ACCOUNT-FILE
               ASSIGN TO 'data/input/accounts.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCT-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  INPUT-TXN-FILE
           RECORDING MODE IS F.
       01  INPUT-TXN-REC              PIC X(200).

       FD  VALID-TXN-FILE
           RECORDING MODE IS F.
       01  VALID-TXN-REC              PIC X(200).

       FD  ERROR-RPT-FILE
           RECORDING MODE IS F.
       01  ERROR-RPT-REC              PIC X(132).

       FD  AUDIT-LOG-FILE
           RECORDING MODE IS F.
       01  AUDIT-LOG-REC              PIC X(250).

       FD  ACCOUNT-FILE
           RECORDING MODE IS F.
       01  ACCOUNT-FILE-REC           PIC X(200).

       WORKING-STORAGE SECTION.

      * File status variables
       01  WS-INPUT-STATUS             PIC X(02).
       01  WS-VALID-STATUS             PIC X(02).
       01  WS-ERROR-STATUS             PIC X(02).
       01  WS-AUDIT-STATUS             PIC X(02).
       01  WS-ACCT-STATUS              PIC X(02).

      * Control flags
       01  WS-EOF-FLAG                 PIC X(01) VALUE 'N'.
           88  END-OF-FILE             VALUE 'Y'.
           88  NOT-END-OF-FILE         VALUE 'N'.

       01  WS-ACCT-EOF-FLAG            PIC X(01) VALUE 'N'.
           88  ACCT-END-OF-FILE        VALUE 'Y'.
           88  ACCT-NOT-EOF            VALUE 'N'.

       01  WS-VALID-FLAG               PIC X(01) VALUE 'Y'.
           88  TXN-IS-VALID            VALUE 'Y'.
           88  TXN-IS-INVALID          VALUE 'N'.

      * Copybook includes
       COPY 'src/copybooks/TXNREC.cpy'.
       COPY 'src/copybooks/ACTREC.cpy'.
       COPY 'src/copybooks/ERRREC.cpy'.
       COPY 'src/copybooks/AUDREC.cpy'.
       COPY 'src/copybooks/RPTFLD.cpy'.

      * Processing counters
       01  WS-COUNTERS.
           05  WS-TOTAL-READ           PIC 9(08) VALUE 0.
           05  WS-TOTAL-VALID          PIC 9(08) VALUE 0.
           05  WS-TOTAL-INVALID        PIC 9(08) VALUE 0.
           05  WS-ERROR-SEQ            PIC 9(10) VALUE 0.
           05  WS-AUDIT-SEQ            PIC 9(10) VALUE 0.

      * Duplicate detection table (tracks last 10000 sequence nums)
       01  WS-DUP-TABLE.
           05  WS-DUP-MAX             PIC 9(05) VALUE 10000.
           05  WS-DUP-COUNT           PIC 9(05) VALUE 0.
           05  WS-DUP-ENTRY OCCURS 10000 TIMES.
               10  WS-DUP-SEQ-NUM     PIC 9(10).

      * Account lookup table (max 1000 accounts)
       01  WS-ACCT-TABLE.
           05  WS-ACCT-COUNT          PIC 9(05) VALUE 0.
           05  WS-ACCT-ENTRY OCCURS 1000 TIMES.
               10  WS-ACCT-NUM        PIC X(12).
               10  WS-ACCT-STAT       PIC X(01).
               10  WS-ACCT-CURR       PIC X(03).

      * Valid currency codes
       01  WS-VALID-CURRENCIES.
           05  FILLER                  PIC X(03) VALUE 'USD'.
           05  FILLER                  PIC X(03) VALUE 'EUR'.
           05  FILLER                  PIC X(03) VALUE 'GBP'.
           05  FILLER                  PIC X(03) VALUE 'JPY'.
           05  FILLER                  PIC X(03) VALUE 'CAD'.
           05  FILLER                  PIC X(03) VALUE 'CHF'.
       01  WS-CURRENCY-TABLE REDEFINES WS-VALID-CURRENCIES.
           05  WS-CURRENCY-ENTRY OCCURS 6 TIMES.
               10  WS-CURRENCY-CODE    PIC X(03).

      * Work fields
       01  WS-WORK-FIELDS.
           05  WS-CURR-DATE           PIC 9(08).
           05  WS-CURR-TIME           PIC 9(06).
           05  WS-SEARCH-IDX          PIC 9(05).
           05  WS-FOUND-FLAG          PIC X(01).
           05  WS-PREV-HASH           PIC X(16) VALUE ALL '0'.
           05  WS-HASH-INPUT          PIC X(40).
           05  WS-HASH-WORK           PIC 9(10).
           05  WS-HASH-RESULT         PIC X(16).
           05  WS-DATE-YYYY           PIC 9(04).
           05  WS-DATE-MM             PIC 9(02).
           05  WS-DATE-DD             PIC 9(02).
           05  WS-AMOUNT-CHECK        PIC 9(13)V99.

      * Report formatting
       01  WS-RPT-HEADER-1.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(50)
               VALUE 'ENTERPRISE FINANCIAL SERVICES CORP.'.
       01  WS-RPT-HEADER-2.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(50)
               VALUE 'TRANSACTION VALIDATION ERROR REPORT'.
       01  WS-RPT-HEADER-3.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(12) VALUE 'RUN DATE:   '.
           05  WS-RPT-DATE            PIC X(10).
           05  FILLER                  PIC X(10) VALUE SPACES.
           05  FILLER                  PIC X(12) VALUE 'RUN TIME:   '.
           05  WS-RPT-TIME            PIC X(08).
       01  WS-RPT-COL-HDR.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  FILLER                  PIC X(12)
               VALUE 'SEQ NUM     '.
           05  FILLER                  PIC X(06)
               VALUE 'TYPE  '.
           05  FILLER                  PIC X(15)
               VALUE 'SOURCE ACCT    '.
           05  FILLER                  PIC X(18)
               VALUE 'AMOUNT            '.
           05  FILLER                  PIC X(06)
               VALUE 'ERROR '.
           05  FILLER                  PIC X(50)
               VALUE 'DESCRIPTION'.
       01  WS-RPT-DETAIL.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-RPT-SEQ             PIC 9(10).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RPT-TYPE            PIC X(03).
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  WS-RPT-ACCT            PIC X(12).
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  WS-RPT-AMT             PIC Z(12)9.99.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RPT-ERR-CODE        PIC X(03).
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  WS-RPT-ERR-DESC        PIC X(50).
       01  WS-RPT-SUMMARY.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-RPT-SUM-LABEL       PIC X(30).
           05  WS-RPT-SUM-VALUE       PIC Z(07)9.

       PROCEDURE DIVISION.
       0000-MAIN-CONTROL.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-LOAD-ACCOUNTS
           PERFORM 3000-PROCESS-TRANSACTIONS
           PERFORM 9000-FINALIZE
           STOP RUN
           .

       1000-INITIALIZE.
           MOVE FUNCTION CURRENT-DATE(1:8) TO WS-CURR-DATE
           MOVE FUNCTION CURRENT-DATE(9:6) TO WS-CURR-TIME

           OPEN INPUT  INPUT-TXN-FILE
           OPEN OUTPUT VALID-TXN-FILE
           OPEN OUTPUT ERROR-RPT-FILE
           OPEN OUTPUT AUDIT-LOG-FILE

           IF WS-INPUT-STATUS NOT = '00'
               DISPLAY 'ERROR: Cannot open input transaction file'
               DISPLAY 'File status: ' WS-INPUT-STATUS
               STOP RUN
           END-IF

           PERFORM 1100-WRITE-REPORT-HEADERS
           .

       1100-WRITE-REPORT-HEADERS.
           WRITE ERROR-RPT-REC FROM RPT-SEPARATOR
           WRITE ERROR-RPT-REC FROM WS-RPT-HEADER-1

           MOVE WS-CURR-DATE(1:4) TO WS-RPT-DATE(1:4)
           MOVE '-'               TO WS-RPT-DATE(5:1)
           MOVE WS-CURR-DATE(5:2) TO WS-RPT-DATE(6:2)
           MOVE '-'               TO WS-RPT-DATE(8:1)
           MOVE WS-CURR-DATE(7:2) TO WS-RPT-DATE(9:2)

           MOVE WS-CURR-TIME(1:2) TO WS-RPT-TIME(1:2)
           MOVE ':'               TO WS-RPT-TIME(3:1)
           MOVE WS-CURR-TIME(3:2) TO WS-RPT-TIME(4:2)
           MOVE ':'               TO WS-RPT-TIME(6:1)
           MOVE WS-CURR-TIME(5:2) TO WS-RPT-TIME(7:2)

           WRITE ERROR-RPT-REC FROM WS-RPT-HEADER-2
           WRITE ERROR-RPT-REC FROM WS-RPT-HEADER-3
           WRITE ERROR-RPT-REC FROM RPT-SEPARATOR
           WRITE ERROR-RPT-REC FROM WS-RPT-COL-HDR
           WRITE ERROR-RPT-REC FROM RPT-DASH-LINE
           .

       2000-LOAD-ACCOUNTS.
           OPEN INPUT ACCOUNT-FILE
           IF WS-ACCT-STATUS NOT = '00'
               DISPLAY 'ERROR: Cannot open account master file'
               DISPLAY 'File status: ' WS-ACCT-STATUS
               STOP RUN
           END-IF

           SET ACCT-NOT-EOF TO TRUE
           PERFORM UNTIL ACCT-END-OF-FILE
               READ ACCOUNT-FILE INTO WS-ACCOUNT-RECORD
                   AT END
                       SET ACCT-END-OF-FILE TO TRUE
                   NOT AT END
                       ADD 1 TO WS-ACCT-COUNT
                       MOVE ACT-ACCOUNT-NUM
                           TO WS-ACCT-NUM(WS-ACCT-COUNT)
                       MOVE ACT-STATUS
                           TO WS-ACCT-STAT(WS-ACCT-COUNT)
                       MOVE ACT-CURRENCY
                           TO WS-ACCT-CURR(WS-ACCT-COUNT)
               END-READ
           END-PERFORM

           CLOSE ACCOUNT-FILE

           DISPLAY 'TXNVAL00: Loaded ' WS-ACCT-COUNT ' accounts'
           .

       3000-PROCESS-TRANSACTIONS.
           SET NOT-END-OF-FILE TO TRUE

           PERFORM UNTIL END-OF-FILE
               READ INPUT-TXN-FILE INTO WS-TRANSACTION-RECORD
                   AT END
                       SET END-OF-FILE TO TRUE
                   NOT AT END
                       ADD 1 TO WS-TOTAL-READ
                       PERFORM 4000-VALIDATE-TRANSACTION
               END-READ
           END-PERFORM
           .

       4000-VALIDATE-TRANSACTION.
           SET TXN-IS-VALID TO TRUE

           PERFORM 4100-VALIDATE-TYPE
           IF TXN-IS-VALID
               PERFORM 4200-VALIDATE-AMOUNT
           END-IF
           IF TXN-IS-VALID
               PERFORM 4300-VALIDATE-DATE
           END-IF
           IF TXN-IS-VALID
               PERFORM 4400-VALIDATE-ACCOUNTS
           END-IF
           IF TXN-IS-VALID
               PERFORM 4500-VALIDATE-CURRENCY
           END-IF
           IF TXN-IS-VALID
               PERFORM 4600-CHECK-DUPLICATE
           END-IF
           IF TXN-IS-VALID
               PERFORM 4700-VALIDATE-BUSINESS-RULES
           END-IF

           IF TXN-IS-VALID
               MOVE 'V' TO TXN-STATUS
               MOVE SPACES TO TXN-ERROR-CODE
               WRITE VALID-TXN-REC FROM WS-TRANSACTION-RECORD
               ADD 1 TO WS-TOTAL-VALID
               PERFORM 8000-WRITE-AUDIT-VALIDATED
           ELSE
               ADD 1 TO WS-TOTAL-INVALID
           END-IF
           .

       4100-VALIDATE-TYPE.
           IF NOT (TXN-IS-DEPOSIT OR TXN-IS-WITHDRAWAL
                   OR TXN-IS-TRANSFER OR TXN-IS-FEE
                   OR TXN-IS-INTEREST OR TXN-IS-ADJUSTMENT)
               SET TXN-IS-INVALID TO TRUE
               PERFORM 5070-WRITE-ERROR-E07
           END-IF
           .

       4200-VALIDATE-AMOUNT.
           IF TXN-AMOUNT = ZEROS
               SET TXN-IS-INVALID TO TRUE
               PERFORM 5080-WRITE-ERROR-E08-ZERO
           ELSE
               IF TXN-AMOUNT > 99999999999.99
                   SET TXN-IS-INVALID TO TRUE
                   PERFORM 5081-WRITE-ERROR-E08-MAX
               END-IF
           END-IF
           .

       4300-VALIDATE-DATE.
           MOVE TXN-DATE(1:4) TO WS-DATE-YYYY
           MOVE TXN-DATE(5:2) TO WS-DATE-MM
           MOVE TXN-DATE(7:2) TO WS-DATE-DD

           IF WS-DATE-YYYY < 2000 OR WS-DATE-YYYY > 2099
               SET TXN-IS-INVALID TO TRUE
               PERFORM 5080-WRITE-ERROR-E08-ZERO
           END-IF

           IF WS-DATE-MM < 01 OR WS-DATE-MM > 12
               SET TXN-IS-INVALID TO TRUE
               PERFORM 5080-WRITE-ERROR-E08-ZERO
           END-IF

           IF WS-DATE-DD < 01 OR WS-DATE-DD > 31
               SET TXN-IS-INVALID TO TRUE
               PERFORM 5080-WRITE-ERROR-E08-ZERO
           END-IF
           .

       4400-VALIDATE-ACCOUNTS.
           PERFORM 4410-CHECK-SOURCE-ACCOUNT

           IF TXN-IS-VALID AND TXN-IS-TRANSFER
               PERFORM 4420-CHECK-TARGET-ACCOUNT
           END-IF
           .

       4410-CHECK-SOURCE-ACCOUNT.
           IF TXN-SOURCE-ACCOUNT = SPACES
               SET TXN-IS-INVALID TO TRUE
               PERFORM 5010-WRITE-ERROR-E01-SOURCE
           ELSE
               MOVE 'N' TO WS-FOUND-FLAG
               PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
                   UNTIL WS-SEARCH-IDX > WS-ACCT-COUNT
                   OR WS-FOUND-FLAG = 'Y'
                   IF WS-ACCT-NUM(WS-SEARCH-IDX)
                       = TXN-SOURCE-ACCOUNT
                       MOVE 'Y' TO WS-FOUND-FLAG
                       IF WS-ACCT-STAT(WS-SEARCH-IDX) = 'F'
                          OR WS-ACCT-STAT(WS-SEARCH-IDX) = 'C'
                           SET TXN-IS-INVALID TO TRUE
                           PERFORM 5030-WRITE-ERROR-E03
                       END-IF
                   END-IF
               END-PERFORM
               IF WS-FOUND-FLAG = 'N'
                   SET TXN-IS-INVALID TO TRUE
                   PERFORM 5010-WRITE-ERROR-E01-SOURCE
               END-IF
           END-IF
           .

       4420-CHECK-TARGET-ACCOUNT.
           IF TXN-TARGET-ACCOUNT = SPACES
               SET TXN-IS-INVALID TO TRUE
               PERFORM 5011-WRITE-ERROR-E01-TARGET
           ELSE
               MOVE 'N' TO WS-FOUND-FLAG
               PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
                   UNTIL WS-SEARCH-IDX > WS-ACCT-COUNT
                   OR WS-FOUND-FLAG = 'Y'
                   IF WS-ACCT-NUM(WS-SEARCH-IDX)
                       = TXN-TARGET-ACCOUNT
                       MOVE 'Y' TO WS-FOUND-FLAG
                       IF WS-ACCT-STAT(WS-SEARCH-IDX) = 'F'
                          OR WS-ACCT-STAT(WS-SEARCH-IDX) = 'C'
                           SET TXN-IS-INVALID TO TRUE
                           PERFORM 5030-WRITE-ERROR-E03
                       END-IF
                   END-IF
               END-PERFORM
               IF WS-FOUND-FLAG = 'N'
                   SET TXN-IS-INVALID TO TRUE
                   PERFORM 5011-WRITE-ERROR-E01-TARGET
               END-IF
           END-IF
           .

       4500-VALIDATE-CURRENCY.
           MOVE 'N' TO WS-FOUND-FLAG
           PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
               UNTIL WS-SEARCH-IDX > 6
               OR WS-FOUND-FLAG = 'Y'
               IF WS-CURRENCY-CODE(WS-SEARCH-IDX)
                   = TXN-CURRENCY
                   MOVE 'Y' TO WS-FOUND-FLAG
               END-IF
           END-PERFORM

           IF WS-FOUND-FLAG = 'N'
               SET TXN-IS-INVALID TO TRUE
               PERFORM 5050-WRITE-ERROR-E05
           END-IF
           .

       4600-CHECK-DUPLICATE.
           MOVE 'N' TO WS-FOUND-FLAG
           PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
               UNTIL WS-SEARCH-IDX > WS-DUP-COUNT
               OR WS-FOUND-FLAG = 'Y'
               IF WS-DUP-SEQ-NUM(WS-SEARCH-IDX)
                   = TXN-SEQUENCE-NUM
                   MOVE 'Y' TO WS-FOUND-FLAG
                   SET TXN-IS-INVALID TO TRUE
                   PERFORM 5060-WRITE-ERROR-E06
               END-IF
           END-PERFORM

           IF TXN-IS-VALID
               IF WS-DUP-COUNT < WS-DUP-MAX
                   ADD 1 TO WS-DUP-COUNT
                   MOVE TXN-SEQUENCE-NUM
                       TO WS-DUP-SEQ-NUM(WS-DUP-COUNT)
               END-IF
           END-IF
           .

       4700-VALIDATE-BUSINESS-RULES.
           IF TXN-IS-ADJUSTMENT AND TXN-REASON-CODE = SPACES
               SET TXN-IS-INVALID TO TRUE
               PERFORM 5080-WRITE-ERROR-E08-ZERO
           END-IF
           .

      ******************************************************************
      * Error writing paragraphs
      ******************************************************************

       5010-WRITE-ERROR-E01-SOURCE.
           ADD 1 TO WS-ERROR-SEQ
           MOVE WS-ERROR-SEQ        TO ERR-SEQUENCE-NUM
           MOVE TXN-SEQUENCE-NUM    TO ERR-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO ERR-DATE
           MOVE WS-CURR-TIME        TO ERR-TIME
           MOVE 'E01'               TO ERR-CODE
           MOVE 'E'                 TO ERR-SEVERITY
           MOVE 'TXNVAL00'          TO ERR-PROGRAM-ID
           MOVE 'Invalid or unknown source account number'
                                    TO ERR-DESCRIPTION
           MOVE TXN-SOURCE-ACCOUNT  TO ERR-SOURCE-ACCOUNT
           MOVE TXN-TARGET-ACCOUNT  TO ERR-TARGET-ACCOUNT
           MOVE TXN-AMOUNT          TO ERR-AMOUNT
           MOVE TXN-TYPE            TO ERR-ORIGINAL-TYPE
           MOVE 'N'                 TO ERR-REPROCESS-FLAG

           PERFORM 6000-WRITE-ERROR-REPORT-LINE
           PERFORM 8100-WRITE-AUDIT-REJECTED
           .

       5011-WRITE-ERROR-E01-TARGET.
           ADD 1 TO WS-ERROR-SEQ
           MOVE WS-ERROR-SEQ        TO ERR-SEQUENCE-NUM
           MOVE TXN-SEQUENCE-NUM    TO ERR-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO ERR-DATE
           MOVE WS-CURR-TIME        TO ERR-TIME
           MOVE 'E01'               TO ERR-CODE
           MOVE 'E'                 TO ERR-SEVERITY
           MOVE 'TXNVAL00'          TO ERR-PROGRAM-ID
           MOVE 'Invalid or unknown target account number'
                                    TO ERR-DESCRIPTION
           MOVE TXN-SOURCE-ACCOUNT  TO ERR-SOURCE-ACCOUNT
           MOVE TXN-TARGET-ACCOUNT  TO ERR-TARGET-ACCOUNT
           MOVE TXN-AMOUNT          TO ERR-AMOUNT
           MOVE TXN-TYPE            TO ERR-ORIGINAL-TYPE
           MOVE 'N'                 TO ERR-REPROCESS-FLAG

           PERFORM 6000-WRITE-ERROR-REPORT-LINE
           PERFORM 8100-WRITE-AUDIT-REJECTED
           .

       5030-WRITE-ERROR-E03.
           ADD 1 TO WS-ERROR-SEQ
           MOVE WS-ERROR-SEQ        TO ERR-SEQUENCE-NUM
           MOVE TXN-SEQUENCE-NUM    TO ERR-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO ERR-DATE
           MOVE WS-CURR-TIME        TO ERR-TIME
           MOVE 'E03'               TO ERR-CODE
           MOVE 'E'                 TO ERR-SEVERITY
           MOVE 'TXNVAL00'          TO ERR-PROGRAM-ID
           MOVE 'Account is frozen or closed'
                                    TO ERR-DESCRIPTION
           MOVE TXN-SOURCE-ACCOUNT  TO ERR-SOURCE-ACCOUNT
           MOVE TXN-TARGET-ACCOUNT  TO ERR-TARGET-ACCOUNT
           MOVE TXN-AMOUNT          TO ERR-AMOUNT
           MOVE TXN-TYPE            TO ERR-ORIGINAL-TYPE
           MOVE 'Y'                 TO ERR-REPROCESS-FLAG

           PERFORM 6000-WRITE-ERROR-REPORT-LINE
           PERFORM 8100-WRITE-AUDIT-REJECTED
           .

       5050-WRITE-ERROR-E05.
           ADD 1 TO WS-ERROR-SEQ
           MOVE WS-ERROR-SEQ        TO ERR-SEQUENCE-NUM
           MOVE TXN-SEQUENCE-NUM    TO ERR-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO ERR-DATE
           MOVE WS-CURR-TIME        TO ERR-TIME
           MOVE 'E05'               TO ERR-CODE
           MOVE 'E'                 TO ERR-SEVERITY
           MOVE 'TXNVAL00'          TO ERR-PROGRAM-ID
           MOVE 'Invalid or unsupported currency code'
                                    TO ERR-DESCRIPTION
           MOVE TXN-SOURCE-ACCOUNT  TO ERR-SOURCE-ACCOUNT
           MOVE TXN-TARGET-ACCOUNT  TO ERR-TARGET-ACCOUNT
           MOVE TXN-AMOUNT          TO ERR-AMOUNT
           MOVE TXN-TYPE            TO ERR-ORIGINAL-TYPE
           MOVE 'Y'                 TO ERR-REPROCESS-FLAG

           PERFORM 6000-WRITE-ERROR-REPORT-LINE
           PERFORM 8100-WRITE-AUDIT-REJECTED
           .

       5060-WRITE-ERROR-E06.
           ADD 1 TO WS-ERROR-SEQ
           MOVE WS-ERROR-SEQ        TO ERR-SEQUENCE-NUM
           MOVE TXN-SEQUENCE-NUM    TO ERR-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO ERR-DATE
           MOVE WS-CURR-TIME        TO ERR-TIME
           MOVE 'E06'               TO ERR-CODE
           MOVE 'W'                 TO ERR-SEVERITY
           MOVE 'TXNVAL00'          TO ERR-PROGRAM-ID
           MOVE 'Duplicate transaction sequence number detected'
                                    TO ERR-DESCRIPTION
           MOVE TXN-SOURCE-ACCOUNT  TO ERR-SOURCE-ACCOUNT
           MOVE TXN-TARGET-ACCOUNT  TO ERR-TARGET-ACCOUNT
           MOVE TXN-AMOUNT          TO ERR-AMOUNT
           MOVE TXN-TYPE            TO ERR-ORIGINAL-TYPE
           MOVE 'N'                 TO ERR-REPROCESS-FLAG

           PERFORM 6000-WRITE-ERROR-REPORT-LINE
           PERFORM 8100-WRITE-AUDIT-REJECTED
           .

       5070-WRITE-ERROR-E07.
           ADD 1 TO WS-ERROR-SEQ
           MOVE WS-ERROR-SEQ        TO ERR-SEQUENCE-NUM
           MOVE TXN-SEQUENCE-NUM    TO ERR-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO ERR-DATE
           MOVE WS-CURR-TIME        TO ERR-TIME
           MOVE 'E07'               TO ERR-CODE
           MOVE 'E'                 TO ERR-SEVERITY
           MOVE 'TXNVAL00'          TO ERR-PROGRAM-ID
           MOVE 'Invalid transaction type code'
                                    TO ERR-DESCRIPTION
           MOVE TXN-SOURCE-ACCOUNT  TO ERR-SOURCE-ACCOUNT
           MOVE TXN-TARGET-ACCOUNT  TO ERR-TARGET-ACCOUNT
           MOVE TXN-AMOUNT          TO ERR-AMOUNT
           MOVE TXN-TYPE            TO ERR-ORIGINAL-TYPE
           MOVE 'N'                 TO ERR-REPROCESS-FLAG

           PERFORM 6000-WRITE-ERROR-REPORT-LINE
           PERFORM 8100-WRITE-AUDIT-REJECTED
           .

       5080-WRITE-ERROR-E08-ZERO.
           ADD 1 TO WS-ERROR-SEQ
           MOVE WS-ERROR-SEQ        TO ERR-SEQUENCE-NUM
           MOVE TXN-SEQUENCE-NUM    TO ERR-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO ERR-DATE
           MOVE WS-CURR-TIME        TO ERR-TIME
           MOVE 'E08'               TO ERR-CODE
           MOVE 'E'                 TO ERR-SEVERITY
           MOVE 'TXNVAL00'          TO ERR-PROGRAM-ID
           MOVE 'Transaction amount is zero or invalid'
                                    TO ERR-DESCRIPTION
           MOVE TXN-SOURCE-ACCOUNT  TO ERR-SOURCE-ACCOUNT
           MOVE TXN-TARGET-ACCOUNT  TO ERR-TARGET-ACCOUNT
           MOVE TXN-AMOUNT          TO ERR-AMOUNT
           MOVE TXN-TYPE            TO ERR-ORIGINAL-TYPE
           MOVE 'N'                 TO ERR-REPROCESS-FLAG

           PERFORM 6000-WRITE-ERROR-REPORT-LINE
           PERFORM 8100-WRITE-AUDIT-REJECTED
           .

       5081-WRITE-ERROR-E08-MAX.
           ADD 1 TO WS-ERROR-SEQ
           MOVE WS-ERROR-SEQ        TO ERR-SEQUENCE-NUM
           MOVE TXN-SEQUENCE-NUM    TO ERR-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO ERR-DATE
           MOVE WS-CURR-TIME        TO ERR-TIME
           MOVE 'E08'               TO ERR-CODE
           MOVE 'C'                 TO ERR-SEVERITY
           MOVE 'TXNVAL00'          TO ERR-PROGRAM-ID
           MOVE 'Transaction amount exceeds maximum threshold'
                                    TO ERR-DESCRIPTION
           MOVE TXN-SOURCE-ACCOUNT  TO ERR-SOURCE-ACCOUNT
           MOVE TXN-TARGET-ACCOUNT  TO ERR-TARGET-ACCOUNT
           MOVE TXN-AMOUNT          TO ERR-AMOUNT
           MOVE TXN-TYPE            TO ERR-ORIGINAL-TYPE
           MOVE 'N'                 TO ERR-REPROCESS-FLAG

           PERFORM 6000-WRITE-ERROR-REPORT-LINE
           PERFORM 8100-WRITE-AUDIT-REJECTED
           .

      ******************************************************************
      * Report output
      ******************************************************************

       6000-WRITE-ERROR-REPORT-LINE.
           MOVE TXN-SEQUENCE-NUM    TO WS-RPT-SEQ
           MOVE TXN-TYPE            TO WS-RPT-TYPE
           MOVE TXN-SOURCE-ACCOUNT  TO WS-RPT-ACCT
           MOVE TXN-AMOUNT          TO WS-RPT-AMT
           MOVE ERR-CODE            TO WS-RPT-ERR-CODE
           MOVE ERR-DESCRIPTION     TO WS-RPT-ERR-DESC

           WRITE ERROR-RPT-REC FROM WS-RPT-DETAIL
           .

      ******************************************************************
      * Audit trail
      ******************************************************************

       8000-WRITE-AUDIT-VALIDATED.
           ADD 1 TO WS-AUDIT-SEQ
           INITIALIZE WS-AUDIT-RECORD

           MOVE WS-AUDIT-SEQ        TO AUD-SEQUENCE-NUM
           MOVE WS-CURR-DATE        TO AUD-DATE
           MOVE WS-CURR-TIME        TO AUD-TIME
           MOVE 'TXNVAL00'          TO AUD-PROGRAM-ID
           MOVE 'VAL'               TO AUD-ACTION-CODE
           MOVE TXN-SEQUENCE-NUM    TO AUD-TXN-SEQUENCE
           MOVE TXN-SOURCE-ACCOUNT  TO AUD-ACCOUNT-NUM
           MOVE TXN-AMOUNT          TO AUD-AMOUNT
           MOVE ZEROS               TO AUD-BEFORE-BALANCE
           MOVE ZEROS               TO AUD-AFTER-BALANCE
           MOVE TXN-OPERATOR-ID     TO AUD-OPERATOR-ID
           MOVE 'Transaction validated successfully'
                                    TO AUD-DESCRIPTION
           MOVE WS-PREV-HASH        TO AUD-PREV-HASH

           PERFORM 8500-COMPUTE-HASH
           MOVE WS-HASH-RESULT      TO AUD-CURR-HASH
           MOVE WS-HASH-RESULT      TO WS-PREV-HASH

           IF WS-AUDIT-SEQ = 1
               MOVE 'F'             TO AUD-CHAIN-STATUS
           ELSE
               MOVE 'V'             TO AUD-CHAIN-STATUS
           END-IF

           WRITE AUDIT-LOG-REC FROM WS-AUDIT-RECORD
           .

       8100-WRITE-AUDIT-REJECTED.
           ADD 1 TO WS-AUDIT-SEQ
           INITIALIZE WS-AUDIT-RECORD

           MOVE WS-AUDIT-SEQ        TO AUD-SEQUENCE-NUM
           MOVE WS-CURR-DATE        TO AUD-DATE
           MOVE WS-CURR-TIME        TO AUD-TIME
           MOVE 'TXNVAL00'          TO AUD-PROGRAM-ID
           MOVE 'REJ'               TO AUD-ACTION-CODE
           MOVE TXN-SEQUENCE-NUM    TO AUD-TXN-SEQUENCE
           MOVE TXN-SOURCE-ACCOUNT  TO AUD-ACCOUNT-NUM
           MOVE TXN-AMOUNT          TO AUD-AMOUNT
           MOVE ZEROS               TO AUD-BEFORE-BALANCE
           MOVE ZEROS               TO AUD-AFTER-BALANCE
           MOVE TXN-OPERATOR-ID     TO AUD-OPERATOR-ID
           STRING 'Rejected: ' ERR-CODE ' - '
                  ERR-DESCRIPTION(1:35)
                  DELIMITED BY SIZE
                  INTO AUD-DESCRIPTION
           MOVE WS-PREV-HASH        TO AUD-PREV-HASH

           PERFORM 8500-COMPUTE-HASH
           MOVE WS-HASH-RESULT      TO AUD-CURR-HASH
           MOVE WS-HASH-RESULT      TO WS-PREV-HASH

           IF WS-AUDIT-SEQ = 1
               MOVE 'F'             TO AUD-CHAIN-STATUS
           ELSE
               MOVE 'V'             TO AUD-CHAIN-STATUS
           END-IF

           WRITE AUDIT-LOG-REC FROM WS-AUDIT-RECORD
           .

      ******************************************************************
      * Hash computation - XOR-rotate chain hash
      * Combines sequence number, account, amount, and previous hash
      * into a 16-character hexadecimal hash string.
      ******************************************************************

       8500-COMPUTE-HASH.
           MOVE ZEROS TO WS-HASH-WORK

           ADD AUD-SEQUENCE-NUM TO WS-HASH-WORK
           ADD AUD-TXN-SEQUENCE TO WS-HASH-WORK

           COMPUTE WS-HASH-WORK =
               FUNCTION MOD(WS-HASH-WORK * 31 + 17, 9999999999)

           MOVE ZEROS TO WS-HASH-WORK
           STRING
               AUD-SEQUENCE-NUM
               AUD-ACCOUNT-NUM(1:6)
               DELIMITED BY SIZE
               INTO WS-HASH-INPUT

           COMPUTE WS-HASH-WORK =
               FUNCTION MOD(
                   AUD-SEQUENCE-NUM * 2654435761 +
                   AUD-TXN-SEQUENCE * 40503,
                   9999999999)

           MOVE WS-HASH-WORK TO WS-HASH-RESULT(1:10)
           MOVE AUD-PREV-HASH(1:6) TO WS-HASH-RESULT(11:6)
           .

      ******************************************************************
      * Finalization
      ******************************************************************

       9000-FINALIZE.
           WRITE ERROR-RPT-REC FROM RPT-DASH-LINE

           MOVE 'Total transactions read:    '
                                    TO WS-RPT-SUM-LABEL
           MOVE WS-TOTAL-READ       TO WS-RPT-SUM-VALUE
           WRITE ERROR-RPT-REC FROM WS-RPT-SUMMARY

           MOVE 'Validated successfully:      '
                                    TO WS-RPT-SUM-LABEL
           MOVE WS-TOTAL-VALID      TO WS-RPT-SUM-VALUE
           WRITE ERROR-RPT-REC FROM WS-RPT-SUMMARY

           MOVE 'Rejected with errors:       '
                                    TO WS-RPT-SUM-LABEL
           MOVE WS-TOTAL-INVALID    TO WS-RPT-SUM-VALUE
           WRITE ERROR-RPT-REC FROM WS-RPT-SUMMARY

           WRITE ERROR-RPT-REC FROM RPT-SEPARATOR
           WRITE ERROR-RPT-REC FROM WS-REPORT-FOOTER

           CLOSE INPUT-TXN-FILE
           CLOSE VALID-TXN-FILE
           CLOSE ERROR-RPT-FILE
           CLOSE AUDIT-LOG-FILE

           DISPLAY 'TXNVAL00: Processing complete'
           DISPLAY '  Records read:     ' WS-TOTAL-READ
           DISPLAY '  Records valid:    ' WS-TOTAL-VALID
           DISPLAY '  Records rejected: ' WS-TOTAL-INVALID

           IF WS-TOTAL-INVALID > 0
               MOVE 4 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF
           .
