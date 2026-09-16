       IDENTIFICATION DIVISION.
       PROGRAM-ID.    GENDATA0.
       AUTHOR.        ENTERPRISE FINANCIAL SYSTEMS.
       DATE-WRITTEN.  2026-03-31.
      ******************************************************************
      * GENDATA0 - Test Data Generator
      *
      * Utility program that generates sample account master and
      * transaction files for testing the batch processing pipeline.
      *
      * Produces:
      *   1. Account master file  (data/input/accounts.dat)
      *   2. Transaction file     (data/input/transactions.dat)
      *
      * The generated data includes a mix of valid transactions and
      * intentionally invalid records to exercise validation logic:
      *   - Bad account reference (BADACCOUNT01)
      *   - Invalid currency code (XYZ)
      *   - Duplicate sequence number
      *   - Invalid transaction type (ZZZ)
      ******************************************************************

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       REPOSITORY.
           FUNCTION ALL INTRINSIC.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE
               ASSIGN TO 'data/input/accounts.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCT-STATUS.

           SELECT TXN-FILE
               ASSIGN TO 'data/input/transactions.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TXN-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  ACCOUNT-FILE
           RECORDING MODE IS F.
       01  ACCOUNT-FILE-REC            PIC X(200).

       FD  TXN-FILE
           RECORDING MODE IS F.
       01  TXN-FILE-REC               PIC X(200).

       WORKING-STORAGE SECTION.

      * File status variables
       01  WS-ACCT-STATUS              PIC X(02).
       01  WS-TXN-STATUS               PIC X(02).

      * Copybook includes
       COPY 'src/copybooks/TXNREC.cpy'.
       COPY 'src/copybooks/ACTREC.cpy'.

      * Counters
       01  WS-ACCT-WRITTEN             PIC 9(05) VALUE 0.
       01  WS-TXN-WRITTEN              PIC 9(05) VALUE 0.
       01  WS-IDX                      PIC 9(05) VALUE 0.

       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-GENERATE-ACCOUNTS
           PERFORM 2000-GENERATE-TRANSACTIONS
           DISPLAY 'GENDATA0: DATA GENERATION COMPLETE'
           DISPLAY 'GENDATA0: ACCOUNTS WRITTEN = '
               WS-ACCT-WRITTEN
           DISPLAY 'GENDATA0: TRANSACTIONS WRITTEN = '
               WS-TXN-WRITTEN
           STOP RUN
           .

      ******************************************************************
      * 1000 - GENERATE ACCOUNT MASTER FILE
      ******************************************************************
       1000-GENERATE-ACCOUNTS.
           OPEN OUTPUT ACCOUNT-FILE
           IF WS-ACCT-STATUS NOT = '00'
               DISPLAY 'GENDATA0: ERROR OPENING ACCOUNT FILE: '
                   WS-ACCT-STATUS
               STOP RUN
           END-IF

      * --- Internal / System Accounts ---
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'SUSPENSE0001' TO ACT-ACCOUNT-NUM
           MOVE 'SUSPENSE HOLDING ACCOUNT' TO ACT-ACCOUNT-NAME
           MOVE 'SUS'          TO ACT-ACCOUNT-TYPE
           MOVE 'I'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 0              TO ACT-OPENING-BALANCE
           MOVE 0              TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 999999999999999 TO ACT-DAILY-XFR-LIMIT
           MOVE 999999999999999 TO ACT-OVERDRAFT-LIMIT
           MOVE 1.00           TO ACT-RISK-WEIGHT
           MOVE 'FINA'         TO ACT-SECTOR-CODE
           MOVE 20200101       TO ACT-OPEN-DATE
           MOVE 20260330       TO ACT-LAST-TXN-DATE
           MOVE 'BR001 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'FEREVENUE001' TO ACT-ACCOUNT-NUM
           MOVE 'FEE REVENUE ACCOUNT'  TO ACT-ACCOUNT-NAME
           MOVE 'INT'          TO ACT-ACCOUNT-TYPE
           MOVE 'I'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 0              TO ACT-OPENING-BALANCE
           MOVE 0              TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 999999999999999 TO ACT-DAILY-XFR-LIMIT
           MOVE 999999999999999 TO ACT-OVERDRAFT-LIMIT
           MOVE 1.00           TO ACT-RISK-WEIGHT
           MOVE 'FINA'         TO ACT-SECTOR-CODE
           MOVE 20200101       TO ACT-OPEN-DATE
           MOVE 20260330       TO ACT-LAST-TXN-DATE
           MOVE 'BR001 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'INTEXPENS001' TO ACT-ACCOUNT-NUM
           MOVE 'INTEREST EXPENSE ACCOUNT' TO ACT-ACCOUNT-NAME
           MOVE 'INT'          TO ACT-ACCOUNT-TYPE
           MOVE 'I'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 0              TO ACT-OPENING-BALANCE
           MOVE 0              TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 999999999999999 TO ACT-DAILY-XFR-LIMIT
           MOVE 999999999999999 TO ACT-OVERDRAFT-LIMIT
           MOVE 1.00           TO ACT-RISK-WEIGHT
           MOVE 'FINA'         TO ACT-SECTOR-CODE
           MOVE 20200101       TO ACT-OPEN-DATE
           MOVE 20260330       TO ACT-LAST-TXN-DATE
           MOVE 'BR001 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * --- Customer Accounts ---
      * Account 1: Large corporate checking - TECH sector
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000001' TO ACT-ACCOUNT-NUM
           MOVE 'NEXGEN TECHNOLOGIES INC'  TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'I'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 750000.00      TO ACT-OPENING-BALANCE
           MOVE 750000.00      TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 50000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 100000.00      TO ACT-OVERDRAFT-LIMIT
           MOVE 0.85           TO ACT-RISK-WEIGHT
           MOVE 'TECH'         TO ACT-SECTOR-CODE
           MOVE 20210315       TO ACT-OPEN-DATE
           MOVE 20260328       TO ACT-LAST-TXN-DATE
           MOVE 'BR001 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 2: Financial services firm
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000002' TO ACT-ACCOUNT-NUM
           MOVE 'MERIDIAN CAPITAL GROUP'   TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'I'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 1000000.00     TO ACT-OPENING-BALANCE
           MOVE 1000000.00     TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 50000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 200000.00      TO ACT-OVERDRAFT-LIMIT
           MOVE 1.00           TO ACT-RISK-WEIGHT
           MOVE 'FINA'         TO ACT-SECTOR-CODE
           MOVE 20200601       TO ACT-OPEN-DATE
           MOVE 20260329       TO ACT-LAST-TXN-DATE
           MOVE 'BR001 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 3: Energy company
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000003' TO ACT-ACCOUNT-NUM
           MOVE 'SOLARIS ENERGY CORP'      TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'P'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 325000.00      TO ACT-OPENING-BALANCE
           MOVE 325000.00      TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 25000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 50000.00       TO ACT-OVERDRAFT-LIMIT
           MOVE 0.90           TO ACT-RISK-WEIGHT
           MOVE 'ENRG'         TO ACT-SECTOR-CODE
           MOVE 20220110       TO ACT-OPEN-DATE
           MOVE 20260327       TO ACT-LAST-TXN-DATE
           MOVE 'BR002 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 4: Healthcare provider
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000004' TO ACT-ACCOUNT-NUM
           MOVE 'HARBOR HEALTH SYSTEMS'    TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'P'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 180000.00      TO ACT-OPENING-BALANCE
           MOVE 180000.00      TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 25000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 25000.00       TO ACT-OVERDRAFT-LIMIT
           MOVE 0.75           TO ACT-RISK-WEIGHT
           MOVE 'HLTH'         TO ACT-SECTOR-CODE
           MOVE 20210820       TO ACT-OPEN-DATE
           MOVE 20260325       TO ACT-LAST-TXN-DATE
           MOVE 'BR002 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 5: Infrastructure fund
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000005' TO ACT-ACCOUNT-NUM
           MOVE 'ATLAS INFRASTRUCTURE LP'  TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'I'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 500000.00      TO ACT-OPENING-BALANCE
           MOVE 500000.00      TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 50000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 75000.00       TO ACT-OVERDRAFT-LIMIT
           MOVE 0.80           TO ACT-RISK-WEIGHT
           MOVE 'INFR'         TO ACT-SECTOR-CODE
           MOVE 20200915       TO ACT-OPEN-DATE
           MOVE 20260330       TO ACT-LAST-TXN-DATE
           MOVE 'BR001 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 6: Trading firm
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000006' TO ACT-ACCOUNT-NUM
           MOVE 'VANGUARD TRADING LLC'     TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'P'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 420000.00      TO ACT-OPENING-BALANCE
           MOVE 420000.00      TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 25000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 50000.00       TO ACT-OVERDRAFT-LIMIT
           MOVE 0.95           TO ACT-RISK-WEIGHT
           MOVE 'TRAD'         TO ACT-SECTOR-CODE
           MOVE 20210205       TO ACT-OPEN-DATE
           MOVE 20260329       TO ACT-LAST-TXN-DATE
           MOVE 'BR003 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 7: Transportation company
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000007' TO ACT-ACCOUNT-NUM
           MOVE 'TRANSGLOBE LOGISTICS INC' TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'S'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 95000.00       TO ACT-OPENING-BALANCE
           MOVE 95000.00       TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 10000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 10000.00       TO ACT-OVERDRAFT-LIMIT
           MOVE 0.70           TO ACT-RISK-WEIGHT
           MOVE 'TRNS'         TO ACT-SECTOR-CODE
           MOVE 20230412       TO ACT-OPEN-DATE
           MOVE 20260328       TO ACT-LAST-TXN-DATE
           MOVE 'BR002 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 8: Agriculture company
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000008' TO ACT-ACCOUNT-NUM
           MOVE 'GREENFIELD AGRI CO'       TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'S'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 67000.00       TO ACT-OPENING-BALANCE
           MOVE 67000.00       TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 10000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 5000.00        TO ACT-OVERDRAFT-LIMIT
           MOVE 0.65           TO ACT-RISK-WEIGHT
           MOVE 'AGRI'         TO ACT-SECTOR-CODE
           MOVE 20220715       TO ACT-OPEN-DATE
           MOVE 20260326       TO ACT-LAST-TXN-DATE
           MOVE 'BR003 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 9: Mining company
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000009' TO ACT-ACCOUNT-NUM
           MOVE 'COPPER RIDGE MINING LTD'  TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'P'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 215000.00      TO ACT-OPENING-BALANCE
           MOVE 215000.00      TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 25000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 30000.00       TO ACT-OVERDRAFT-LIMIT
           MOVE 0.90           TO ACT-RISK-WEIGHT
           MOVE 'MINE'         TO ACT-SECTOR-CODE
           MOVE 20210930       TO ACT-OPEN-DATE
           MOVE 20260329       TO ACT-LAST-TXN-DATE
           MOVE 'BR001 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 10: Defense contractor
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000010' TO ACT-ACCOUNT-NUM
           MOVE 'SENTINEL DEFENSE SYSTEMS' TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'I'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 890000.00      TO ACT-OPENING-BALANCE
           MOVE 890000.00      TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 50000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 150000.00      TO ACT-OVERDRAFT-LIMIT
           MOVE 0.80           TO ACT-RISK-WEIGHT
           MOVE 'DEFE'         TO ACT-SECTOR-CODE
           MOVE 20200301       TO ACT-OPEN-DATE
           MOVE 20260330       TO ACT-LAST-TXN-DATE
           MOVE 'BR001 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 11: Real estate firm
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000011' TO ACT-ACCOUNT-NUM
           MOVE 'PINNACLE REALTY GROUP'    TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'P'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 275000.00      TO ACT-OPENING-BALANCE
           MOVE 275000.00      TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 25000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 40000.00       TO ACT-OVERDRAFT-LIMIT
           MOVE 0.85           TO ACT-RISK-WEIGHT
           MOVE 'REAL'         TO ACT-SECTOR-CODE
           MOVE 20211115       TO ACT-OPEN-DATE
           MOVE 20260327       TO ACT-LAST-TXN-DATE
           MOVE 'BR002 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 12: Manufacturing company
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000012' TO ACT-ACCOUNT-NUM
           MOVE 'IRONWORKS MANUFACTURING'  TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'S'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 142000.00      TO ACT-OPENING-BALANCE
           MOVE 142000.00      TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 10000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 15000.00       TO ACT-OVERDRAFT-LIMIT
           MOVE 0.75           TO ACT-RISK-WEIGHT
           MOVE 'MANU'         TO ACT-SECTOR-CODE
           MOVE 20220501       TO ACT-OPEN-DATE
           MOVE 20260328       TO ACT-LAST-TXN-DATE
           MOVE 'BR003 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 13: Hospitality chain
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000013' TO ACT-ACCOUNT-NUM
           MOVE 'GRANDVIEW HOSPITALITY'    TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'S'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 88000.00       TO ACT-OPENING-BALANCE
           MOVE 88000.00       TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 10000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 10000.00       TO ACT-OVERDRAFT-LIMIT
           MOVE 0.60           TO ACT-RISK-WEIGHT
           MOVE 'HOSP'         TO ACT-SECTOR-CODE
           MOVE 20230201       TO ACT-OPEN-DATE
           MOVE 20260325       TO ACT-LAST-TXN-DATE
           MOVE 'BR002 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 14: Savings account - tech employee
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000014' TO ACT-ACCOUNT-NUM
           MOVE 'CHEN, MARGARET W'         TO ACT-ACCOUNT-NAME
           MOVE 'SAV'          TO ACT-ACCOUNT-TYPE
           MOVE 'S'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 45000.00       TO ACT-OPENING-BALANCE
           MOVE 45000.00       TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 10000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 0              TO ACT-OVERDRAFT-LIMIT
           MOVE 0.50           TO ACT-RISK-WEIGHT
           MOVE 'TECH'         TO ACT-SECTOR-CODE
           MOVE 20230615       TO ACT-OPEN-DATE
           MOVE 20260320       TO ACT-LAST-TXN-DATE
           MOVE 'BR001 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 15: Savings account - doctor
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000015' TO ACT-ACCOUNT-NUM
           MOVE 'PATEL, DR RAJESH K'       TO ACT-ACCOUNT-NAME
           MOVE 'SAV'          TO ACT-ACCOUNT-TYPE
           MOVE 'P'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 120000.00      TO ACT-OPENING-BALANCE
           MOVE 120000.00      TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 25000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 0              TO ACT-OVERDRAFT-LIMIT
           MOVE 0.55           TO ACT-RISK-WEIGHT
           MOVE 'HLTH'         TO ACT-SECTOR-CODE
           MOVE 20220301       TO ACT-OPEN-DATE
           MOVE 20260328       TO ACT-LAST-TXN-DATE
           MOVE 'BR002 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 16: Checking - small business
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000016' TO ACT-ACCOUNT-NUM
           MOVE 'OAKRIDGE CONSULTING LLC'  TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'S'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 38000.00       TO ACT-OPENING-BALANCE
           MOVE 38000.00       TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 10000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 5000.00        TO ACT-OVERDRAFT-LIMIT
           MOVE 0.70           TO ACT-RISK-WEIGHT
           MOVE 'FINA'         TO ACT-SECTOR-CODE
           MOVE 20240101       TO ACT-OPEN-DATE
           MOVE 20260329       TO ACT-LAST-TXN-DATE
           MOVE 'BR003 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 17: Checking - energy startup
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000017' TO ACT-ACCOUNT-NUM
           MOVE 'WINDBORNE RENEWABLES'     TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'S'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 52000.00       TO ACT-OPENING-BALANCE
           MOVE 52000.00       TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 10000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 5000.00        TO ACT-OVERDRAFT-LIMIT
           MOVE 0.75           TO ACT-RISK-WEIGHT
           MOVE 'ENRG'         TO ACT-SECTOR-CODE
           MOVE 20240315       TO ACT-OPEN-DATE
           MOVE 20260327       TO ACT-LAST-TXN-DATE
           MOVE 'BR001 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 18: Savings - individual
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000018' TO ACT-ACCOUNT-NUM
           MOVE 'THOMPSON, JAMES R'        TO ACT-ACCOUNT-NAME
           MOVE 'SAV'          TO ACT-ACCOUNT-TYPE
           MOVE 'S'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 15000.00       TO ACT-OPENING-BALANCE
           MOVE 15000.00       TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 5000.00        TO ACT-DAILY-XFR-LIMIT
           MOVE 0              TO ACT-OVERDRAFT-LIMIT
           MOVE 0.50           TO ACT-RISK-WEIGHT
           MOVE 'TECH'         TO ACT-SECTOR-CODE
           MOVE 20250601       TO ACT-OPEN-DATE
           MOVE 20260315       TO ACT-LAST-TXN-DATE
           MOVE 'BR002 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 19: Frozen account (for testing)
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000019' TO ACT-ACCOUNT-NUM
           MOVE 'BLACKSTONE VENTURES LLC'  TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'P'            TO ACT-TIER
           MOVE 'F'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 200000.00      TO ACT-OPENING-BALANCE
           MOVE 200000.00      TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 25000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 25000.00       TO ACT-OVERDRAFT-LIMIT
           MOVE 1.00           TO ACT-RISK-WEIGHT
           MOVE 'FINA'         TO ACT-SECTOR-CODE
           MOVE 20210801       TO ACT-OPEN-DATE
           MOVE 20260101       TO ACT-LAST-TXN-DATE
           MOVE 'BR001 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 20: Loan account
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000020' TO ACT-ACCOUNT-NUM
           MOVE 'NEXGEN TECH TERM LOAN'    TO ACT-ACCOUNT-NAME
           MOVE 'LON'          TO ACT-ACCOUNT-TYPE
           MOVE 'I'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE -250000.00     TO ACT-OPENING-BALANCE
           MOVE -250000.00     TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 50000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 0              TO ACT-OVERDRAFT-LIMIT
           MOVE 1.00           TO ACT-RISK-WEIGHT
           MOVE 'TECH'         TO ACT-SECTOR-CODE
           MOVE 20220601       TO ACT-OPEN-DATE
           MOVE 20260325       TO ACT-LAST-TXN-DATE
           MOVE 'BR001 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 21: Savings - premium individual
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000021' TO ACT-ACCOUNT-NUM
           MOVE 'RODRIGUEZ, ELENA M'       TO ACT-ACCOUNT-NAME
           MOVE 'SAV'          TO ACT-ACCOUNT-TYPE
           MOVE 'P'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 85000.00       TO ACT-OPENING-BALANCE
           MOVE 85000.00       TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 25000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 0              TO ACT-OVERDRAFT-LIMIT
           MOVE 0.55           TO ACT-RISK-WEIGHT
           MOVE 'REAL'         TO ACT-SECTOR-CODE
           MOVE 20230801       TO ACT-OPEN-DATE
           MOVE 20260328       TO ACT-LAST-TXN-DATE
           MOVE 'BR003 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 22: Checking - tech
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000022' TO ACT-ACCOUNT-NUM
           MOVE 'QUANTUM DYNAMICS CORP'    TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'I'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 630000.00      TO ACT-OPENING-BALANCE
           MOVE 630000.00      TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 50000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 100000.00      TO ACT-OVERDRAFT-LIMIT
           MOVE 0.85           TO ACT-RISK-WEIGHT
           MOVE 'TECH'         TO ACT-SECTOR-CODE
           MOVE 20210401       TO ACT-OPEN-DATE
           MOVE 20260330       TO ACT-LAST-TXN-DATE
           MOVE 'BR001 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 23: Checking - small business
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000023' TO ACT-ACCOUNT-NUM
           MOVE 'RIVERSIDE BAKERY INC'     TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'S'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 22000.00       TO ACT-OPENING-BALANCE
           MOVE 22000.00       TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 5000.00        TO ACT-DAILY-XFR-LIMIT
           MOVE 2000.00        TO ACT-OVERDRAFT-LIMIT
           MOVE 0.60           TO ACT-RISK-WEIGHT
           MOVE 'HOSP'         TO ACT-SECTOR-CODE
           MOVE 20240901       TO ACT-OPEN-DATE
           MOVE 20260326       TO ACT-LAST-TXN-DATE
           MOVE 'BR003 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 24: Savings - individual
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000024' TO ACT-ACCOUNT-NUM
           MOVE 'WILLIAMS, DAVID A'        TO ACT-ACCOUNT-NAME
           MOVE 'SAV'          TO ACT-ACCOUNT-TYPE
           MOVE 'S'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 8500.00        TO ACT-OPENING-BALANCE
           MOVE 8500.00        TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 5000.00        TO ACT-DAILY-XFR-LIMIT
           MOVE 0              TO ACT-OVERDRAFT-LIMIT
           MOVE 0.50           TO ACT-RISK-WEIGHT
           MOVE 'MANU'         TO ACT-SECTOR-CODE
           MOVE 20250201       TO ACT-OPEN-DATE
           MOVE 20260320       TO ACT-LAST-TXN-DATE
           MOVE 'BR002 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 25: Checking - mining
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000025' TO ACT-ACCOUNT-NUM
           MOVE 'SILVERPEAK RESOURCES'     TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'P'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 310000.00      TO ACT-OPENING-BALANCE
           MOVE 310000.00      TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 25000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 40000.00       TO ACT-OVERDRAFT-LIMIT
           MOVE 0.90           TO ACT-RISK-WEIGHT
           MOVE 'MINE'         TO ACT-SECTOR-CODE
           MOVE 20220101       TO ACT-OPEN-DATE
           MOVE 20260329       TO ACT-LAST-TXN-DATE
           MOVE 'BR001 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

      * Account 26: Checking - defense
           INITIALIZE WS-ACCOUNT-RECORD
           MOVE 'ACCT00000026' TO ACT-ACCOUNT-NUM
           MOVE 'PATRIOT AEROSPACE INC'    TO ACT-ACCOUNT-NAME
           MOVE 'CHK'          TO ACT-ACCOUNT-TYPE
           MOVE 'I'            TO ACT-TIER
           MOVE 'A'            TO ACT-STATUS
           MOVE 'USD'          TO ACT-CURRENCY
           MOVE 475000.00      TO ACT-OPENING-BALANCE
           MOVE 475000.00      TO ACT-CURRENT-BALANCE
           MOVE 0              TO ACT-DAILY-DEBIT-TOTAL
           MOVE 0              TO ACT-DAILY-CREDIT-TOTAL
           MOVE 0              TO ACT-DAILY-TXN-COUNT
           MOVE 0              TO ACT-DAILY-XFR-TOTAL
           MOVE 50000.00       TO ACT-DAILY-XFR-LIMIT
           MOVE 75000.00       TO ACT-OVERDRAFT-LIMIT
           MOVE 0.80           TO ACT-RISK-WEIGHT
           MOVE 'DEFE'         TO ACT-SECTOR-CODE
           MOVE 20210601       TO ACT-OPEN-DATE
           MOVE 20260330       TO ACT-LAST-TXN-DATE
           MOVE 'BR001 '       TO ACT-BRANCH-CODE
           WRITE ACCOUNT-FILE-REC FROM WS-ACCOUNT-RECORD
           ADD 1 TO WS-ACCT-WRITTEN

           CLOSE ACCOUNT-FILE
           DISPLAY 'GENDATA0: ACCOUNT FILE CLOSED, STATUS='
               WS-ACCT-STATUS
           .

      ******************************************************************
      * 2000 - GENERATE TRANSACTION FILE
      ******************************************************************
       2000-GENERATE-TRANSACTIONS.
           OPEN OUTPUT TXN-FILE
           IF WS-TXN-STATUS NOT = '00'
               DISPLAY 'GENDATA0: ERROR OPENING TXN FILE: '
                   WS-TXN-STATUS
               STOP RUN
           END-IF

      * ============================================================
      * DEPOSITS (15 transactions) - TXN 1 through 15
      * ============================================================

      * TXN 1: Standard deposit - ACCT01
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000001     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 083015         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000001' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 5000.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'WIRE DEPOSIT - CLIENT PAYMENT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 2: Large deposit >$10K (BSA trigger) - ACCT02
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000002     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 083245         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000002' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 25000.00       TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'LARGE WIRE TRANSFER IN'
                               TO TXN-DESCRIPTION
           MOVE 'OP0002  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 3: Deposit - ACCT03
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000003     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 084100         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000003' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 7500.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'CHECK DEPOSIT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 4: Large deposit >$10K (BSA trigger) - ACCT05
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000004     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 084530         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000005' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 15000.00       TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'INFRASTRUCTURE GRANT PAYMENT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0003  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 5: Deposit - ACCT06
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000005     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 085000         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000006' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 3200.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'TRADING SETTLEMENT RECEIPT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0002  '    TO TXN-OPERATOR-ID
           MOVE 'BR003 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 6: Deposit - ACCT08
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000006     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 085500         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000008' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 2800.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'CROP SALE PROCEEDS'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR003 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 7: Deposit - ACCT10
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000007     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 090000         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000010' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 45000.00       TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'GOVT CONTRACT MILESTONE PAYMENT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0003  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 8: Deposit - ACCT11
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000008     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 090530         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000011' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 8750.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'RENTAL INCOME COLLECTION'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 9: Deposit - ACCT14
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000009     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 091000         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000014' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 3500.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'PAYROLL DIRECT DEPOSIT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0002  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 10: Large deposit >$10K (BSA trigger) - ACCT22
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000010     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 091500         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000022' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 50000.00       TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'VENTURE CAPITAL FUNDING ROUND'
                               TO TXN-DESCRIPTION
           MOVE 'OP0003  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 11: Deposit - ACCT15
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000011     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 092000         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000015' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 6200.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'MEDICAL PRACTICE INCOME'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 12: Deposit - ACCT16
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000012     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 092500         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000016' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 4100.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'CONSULTING FEE RECEIVED'
                               TO TXN-DESCRIPTION
           MOVE 'OP0002  '    TO TXN-OPERATOR-ID
           MOVE 'BR003 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 13: Deposit - ACCT23
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000013     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 093000         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000023' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 1850.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'DAILY BAKERY SALES DEPOSIT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR003 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 14: Large deposit >$10K (BSA trigger) - ACCT26
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000014     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 093500         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000026' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 35000.00       TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'DEFENSE SUBCONTRACT PAYMENT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0003  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 15: Deposit - ACCT25
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000015     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 094000         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000025' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 9500.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'MINERAL RIGHTS ROYALTY'
                               TO TXN-DESCRIPTION
           MOVE 'OP0002  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * ============================================================
      * WITHDRAWALS (10 transactions) - TXN 16 through 25
      * ============================================================

      * TXN 16: Withdrawal - ACCT01 (bal 750K, withdraw 8K)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000016     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 100000         TO TXN-TIME
           MOVE 'WDR'          TO TXN-TYPE
           MOVE 'ACCT00000001' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 8000.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'VENDOR PAYMENT - CLOUD SERVICES'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 17: Large withdrawal >$10K (BSA) - ACCT02 (bal 1M)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000017     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 100530         TO TXN-TIME
           MOVE 'WDR'          TO TXN-TYPE
           MOVE 'ACCT00000002' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 18500.00       TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'QUARTERLY DIVIDEND DISTRIBUTION'
                               TO TXN-DESCRIPTION
           MOVE 'OP0002  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 18: Withdrawal - ACCT04 (bal 180K)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000018     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 101000         TO TXN-TIME
           MOVE 'WDR'          TO TXN-TYPE
           MOVE 'ACCT00000004' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 4500.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'MEDICAL SUPPLY ORDER'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 19: Withdrawal - ACCT06 (bal 420K)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000019     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 101500         TO TXN-TIME
           MOVE 'WDR'          TO TXN-TYPE
           MOVE 'ACCT00000006' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 6700.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'TRADING PLATFORM LICENSE FEE'
                               TO TXN-DESCRIPTION
           MOVE 'OP0003  '    TO TXN-OPERATOR-ID
           MOVE 'BR003 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 20: Withdrawal - ACCT09 (bal 215K)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000020     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 102000         TO TXN-TIME
           MOVE 'WDR'          TO TXN-TYPE
           MOVE 'ACCT00000009' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 3200.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'EQUIPMENT MAINTENANCE'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 21: Withdrawal - ACCT12 (bal 142K)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000021     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 102500         TO TXN-TIME
           MOVE 'WDR'          TO TXN-TYPE
           MOVE 'ACCT00000012' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 7800.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'RAW MATERIALS PURCHASE'
                               TO TXN-DESCRIPTION
           MOVE 'OP0002  '    TO TXN-OPERATOR-ID
           MOVE 'BR003 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 22: Withdrawal - ACCT13 (bal 88K)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000022     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 103000         TO TXN-TIME
           MOVE 'WDR'          TO TXN-TYPE
           MOVE 'ACCT00000013' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 2400.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'FOOD SERVICE SUPPLIER PAYMENT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 23: Withdrawal - ACCT17 (bal 52K)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000023     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 103500         TO TXN-TIME
           MOVE 'WDR'          TO TXN-TYPE
           MOVE 'ACCT00000017' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 1900.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'UTILITY BILL PAYMENT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0003  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 24: Large withdrawal >$10K (BSA) - ACCT10 (bal 890K)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000024     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 104000         TO TXN-TIME
           MOVE 'WDR'          TO TXN-TYPE
           MOVE 'ACCT00000010' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 22000.00       TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'CONTRACTOR PAYROLL BATCH'
                               TO TXN-DESCRIPTION
           MOVE 'OP0002  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 25: Withdrawal - ACCT21 (bal 85K)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000025     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 104500         TO TXN-TIME
           MOVE 'WDR'          TO TXN-TYPE
           MOVE 'ACCT00000021' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 5500.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'PROPERTY TAX PAYMENT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR003 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * ============================================================
      * TRANSFERS (8 transactions) - TXN 26 through 33
      * ============================================================

      * TXN 26: Transfer ACCT01 -> ACCT05
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000026     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 110000         TO TXN-TIME
           MOVE 'XFR'          TO TXN-TYPE
           MOVE 'ACCT00000001' TO TXN-SOURCE-ACCOUNT
           MOVE 'ACCT00000005' TO TXN-TARGET-ACCOUNT
           MOVE 5000.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'INTERCOMPANY FUND TRANSFER'
                               TO TXN-DESCRIPTION
           MOVE 'OP0002  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 27: Large transfer >$10K (BSA) ACCT02 -> ACCT22
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000027     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 110500         TO TXN-TIME
           MOVE 'XFR'          TO TXN-TYPE
           MOVE 'ACCT00000002' TO TXN-SOURCE-ACCOUNT
           MOVE 'ACCT00000022' TO TXN-TARGET-ACCOUNT
           MOVE 30000.00       TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'INVESTMENT CAPITAL ALLOCATION'
                               TO TXN-DESCRIPTION
           MOVE 'OP0003  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 28: Transfer ACCT03 -> ACCT17
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000028     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 111000         TO TXN-TIME
           MOVE 'XFR'          TO TXN-TYPE
           MOVE 'ACCT00000003' TO TXN-SOURCE-ACCOUNT
           MOVE 'ACCT00000017' TO TXN-TARGET-ACCOUNT
           MOVE 8000.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'ENERGY SECTOR REBALANCING'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 29: Transfer ACCT10 -> ACCT26
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000029     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 111500         TO TXN-TIME
           MOVE 'XFR'          TO TXN-TYPE
           MOVE 'ACCT00000010' TO TXN-SOURCE-ACCOUNT
           MOVE 'ACCT00000026' TO TXN-TARGET-ACCOUNT
           MOVE 7500.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'DEFENSE PROGRAM FUND MOVEMENT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0002  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 30: Transfer ACCT15 -> ACCT21
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000030     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 112000         TO TXN-TIME
           MOVE 'XFR'          TO TXN-TYPE
           MOVE 'ACCT00000015' TO TXN-SOURCE-ACCOUNT
           MOVE 'ACCT00000021' TO TXN-TARGET-ACCOUNT
           MOVE 2000.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'PERSONAL SAVINGS TRANSFER'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 31: Transfer ACCT06 -> ACCT09
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000031     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 112500         TO TXN-TIME
           MOVE 'XFR'          TO TXN-TYPE
           MOVE 'ACCT00000006' TO TXN-SOURCE-ACCOUNT
           MOVE 'ACCT00000009' TO TXN-TARGET-ACCOUNT
           MOVE 4500.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'COMMODITY SETTLEMENT TRANSFER'
                               TO TXN-DESCRIPTION
           MOVE 'OP0003  '    TO TXN-OPERATOR-ID
           MOVE 'BR003 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 32: Transfer ACCT11 -> ACCT23
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000032     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 113000         TO TXN-TIME
           MOVE 'XFR'          TO TXN-TYPE
           MOVE 'ACCT00000011' TO TXN-SOURCE-ACCOUNT
           MOVE 'ACCT00000023' TO TXN-TARGET-ACCOUNT
           MOVE 3000.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'TENANT IMPROVEMENT FUNDING'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 33: Transfer ACCT25 -> ACCT08
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000033     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 113500         TO TXN-TIME
           MOVE 'XFR'          TO TXN-TYPE
           MOVE 'ACCT00000025' TO TXN-SOURCE-ACCOUNT
           MOVE 'ACCT00000008' TO TXN-TARGET-ACCOUNT
           MOVE 6000.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'AGRICULTURAL SUPPLY CHAIN FUND'
                               TO TXN-DESCRIPTION
           MOVE 'OP0002  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * ============================================================
      * FEES (5 transactions) - TXN 34 through 38
      * ============================================================

      * TXN 34: Fee - ACCT07
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000034     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 120000         TO TXN-TIME
           MOVE 'FEE'          TO TXN-TYPE
           MOVE 'ACCT00000007' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 25.00          TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'MONTHLY ACCOUNT MAINTENANCE FEE'
                               TO TXN-DESCRIPTION
           MOVE 'SYSTEM  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 35: Fee - ACCT12
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000035     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 120100         TO TXN-TIME
           MOVE 'FEE'          TO TXN-TYPE
           MOVE 'ACCT00000012' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 25.00          TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'MONTHLY ACCOUNT MAINTENANCE FEE'
                               TO TXN-DESCRIPTION
           MOVE 'SYSTEM  '    TO TXN-OPERATOR-ID
           MOVE 'BR003 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 36: Fee - ACCT16
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000036     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 120200         TO TXN-TIME
           MOVE 'FEE'          TO TXN-TYPE
           MOVE 'ACCT00000016' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 15.00          TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'WIRE TRANSFER FEE'
                               TO TXN-DESCRIPTION
           MOVE 'SYSTEM  '    TO TXN-OPERATOR-ID
           MOVE 'BR003 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 37: Fee - ACCT23
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000037     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 120300         TO TXN-TIME
           MOVE 'FEE'          TO TXN-TYPE
           MOVE 'ACCT00000023' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 25.00          TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'MONTHLY ACCOUNT MAINTENANCE FEE'
                               TO TXN-DESCRIPTION
           MOVE 'SYSTEM  '    TO TXN-OPERATOR-ID
           MOVE 'BR003 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 38: Fee - ACCT18
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000038     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 120400         TO TXN-TIME
           MOVE 'FEE'          TO TXN-TYPE
           MOVE 'ACCT00000018' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 10.00          TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'LOW BALANCE SERVICE CHARGE'
                               TO TXN-DESCRIPTION
           MOVE 'SYSTEM  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * ============================================================
      * INTEREST (5 transactions) - TXN 39 through 43
      * ============================================================

      * TXN 39: Interest credit - ACCT14 (SAV, bal 45K)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000039     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 130000         TO TXN-TIME
           MOVE 'INT'          TO TXN-TYPE
           MOVE 'ACCT00000014' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 18.75          TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'DAILY INTEREST ACCRUAL'
                               TO TXN-DESCRIPTION
           MOVE 'SYSTEM  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 40: Interest credit - ACCT15 (SAV, bal 120K)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000040     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 130100         TO TXN-TIME
           MOVE 'INT'          TO TXN-TYPE
           MOVE 'ACCT00000015' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 50.00          TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'DAILY INTEREST ACCRUAL'
                               TO TXN-DESCRIPTION
           MOVE 'SYSTEM  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 41: Interest credit - ACCT18 (SAV, bal 15K)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000041     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 130200         TO TXN-TIME
           MOVE 'INT'          TO TXN-TYPE
           MOVE 'ACCT00000018' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 6.25           TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'DAILY INTEREST ACCRUAL'
                               TO TXN-DESCRIPTION
           MOVE 'SYSTEM  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 42: Interest credit - ACCT21 (SAV, bal 85K)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000042     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 130300         TO TXN-TIME
           MOVE 'INT'          TO TXN-TYPE
           MOVE 'ACCT00000021' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 35.42          TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'DAILY INTEREST ACCRUAL'
                               TO TXN-DESCRIPTION
           MOVE 'SYSTEM  '    TO TXN-OPERATOR-ID
           MOVE 'BR003 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 43: Interest credit - ACCT24 (SAV, bal 8.5K)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000043     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 130400         TO TXN-TIME
           MOVE 'INT'          TO TXN-TYPE
           MOVE 'ACCT00000024' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 3.54           TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'DAILY INTEREST ACCRUAL'
                               TO TXN-DESCRIPTION
           MOVE 'SYSTEM  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * ============================================================
      * ADJUSTMENTS (3 transactions) - TXN 44 through 46
      * ============================================================

      * TXN 44: Adjustment - ACCT07 (correction)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000044     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 140000         TO TXN-TIME
           MOVE 'ADJ'          TO TXN-TYPE
           MOVE 'ACCT00000007' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 150.00         TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'POSTING ERROR CORRECTION'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE 'ADJ1'         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 45: Adjustment - ACCT13 (fee reversal)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000045     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 140500         TO TXN-TIME
           MOVE 'ADJ'          TO TXN-TYPE
           MOVE 'ACCT00000013' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 25.00          TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'FEE REVERSAL PER CUSTOMER REQUEST'
                               TO TXN-DESCRIPTION
           MOVE 'OP0002  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE 'ADJ2'         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 46: Adjustment - ACCT24 (balance correction)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000046     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 141000         TO TXN-TIME
           MOVE 'ADJ'          TO TXN-TYPE
           MOVE 'ACCT00000024' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 75.00          TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'BALANCE RECONCILIATION ADJUSTMENT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0003  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE 'ADJ1'         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * ============================================================
      * INVALID TRANSACTIONS (4 transactions) - TXN 47 through 50
      * ============================================================

      * ============================================================
      * EDGE CASES (8 transactions) - TXN 47 through 54
      * ============================================================

      * TXN 47: Withdrawal that uses overdraft (should PASS)
      * ACCT06 has bal=$420K, overdraft=$10K
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000047     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 143000         TO TXN-TIME
           MOVE 'WDR'          TO TXN-TYPE
           MOVE 'ACCT00000006' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 420500.00      TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'LARGE WITHDRAWAL INTO OVERDRAFT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 48: Withdrawal exceeding balance+overdraft (E02)
      * ACCT12 has bal=$142K, overdraft=$1K
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000048     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 143500         TO TXN-TIME
           MOVE 'WDR'          TO TXN-TYPE
           MOVE 'ACCT00000012' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 999999.00      TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'WITHDRAWAL EXCEEDING ALL LIMITS'
                               TO TXN-DESCRIPTION
           MOVE 'OP0002  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 49: Transaction on frozen account (E03)
      * ACCT19 is frozen
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000049     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 144000         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000019' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 5000.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'DEPOSIT TO FROZEN ACCOUNT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0003  '    TO TXN-OPERATOR-ID
           MOVE 'BR003 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 50: Zero amount transaction (E08)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000050     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 144500         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000001' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 0              TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'ZERO AMOUNT DEPOSIT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 51: Adjustment without reason code (E08)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000051     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 145000         TO TXN-TIME
           MOVE 'ADJ'          TO TXN-TYPE
           MOVE 'ACCT00000003' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 100.00         TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'ADJUSTMENT WITH NO REASON CODE'
                               TO TXN-DESCRIPTION
           MOVE 'OP0005  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * ============================================================
      * INVALID TRANSACTIONS (4 transactions) - TXN 52 through 55
      * ============================================================

      * TXN 52: INVALID - Bad account number (not in master)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000047     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 150000         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'BADACCOUNT01' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 1000.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'DEPOSIT TO NON-EXISTENT ACCOUNT'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 48: INVALID - Bad currency code (XYZ)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000048     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 150500         TO TXN-TIME
           MOVE 'WDR'          TO TXN-TYPE
           MOVE 'ACCT00000003' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 500.00         TO TXN-AMOUNT
           MOVE 'XYZ'          TO TXN-CURRENCY
           MOVE 'WITHDRAWAL WITH INVALID CURRENCY'
                               TO TXN-DESCRIPTION
           MOVE 'OP0002  '    TO TXN-OPERATOR-ID
           MOVE 'BR002 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 49: INVALID - Duplicate sequence number (same as TXN 10)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000010     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 151000         TO TXN-TIME
           MOVE 'DEP'          TO TXN-TYPE
           MOVE 'ACCT00000005' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 2500.00        TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'DUPLICATE SEQUENCE NUMBER TEST'
                               TO TXN-DESCRIPTION
           MOVE 'OP0003  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

      * TXN 50: INVALID - Bad transaction type (ZZZ)
           INITIALIZE WS-TRANSACTION-RECORD
           MOVE 0000000050     TO TXN-SEQUENCE-NUM
           MOVE 20260331       TO TXN-DATE
           MOVE 151500         TO TXN-TIME
           MOVE 'ZZZ'          TO TXN-TYPE
           MOVE 'ACCT00000001' TO TXN-SOURCE-ACCOUNT
           MOVE SPACES         TO TXN-TARGET-ACCOUNT
           MOVE 750.00         TO TXN-AMOUNT
           MOVE 'USD'          TO TXN-CURRENCY
           MOVE 'INVALID TRANSACTION TYPE TEST'
                               TO TXN-DESCRIPTION
           MOVE 'OP0001  '    TO TXN-OPERATOR-ID
           MOVE 'BR001 '       TO TXN-BRANCH-CODE
           MOVE SPACES         TO TXN-REASON-CODE
           MOVE 'P'            TO TXN-STATUS
           MOVE SPACES         TO TXN-ERROR-CODE
           MOVE 000001         TO TXN-BATCH-ID
           MOVE SPACES         TO TXN-CHECKSUM
           WRITE TXN-FILE-REC FROM WS-TRANSACTION-RECORD
           ADD 1 TO WS-TXN-WRITTEN

           CLOSE TXN-FILE
           DISPLAY 'GENDATA0: TRANSACTION FILE CLOSED, STATUS='
               WS-TXN-STATUS
           .
