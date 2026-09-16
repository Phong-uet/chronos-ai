       IDENTIFICATION DIVISION.
       PROGRAM-ID.    REGRPT00.
       AUTHOR.        ENTERPRISE FINANCIAL SYSTEMS.
       DATE-WRITTEN.  2026-03-31.
      ******************************************************************
      * REGRPT00 - Regulatory Report Generator
      *
      * Fifth stage of the batch pipeline. Generates compliance and
      * regulatory reports required by financial authorities:
      *   1. Daily Transaction Summary
      *   2. Capital Adequacy Ratio (Basel III)
      *   3. Large Transaction Report (BSA/AML threshold $10,000)
      *   4. Risk Concentration Report (top exposures by sector)
      *
      * All reports follow mainframe-style fixed-width formatting
      * with headers, page numbers, timestamps, and control totals.
      ******************************************************************

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       REPOSITORY.
           FUNCTION ALL INTRINSIC.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PROCESSED-TXN-FILE
               ASSIGN TO 'data/work/processed-transactions.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TXN-STATUS.

           SELECT ACCOUNT-FILE
               ASSIGN TO 'data/work/accounts-updated.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCT-STATUS.

           SELECT REG-RPT-FILE
               ASSIGN TO 'data/output/regulatory-reports.rpt'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-RPT-STATUS.

           SELECT AUDIT-LOG-FILE
               ASSIGN TO 'data/work/regrpt-audit.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-AUDIT-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  PROCESSED-TXN-FILE
           RECORDING MODE IS F.
       01  PROCESSED-TXN-REC          PIC X(200).

       FD  ACCOUNT-FILE
           RECORDING MODE IS F.
       01  ACCOUNT-FILE-REC           PIC X(200).

       FD  REG-RPT-FILE
           RECORDING MODE IS F.
       01  REG-RPT-REC                PIC X(132).

       FD  AUDIT-LOG-FILE
           RECORDING MODE IS F.
       01  AUDIT-LOG-REC              PIC X(250).

       WORKING-STORAGE SECTION.

      * File status
       01  WS-TXN-STATUS              PIC X(02).
       01  WS-ACCT-STATUS             PIC X(02).
       01  WS-RPT-STATUS              PIC X(02).
       01  WS-AUDIT-STATUS            PIC X(02).

      * Control flags
       01  WS-EOF-FLAG                PIC X(01) VALUE 'N'.
           88  END-OF-FILE            VALUE 'Y'.
           88  NOT-END-OF-FILE        VALUE 'N'.

       01  WS-ACCT-EOF                PIC X(01) VALUE 'N'.
           88  ACCT-EOF               VALUE 'Y'.
           88  ACCT-NOT-EOF           VALUE 'N'.

      * Copybooks
       COPY 'src/copybooks/TXNREC.cpy'.
       COPY 'src/copybooks/ACTREC.cpy'.
       COPY 'src/copybooks/AUDREC.cpy'.
       COPY 'src/copybooks/RPTFLD.cpy'.

      * Transaction summary accumulators
       01  WS-TXN-SUMMARY.
           05  WS-TOTAL-TXN-COUNT     PIC 9(08) VALUE 0.
           05  WS-TOTAL-TXN-VALUE     PIC 9(15)V99 VALUE 0.
           05  WS-DEP-COUNT           PIC 9(08) VALUE 0.
           05  WS-DEP-VALUE           PIC 9(15)V99 VALUE 0.
           05  WS-WDR-COUNT           PIC 9(08) VALUE 0.
           05  WS-WDR-VALUE           PIC 9(15)V99 VALUE 0.
           05  WS-XFR-COUNT           PIC 9(08) VALUE 0.
           05  WS-XFR-VALUE           PIC 9(15)V99 VALUE 0.
           05  WS-FEE-COUNT           PIC 9(08) VALUE 0.
           05  WS-FEE-VALUE           PIC 9(15)V99 VALUE 0.
           05  WS-INT-COUNT           PIC 9(08) VALUE 0.
           05  WS-INT-VALUE           PIC 9(15)V99 VALUE 0.
           05  WS-ADJ-COUNT           PIC 9(08) VALUE 0.
           05  WS-ADJ-VALUE           PIC 9(15)V99 VALUE 0.
           05  WS-ERROR-RATE          PIC 9(03)V99 VALUE 0.

      * Large transaction tracking (>$10,000)
       01  WS-LARGE-TXN-TABLE.
           05  WS-LARGE-COUNT         PIC 9(05) VALUE 0.
           05  WS-LARGE-ENTRY OCCURS 500 TIMES.
               10  WS-LT-SEQ-NUM     PIC 9(10).
               10  WS-LT-TYPE        PIC X(03).
               10  WS-LT-SRC-ACCT    PIC X(12).
               10  WS-LT-TGT-ACCT    PIC X(12).
               10  WS-LT-AMOUNT      PIC 9(13)V99.
               10  WS-LT-DATE        PIC 9(08).

      * Account table for capital/risk analysis
       01  WS-RISK-TABLE.
           05  WS-RISK-COUNT          PIC 9(05) VALUE 0.
           05  WS-RISK-ENTRY OCCURS 1000 TIMES.
               10  WS-RK-ACCOUNT-NUM  PIC X(12).
               10  WS-RK-BALANCE      PIC S9(13)V99.
               10  WS-RK-RISK-WEIGHT  PIC 9V99.
               10  WS-RK-WEIGHTED-AMT PIC 9(15)V99.
               10  WS-RK-SECTOR       PIC X(04).
               10  WS-RK-TIER         PIC X(01).

      * Sector concentration
       01  WS-SECTOR-TABLE.
           05  WS-SECT-COUNT          PIC 9(03) VALUE 0.
           05  WS-SECT-ENTRY OCCURS 50 TIMES.
               10  WS-SC-CODE         PIC X(04).
               10  WS-SC-TOTAL-BAL    PIC 9(15)V99.
               10  WS-SC-ACCT-COUNT   PIC 9(05).
               10  WS-SC-PCT          PIC 9(03)V99.

      * Capital adequacy
       01  WS-CAPITAL-FIELDS.
           05  WS-TIER1-CAPITAL        PIC 9(15)V99.
           05  WS-TOTAL-RWA            PIC 9(15)V99 VALUE 0.
           05  WS-TOTAL-ASSETS         PIC 9(15)V99 VALUE 0.
           05  WS-CAR-RATIO            PIC 9(03)V9(04).
           05  WS-CAR-STATUS           PIC X(20).
           05  WS-LEVERAGE-RATIO       PIC 9(03)V9(04).

      * Counters and work fields
       01  WS-COUNTERS.
           05  WS-AUDIT-SEQ           PIC 9(10) VALUE 0.
           05  WS-PAGE-NUM            PIC 9(05) VALUE 0.

       01  WS-WORK-FIELDS.
           05  WS-CURR-DATE           PIC 9(08).
           05  WS-CURR-TIME           PIC 9(06).
           05  WS-SEARCH-IDX          PIC 9(05).
           05  WS-INNER-IDX           PIC 9(05).
           05  WS-FOUND-FLAG          PIC X(01).
           05  WS-PREV-HASH           PIC X(16) VALUE ALL '0'.
           05  WS-HASH-RESULT         PIC X(16).
           05  WS-HASH-WORK           PIC 9(10).
           05  WS-TEMP-BAL            PIC 9(15)V99.
           05  WS-TEMP-ACCT           PIC X(12).
           05  WS-TEMP-SECTOR         PIC X(04).
           05  WS-SORT-IDX            PIC 9(05).

      * Report formatting
       01  WS-RPT-LINE                PIC X(132).
       01  WS-RPT-DETAIL.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-RD-LABEL            PIC X(35).
           05  WS-RD-COUNT            PIC Z(07)9.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-RD-VALUE            PIC $$$,$$$,$$$,$$9.99.
       01  WS-RPT-LT-LINE.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-RL-SEQ              PIC 9(10).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RL-TYPE             PIC X(03).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RL-SRC              PIC X(12).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RL-TGT              PIC X(12).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RL-AMOUNT           PIC $$$,$$$,$$$,$$9.99.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RL-DATE             PIC X(10).
       01  WS-RPT-RISK-LINE.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-RR-RANK             PIC Z9.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RR-ACCT             PIC X(12).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RR-BALANCE          PIC $$$,$$$,$$$,$$9.99.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RR-WEIGHT           PIC 9.99.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RR-WEIGHTED         PIC $$$,$$$,$$$,$$9.99.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-RR-SECTOR           PIC X(04).
       01  WS-RPT-SECTOR-LINE.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-RS-CODE             PIC X(04).
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-RS-TOTAL            PIC $$$,$$$,$$$,$$9.99.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-RS-COUNT            PIC Z(04)9.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-RS-PCT              PIC ZZ9.99.
           05  FILLER                  PIC X(01) VALUE '%'.

       PROCEDURE DIVISION.
       0000-MAIN-CONTROL.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-ANALYZE-TRANSACTIONS
           PERFORM 3000-LOAD-RISK-DATA
           PERFORM 4000-WRITE-TXN-SUMMARY
           PERFORM 5000-WRITE-CAPITAL-REPORT
           PERFORM 6000-WRITE-LARGE-TXN-REPORT
           PERFORM 7000-WRITE-RISK-CONCENTRATION
           PERFORM 8000-WRITE-FOOTER
           PERFORM 9000-FINALIZE
           STOP RUN
           .

       1000-INITIALIZE.
           MOVE FUNCTION CURRENT-DATE(1:8) TO WS-CURR-DATE
           MOVE FUNCTION CURRENT-DATE(9:6) TO WS-CURR-TIME

           OPEN INPUT  PROCESSED-TXN-FILE
           OPEN OUTPUT REG-RPT-FILE
           OPEN OUTPUT AUDIT-LOG-FILE

           IF WS-TXN-STATUS NOT = '00'
               DISPLAY 'ERROR: Cannot open processed txn file'
               STOP RUN
           END-IF

      * Master header
           WRITE REG-RPT-REC FROM RPT-SEPARATOR
           MOVE SPACES TO WS-RPT-LINE
           STRING
               '     ENTERPRISE FINANCIAL SERVICES CORP.'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE
           MOVE SPACES TO WS-RPT-LINE
           STRING
               '     REGULATORY COMPLIANCE REPORT SUITE'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE
           MOVE SPACES TO WS-RPT-LINE
           STRING '     Report Date: '
               WS-CURR-DATE(1:4) '-'
               WS-CURR-DATE(5:2) '-'
               WS-CURR-DATE(7:2)
               '    Generated: '
               WS-CURR-TIME(1:2) ':'
               WS-CURR-TIME(3:2) ':'
               WS-CURR-TIME(5:2)
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE
           WRITE REG-RPT-REC FROM RPT-SEPARATOR

           DISPLAY 'REGRPT00: Initialization complete'
           .

       2000-ANALYZE-TRANSACTIONS.
           SET NOT-END-OF-FILE TO TRUE

           PERFORM UNTIL END-OF-FILE
               READ PROCESSED-TXN-FILE
                   INTO WS-TRANSACTION-RECORD
                   AT END
                       SET END-OF-FILE TO TRUE
                   NOT AT END
                       ADD 1 TO WS-TOTAL-TXN-COUNT
                       ADD TXN-AMOUNT TO WS-TOTAL-TXN-VALUE

                       EVALUATE TRUE
                           WHEN TXN-IS-DEPOSIT
                               ADD 1 TO WS-DEP-COUNT
                               ADD TXN-AMOUNT TO WS-DEP-VALUE
                           WHEN TXN-IS-WITHDRAWAL
                               ADD 1 TO WS-WDR-COUNT
                               ADD TXN-AMOUNT TO WS-WDR-VALUE
                           WHEN TXN-IS-TRANSFER
                               ADD 1 TO WS-XFR-COUNT
                               ADD TXN-AMOUNT TO WS-XFR-VALUE
                           WHEN TXN-IS-FEE
                               ADD 1 TO WS-FEE-COUNT
                               ADD TXN-AMOUNT TO WS-FEE-VALUE
                           WHEN TXN-IS-INTEREST
                               ADD 1 TO WS-INT-COUNT
                               ADD TXN-AMOUNT TO WS-INT-VALUE
                           WHEN TXN-IS-ADJUSTMENT
                               ADD 1 TO WS-ADJ-COUNT
                               ADD TXN-AMOUNT TO WS-ADJ-VALUE
                       END-EVALUATE

      * Track large transactions (BSA/AML)
                       IF TXN-AMOUNT >= 10000.00
                           IF WS-LARGE-COUNT < 500
                               ADD 1 TO WS-LARGE-COUNT
                               MOVE TXN-SEQUENCE-NUM
                                 TO WS-LT-SEQ-NUM(WS-LARGE-COUNT)
                               MOVE TXN-TYPE
                                 TO WS-LT-TYPE(WS-LARGE-COUNT)
                               MOVE TXN-SOURCE-ACCOUNT
                                 TO WS-LT-SRC-ACCT(WS-LARGE-COUNT)
                               MOVE TXN-TARGET-ACCOUNT
                                 TO WS-LT-TGT-ACCT(WS-LARGE-COUNT)
                               MOVE TXN-AMOUNT
                                 TO WS-LT-AMOUNT(WS-LARGE-COUNT)
                               MOVE TXN-DATE
                                 TO WS-LT-DATE(WS-LARGE-COUNT)
                           END-IF
                       END-IF
               END-READ
           END-PERFORM

           CLOSE PROCESSED-TXN-FILE
           .

       3000-LOAD-RISK-DATA.
           OPEN INPUT ACCOUNT-FILE
           SET ACCT-NOT-EOF TO TRUE

           PERFORM UNTIL ACCT-EOF
               READ ACCOUNT-FILE INTO WS-ACCOUNT-RECORD
                   AT END
                       SET ACCT-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO WS-RISK-COUNT
                       MOVE ACT-ACCOUNT-NUM
                           TO WS-RK-ACCOUNT-NUM(WS-RISK-COUNT)
                       MOVE ACT-CURRENT-BALANCE
                           TO WS-RK-BALANCE(WS-RISK-COUNT)
                       MOVE ACT-RISK-WEIGHT
                           TO WS-RK-RISK-WEIGHT(WS-RISK-COUNT)
                       MOVE ACT-SECTOR-CODE
                           TO WS-RK-SECTOR(WS-RISK-COUNT)
                       MOVE ACT-TIER
                           TO WS-RK-TIER(WS-RISK-COUNT)

      * Calculate risk-weighted amount
                       IF ACT-CURRENT-BALANCE > 0
                           COMPUTE WS-RK-WEIGHTED-AMT(
                               WS-RISK-COUNT) =
                               ACT-CURRENT-BALANCE
                               * ACT-RISK-WEIGHT
                           ADD ACT-CURRENT-BALANCE
                               TO WS-TOTAL-ASSETS
                           ADD WS-RK-WEIGHTED-AMT(WS-RISK-COUNT)
                               TO WS-TOTAL-RWA
                       ELSE
                           MOVE 0 TO
                               WS-RK-WEIGHTED-AMT(WS-RISK-COUNT)
                       END-IF

      * Accumulate sector data
                       PERFORM 3100-UPDATE-SECTOR
               END-READ
           END-PERFORM

           CLOSE ACCOUNT-FILE

      * Set Tier 1 capital (10% of total assets for demo)
           COMPUTE WS-TIER1-CAPITAL =
               WS-TOTAL-ASSETS * 0.10
           .

       3100-UPDATE-SECTOR.
           MOVE 'N' TO WS-FOUND-FLAG
           PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
               UNTIL WS-SEARCH-IDX > WS-SECT-COUNT
               OR WS-FOUND-FLAG = 'Y'
               IF WS-SC-CODE(WS-SEARCH-IDX) = ACT-SECTOR-CODE
                   MOVE 'Y' TO WS-FOUND-FLAG
                   IF ACT-CURRENT-BALANCE > 0
                       ADD ACT-CURRENT-BALANCE
                           TO WS-SC-TOTAL-BAL(WS-SEARCH-IDX)
                   END-IF
                   ADD 1 TO WS-SC-ACCT-COUNT(WS-SEARCH-IDX)
               END-IF
           END-PERFORM

           IF WS-FOUND-FLAG = 'N'
               ADD 1 TO WS-SECT-COUNT
               MOVE ACT-SECTOR-CODE
                   TO WS-SC-CODE(WS-SECT-COUNT)
               IF ACT-CURRENT-BALANCE > 0
                   MOVE ACT-CURRENT-BALANCE
                       TO WS-SC-TOTAL-BAL(WS-SECT-COUNT)
               ELSE
                   MOVE 0 TO WS-SC-TOTAL-BAL(WS-SECT-COUNT)
               END-IF
               MOVE 1 TO WS-SC-ACCT-COUNT(WS-SECT-COUNT)
           END-IF
           .

       4000-WRITE-TXN-SUMMARY.
           WRITE REG-RPT-REC FROM RPT-BLANK-LINE
           MOVE SPACES TO WS-RPT-LINE
           STRING '     REPORT 1: DAILY TRANSACTION SUMMARY'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE
           WRITE REG-RPT-REC FROM RPT-DASH-LINE

           MOVE SPACES TO WS-RPT-LINE
           STRING '     Type                    '
               '   Count          Value'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE
           WRITE REG-RPT-REC FROM RPT-DASH-LINE

           MOVE 'Deposits (DEP)'      TO WS-RD-LABEL
           MOVE WS-DEP-COUNT          TO WS-RD-COUNT
           MOVE WS-DEP-VALUE          TO WS-RD-VALUE
           WRITE REG-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'Withdrawals (WDR)'   TO WS-RD-LABEL
           MOVE WS-WDR-COUNT          TO WS-RD-COUNT
           MOVE WS-WDR-VALUE          TO WS-RD-VALUE
           WRITE REG-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'Transfers (XFR)'     TO WS-RD-LABEL
           MOVE WS-XFR-COUNT          TO WS-RD-COUNT
           MOVE WS-XFR-VALUE          TO WS-RD-VALUE
           WRITE REG-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'Fees (FEE)'          TO WS-RD-LABEL
           MOVE WS-FEE-COUNT          TO WS-RD-COUNT
           MOVE WS-FEE-VALUE          TO WS-RD-VALUE
           WRITE REG-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'Interest (INT)'      TO WS-RD-LABEL
           MOVE WS-INT-COUNT          TO WS-RD-COUNT
           MOVE WS-INT-VALUE          TO WS-RD-VALUE
           WRITE REG-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'Adjustments (ADJ)'   TO WS-RD-LABEL
           MOVE WS-ADJ-COUNT          TO WS-RD-COUNT
           MOVE WS-ADJ-VALUE          TO WS-RD-VALUE
           WRITE REG-RPT-REC FROM WS-RPT-DETAIL

           WRITE REG-RPT-REC FROM RPT-DASH-LINE

           MOVE 'TOTAL'               TO WS-RD-LABEL
           MOVE WS-TOTAL-TXN-COUNT    TO WS-RD-COUNT
           MOVE WS-TOTAL-TXN-VALUE    TO WS-RD-VALUE
           WRITE REG-RPT-REC FROM WS-RPT-DETAIL
           .

       5000-WRITE-CAPITAL-REPORT.
           WRITE REG-RPT-REC FROM RPT-BLANK-LINE
           WRITE REG-RPT-REC FROM RPT-BLANK-LINE
           MOVE SPACES TO WS-RPT-LINE
           STRING
               '     REPORT 2: CAPITAL ADEQUACY (BASEL III)'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE
           WRITE REG-RPT-REC FROM RPT-DASH-LINE

           MOVE 'Tier 1 Capital:' TO WS-RD-LABEL
           MOVE 0 TO WS-RD-COUNT
           MOVE WS-TIER1-CAPITAL TO WS-RD-VALUE
           WRITE REG-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'Total Assets:' TO WS-RD-LABEL
           MOVE WS-TOTAL-ASSETS TO WS-RD-VALUE
           WRITE REG-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'Risk-Weighted Assets (RWA):' TO WS-RD-LABEL
           MOVE WS-TOTAL-RWA TO WS-RD-VALUE
           WRITE REG-RPT-REC FROM WS-RPT-DETAIL

      * Calculate CAR
           IF WS-TOTAL-RWA > 0
               COMPUTE WS-CAR-RATIO =
                   WS-TIER1-CAPITAL / WS-TOTAL-RWA
           ELSE
               MOVE 0 TO WS-CAR-RATIO
           END-IF

           WRITE REG-RPT-REC FROM RPT-DASH-LINE

           MOVE SPACES TO WS-RPT-LINE
           STRING '     Capital Adequacy Ratio: '
               WS-CAR-RATIO
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE

           MOVE SPACES TO WS-RPT-LINE
           IF WS-CAR-RATIO >= 0.08
               STRING '     Status: COMPLIANT'
                   ' (minimum 8.00% required)'
                   DELIMITED BY SIZE INTO WS-RPT-LINE
           ELSE
               STRING '     *** NON-COMPLIANT ***'
                   ' (below 8.00% minimum)'
                   DELIMITED BY SIZE INTO WS-RPT-LINE
           END-IF
           WRITE REG-RPT-REC FROM WS-RPT-LINE

      * Leverage ratio
           IF WS-TOTAL-ASSETS > 0
               COMPUTE WS-LEVERAGE-RATIO =
                   WS-TIER1-CAPITAL / WS-TOTAL-ASSETS
           ELSE
               MOVE 0 TO WS-LEVERAGE-RATIO
           END-IF

           MOVE SPACES TO WS-RPT-LINE
           STRING '     Leverage Ratio:         '
               WS-LEVERAGE-RATIO
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE
           .

       6000-WRITE-LARGE-TXN-REPORT.
           WRITE REG-RPT-REC FROM RPT-BLANK-LINE
           WRITE REG-RPT-REC FROM RPT-BLANK-LINE
           MOVE SPACES TO WS-RPT-LINE
           STRING
               '     REPORT 3: LARGE TRANSACTION REPORT'
               ' (BSA/AML - Threshold: $10,000)'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE
           WRITE REG-RPT-REC FROM RPT-DASH-LINE

           MOVE SPACES TO WS-RPT-LINE
           STRING '     SEQ NUM   '
               '  TYP  SOURCE ACCT   '
               '  TARGET ACCT   '
               '              AMOUNT  '
               '  DATE'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE
           WRITE REG-RPT-REC FROM RPT-DASH-LINE

           IF WS-LARGE-COUNT = 0
               MOVE SPACES TO WS-RPT-LINE
               STRING '     No large transactions to report.'
                   DELIMITED BY SIZE INTO WS-RPT-LINE
               WRITE REG-RPT-REC FROM WS-RPT-LINE
           ELSE
               PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
                   UNTIL WS-SEARCH-IDX > WS-LARGE-COUNT
                   MOVE WS-LT-SEQ-NUM(WS-SEARCH-IDX)
                       TO WS-RL-SEQ
                   MOVE WS-LT-TYPE(WS-SEARCH-IDX)
                       TO WS-RL-TYPE
                   MOVE WS-LT-SRC-ACCT(WS-SEARCH-IDX)
                       TO WS-RL-SRC
                   MOVE WS-LT-TGT-ACCT(WS-SEARCH-IDX)
                       TO WS-RL-TGT
                   MOVE WS-LT-AMOUNT(WS-SEARCH-IDX)
                       TO WS-RL-AMOUNT
                   STRING
                       WS-LT-DATE(WS-SEARCH-IDX)(1:4) '-'
                       WS-LT-DATE(WS-SEARCH-IDX)(5:2) '-'
                       WS-LT-DATE(WS-SEARCH-IDX)(7:2)
                       DELIMITED BY SIZE INTO WS-RL-DATE
                   WRITE REG-RPT-REC FROM WS-RPT-LT-LINE
               END-PERFORM
           END-IF

           WRITE REG-RPT-REC FROM RPT-DASH-LINE
           MOVE SPACES TO WS-RPT-LINE
           STRING '     Total large transactions: '
               WS-LARGE-COUNT
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE
           .

       7000-WRITE-RISK-CONCENTRATION.
           WRITE REG-RPT-REC FROM RPT-BLANK-LINE
           WRITE REG-RPT-REC FROM RPT-BLANK-LINE
           MOVE SPACES TO WS-RPT-LINE
           STRING
               '     REPORT 4: RISK CONCENTRATION ANALYSIS'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE
           WRITE REG-RPT-REC FROM RPT-DASH-LINE

      * Top 10 accounts by exposure
           MOVE SPACES TO WS-RPT-LINE
           STRING '     TOP 10 ACCOUNTS BY RISK-WEIGHTED EXPOSURE'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE

           MOVE SPACES TO WS-RPT-LINE
           STRING '     Rank  Account      '
               '          Balance  '
               'Wgt              Weighted  '
               'Sector'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE
           WRITE REG-RPT-REC FROM RPT-DASH-LINE

      * Simple bubble sort top 10 by weighted amount (descending)
           PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
               UNTIL WS-SEARCH-IDX >= WS-RISK-COUNT
               PERFORM VARYING WS-INNER-IDX FROM 1 BY 1
                   UNTIL WS-INNER-IDX >=
                       WS-RISK-COUNT - WS-SEARCH-IDX + 1
                   IF WS-RK-WEIGHTED-AMT(WS-INNER-IDX) <
                      WS-RK-WEIGHTED-AMT(WS-INNER-IDX + 1)
      * Swap entries
                       MOVE WS-RK-ACCOUNT-NUM(WS-INNER-IDX)
                           TO WS-TEMP-ACCT
                       MOVE WS-RK-ACCOUNT-NUM(WS-INNER-IDX + 1)
                           TO WS-RK-ACCOUNT-NUM(WS-INNER-IDX)
                       MOVE WS-TEMP-ACCT
                           TO WS-RK-ACCOUNT-NUM(WS-INNER-IDX + 1)

                       MOVE WS-RK-BALANCE(WS-INNER-IDX)
                           TO WS-TEMP-BAL
                       MOVE WS-RK-BALANCE(WS-INNER-IDX + 1)
                           TO WS-RK-BALANCE(WS-INNER-IDX)
                       MOVE WS-TEMP-BAL
                           TO WS-RK-BALANCE(WS-INNER-IDX + 1)

                       MOVE WS-RK-WEIGHTED-AMT(WS-INNER-IDX)
                           TO WS-TEMP-BAL
                       MOVE WS-RK-WEIGHTED-AMT(WS-INNER-IDX + 1)
                           TO WS-RK-WEIGHTED-AMT(WS-INNER-IDX)
                       MOVE WS-TEMP-BAL
                         TO WS-RK-WEIGHTED-AMT(WS-INNER-IDX + 1)

                       MOVE WS-RK-RISK-WEIGHT(WS-INNER-IDX)
                           TO WS-TEMP-BAL
                       MOVE WS-RK-RISK-WEIGHT(WS-INNER-IDX + 1)
                           TO WS-RK-RISK-WEIGHT(WS-INNER-IDX)
                       MOVE WS-TEMP-BAL
                         TO WS-RK-RISK-WEIGHT(WS-INNER-IDX + 1)

                       MOVE WS-RK-SECTOR(WS-INNER-IDX)
                           TO WS-TEMP-SECTOR
                       MOVE WS-RK-SECTOR(WS-INNER-IDX + 1)
                           TO WS-RK-SECTOR(WS-INNER-IDX)
                       MOVE WS-TEMP-SECTOR
                           TO WS-RK-SECTOR(WS-INNER-IDX + 1)
                   END-IF
               END-PERFORM
           END-PERFORM

      * Print top 10
           COMPUTE WS-SORT-IDX =
               FUNCTION MIN(10, WS-RISK-COUNT)

           PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
               UNTIL WS-SEARCH-IDX > WS-SORT-IDX
               MOVE WS-SEARCH-IDX
                   TO WS-RR-RANK
               MOVE WS-RK-ACCOUNT-NUM(WS-SEARCH-IDX)
                   TO WS-RR-ACCT
               MOVE WS-RK-BALANCE(WS-SEARCH-IDX)
                   TO WS-RR-BALANCE
               MOVE WS-RK-RISK-WEIGHT(WS-SEARCH-IDX)
                   TO WS-RR-WEIGHT
               MOVE WS-RK-WEIGHTED-AMT(WS-SEARCH-IDX)
                   TO WS-RR-WEIGHTED
               MOVE WS-RK-SECTOR(WS-SEARCH-IDX)
                   TO WS-RR-SECTOR
               WRITE REG-RPT-REC FROM WS-RPT-RISK-LINE
           END-PERFORM

      * Sector concentration
           WRITE REG-RPT-REC FROM RPT-BLANK-LINE
           MOVE SPACES TO WS-RPT-LINE
           STRING '     SECTOR CONCENTRATION'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE

           MOVE SPACES TO WS-RPT-LINE
           STRING '     Code       Total Balance'
               '      Accounts  Concentration'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE
           WRITE REG-RPT-REC FROM RPT-DASH-LINE

      * Calculate percentages
           PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
               UNTIL WS-SEARCH-IDX > WS-SECT-COUNT
               IF WS-TOTAL-ASSETS > 0
                   COMPUTE WS-SC-PCT(WS-SEARCH-IDX) =
                       (WS-SC-TOTAL-BAL(WS-SEARCH-IDX)
                       / WS-TOTAL-ASSETS) * 100
               END-IF

               MOVE WS-SC-CODE(WS-SEARCH-IDX) TO WS-RS-CODE
               MOVE WS-SC-TOTAL-BAL(WS-SEARCH-IDX)
                   TO WS-RS-TOTAL
               MOVE WS-SC-ACCT-COUNT(WS-SEARCH-IDX)
                   TO WS-RS-COUNT
               MOVE WS-SC-PCT(WS-SEARCH-IDX)
                   TO WS-RS-PCT
               WRITE REG-RPT-REC FROM WS-RPT-SECTOR-LINE
           END-PERFORM
           .

       8000-WRITE-FOOTER.
           WRITE REG-RPT-REC FROM RPT-BLANK-LINE
           WRITE REG-RPT-REC FROM RPT-SEPARATOR

           MOVE SPACES TO WS-RPT-LINE
           STRING '     DISCLAIMER: This report is generated for'
               ' regulatory compliance purposes.'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE

           MOVE SPACES TO WS-RPT-LINE
           STRING '     All figures are subject to independent'
               ' verification and audit.'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE REG-RPT-REC FROM WS-RPT-LINE

           WRITE REG-RPT-REC FROM RPT-SEPARATOR
           WRITE REG-RPT-REC FROM WS-REPORT-FOOTER

      * Audit
           ADD 1 TO WS-AUDIT-SEQ
           INITIALIZE WS-AUDIT-RECORD
           MOVE WS-AUDIT-SEQ    TO AUD-SEQUENCE-NUM
           MOVE WS-CURR-DATE    TO AUD-DATE
           MOVE WS-CURR-TIME    TO AUD-TIME
           MOVE 'REGRPT00'      TO AUD-PROGRAM-ID
           MOVE 'RPT'           TO AUD-ACTION-CODE
           MOVE ZEROS           TO AUD-TXN-SEQUENCE
           MOVE 'Regulatory reports generated successfully'
                                TO AUD-DESCRIPTION
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
           CLOSE REG-RPT-FILE
           CLOSE AUDIT-LOG-FILE

           DISPLAY 'REGRPT00: Report generation complete'
           DISPLAY '  Transactions analyzed:  ' WS-TOTAL-TXN-COUNT
           DISPLAY '  Large transactions:     ' WS-LARGE-COUNT
           DISPLAY '  Accounts assessed:      ' WS-RISK-COUNT
           DISPLAY '  Sectors tracked:        ' WS-SECT-COUNT

           MOVE 0 TO RETURN-CODE
           .
