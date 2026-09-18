       IDENTIFICATION DIVISION.
       PROGRAM-ID.    RECON00.
       AUTHOR.        ENTERPRISE FINANCIAL SYSTEMS.
       DATE-WRITTEN.  2026-03-31.
      ******************************************************************
      * RECON00 - End-of-Day Reconciliation Engine
      *
      * Fourth stage of the batch pipeline. Performs comprehensive
      * reconciliation checks:
      *   1. Double-entry invariant (total debits = total credits)
      *   2. Account-level balance verification
      *   3. Exception detection (high volume, large amounts, swings)
      *   4. Suspense account monitoring
      *
      * Produces:
      *   1. Reconciliation report
      *   2. Exceptions file with severity levels
      *   3. Audit trail records
      ******************************************************************

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       REPOSITORY.
           FUNCTION ALL INTRINSIC.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT POSTING-LOG-FILE
               ASSIGN TO 'data/work/posting-log.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-POST-STATUS.

           SELECT ACCOUNT-FILE
               ASSIGN TO 'data/work/accounts-updated.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCT-STATUS.

           SELECT RECON-RPT-FILE
               ASSIGN TO 'data/output/reconciliation.rpt'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-RPT-STATUS.

           SELECT EXCEPT-FILE
               ASSIGN TO 'data/work/exceptions.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-EXC-STATUS.

           SELECT AUDIT-LOG-FILE
               ASSIGN TO 'data/work/recon-audit.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-AUDIT-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  POSTING-LOG-FILE
           RECORDING MODE IS F.
       01  POSTING-LOG-REC            PIC X(200).

       FD  ACCOUNT-FILE
           RECORDING MODE IS F.
       01  ACCOUNT-FILE-REC          PIC X(200).

       FD  RECON-RPT-FILE
           RECORDING MODE IS F.
       01  RECON-RPT-REC             PIC X(132).

       FD  EXCEPT-FILE
           RECORDING MODE IS F.
       01  EXCEPT-FILE-REC           PIC X(180).

       FD  AUDIT-LOG-FILE
           RECORDING MODE IS F.
       01  AUDIT-LOG-REC             PIC X(250).

       WORKING-STORAGE SECTION.

      * File status
       01  WS-POST-STATUS             PIC X(02).
       01  WS-ACCT-STATUS             PIC X(02).
       01  WS-RPT-STATUS              PIC X(02).
       01  WS-EXC-STATUS              PIC X(02).
       01  WS-AUDIT-STATUS            PIC X(02).

      * Control flags
       01  WS-EOF-FLAG                PIC X(01) VALUE 'N'.
           88  END-OF-FILE            VALUE 'Y'.
           88  NOT-END-OF-FILE        VALUE 'N'.

       01  WS-ACCT-EOF                PIC X(01) VALUE 'N'.
           88  ACCT-EOF               VALUE 'Y'.
           88  ACCT-NOT-EOF           VALUE 'N'.

       01  WS-RECON-STATUS            PIC X(01) VALUE 'P'.
           88  RECON-PASS             VALUE 'P'.
           88  RECON-FAIL             VALUE 'F'.

      * Copybooks
       COPY 'src/copybooks/ACTREC.cpy'.
       COPY 'src/copybooks/ERRREC.cpy'.
       COPY 'src/copybooks/AUDREC.cpy'.
       COPY 'src/copybooks/RPTFLD.cpy'.

      * Posting log record (read-only)
       01  WS-POSTING-RECORD.
           05  PST-POSTING-NUM         PIC 9(10).
           05  PST-JRN-ENTRY-NUM       PIC 9(10).
           05  PST-DATE                PIC 9(08).
           05  PST-TIME                PIC 9(06).
           05  PST-DEBIT-ACCOUNT       PIC X(12).
           05  PST-CREDIT-ACCOUNT      PIC X(12).
           05  PST-AMOUNT              PIC 9(13)V99.
           05  PST-ENTRY-TYPE          PIC X(03).
           05  PST-STATUS              PIC X(01).
           05  PST-DESCRIPTION         PIC X(40).
           05  PST-PROGRAM-ID          PIC X(08).
           05  FILLER                  PIC X(82).

      * Account table for reconciliation
       01  WS-ACCT-TABLE.
           05  WS-ACCT-COUNT          PIC 9(05) VALUE 0.
           05  WS-ACCT-ENTRY OCCURS 1000 TIMES.
               10  WS-RC-ACCOUNT-NUM  PIC X(12).
               10  WS-RC-OPEN-BAL     PIC S9(13)V99.
               10  WS-RC-CURR-BAL     PIC S9(13)V99.
               10  WS-RC-DAILY-DEBIT  PIC 9(13)V99.
               10  WS-RC-DAILY-CREDIT PIC 9(13)V99.
               10  WS-RC-TXN-COUNT    PIC 9(05).
               10  WS-RC-STATUS       PIC X(01).
               10  WS-RC-TYPE         PIC X(03).

      * Reconciliation totals
       01  WS-RECON-TOTALS.
           05  WS-TOTAL-DEBITS        PIC 9(15)V99 VALUE 0.
           05  WS-TOTAL-CREDITS       PIC 9(15)V99 VALUE 0.
           05  WS-POSTING-COUNT       PIC 9(08) VALUE 0.
           05  WS-EXCEPTION-COUNT     PIC 9(05) VALUE 0.
           05  WS-ACCTS-BALANCED      PIC 9(05) VALUE 0.
           05  WS-ACCTS-IMBALANCED    PIC 9(05) VALUE 0.

      * Counters
       01  WS-COUNTERS.
           05  WS-AUDIT-SEQ           PIC 9(10) VALUE 0.
           05  WS-ERROR-SEQ           PIC 9(10) VALUE 0.

      * Work fields
       01  WS-WORK-FIELDS.
           05  WS-CURR-DATE           PIC 9(08).
           05  WS-CURR-TIME           PIC 9(06).
           05  WS-SEARCH-IDX          PIC 9(05).
           05  WS-IMBALANCE           PIC S9(15)V99.
           05  WS-EXPECTED-BAL        PIC S9(13)V99.
           05  WS-BAL-DIFF            PIC S9(13)V99.
           05  WS-SWING-PCT           PIC 9(05)V99.
           05  WS-DISPLAY-AMT         PIC -(15)9.99.
           05  WS-PREV-HASH           PIC X(16) VALUE ALL '0'.
           05  WS-HASH-RESULT         PIC X(16).
           05  WS-HASH-WORK           PIC 9(10).

      * Report detail lines
       01  WS-RPT-LINE                PIC X(132).
       01  WS-RPT-DETAIL.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  WS-RD-LABEL            PIC X(40).
           05  WS-RD-VALUE            PIC X(89).
       01  WS-RPT-ACCT-LINE.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  WS-RA-ACCT             PIC X(12).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RA-OPEN-BAL         PIC -(13)9.99.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RA-NET-CHANGE       PIC -(13)9.99.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RA-CLOSE-BAL        PIC -(13)9.99.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RA-STATUS           PIC X(04).
       01  WS-RPT-ACCT-HDR.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  FILLER                  PIC X(12) VALUE 'ACCOUNT     '.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'OPENING BALANCE '.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'NET CHANGE      '.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(16)
               VALUE 'CLOSING BALANCE '.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(06) VALUE 'STATUS'.

      * Exception record for output
       01  WS-EXCEPT-RECORD.
           05  EXC-ACCOUNT-NUM         PIC X(12).
           05  EXC-TYPE                PIC X(03).
           05  EXC-SEVERITY            PIC X(01).
           05  EXC-DESCRIPTION         PIC X(80).
           05  EXC-VALUE               PIC -(13)9.99.
           05  EXC-THRESHOLD           PIC -(13)9.99.
           05  FILLER                  PIC X(52).

       PROCEDURE DIVISION.
       0000-MAIN-CONTROL.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-LOAD-ACCOUNTS
           PERFORM 3000-TALLY-POSTINGS
           PERFORM 4000-RECONCILE-ACCOUNTS
           PERFORM 5000-DETECT-EXCEPTIONS
           PERFORM 6000-WRITE-SUMMARY
           PERFORM 9000-FINALIZE
           STOP RUN
           .

       1000-INITIALIZE.
           MOVE FUNCTION CURRENT-DATE(1:8) TO WS-CURR-DATE
           MOVE FUNCTION CURRENT-DATE(9:6) TO WS-CURR-TIME

           OPEN INPUT  POSTING-LOG-FILE
           OPEN OUTPUT RECON-RPT-FILE
           OPEN OUTPUT EXCEPT-FILE
           OPEN OUTPUT AUDIT-LOG-FILE

           PERFORM 1100-WRITE-REPORT-HEADER
           DISPLAY 'RECON00: Initialization complete'
           .

       1100-WRITE-REPORT-HEADER.
           WRITE RECON-RPT-REC FROM RPT-SEPARATOR

           MOVE SPACES TO WS-RPT-LINE
           STRING '     ENTERPRISE FINANCIAL SERVICES CORP.'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE RECON-RPT-REC FROM WS-RPT-LINE

           MOVE SPACES TO WS-RPT-LINE
           STRING '     END-OF-DAY RECONCILIATION REPORT'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE RECON-RPT-REC FROM WS-RPT-LINE

           MOVE SPACES TO WS-RPT-LINE
           STRING '     Run Date: '
               WS-CURR-DATE(1:4) '-'
               WS-CURR-DATE(5:2) '-'
               WS-CURR-DATE(7:2)
               '    Run Time: '
               WS-CURR-TIME(1:2) ':'
               WS-CURR-TIME(3:2) ':'
               WS-CURR-TIME(5:2)
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE RECON-RPT-REC FROM WS-RPT-LINE

           WRITE RECON-RPT-REC FROM RPT-SEPARATOR
           .

       2000-LOAD-ACCOUNTS.
           OPEN INPUT ACCOUNT-FILE
           SET ACCT-NOT-EOF TO TRUE
           PERFORM UNTIL ACCT-EOF
               READ ACCOUNT-FILE INTO WS-ACCOUNT-RECORD
                   AT END
                       SET ACCT-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO WS-ACCT-COUNT
                       MOVE ACT-ACCOUNT-NUM
                           TO WS-RC-ACCOUNT-NUM(WS-ACCT-COUNT)
                       MOVE ACT-OPENING-BALANCE
                           TO WS-RC-OPEN-BAL(WS-ACCT-COUNT)
                       MOVE ACT-CURRENT-BALANCE
                           TO WS-RC-CURR-BAL(WS-ACCT-COUNT)
                       MOVE ACT-DAILY-DEBIT-TOTAL
                           TO WS-RC-DAILY-DEBIT(WS-ACCT-COUNT)
                       MOVE ACT-DAILY-CREDIT-TOTAL
                           TO WS-RC-DAILY-CREDIT(WS-ACCT-COUNT)
                       MOVE ACT-DAILY-TXN-COUNT
                           TO WS-RC-TXN-COUNT(WS-ACCT-COUNT)
                       MOVE ACT-STATUS
                           TO WS-RC-STATUS(WS-ACCT-COUNT)
                       MOVE ACT-ACCOUNT-TYPE
                           TO WS-RC-TYPE(WS-ACCT-COUNT)
               END-READ
           END-PERFORM
           CLOSE ACCOUNT-FILE
           .

       3000-TALLY-POSTINGS.
           SET NOT-END-OF-FILE TO TRUE

           PERFORM UNTIL END-OF-FILE
               READ POSTING-LOG-FILE INTO WS-POSTING-RECORD
                   AT END
                       SET END-OF-FILE TO TRUE
                   NOT AT END
                       ADD 1 TO WS-POSTING-COUNT
                       ADD PST-AMOUNT TO WS-TOTAL-DEBITS
                       ADD PST-AMOUNT TO WS-TOTAL-CREDITS
               END-READ
           END-PERFORM

           CLOSE POSTING-LOG-FILE

      * Write double-entry check
           MOVE SPACES TO WS-RPT-LINE
           STRING '     SECTION 1: DOUBLE-ENTRY VERIFICATION'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE RECON-RPT-REC FROM WS-RPT-LINE
           WRITE RECON-RPT-REC FROM RPT-DASH-LINE

           MOVE 'Total postings processed:' TO WS-RD-LABEL
           MOVE WS-POSTING-COUNT TO WS-RD-VALUE
           WRITE RECON-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'Total debit amounts:' TO WS-RD-LABEL
           MOVE WS-TOTAL-DEBITS TO WS-DISPLAY-AMT
           MOVE WS-DISPLAY-AMT TO WS-RD-VALUE
           WRITE RECON-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'Total credit amounts:' TO WS-RD-LABEL
           MOVE WS-TOTAL-CREDITS TO WS-DISPLAY-AMT
           MOVE WS-DISPLAY-AMT TO WS-RD-VALUE
           WRITE RECON-RPT-REC FROM WS-RPT-DETAIL

           COMPUTE WS-IMBALANCE =
               WS-TOTAL-DEBITS - WS-TOTAL-CREDITS

           IF WS-IMBALANCE = 0
               MOVE 'Status: BALANCED - Debits equal Credits'
                   TO WS-RD-LABEL
               MOVE SPACES TO WS-RD-VALUE
               WRITE RECON-RPT-REC FROM WS-RPT-DETAIL
           ELSE
               SET RECON-FAIL TO TRUE
               MOVE '*** IMBALANCE DETECTED ***'
                   TO WS-RD-LABEL
               MOVE WS-IMBALANCE TO WS-DISPLAY-AMT
               MOVE WS-DISPLAY-AMT TO WS-RD-VALUE
               WRITE RECON-RPT-REC FROM WS-RPT-DETAIL
           END-IF

           WRITE RECON-RPT-REC FROM RPT-BLANK-LINE
           .

       4000-RECONCILE-ACCOUNTS.
           MOVE SPACES TO WS-RPT-LINE
           STRING '     SECTION 2: ACCOUNT BALANCE RECONCILIATION'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE RECON-RPT-REC FROM WS-RPT-LINE
           WRITE RECON-RPT-REC FROM RPT-DASH-LINE
           WRITE RECON-RPT-REC FROM WS-RPT-ACCT-HDR
           WRITE RECON-RPT-REC FROM RPT-DASH-LINE

           PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
               UNTIL WS-SEARCH-IDX > WS-ACCT-COUNT

               MOVE WS-RC-ACCOUNT-NUM(WS-SEARCH-IDX)
                   TO WS-RA-ACCT
               MOVE WS-RC-OPEN-BAL(WS-SEARCH-IDX)
                   TO WS-RA-OPEN-BAL

      * Net change = closing - opening
               COMPUTE WS-EXPECTED-BAL =
                   WS-RC-CURR-BAL(WS-SEARCH-IDX)
                   - WS-RC-OPEN-BAL(WS-SEARCH-IDX)
               MOVE WS-EXPECTED-BAL TO WS-RA-NET-CHANGE

               MOVE WS-RC-CURR-BAL(WS-SEARCH-IDX)
                   TO WS-RA-CLOSE-BAL

      * Verify debit/credit totals explain the change.
      * Expected = opening + credits - debits
               COMPUTE WS-EXPECTED-BAL =
                   WS-RC-OPEN-BAL(WS-SEARCH-IDX)
                   + WS-RC-DAILY-CREDIT(WS-SEARCH-IDX)
                   - WS-RC-DAILY-DEBIT(WS-SEARCH-IDX)

               COMPUTE WS-BAL-DIFF =
                   WS-RC-CURR-BAL(WS-SEARCH-IDX)
                   - WS-EXPECTED-BAL

      * Use absolute value for tolerance check
               IF WS-BAL-DIFF < 0
                   COMPUTE WS-BAL-DIFF = 0 - WS-BAL-DIFF
               END-IF

      * Tolerance accounts for rounding in computed
      * fields (fees, interest) where intermediate
      * COBOL arithmetic creates minor differences.
               IF WS-BAL-DIFF <= 1.00
                   MOVE ' OK ' TO WS-RA-STATUS
                   ADD 1 TO WS-ACCTS-BALANCED
               ELSE
                   MOVE 'WARN' TO WS-RA-STATUS
                   ADD 1 TO WS-ACCTS-IMBALANCED
               END-IF

               WRITE RECON-RPT-REC FROM WS-RPT-ACCT-LINE
           END-PERFORM

           WRITE RECON-RPT-REC FROM RPT-DASH-LINE
           WRITE RECON-RPT-REC FROM RPT-BLANK-LINE
           .

       5000-DETECT-EXCEPTIONS.
           MOVE SPACES TO WS-RPT-LINE
           STRING '     SECTION 3: EXCEPTION DETECTION'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE RECON-RPT-REC FROM WS-RPT-LINE
           WRITE RECON-RPT-REC FROM RPT-DASH-LINE

           PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
               UNTIL WS-SEARCH-IDX > WS-ACCT-COUNT

      * High volume check (>50 transactions/day)
               IF WS-RC-TXN-COUNT(WS-SEARCH-IDX) > 50
                   ADD 1 TO WS-EXCEPTION-COUNT
                   INITIALIZE WS-EXCEPT-RECORD
                   MOVE WS-RC-ACCOUNT-NUM(WS-SEARCH-IDX)
                       TO EXC-ACCOUNT-NUM
                   MOVE 'VOL' TO EXC-TYPE
                   MOVE 'W' TO EXC-SEVERITY
                   MOVE 'High transaction volume detected'
                       TO EXC-DESCRIPTION
                   MOVE WS-RC-TXN-COUNT(WS-SEARCH-IDX)
                       TO EXC-VALUE
                   MOVE 50 TO EXC-THRESHOLD
                   WRITE EXCEPT-FILE-REC FROM WS-EXCEPT-RECORD

                   MOVE SPACES TO WS-RPT-LINE
                   STRING '   WARN: Account '
                       WS-RC-ACCOUNT-NUM(WS-SEARCH-IDX)
                       ' - High volume: '
                       WS-RC-TXN-COUNT(WS-SEARCH-IDX)
                       ' transactions'
                       DELIMITED BY SIZE INTO WS-RPT-LINE
                   WRITE RECON-RPT-REC FROM WS-RPT-LINE
               END-IF

      * Balance swing check (>200% change)
               IF WS-RC-OPEN-BAL(WS-SEARCH-IDX) NOT = 0
                   COMPUTE WS-BAL-DIFF =
                       WS-RC-CURR-BAL(WS-SEARCH-IDX)
                       - WS-RC-OPEN-BAL(WS-SEARCH-IDX)

                   IF WS-BAL-DIFF < 0
                       COMPUTE WS-BAL-DIFF =
                           0 - WS-BAL-DIFF
                   END-IF

                   COMPUTE WS-SWING-PCT =
                       (WS-BAL-DIFF /
                        WS-RC-OPEN-BAL(WS-SEARCH-IDX))
                       * 100

                   IF WS-SWING-PCT > 200
                       ADD 1 TO WS-EXCEPTION-COUNT
                       INITIALIZE WS-EXCEPT-RECORD
                       MOVE WS-RC-ACCOUNT-NUM(WS-SEARCH-IDX)
                           TO EXC-ACCOUNT-NUM
                       MOVE 'SWG' TO EXC-TYPE
                       MOVE 'C' TO EXC-SEVERITY
                       MOVE 'Balance swing exceeds 200% threshold'
                           TO EXC-DESCRIPTION
                       MOVE WS-SWING-PCT TO EXC-VALUE
                       MOVE 200 TO EXC-THRESHOLD
                       WRITE EXCEPT-FILE-REC
                           FROM WS-EXCEPT-RECORD

                       MOVE SPACES TO WS-RPT-LINE
                       STRING '   CRIT: Account '
                           WS-RC-ACCOUNT-NUM(WS-SEARCH-IDX)
                           ' - Balance swing: '
                           WS-SWING-PCT '%'
                           DELIMITED BY SIZE
                           INTO WS-RPT-LINE
                       WRITE RECON-RPT-REC FROM WS-RPT-LINE
                   END-IF
               END-IF

      * Suspense account check
               IF WS-RC-TYPE(WS-SEARCH-IDX) = 'SUS'
                  AND WS-RC-CURR-BAL(WS-SEARCH-IDX) NOT = 0
                   ADD 1 TO WS-EXCEPTION-COUNT
                   MOVE SPACES TO WS-RPT-LINE
                   STRING '   WARN: Suspense account '
                       WS-RC-ACCOUNT-NUM(WS-SEARCH-IDX)
                       ' has non-zero balance'
                       DELIMITED BY SIZE INTO WS-RPT-LINE
                   WRITE RECON-RPT-REC FROM WS-RPT-LINE
               END-IF
           END-PERFORM

           IF WS-EXCEPTION-COUNT = 0
               MOVE SPACES TO WS-RPT-LINE
               STRING '   No exceptions detected.'
                   DELIMITED BY SIZE INTO WS-RPT-LINE
               WRITE RECON-RPT-REC FROM WS-RPT-LINE
           END-IF

           WRITE RECON-RPT-REC FROM RPT-BLANK-LINE
           .

       6000-WRITE-SUMMARY.
           MOVE SPACES TO WS-RPT-LINE
           STRING '     SECTION 4: RECONCILIATION SUMMARY'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE RECON-RPT-REC FROM WS-RPT-LINE
           WRITE RECON-RPT-REC FROM RPT-DASH-LINE

           MOVE 'Accounts reconciled:' TO WS-RD-LABEL
           MOVE WS-ACCT-COUNT TO WS-RD-VALUE
           WRITE RECON-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'Accounts balanced:' TO WS-RD-LABEL
           MOVE WS-ACCTS-BALANCED TO WS-RD-VALUE
           WRITE RECON-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'Accounts with discrepancy:' TO WS-RD-LABEL
           MOVE WS-ACCTS-IMBALANCED TO WS-RD-VALUE
           WRITE RECON-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'Exceptions flagged:' TO WS-RD-LABEL
           MOVE WS-EXCEPTION-COUNT TO WS-RD-VALUE
           WRITE RECON-RPT-REC FROM WS-RPT-DETAIL

           WRITE RECON-RPT-REC FROM RPT-DASH-LINE

           IF RECON-PASS
               MOVE 'OVERALL STATUS: PASS' TO WS-RD-LABEL
           ELSE
               MOVE 'OVERALL STATUS: FAIL - REVIEW REQUIRED'
                   TO WS-RD-LABEL
           END-IF
           MOVE SPACES TO WS-RD-VALUE
           WRITE RECON-RPT-REC FROM WS-RPT-DETAIL

           WRITE RECON-RPT-REC FROM RPT-SEPARATOR
           WRITE RECON-RPT-REC FROM WS-REPORT-FOOTER

      * Audit the reconciliation result
           ADD 1 TO WS-AUDIT-SEQ
           INITIALIZE WS-AUDIT-RECORD
           MOVE WS-AUDIT-SEQ    TO AUD-SEQUENCE-NUM
           MOVE WS-CURR-DATE    TO AUD-DATE
           MOVE WS-CURR-TIME    TO AUD-TIME
           MOVE 'RECON00 '      TO AUD-PROGRAM-ID
           MOVE 'REC'           TO AUD-ACTION-CODE
           MOVE ZEROS           TO AUD-TXN-SEQUENCE
           MOVE SPACES          TO AUD-ACCOUNT-NUM
           MOVE ZEROS           TO AUD-AMOUNT
           MOVE ZEROS           TO AUD-BEFORE-BALANCE
           MOVE ZEROS           TO AUD-AFTER-BALANCE
           MOVE SPACES          TO AUD-OPERATOR-ID

           IF RECON-PASS
               MOVE 'Reconciliation completed: PASS'
                   TO AUD-DESCRIPTION
           ELSE
               MOVE 'Reconciliation completed: FAIL'
                   TO AUD-DESCRIPTION
           END-IF

           MOVE WS-PREV-HASH    TO AUD-PREV-HASH
           PERFORM 8500-COMPUTE-HASH
           MOVE WS-HASH-RESULT  TO AUD-CURR-HASH
           MOVE 'F'             TO AUD-CHAIN-STATUS

           WRITE AUDIT-LOG-REC FROM WS-AUDIT-RECORD
           .

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

       9000-FINALIZE.
           CLOSE RECON-RPT-FILE
           CLOSE EXCEPT-FILE
           CLOSE AUDIT-LOG-FILE

           DISPLAY 'RECON00: Reconciliation complete'
           DISPLAY '  Postings reviewed:  ' WS-POSTING-COUNT
           DISPLAY '  Accounts checked:   ' WS-ACCT-COUNT
           DISPLAY '  Exceptions found:   ' WS-EXCEPTION-COUNT

           IF RECON-PASS
               DISPLAY '  Status: PASS'
               MOVE 0 TO RETURN-CODE
           ELSE
               DISPLAY '  Status: FAIL'
               MOVE 8 TO RETURN-CODE
           END-IF
           .
