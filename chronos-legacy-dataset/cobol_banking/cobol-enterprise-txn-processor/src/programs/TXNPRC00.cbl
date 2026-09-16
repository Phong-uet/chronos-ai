       IDENTIFICATION DIVISION.
       PROGRAM-ID.    TXNPRC00.
       AUTHOR.        ENTERPRISE FINANCIAL SYSTEMS.
       DATE-WRITTEN.  2026-03-31.
      ******************************************************************
      * TXNPRC00 - Transaction Processing Engine
      *
      * Second stage of the batch pipeline. Reads validated
      * transactions and applies business logic:
      *   - Deposit processing (credit to account)
      *   - Withdrawal processing (debit with balance check)
      *   - Transfer processing (atomic debit+credit)
      *   - Fee calculation (tiered by account type)
      *   - Interest computation (daily accrual by balance band)
      *   - Adjustment posting (with reason code audit)
      *
      * Produces:
      *   1. Processed transaction file (status = 'C')
      *   2. Journal entries (double-entry bookkeeping)
      *   3. Updated account master file
      *   4. Audit trail records
      ******************************************************************

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       REPOSITORY.
           FUNCTION ALL INTRINSIC.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT VALID-TXN-FILE
               ASSIGN TO 'data/work/valid-transactions.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-VALID-STATUS.

           SELECT PROCESSED-TXN-FILE
               ASSIGN TO 'data/work/processed-transactions.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-PROC-STATUS.

           SELECT JOURNAL-FILE
               ASSIGN TO 'data/work/journal-entries.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-JRNL-STATUS.

           SELECT ACCOUNT-IN-FILE
               ASSIGN TO 'data/input/accounts.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACTIN-STATUS.

           SELECT ACCOUNT-OUT-FILE
               ASSIGN TO 'data/work/accounts-updated.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACTOUT-STATUS.

           SELECT AUDIT-LOG-FILE
               ASSIGN TO 'data/work/txnprc-audit.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-AUDIT-STATUS.

           SELECT ERROR-FILE
               ASSIGN TO 'data/work/processing-errors.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ERROR-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  VALID-TXN-FILE
           RECORDING MODE IS F.
       01  VALID-TXN-REC              PIC X(200).

       FD  PROCESSED-TXN-FILE
           RECORDING MODE IS F.
       01  PROCESSED-TXN-REC          PIC X(200).

       FD  JOURNAL-FILE
           RECORDING MODE IS F.
       01  JOURNAL-FILE-REC           PIC X(150).

       FD  ACCOUNT-IN-FILE
           RECORDING MODE IS F.
       01  ACCOUNT-IN-REC             PIC X(200).

       FD  ACCOUNT-OUT-FILE
           RECORDING MODE IS F.
       01  ACCOUNT-OUT-REC            PIC X(200).

       FD  AUDIT-LOG-FILE
           RECORDING MODE IS F.
       01  AUDIT-LOG-REC              PIC X(250).

       FD  ERROR-FILE
           RECORDING MODE IS F.
       01  ERROR-FILE-REC             PIC X(180).

       WORKING-STORAGE SECTION.

      * File status variables
       01  WS-VALID-STATUS             PIC X(02).
       01  WS-PROC-STATUS              PIC X(02).
       01  WS-JRNL-STATUS              PIC X(02).
       01  WS-ACTIN-STATUS             PIC X(02).
       01  WS-ACTOUT-STATUS            PIC X(02).
       01  WS-AUDIT-STATUS             PIC X(02).
       01  WS-ERROR-STATUS             PIC X(02).

      * Control flags
       01  WS-EOF-FLAG                 PIC X(01) VALUE 'N'.
           88  END-OF-FILE             VALUE 'Y'.
           88  NOT-END-OF-FILE         VALUE 'N'.

       01  WS-ACCT-EOF                 PIC X(01) VALUE 'N'.
           88  ACCT-EOF                VALUE 'Y'.
           88  ACCT-NOT-EOF            VALUE 'N'.

       01  WS-PROCESS-OK              PIC X(01) VALUE 'Y'.
           88  PROCESSING-SUCCESS      VALUE 'Y'.
           88  PROCESSING-FAILED       VALUE 'N'.

      * Copybook includes
       COPY 'src/copybooks/TXNREC.cpy'.
       COPY 'src/copybooks/ACTREC.cpy'.
       COPY 'src/copybooks/JRNREC.cpy'.
       COPY 'src/copybooks/ERRREC.cpy'.
       COPY 'src/copybooks/AUDREC.cpy'.

      * Account master table (in-memory for processing)
       01  WS-ACCT-TABLE.
           05  WS-ACCT-COUNT          PIC 9(05) VALUE 0.
           05  WS-ACCT-ENTRY OCCURS 1000 TIMES.
               10  WS-AT-ACCOUNT-NUM      PIC X(12).
               10  WS-AT-ACCOUNT-NAME     PIC X(30).
               10  WS-AT-ACCOUNT-TYPE     PIC X(03).
               10  WS-AT-TIER             PIC X(01).
               10  WS-AT-STATUS           PIC X(01).
               10  WS-AT-CURRENCY         PIC X(03).
               10  WS-AT-OPEN-BAL         PIC S9(13)V99.
               10  WS-AT-CURR-BAL         PIC S9(13)V99.
               10  WS-AT-DAILY-DEBIT      PIC 9(13)V99.
               10  WS-AT-DAILY-CREDIT     PIC 9(13)V99.
               10  WS-AT-DAILY-TXN-CT     PIC 9(05).
               10  WS-AT-DAILY-XFR        PIC 9(13)V99.
               10  WS-AT-XFR-LIMIT        PIC 9(13)V99.
               10  WS-AT-OVERDRAFT        PIC 9(13)V99.
               10  WS-AT-RISK-WEIGHT      PIC 9V99.
               10  WS-AT-SECTOR           PIC X(04).
               10  WS-AT-OPEN-DATE        PIC 9(08).
               10  WS-AT-LAST-TXN         PIC 9(08).
               10  WS-AT-BRANCH           PIC X(06).

      * Fee schedule
       01  WS-FEE-SCHEDULE.
           05  WS-FEE-STANDARD        PIC 9V9999 VALUE 0.0015.
           05  WS-FEE-PREMIUM         PIC 9V9999 VALUE 0.0008.
           05  WS-FEE-INSTITUTIONAL   PIC 9V9999 VALUE 0.0003.

      * Interest rate bands
       01  WS-INTEREST-RATES.
           05  WS-INT-BAND1-LIMIT     PIC 9(13)V99
               VALUE 10000.00.
           05  WS-INT-BAND1-RATE      PIC 9V9999 VALUE 0.0150.
           05  WS-INT-BAND2-LIMIT     PIC 9(13)V99
               VALUE 100000.00.
           05  WS-INT-BAND2-RATE      PIC 9V9999 VALUE 0.0225.
           05  WS-INT-BAND3-RATE      PIC 9V9999 VALUE 0.0310.

      * Processing counters
       01  WS-COUNTERS.
           05  WS-TXN-READ            PIC 9(08) VALUE 0.
           05  WS-TXN-PROCESSED       PIC 9(08) VALUE 0.
           05  WS-TXN-FAILED          PIC 9(08) VALUE 0.
           05  WS-JRN-WRITTEN         PIC 9(08) VALUE 0.
           05  WS-JOURNAL-SEQ         PIC 9(10) VALUE 0.
           05  WS-AUDIT-SEQ           PIC 9(10) VALUE 0.
           05  WS-ERROR-SEQ           PIC 9(10) VALUE 0.

      * Work fields
       01  WS-WORK-FIELDS.
           05  WS-CURR-DATE           PIC 9(08).
           05  WS-CURR-TIME           PIC 9(06).
           05  WS-SRC-IDX             PIC 9(05).
           05  WS-TGT-IDX             PIC 9(05).
           05  WS-SEARCH-IDX          PIC 9(05).
           05  WS-FOUND-FLAG          PIC X(01).
           05  WS-BEFORE-BAL          PIC S9(13)V99.
           05  WS-AFTER-BAL           PIC S9(13)V99.
           05  WS-FEE-AMOUNT          PIC 9(13)V99.
           05  WS-INT-AMOUNT          PIC 9(13)V99.
           05  WS-DAILY-RATE          PIC 9V9(08).
           05  WS-EFFECTIVE-BAL       PIC S9(13)V99.
           05  WS-PREV-HASH           PIC X(16) VALUE ALL '0'.
           05  WS-HASH-RESULT         PIC X(16).
           05  WS-HASH-WORK           PIC 9(10).

      * Internal fee and revenue accounts
       01  WS-INTERNAL-ACCOUNTS.
           05  WS-FEE-REVENUE-ACCT    PIC X(12)
               VALUE 'FEREVENUE001'.
           05  WS-INT-EXPENSE-ACCT    PIC X(12)
               VALUE 'INTEXPENS001'.
           05  WS-SUSPENSE-ACCT       PIC X(12)
               VALUE 'SUSPENSE0001'.

       PROCEDURE DIVISION.
       0000-MAIN-CONTROL.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-LOAD-ACCOUNTS
           PERFORM 3000-PROCESS-TRANSACTIONS
           PERFORM 7000-WRITE-ACCOUNTS
           PERFORM 9000-FINALIZE
           STOP RUN
           .

       1000-INITIALIZE.
           MOVE FUNCTION CURRENT-DATE(1:8) TO WS-CURR-DATE
           MOVE FUNCTION CURRENT-DATE(9:6) TO WS-CURR-TIME

           OPEN INPUT  VALID-TXN-FILE
           OPEN OUTPUT PROCESSED-TXN-FILE
           OPEN OUTPUT JOURNAL-FILE
           OPEN OUTPUT AUDIT-LOG-FILE
           OPEN OUTPUT ERROR-FILE

           IF WS-VALID-STATUS NOT = '00'
               DISPLAY 'ERROR: Cannot open validated txn file'
               STOP RUN
           END-IF

           DISPLAY 'TXNPRC00: Initialization complete'
           .

       2000-LOAD-ACCOUNTS.
           OPEN INPUT ACCOUNT-IN-FILE
           IF WS-ACTIN-STATUS NOT = '00'
               DISPLAY 'ERROR: Cannot open account master file'
               STOP RUN
           END-IF

           SET ACCT-NOT-EOF TO TRUE
           PERFORM UNTIL ACCT-EOF
               READ ACCOUNT-IN-FILE INTO WS-ACCOUNT-RECORD
                   AT END
                       SET ACCT-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO WS-ACCT-COUNT
                       MOVE ACT-ACCOUNT-NUM
                           TO WS-AT-ACCOUNT-NUM(WS-ACCT-COUNT)
                       MOVE ACT-ACCOUNT-NAME
                           TO WS-AT-ACCOUNT-NAME(WS-ACCT-COUNT)
                       MOVE ACT-ACCOUNT-TYPE
                           TO WS-AT-ACCOUNT-TYPE(WS-ACCT-COUNT)
                       MOVE ACT-TIER
                           TO WS-AT-TIER(WS-ACCT-COUNT)
                       MOVE ACT-STATUS
                           TO WS-AT-STATUS(WS-ACCT-COUNT)
                       MOVE ACT-CURRENCY
                           TO WS-AT-CURRENCY(WS-ACCT-COUNT)
                       MOVE ACT-OPENING-BALANCE
                           TO WS-AT-OPEN-BAL(WS-ACCT-COUNT)
                       MOVE ACT-CURRENT-BALANCE
                           TO WS-AT-CURR-BAL(WS-ACCT-COUNT)
                       MOVE ACT-DAILY-DEBIT-TOTAL
                           TO WS-AT-DAILY-DEBIT(WS-ACCT-COUNT)
                       MOVE ACT-DAILY-CREDIT-TOTAL
                           TO WS-AT-DAILY-CREDIT(WS-ACCT-COUNT)
                       MOVE ACT-DAILY-TXN-COUNT
                           TO WS-AT-DAILY-TXN-CT(WS-ACCT-COUNT)
                       MOVE ACT-DAILY-XFR-TOTAL
                           TO WS-AT-DAILY-XFR(WS-ACCT-COUNT)
                       MOVE ACT-DAILY-XFR-LIMIT
                           TO WS-AT-XFR-LIMIT(WS-ACCT-COUNT)
                       MOVE ACT-OVERDRAFT-LIMIT
                           TO WS-AT-OVERDRAFT(WS-ACCT-COUNT)
                       MOVE ACT-RISK-WEIGHT
                           TO WS-AT-RISK-WEIGHT(WS-ACCT-COUNT)
                       MOVE ACT-SECTOR-CODE
                           TO WS-AT-SECTOR(WS-ACCT-COUNT)
                       MOVE ACT-OPEN-DATE
                           TO WS-AT-OPEN-DATE(WS-ACCT-COUNT)
                       MOVE ACT-LAST-TXN-DATE
                           TO WS-AT-LAST-TXN(WS-ACCT-COUNT)
                       MOVE ACT-BRANCH-CODE
                           TO WS-AT-BRANCH(WS-ACCT-COUNT)
               END-READ
           END-PERFORM

           CLOSE ACCOUNT-IN-FILE
           DISPLAY 'TXNPRC00: Loaded ' WS-ACCT-COUNT ' accounts'
           .

       3000-PROCESS-TRANSACTIONS.
           SET NOT-END-OF-FILE TO TRUE

           PERFORM UNTIL END-OF-FILE
               READ VALID-TXN-FILE INTO WS-TRANSACTION-RECORD
                   AT END
                       SET END-OF-FILE TO TRUE
                   NOT AT END
                       ADD 1 TO WS-TXN-READ
                       SET PROCESSING-SUCCESS TO TRUE
                       PERFORM 4000-ROUTE-TRANSACTION
               END-READ
           END-PERFORM
           .

       4000-ROUTE-TRANSACTION.
      * Find source account index
           PERFORM 4050-FIND-SOURCE-ACCOUNT

           EVALUATE TRUE
               WHEN TXN-IS-DEPOSIT
                   PERFORM 4100-PROCESS-DEPOSIT
               WHEN TXN-IS-WITHDRAWAL
                   PERFORM 4200-PROCESS-WITHDRAWAL
               WHEN TXN-IS-TRANSFER
                   PERFORM 4300-PROCESS-TRANSFER
               WHEN TXN-IS-FEE
                   PERFORM 4400-PROCESS-FEE
               WHEN TXN-IS-INTEREST
                   PERFORM 4500-PROCESS-INTEREST
               WHEN TXN-IS-ADJUSTMENT
                   PERFORM 4600-PROCESS-ADJUSTMENT
           END-EVALUATE

           IF PROCESSING-SUCCESS
               MOVE 'C' TO TXN-STATUS
               WRITE PROCESSED-TXN-REC
                   FROM WS-TRANSACTION-RECORD
               ADD 1 TO WS-TXN-PROCESSED
           ELSE
               MOVE 'R' TO TXN-STATUS
               ADD 1 TO WS-TXN-FAILED
           END-IF
           .

       4050-FIND-SOURCE-ACCOUNT.
           MOVE 0 TO WS-SRC-IDX
           PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
               UNTIL WS-SEARCH-IDX > WS-ACCT-COUNT
               OR WS-SRC-IDX > 0
               IF WS-AT-ACCOUNT-NUM(WS-SEARCH-IDX)
                   = TXN-SOURCE-ACCOUNT
                   MOVE WS-SEARCH-IDX TO WS-SRC-IDX
               END-IF
           END-PERFORM
           .

       4100-PROCESS-DEPOSIT.
           MOVE WS-AT-CURR-BAL(WS-SRC-IDX) TO WS-BEFORE-BAL
           ADD TXN-AMOUNT TO WS-AT-CURR-BAL(WS-SRC-IDX)
           MOVE WS-AT-CURR-BAL(WS-SRC-IDX) TO WS-AFTER-BAL
           ADD TXN-AMOUNT TO WS-AT-DAILY-CREDIT(WS-SRC-IDX)
           ADD 1 TO WS-AT-DAILY-TXN-CT(WS-SRC-IDX)
           MOVE WS-CURR-DATE TO WS-AT-LAST-TXN(WS-SRC-IDX)

      * Journal: debit cash-in-transit, credit customer account
           PERFORM 5100-WRITE-DEPOSIT-JOURNAL

      * Audit
           PERFORM 6100-WRITE-PROCESS-AUDIT
           .

       4200-PROCESS-WITHDRAWAL.
           MOVE WS-AT-CURR-BAL(WS-SRC-IDX) TO WS-BEFORE-BAL

      * Check sufficient funds (balance + overdraft limit)
           COMPUTE WS-EFFECTIVE-BAL =
               WS-AT-CURR-BAL(WS-SRC-IDX)
               + WS-AT-OVERDRAFT(WS-SRC-IDX)

           IF TXN-AMOUNT > WS-EFFECTIVE-BAL
               SET PROCESSING-FAILED TO TRUE
               PERFORM 6500-WRITE-INSUF-FUNDS-ERROR
           ELSE
               SUBTRACT TXN-AMOUNT
                   FROM WS-AT-CURR-BAL(WS-SRC-IDX)
               MOVE WS-AT-CURR-BAL(WS-SRC-IDX)
                   TO WS-AFTER-BAL
               ADD TXN-AMOUNT
                   TO WS-AT-DAILY-DEBIT(WS-SRC-IDX)
               ADD 1 TO WS-AT-DAILY-TXN-CT(WS-SRC-IDX)
               MOVE WS-CURR-DATE
                   TO WS-AT-LAST-TXN(WS-SRC-IDX)

               PERFORM 5200-WRITE-WITHDRAWAL-JOURNAL
               PERFORM 6100-WRITE-PROCESS-AUDIT
           END-IF
           .

       4300-PROCESS-TRANSFER.
      * Find target account
           MOVE 0 TO WS-TGT-IDX
           PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
               UNTIL WS-SEARCH-IDX > WS-ACCT-COUNT
               OR WS-TGT-IDX > 0
               IF WS-AT-ACCOUNT-NUM(WS-SEARCH-IDX)
                   = TXN-TARGET-ACCOUNT
                   MOVE WS-SEARCH-IDX TO WS-TGT-IDX
               END-IF
           END-PERFORM

      * Check daily transfer limit
           COMPUTE WS-EFFECTIVE-BAL =
               WS-AT-DAILY-XFR(WS-SRC-IDX) + TXN-AMOUNT

           IF WS-AT-XFR-LIMIT(WS-SRC-IDX) > 0
              AND WS-EFFECTIVE-BAL >
                  WS-AT-XFR-LIMIT(WS-SRC-IDX)
               SET PROCESSING-FAILED TO TRUE
               PERFORM 6600-WRITE-LIMIT-ERROR
           ELSE
      * Check sufficient funds
               COMPUTE WS-EFFECTIVE-BAL =
                   WS-AT-CURR-BAL(WS-SRC-IDX)
                   + WS-AT-OVERDRAFT(WS-SRC-IDX)

               IF TXN-AMOUNT > WS-EFFECTIVE-BAL
                   SET PROCESSING-FAILED TO TRUE
                   PERFORM 6500-WRITE-INSUF-FUNDS-ERROR
               ELSE
                   MOVE WS-AT-CURR-BAL(WS-SRC-IDX)
                       TO WS-BEFORE-BAL

      * Debit source
                   SUBTRACT TXN-AMOUNT
                       FROM WS-AT-CURR-BAL(WS-SRC-IDX)
                   ADD TXN-AMOUNT
                       TO WS-AT-DAILY-DEBIT(WS-SRC-IDX)
                   ADD TXN-AMOUNT
                       TO WS-AT-DAILY-XFR(WS-SRC-IDX)
                   ADD 1 TO WS-AT-DAILY-TXN-CT(WS-SRC-IDX)
                   MOVE WS-CURR-DATE
                       TO WS-AT-LAST-TXN(WS-SRC-IDX)

      * Credit target
                   ADD TXN-AMOUNT
                       TO WS-AT-CURR-BAL(WS-TGT-IDX)
                   ADD TXN-AMOUNT
                       TO WS-AT-DAILY-CREDIT(WS-TGT-IDX)
                   ADD 1 TO WS-AT-DAILY-TXN-CT(WS-TGT-IDX)
                   MOVE WS-CURR-DATE
                       TO WS-AT-LAST-TXN(WS-TGT-IDX)

                   MOVE WS-AT-CURR-BAL(WS-SRC-IDX)
                       TO WS-AFTER-BAL

                   PERFORM 5300-WRITE-TRANSFER-JOURNAL
                   PERFORM 6100-WRITE-PROCESS-AUDIT
               END-IF
           END-IF
           .

       4400-PROCESS-FEE.
      * Calculate fee based on account tier
           EVALUATE WS-AT-TIER(WS-SRC-IDX)
               WHEN 'S'
                   COMPUTE WS-FEE-AMOUNT =
                       TXN-AMOUNT * WS-FEE-STANDARD
               WHEN 'P'
                   COMPUTE WS-FEE-AMOUNT =
                       TXN-AMOUNT * WS-FEE-PREMIUM
               WHEN 'I'
                   COMPUTE WS-FEE-AMOUNT =
                       TXN-AMOUNT * WS-FEE-INSTITUTIONAL
               WHEN OTHER
                   COMPUTE WS-FEE-AMOUNT =
                       TXN-AMOUNT * WS-FEE-STANDARD
           END-EVALUATE

           MOVE WS-AT-CURR-BAL(WS-SRC-IDX) TO WS-BEFORE-BAL
           SUBTRACT WS-FEE-AMOUNT
               FROM WS-AT-CURR-BAL(WS-SRC-IDX)
           MOVE WS-AT-CURR-BAL(WS-SRC-IDX) TO WS-AFTER-BAL
           ADD WS-FEE-AMOUNT
               TO WS-AT-DAILY-DEBIT(WS-SRC-IDX)
           ADD 1 TO WS-AT-DAILY-TXN-CT(WS-SRC-IDX)

           MOVE WS-FEE-AMOUNT TO TXN-AMOUNT
           PERFORM 5400-WRITE-FEE-JOURNAL
           PERFORM 6100-WRITE-PROCESS-AUDIT
           .

       4500-PROCESS-INTEREST.
      * Calculate interest based on balance bands
           MOVE WS-AT-CURR-BAL(WS-SRC-IDX) TO WS-EFFECTIVE-BAL

           IF WS-EFFECTIVE-BAL <= 0
               MOVE 0 TO WS-INT-AMOUNT
           ELSE IF WS-EFFECTIVE-BAL <= WS-INT-BAND1-LIMIT
               COMPUTE WS-DAILY-RATE =
                   WS-INT-BAND1-RATE / 365
               COMPUTE WS-INT-AMOUNT =
                   WS-EFFECTIVE-BAL * WS-DAILY-RATE
           ELSE IF WS-EFFECTIVE-BAL <= WS-INT-BAND2-LIMIT
               COMPUTE WS-DAILY-RATE =
                   WS-INT-BAND2-RATE / 365
               COMPUTE WS-INT-AMOUNT =
                   WS-EFFECTIVE-BAL * WS-DAILY-RATE
           ELSE
               COMPUTE WS-DAILY-RATE =
                   WS-INT-BAND3-RATE / 365
               COMPUTE WS-INT-AMOUNT =
                   WS-EFFECTIVE-BAL * WS-DAILY-RATE
           END-IF

           MOVE WS-AT-CURR-BAL(WS-SRC-IDX) TO WS-BEFORE-BAL
           ADD WS-INT-AMOUNT TO WS-AT-CURR-BAL(WS-SRC-IDX)
           MOVE WS-AT-CURR-BAL(WS-SRC-IDX) TO WS-AFTER-BAL
           ADD WS-INT-AMOUNT
               TO WS-AT-DAILY-CREDIT(WS-SRC-IDX)
           ADD 1 TO WS-AT-DAILY-TXN-CT(WS-SRC-IDX)

           MOVE WS-INT-AMOUNT TO TXN-AMOUNT
           PERFORM 5500-WRITE-INTEREST-JOURNAL
           PERFORM 6100-WRITE-PROCESS-AUDIT
           .

       4600-PROCESS-ADJUSTMENT.
           MOVE WS-AT-CURR-BAL(WS-SRC-IDX) TO WS-BEFORE-BAL
           ADD TXN-AMOUNT TO WS-AT-CURR-BAL(WS-SRC-IDX)
           MOVE WS-AT-CURR-BAL(WS-SRC-IDX) TO WS-AFTER-BAL
           ADD 1 TO WS-AT-DAILY-TXN-CT(WS-SRC-IDX)
           MOVE WS-CURR-DATE TO WS-AT-LAST-TXN(WS-SRC-IDX)

           PERFORM 5600-WRITE-ADJUSTMENT-JOURNAL
           PERFORM 6100-WRITE-PROCESS-AUDIT
           .

      ******************************************************************
      * Journal entry writing paragraphs
      ******************************************************************

       5100-WRITE-DEPOSIT-JOURNAL.
           ADD 1 TO WS-JOURNAL-SEQ
           INITIALIZE WS-JOURNAL-RECORD
           MOVE WS-JOURNAL-SEQ      TO JRN-ENTRY-NUM
           MOVE TXN-SEQUENCE-NUM    TO JRN-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO JRN-DATE
           MOVE WS-CURR-TIME        TO JRN-TIME
           MOVE WS-SUSPENSE-ACCT    TO JRN-DEBIT-ACCOUNT
           MOVE TXN-SOURCE-ACCOUNT  TO JRN-CREDIT-ACCOUNT
           MOVE TXN-AMOUNT          TO JRN-AMOUNT
           MOVE 'PRI'               TO JRN-ENTRY-TYPE
           MOVE 'Deposit to customer account'
                                    TO JRN-DESCRIPTION
           MOVE 'TXNPRC00'          TO JRN-PROGRAM-ID
           MOVE 'P'                 TO JRN-STATUS

           WRITE JOURNAL-FILE-REC FROM WS-JOURNAL-RECORD
           ADD 1 TO WS-JRN-WRITTEN
           .

       5200-WRITE-WITHDRAWAL-JOURNAL.
           ADD 1 TO WS-JOURNAL-SEQ
           INITIALIZE WS-JOURNAL-RECORD
           MOVE WS-JOURNAL-SEQ      TO JRN-ENTRY-NUM
           MOVE TXN-SEQUENCE-NUM    TO JRN-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO JRN-DATE
           MOVE WS-CURR-TIME        TO JRN-TIME
           MOVE TXN-SOURCE-ACCOUNT  TO JRN-DEBIT-ACCOUNT
           MOVE WS-SUSPENSE-ACCT    TO JRN-CREDIT-ACCOUNT
           MOVE TXN-AMOUNT          TO JRN-AMOUNT
           MOVE 'PRI'               TO JRN-ENTRY-TYPE
           MOVE 'Withdrawal from customer account'
                                    TO JRN-DESCRIPTION
           MOVE 'TXNPRC00'          TO JRN-PROGRAM-ID
           MOVE 'P'                 TO JRN-STATUS

           WRITE JOURNAL-FILE-REC FROM WS-JOURNAL-RECORD
           ADD 1 TO WS-JRN-WRITTEN
           .

       5300-WRITE-TRANSFER-JOURNAL.
           ADD 1 TO WS-JOURNAL-SEQ
           INITIALIZE WS-JOURNAL-RECORD
           MOVE WS-JOURNAL-SEQ      TO JRN-ENTRY-NUM
           MOVE TXN-SEQUENCE-NUM    TO JRN-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO JRN-DATE
           MOVE WS-CURR-TIME        TO JRN-TIME
           MOVE TXN-SOURCE-ACCOUNT  TO JRN-DEBIT-ACCOUNT
           MOVE TXN-TARGET-ACCOUNT  TO JRN-CREDIT-ACCOUNT
           MOVE TXN-AMOUNT          TO JRN-AMOUNT
           MOVE 'PRI'               TO JRN-ENTRY-TYPE
           MOVE 'Inter-account transfer'
                                    TO JRN-DESCRIPTION
           MOVE 'TXNPRC00'          TO JRN-PROGRAM-ID
           MOVE 'P'                 TO JRN-STATUS

           WRITE JOURNAL-FILE-REC FROM WS-JOURNAL-RECORD
           ADD 1 TO WS-JRN-WRITTEN
           .

       5400-WRITE-FEE-JOURNAL.
           ADD 1 TO WS-JOURNAL-SEQ
           INITIALIZE WS-JOURNAL-RECORD
           MOVE WS-JOURNAL-SEQ      TO JRN-ENTRY-NUM
           MOVE TXN-SEQUENCE-NUM    TO JRN-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO JRN-DATE
           MOVE WS-CURR-TIME        TO JRN-TIME
           MOVE TXN-SOURCE-ACCOUNT  TO JRN-DEBIT-ACCOUNT
           MOVE WS-FEE-REVENUE-ACCT TO JRN-CREDIT-ACCOUNT
           MOVE WS-FEE-AMOUNT       TO JRN-AMOUNT
           MOVE 'FEE'               TO JRN-ENTRY-TYPE
           MOVE 'Transaction fee assessment'
                                    TO JRN-DESCRIPTION
           MOVE 'TXNPRC00'          TO JRN-PROGRAM-ID
           MOVE 'P'                 TO JRN-STATUS

           WRITE JOURNAL-FILE-REC FROM WS-JOURNAL-RECORD
           ADD 1 TO WS-JRN-WRITTEN
           .

       5500-WRITE-INTEREST-JOURNAL.
           ADD 1 TO WS-JOURNAL-SEQ
           INITIALIZE WS-JOURNAL-RECORD
           MOVE WS-JOURNAL-SEQ      TO JRN-ENTRY-NUM
           MOVE TXN-SEQUENCE-NUM    TO JRN-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO JRN-DATE
           MOVE WS-CURR-TIME        TO JRN-TIME
           MOVE WS-INT-EXPENSE-ACCT TO JRN-DEBIT-ACCOUNT
           MOVE TXN-SOURCE-ACCOUNT  TO JRN-CREDIT-ACCOUNT
           MOVE WS-INT-AMOUNT       TO JRN-AMOUNT
           MOVE 'INT'               TO JRN-ENTRY-TYPE
           MOVE 'Daily interest accrual'
                                    TO JRN-DESCRIPTION
           MOVE 'TXNPRC00'          TO JRN-PROGRAM-ID
           MOVE 'P'                 TO JRN-STATUS

           WRITE JOURNAL-FILE-REC FROM WS-JOURNAL-RECORD
           ADD 1 TO WS-JRN-WRITTEN
           .

       5600-WRITE-ADJUSTMENT-JOURNAL.
           ADD 1 TO WS-JOURNAL-SEQ
           INITIALIZE WS-JOURNAL-RECORD
           MOVE WS-JOURNAL-SEQ      TO JRN-ENTRY-NUM
           MOVE TXN-SEQUENCE-NUM    TO JRN-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO JRN-DATE
           MOVE WS-CURR-TIME        TO JRN-TIME
           MOVE WS-SUSPENSE-ACCT    TO JRN-DEBIT-ACCOUNT
           MOVE TXN-SOURCE-ACCOUNT  TO JRN-CREDIT-ACCOUNT
           MOVE TXN-AMOUNT          TO JRN-AMOUNT
           MOVE 'ADJ'               TO JRN-ENTRY-TYPE
           STRING 'Adjustment: ' TXN-REASON-CODE
               DELIMITED BY SIZE
               INTO JRN-DESCRIPTION
           MOVE 'TXNPRC00'          TO JRN-PROGRAM-ID
           MOVE 'P'                 TO JRN-STATUS

           WRITE JOURNAL-FILE-REC FROM WS-JOURNAL-RECORD
           ADD 1 TO WS-JRN-WRITTEN
           .

      ******************************************************************
      * Audit trail writing
      ******************************************************************

       6100-WRITE-PROCESS-AUDIT.
           ADD 1 TO WS-AUDIT-SEQ
           INITIALIZE WS-AUDIT-RECORD

           MOVE WS-AUDIT-SEQ        TO AUD-SEQUENCE-NUM
           MOVE WS-CURR-DATE        TO AUD-DATE
           MOVE WS-CURR-TIME        TO AUD-TIME
           MOVE 'TXNPRC00'          TO AUD-PROGRAM-ID
           MOVE 'PRC'               TO AUD-ACTION-CODE
           MOVE TXN-SEQUENCE-NUM    TO AUD-TXN-SEQUENCE
           MOVE TXN-SOURCE-ACCOUNT  TO AUD-ACCOUNT-NUM
           MOVE TXN-AMOUNT          TO AUD-AMOUNT
           MOVE WS-BEFORE-BAL       TO AUD-BEFORE-BALANCE
           MOVE WS-AFTER-BAL        TO AUD-AFTER-BALANCE
           MOVE TXN-OPERATOR-ID     TO AUD-OPERATOR-ID
           STRING 'Processed ' TXN-TYPE ' transaction'
               DELIMITED BY SIZE
               INTO AUD-DESCRIPTION
           MOVE WS-PREV-HASH        TO AUD-PREV-HASH

           PERFORM 8500-COMPUTE-HASH
           MOVE WS-HASH-RESULT      TO AUD-CURR-HASH
           MOVE WS-HASH-RESULT      TO WS-PREV-HASH

           IF WS-AUDIT-SEQ = 1
               MOVE 'F' TO AUD-CHAIN-STATUS
           ELSE
               MOVE 'V' TO AUD-CHAIN-STATUS
           END-IF

           WRITE AUDIT-LOG-REC FROM WS-AUDIT-RECORD
           .

      ******************************************************************
      * Error writing
      ******************************************************************

       6500-WRITE-INSUF-FUNDS-ERROR.
           ADD 1 TO WS-ERROR-SEQ
           INITIALIZE WS-ERROR-RECORD
           MOVE WS-ERROR-SEQ        TO ERR-SEQUENCE-NUM
           MOVE TXN-SEQUENCE-NUM    TO ERR-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO ERR-DATE
           MOVE WS-CURR-TIME        TO ERR-TIME
           MOVE 'E02'               TO ERR-CODE
           MOVE 'E'                 TO ERR-SEVERITY
           MOVE 'TXNPRC00'          TO ERR-PROGRAM-ID
           MOVE 'Insufficient funds for transaction'
                                    TO ERR-DESCRIPTION
           MOVE TXN-SOURCE-ACCOUNT  TO ERR-SOURCE-ACCOUNT
           MOVE TXN-TARGET-ACCOUNT  TO ERR-TARGET-ACCOUNT
           MOVE TXN-AMOUNT          TO ERR-AMOUNT
           MOVE TXN-TYPE            TO ERR-ORIGINAL-TYPE
           MOVE 'Y'                 TO ERR-REPROCESS-FLAG

           WRITE ERROR-FILE-REC FROM WS-ERROR-RECORD
           .

       6600-WRITE-LIMIT-ERROR.
           ADD 1 TO WS-ERROR-SEQ
           INITIALIZE WS-ERROR-RECORD
           MOVE WS-ERROR-SEQ        TO ERR-SEQUENCE-NUM
           MOVE TXN-SEQUENCE-NUM    TO ERR-TXN-SEQUENCE
           MOVE WS-CURR-DATE        TO ERR-DATE
           MOVE WS-CURR-TIME        TO ERR-TIME
           MOVE 'E04'               TO ERR-CODE
           MOVE 'E'                 TO ERR-SEVERITY
           MOVE 'TXNPRC00'          TO ERR-PROGRAM-ID
           MOVE 'Daily transfer limit exceeded'
                                    TO ERR-DESCRIPTION
           MOVE TXN-SOURCE-ACCOUNT  TO ERR-SOURCE-ACCOUNT
           MOVE TXN-TARGET-ACCOUNT  TO ERR-TARGET-ACCOUNT
           MOVE TXN-AMOUNT          TO ERR-AMOUNT
           MOVE TXN-TYPE            TO ERR-ORIGINAL-TYPE
           MOVE 'Y'                 TO ERR-REPROCESS-FLAG

           WRITE ERROR-FILE-REC FROM WS-ERROR-RECORD
           .

      ******************************************************************
      * Write updated account master
      ******************************************************************

       7000-WRITE-ACCOUNTS.
           OPEN OUTPUT ACCOUNT-OUT-FILE

           PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
               UNTIL WS-SEARCH-IDX > WS-ACCT-COUNT

               INITIALIZE WS-ACCOUNT-RECORD
               MOVE WS-AT-ACCOUNT-NUM(WS-SEARCH-IDX)
                   TO ACT-ACCOUNT-NUM
               MOVE WS-AT-ACCOUNT-NAME(WS-SEARCH-IDX)
                   TO ACT-ACCOUNT-NAME
               MOVE WS-AT-ACCOUNT-TYPE(WS-SEARCH-IDX)
                   TO ACT-ACCOUNT-TYPE
               MOVE WS-AT-TIER(WS-SEARCH-IDX)
                   TO ACT-TIER
               MOVE WS-AT-STATUS(WS-SEARCH-IDX)
                   TO ACT-STATUS
               MOVE WS-AT-CURRENCY(WS-SEARCH-IDX)
                   TO ACT-CURRENCY
               MOVE WS-AT-OPEN-BAL(WS-SEARCH-IDX)
                   TO ACT-OPENING-BALANCE
               MOVE WS-AT-CURR-BAL(WS-SEARCH-IDX)
                   TO ACT-CURRENT-BALANCE
               MOVE WS-AT-DAILY-DEBIT(WS-SEARCH-IDX)
                   TO ACT-DAILY-DEBIT-TOTAL
               MOVE WS-AT-DAILY-CREDIT(WS-SEARCH-IDX)
                   TO ACT-DAILY-CREDIT-TOTAL
               MOVE WS-AT-DAILY-TXN-CT(WS-SEARCH-IDX)
                   TO ACT-DAILY-TXN-COUNT
               MOVE WS-AT-DAILY-XFR(WS-SEARCH-IDX)
                   TO ACT-DAILY-XFR-TOTAL
               MOVE WS-AT-XFR-LIMIT(WS-SEARCH-IDX)
                   TO ACT-DAILY-XFR-LIMIT
               MOVE WS-AT-OVERDRAFT(WS-SEARCH-IDX)
                   TO ACT-OVERDRAFT-LIMIT
               MOVE WS-AT-RISK-WEIGHT(WS-SEARCH-IDX)
                   TO ACT-RISK-WEIGHT
               MOVE WS-AT-SECTOR(WS-SEARCH-IDX)
                   TO ACT-SECTOR-CODE
               MOVE WS-AT-OPEN-DATE(WS-SEARCH-IDX)
                   TO ACT-OPEN-DATE
               MOVE WS-AT-LAST-TXN(WS-SEARCH-IDX)
                   TO ACT-LAST-TXN-DATE
               MOVE WS-AT-BRANCH(WS-SEARCH-IDX)
                   TO ACT-BRANCH-CODE

               WRITE ACCOUNT-OUT-REC FROM WS-ACCOUNT-RECORD
           END-PERFORM

           CLOSE ACCOUNT-OUT-FILE
           .

      ******************************************************************
      * Hash computation
      ******************************************************************

       8500-COMPUTE-HASH.
           MOVE ZEROS TO WS-HASH-WORK

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
           CLOSE VALID-TXN-FILE
           CLOSE PROCESSED-TXN-FILE
           CLOSE JOURNAL-FILE
           CLOSE AUDIT-LOG-FILE
           CLOSE ERROR-FILE

           DISPLAY 'TXNPRC00: Processing complete'
           DISPLAY '  Transactions read:      ' WS-TXN-READ
           DISPLAY '  Transactions processed: ' WS-TXN-PROCESSED
           DISPLAY '  Transactions failed:    ' WS-TXN-FAILED
           DISPLAY '  Journal entries:        ' WS-JRN-WRITTEN

           IF WS-TXN-FAILED > 0
               MOVE 4 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF
           .
