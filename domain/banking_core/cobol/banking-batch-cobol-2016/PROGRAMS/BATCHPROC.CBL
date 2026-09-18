       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATCHPROC.
      ******************************************************************
      * PROGRAM NAME: BATCHPROC
      * DESCRIPTION:  DAILY BATCH PROCESSING FOR BANKING TRANSACTIONS
      *               - READS TRANSACTION FILE
      *               - VALIDATES EACH TRANSACTION
      *               - UPDATES ACCOUNT BALANCES
      *               - GENERATES REPORTS
      * AUTHOR:       BANKING SYSTEMS TEAM
      * DATE:         2016-01-15
      * SYSTEM:       IBM z/OS MAINFRAME
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
       
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANS-FILE
               ASSIGN TO TRANSIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-TRANS-FILE-STATUS.
               
           SELECT ACCOUNT-FILE
               ASSIGN TO ACCTMAST
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS ACCT-NUMBER
               ALTERNATE RECORD KEY IS ACCT-CUST-ID
                   WITH DUPLICATES
               FILE STATUS IS WS-ACCT-FILE-STATUS.
               
           SELECT TRANS-LOG
               ASSIGN TO TRANSLOG
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-LOG-FILE-STATUS.
               
           SELECT ERROR-FILE
               ASSIGN TO ERRFILE
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-ERR-FILE-STATUS.
               
           SELECT REPORT-FILE
               ASSIGN TO RPTFILE
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-RPT-FILE-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       
       FD  TRANS-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 500 CHARACTERS.
       COPY TRANSACT.
       
       FD  ACCOUNT-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 600 CHARACTERS.
       COPY ACCOUNT.
       
       FD  TRANS-LOG
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 550 CHARACTERS.
       01  LOG-RECORD                  PIC X(550).
       
       FD  ERROR-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 200 CHARACTERS.
       01  ERROR-RECORD                PIC X(200).
       
       FD  REPORT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 133 CHARACTERS.
       01  REPORT-RECORD               PIC X(133).
       
       WORKING-STORAGE SECTION.
       
      * FILE STATUS VARIABLES
       01  WS-TRANS-FILE-STATUS        PIC XX.
           88  WS-TRANS-EOF            VALUE '10'.
           88  WS-TRANS-OK             VALUE '00'.
           
       01  WS-ACCT-FILE-STATUS         PIC XX.
           88  WS-ACCT-OK              VALUE '00'.
           88  WS-ACCT-NOT-FOUND       VALUE '23'.
           
       01  WS-LOG-FILE-STATUS          PIC XX.
       01  WS-ERR-FILE-STATUS          PIC XX.
       01  WS-RPT-FILE-STATUS          PIC XX.
       
      * COUNTERS AND ACCUMULATORS
       01  WS-COUNTERS.
           05  WS-TRANS-READ-COUNT     PIC 9(9) VALUE ZERO.
           05  WS-TRANS-PROCESSED      PIC 9(9) VALUE ZERO.
           05  WS-TRANS-ERROR-COUNT    PIC 9(9) VALUE ZERO.
           05  WS-ACCT-UPDATED         PIC 9(9) VALUE ZERO.
           05  WS-DEPOSITS-COUNT       PIC 9(9) VALUE ZERO.
           05  WS-WITHDRAWALS-COUNT    PIC 9(9) VALUE ZERO.
           05  WS-TRANSFERS-COUNT      PIC 9(9) VALUE ZERO.
           
       01  WS-TOTALS.
           05  WS-TOTAL-DEPOSITS       PIC S9(15)V99 VALUE ZERO.
           05  WS-TOTAL-WITHDRAWALS    PIC S9(15)V99 VALUE ZERO.
           05  WS-TOTAL-TRANSFERS      PIC S9(15)V99 VALUE ZERO.
           05  WS-TOTAL-FEES           PIC S9(13)V99 VALUE ZERO.
       
      * DATE AND TIME FIELDS
       01  WS-CURRENT-DATE.
           05  WS-CURR-YEAR            PIC 9(4).
           05  WS-CURR-MONTH           PIC 99.
           05  WS-CURR-DAY             PIC 99.
           
       01  WS-CURRENT-TIME.
           05  WS-CURR-HOUR            PIC 99.
           05  WS-CURR-MINUTE          PIC 99.
           05  WS-CURR-SECOND          PIC 99.
           
       01  WS-BUSINESS-DATE            PIC 9(8).
       
      * WORK FIELDS
       01  WS-RETURN-CODE              PIC S9(4) COMP VALUE ZERO.
       01  WS-ERROR-MESSAGE            PIC X(80).
       01  WS-EDIT-AMOUNT              PIC ZZZ,ZZZ,ZZZ,ZZ9.99-.
       
      * REPORT HEADERS
       01  WS-REPORT-HEADER-1.
           05  FILLER                  PIC X(20) VALUE SPACES.
           05  FILLER                  PIC X(40) 
               VALUE 'DAILY BATCH PROCESSING SUMMARY REPORT'.
           05  FILLER                  PIC X(73) VALUE SPACES.
           
       01  WS-REPORT-HEADER-2.
           05  FILLER                  PIC X(10) VALUE 'RUN DATE: '.
           05  WS-RPT-DATE             PIC X(10).
           05  FILLER                  PIC X(15) VALUE SPACES.
           05  FILLER                  PIC X(10) VALUE 'RUN TIME: '.
           05  WS-RPT-TIME             PIC X(8).
           05  FILLER                  PIC X(80) VALUE SPACES.
           
       01  WS-REPORT-LINE              PIC X(133).
       
      * DB2 VARIABLES
       EXEC SQL
           INCLUDE SQLCA
       END-EXEC.
       
       EXEC SQL
           DECLARE C1 CURSOR FOR
           SELECT ACCT_NUMBER, ACCT_TYPE, ACCT_CURRENT_BALANCE
           FROM ACCOUNTS
           WHERE ACCT_STATUS = 'A'
       END-EXEC.
       
       PROCEDURE DIVISION.
       
       0000-MAIN-LOGIC.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-TRANSACTIONS
               UNTIL WS-TRANS-EOF
           PERFORM 3000-GENERATE-REPORT
           PERFORM 9000-FINALIZE
           STOP RUN.
       
       1000-INITIALIZE.
           DISPLAY '*** BATCH PROCESSING STARTED ***'
           
           ACCEPT WS-CURRENT-DATE FROM DATE YYYYMMDD
           ACCEPT WS-CURRENT-TIME FROM TIME
           MOVE WS-CURRENT-DATE TO WS-BUSINESS-DATE
           
           PERFORM 1100-OPEN-FILES
           
           IF WS-RETURN-CODE NOT = ZERO
               DISPLAY 'ERROR IN FILE INITIALIZATION'
               MOVE 16 TO RETURN-CODE
               STOP RUN
           END-IF
           
           PERFORM 1200-WRITE-LOG-HEADER.
       
       1100-OPEN-FILES.
           OPEN INPUT TRANS-FILE
           IF NOT WS-TRANS-OK
               DISPLAY 'ERROR OPENING TRANS-FILE: ' 
                       WS-TRANS-FILE-STATUS
               MOVE 8 TO WS-RETURN-CODE
               GO TO 1100-EXIT
           END-IF
           
           OPEN I-O ACCOUNT-FILE
           IF NOT WS-ACCT-OK
               DISPLAY 'ERROR OPENING ACCOUNT-FILE: ' 
                       WS-ACCT-FILE-STATUS
               MOVE 8 TO WS-RETURN-CODE
               GO TO 1100-EXIT
           END-IF
           
           OPEN OUTPUT TRANS-LOG
           OPEN OUTPUT ERROR-FILE
           OPEN OUTPUT REPORT-FILE
           
           EXEC SQL
               CONNECT TO BANKDB
           END-EXEC
           
           IF SQLCODE NOT = 0
               DISPLAY 'DB2 CONNECTION FAILED: ' SQLCODE
               MOVE 8 TO WS-RETURN-CODE
           END-IF.
           
       1100-EXIT.
           EXIT.
       
       1200-WRITE-LOG-HEADER.
           MOVE SPACES TO LOG-RECORD
           STRING 'BATCH PROCESSING LOG - '
                  WS-CURR-YEAR '/'
                  WS-CURR-MONTH '/'
                  WS-CURR-DAY ' '
                  WS-CURR-HOUR ':'
                  WS-CURR-MINUTE ':'
                  WS-CURR-SECOND
                  DELIMITED BY SIZE
                  INTO LOG-RECORD
           END-STRING
           WRITE LOG-RECORD.
       
       2000-PROCESS-TRANSACTIONS.
           PERFORM 2100-READ-TRANSACTION
           
           IF WS-TRANS-EOF
               GO TO 2000-EXIT
           END-IF
           
           ADD 1 TO WS-TRANS-READ-COUNT
           
           PERFORM 2200-VALIDATE-TRANSACTION
           
           IF WS-RETURN-CODE = ZERO
               PERFORM 2300-PROCESS-BY-TYPE
               IF WS-RETURN-CODE = ZERO
                   ADD 1 TO WS-TRANS-PROCESSED
                   PERFORM 2400-LOG-TRANSACTION
               ELSE
                   ADD 1 TO WS-TRANS-ERROR-COUNT
                   PERFORM 2500-LOG-ERROR
               END-IF
           ELSE
               ADD 1 TO WS-TRANS-ERROR-COUNT
               PERFORM 2500-LOG-ERROR
           END-IF.
           
       2000-EXIT.
           EXIT.
       
       2100-READ-TRANSACTION.
           READ TRANS-FILE
               AT END
                   SET WS-TRANS-EOF TO TRUE
               NOT AT END
                   CONTINUE
           END-READ.
       
       2200-VALIDATE-TRANSACTION.
           MOVE ZERO TO WS-RETURN-CODE
           
           IF TRANS-ACCT-NUMBER = ZEROS
               MOVE 'INVALID ACCOUNT NUMBER' TO WS-ERROR-MESSAGE
               MOVE 4 TO WS-RETURN-CODE
               GO TO 2200-EXIT
           END-IF
           
           IF TRANS-AMOUNT = ZERO OR TRANS-AMOUNT < ZERO
               MOVE 'INVALID TRANSACTION AMOUNT' TO WS-ERROR-MESSAGE
               MOVE 4 TO WS-RETURN-CODE
               GO TO 2200-EXIT
           END-IF
           
           IF NOT TRANS-DEPOSIT
              AND NOT TRANS-WITHDRAWAL
              AND NOT TRANS-TRANSFER
              AND NOT TRANS-PAYMENT
               MOVE 'INVALID TRANSACTION TYPE' TO WS-ERROR-MESSAGE
               MOVE 4 TO WS-RETURN-CODE
               GO TO 2200-EXIT
           END-IF.
           
       2200-EXIT.
           EXIT.
       
       2300-PROCESS-BY-TYPE.
           MOVE ZERO TO WS-RETURN-CODE
           
           EVALUATE TRUE
               WHEN TRANS-DEPOSIT
                   PERFORM 2310-PROCESS-DEPOSIT
                   
               WHEN TRANS-WITHDRAWAL
                   PERFORM 2320-PROCESS-WITHDRAWAL
                   
               WHEN TRANS-TRANSFER
                   PERFORM 2330-PROCESS-TRANSFER
                   
               WHEN TRANS-PAYMENT
                   PERFORM 2340-PROCESS-PAYMENT
                   
               WHEN OTHER
                   MOVE 'UNSUPPORTED TRANSACTION TYPE' 
                       TO WS-ERROR-MESSAGE
                   MOVE 4 TO WS-RETURN-CODE
           END-EVALUATE.
       
       2310-PROCESS-DEPOSIT.
           MOVE TRANS-ACCT-NUMBER TO ACCT-NUMBER
           
           READ ACCOUNT-FILE
               INVALID KEY
                   MOVE 'ACCOUNT NOT FOUND' TO WS-ERROR-MESSAGE
                   MOVE 4 TO WS-RETURN-CODE
                   GO TO 2310-EXIT
           END-READ
           
           IF NOT ACCT-ACTIVE
               MOVE 'ACCOUNT NOT ACTIVE' TO WS-ERROR-MESSAGE
               MOVE 4 TO WS-RETURN-CODE
               GO TO 2310-EXIT
           END-IF
           
           MOVE ACCT-CURRENT-BALANCE TO TRANS-BALANCE-BEFORE
           ADD TRANS-AMOUNT TO ACCT-CURRENT-BALANCE
           ADD TRANS-AMOUNT TO ACCT-AVAILABLE-BALANCE
           MOVE ACCT-CURRENT-BALANCE TO TRANS-BALANCE-AFTER
           ADD 1 TO ACCT-MTD-CREDITS
           
           MOVE WS-BUSINESS-DATE TO ACCT-LAST-TRANS-DATE
           
           REWRITE ACCOUNT-RECORD
               INVALID KEY
                   MOVE 'ERROR UPDATING ACCOUNT' TO WS-ERROR-MESSAGE
                   MOVE 8 TO WS-RETURN-CODE
                   GO TO 2310-EXIT
           END-REWRITE
           
           ADD 1 TO WS-DEPOSITS-COUNT
           ADD 1 TO WS-ACCT-UPDATED
           ADD TRANS-AMOUNT TO WS-TOTAL-DEPOSITS.
           
       2310-EXIT.
           EXIT.
       
       2320-PROCESS-WITHDRAWAL.
           MOVE TRANS-ACCT-NUMBER TO ACCT-NUMBER
           
           READ ACCOUNT-FILE
               INVALID KEY
                   MOVE 'ACCOUNT NOT FOUND' TO WS-ERROR-MESSAGE
                   MOVE 4 TO WS-RETURN-CODE
                   GO TO 2320-EXIT
           END-READ
           
           IF NOT ACCT-ACTIVE
               MOVE 'ACCOUNT NOT ACTIVE' TO WS-ERROR-MESSAGE
               MOVE 4 TO WS-RETURN-CODE
               GO TO 2320-EXIT
           END-IF
           
           IF ACCT-FROZEN
               MOVE 'ACCOUNT IS FROZEN' TO WS-ERROR-MESSAGE
               MOVE 4 TO WS-RETURN-CODE
               GO TO 2320-EXIT
           END-IF
           
           MOVE ACCT-CURRENT-BALANCE TO TRANS-BALANCE-BEFORE
           
           IF TRANS-AMOUNT > 
              (ACCT-AVAILABLE-BALANCE + ACCT-OVERDRAFT-LIMIT)
               MOVE 'INSUFFICIENT FUNDS' TO WS-ERROR-MESSAGE
               MOVE 4 TO WS-RETURN-CODE
               GO TO 2320-EXIT
           END-IF
           
           SUBTRACT TRANS-AMOUNT FROM ACCT-CURRENT-BALANCE
           SUBTRACT TRANS-AMOUNT FROM ACCT-AVAILABLE-BALANCE
           MOVE ACCT-CURRENT-BALANCE TO TRANS-BALANCE-AFTER
           ADD 1 TO ACCT-MTD-DEBITS
           
           MOVE WS-BUSINESS-DATE TO ACCT-LAST-TRANS-DATE
           
           REWRITE ACCOUNT-RECORD
               INVALID KEY
                   MOVE 'ERROR UPDATING ACCOUNT' TO WS-ERROR-MESSAGE
                   MOVE 8 TO WS-RETURN-CODE
                   GO TO 2320-EXIT
           END-REWRITE
           
           ADD 1 TO WS-WITHDRAWALS-COUNT
           ADD 1 TO WS-ACCT-UPDATED
           ADD TRANS-AMOUNT TO WS-TOTAL-WITHDRAWALS.
           
       2320-EXIT.
           EXIT.
       
       2330-PROCESS-TRANSFER.
           PERFORM 2331-DEBIT-SOURCE-ACCOUNT
           IF WS-RETURN-CODE NOT = ZERO
               GO TO 2330-EXIT
           END-IF
           
           PERFORM 2332-CREDIT-DEST-ACCOUNT
           IF WS-RETURN-CODE NOT = ZERO
               PERFORM 2333-REVERSE-TRANSFER
               GO TO 2330-EXIT
           END-IF
           
           ADD 1 TO WS-TRANSFERS-COUNT
           ADD TRANS-AMOUNT TO WS-TOTAL-TRANSFERS.
           
       2330-EXIT.
           EXIT.
       
       2331-DEBIT-SOURCE-ACCOUNT.
           MOVE TRANS-ACCT-NUMBER TO ACCT-NUMBER
           
           READ ACCOUNT-FILE
               INVALID KEY
                   MOVE 'SOURCE ACCOUNT NOT FOUND' 
                       TO WS-ERROR-MESSAGE
                   MOVE 4 TO WS-RETURN-CODE
                   GO TO 2331-EXIT
           END-READ
           
           IF TRANS-AMOUNT > ACCT-AVAILABLE-BALANCE
               MOVE 'INSUFFICIENT FUNDS FOR TRANSFER' 
                   TO WS-ERROR-MESSAGE
               MOVE 4 TO WS-RETURN-CODE
               GO TO 2331-EXIT
           END-IF
           
           SUBTRACT TRANS-AMOUNT FROM ACCT-CURRENT-BALANCE
           SUBTRACT TRANS-AMOUNT FROM ACCT-AVAILABLE-BALANCE
           
           REWRITE ACCOUNT-RECORD.
           
       2331-EXIT.
           EXIT.
       
       2332-CREDIT-DEST-ACCOUNT.
           MOVE TRANS-DEST-ACCT TO ACCT-NUMBER
           
           READ ACCOUNT-FILE
               INVALID KEY
                   MOVE 'DESTINATION ACCOUNT NOT FOUND' 
                       TO WS-ERROR-MESSAGE
                   MOVE 4 TO WS-RETURN-CODE
                   GO TO 2332-EXIT
           END-READ
           
           ADD TRANS-AMOUNT TO ACCT-CURRENT-BALANCE
           ADD TRANS-AMOUNT TO ACCT-AVAILABLE-BALANCE
           
           REWRITE ACCOUNT-RECORD.
           
       2332-EXIT.
           EXIT.
       
       2333-REVERSE-TRANSFER.
           MOVE TRANS-ACCT-NUMBER TO ACCT-NUMBER
           READ ACCOUNT-FILE
           ADD TRANS-AMOUNT TO ACCT-CURRENT-BALANCE
           ADD TRANS-AMOUNT TO ACCT-AVAILABLE-BALANCE
           REWRITE ACCOUNT-RECORD.
       
       2340-PROCESS-PAYMENT.
           DISPLAY 'PROCESSING PAYMENT: ' TRANS-ID
           MOVE 'PAYMENT PROCESSING NOT IMPLEMENTED' 
               TO WS-ERROR-MESSAGE
           MOVE 4 TO WS-RETURN-CODE.
       
       2400-LOG-TRANSACTION.
           MOVE SPACES TO LOG-RECORD
           STRING 'SUCCESS|'
                  TRANS-ID '|'
                  TRANS-TYPE '|'
                  TRANS-ACCT-NUMBER '|'
                  TRANS-AMOUNT '|'
                  TRANS-BALANCE-AFTER
                  DELIMITED BY SIZE
                  INTO LOG-RECORD
           END-STRING
           WRITE LOG-RECORD.
       
       2500-LOG-ERROR.
           MOVE SPACES TO ERROR-RECORD
           STRING 'ERROR|'
                  TRANS-ID '|'
                  TRANS-TYPE '|'
                  TRANS-ACCT-NUMBER '|'
                  WS-ERROR-MESSAGE
                  DELIMITED BY SIZE
                  INTO ERROR-RECORD
           END-STRING
           WRITE ERROR-RECORD.
       
       3000-GENERATE-REPORT.
           PERFORM 3100-WRITE-REPORT-HEADER
           PERFORM 3200-WRITE-SUMMARY-STATS
           PERFORM 3300-WRITE-TOTALS.
       
       3100-WRITE-REPORT-HEADER.
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-1
           MOVE WS-BUSINESS-DATE TO WS-RPT-DATE
           STRING WS-CURR-HOUR ':' WS-CURR-MINUTE ':' WS-CURR-SECOND
                  DELIMITED BY SIZE
                  INTO WS-RPT-TIME
           END-STRING
           WRITE REPORT-RECORD FROM WS-REPORT-HEADER-2
           MOVE SPACES TO REPORT-RECORD
           WRITE REPORT-RECORD.
       
       3200-WRITE-SUMMARY-STATS.
           MOVE SPACES TO WS-REPORT-LINE
           STRING 'TRANSACTIONS READ:      '
                  WS-TRANS-READ-COUNT
                  DELIMITED BY SIZE
                  INTO WS-REPORT-LINE
           END-STRING
           WRITE REPORT-RECORD FROM WS-REPORT-LINE
           
           MOVE SPACES TO WS-REPORT-LINE
           STRING 'TRANSACTIONS PROCESSED: '
                  WS-TRANS-PROCESSED
                  DELIMITED BY SIZE
                  INTO WS-REPORT-LINE
           END-STRING
           WRITE REPORT-RECORD FROM WS-REPORT-LINE
           
           MOVE SPACES TO WS-REPORT-LINE
           STRING 'TRANSACTIONS IN ERROR:  '
                  WS-TRANS-ERROR-COUNT
                  DELIMITED BY SIZE
                  INTO WS-REPORT-LINE
           END-STRING
           WRITE REPORT-RECORD FROM WS-REPORT-LINE
           
           MOVE SPACES TO WS-REPORT-LINE
           STRING 'ACCOUNTS UPDATED:       '
                  WS-ACCT-UPDATED
                  DELIMITED BY SIZE
                  INTO WS-REPORT-LINE
           END-STRING
           WRITE REPORT-RECORD FROM WS-REPORT-LINE.
       
       3300-WRITE-TOTALS.
           MOVE SPACES TO REPORT-RECORD
           WRITE REPORT-RECORD
           
           MOVE WS-TOTAL-DEPOSITS TO WS-EDIT-AMOUNT
           MOVE SPACES TO WS-REPORT-LINE
           STRING 'TOTAL DEPOSITS:         '
                  WS-EDIT-AMOUNT
                  DELIMITED BY SIZE
                  INTO WS-REPORT-LINE
           END-STRING
           WRITE REPORT-RECORD FROM WS-REPORT-LINE
           
           MOVE WS-TOTAL-WITHDRAWALS TO WS-EDIT-AMOUNT
           MOVE SPACES TO WS-REPORT-LINE
           STRING 'TOTAL WITHDRAWALS:      '
                  WS-EDIT-AMOUNT
                  DELIMITED BY SIZE
                  INTO WS-REPORT-LINE
           END-STRING
           WRITE REPORT-RECORD FROM WS-REPORT-LINE
           
           MOVE WS-TOTAL-TRANSFERS TO WS-EDIT-AMOUNT
           MOVE SPACES TO WS-REPORT-LINE
           STRING 'TOTAL TRANSFERS:        '
                  WS-EDIT-AMOUNT
                  DELIMITED BY SIZE
                  INTO WS-REPORT-LINE
           END-STRING
           WRITE REPORT-RECORD FROM WS-REPORT-LINE.
       
       9000-FINALIZE.
           CLOSE TRANS-FILE
           CLOSE ACCOUNT-FILE
           CLOSE TRANS-LOG
           CLOSE ERROR-FILE
           CLOSE REPORT-FILE
           
           EXEC SQL
               COMMIT
           END-EXEC
           
           EXEC SQL
               DISCONNECT
           END-EXEC
           
           DISPLAY '*** BATCH PROCESSING COMPLETED ***'
           DISPLAY 'TRANSACTIONS READ:      ' WS-TRANS-READ-COUNT
           DISPLAY 'TRANSACTIONS PROCESSED: ' WS-TRANS-PROCESSED
           DISPLAY 'TRANSACTIONS IN ERROR:  ' WS-TRANS-ERROR-COUNT
           DISPLAY 'ACCOUNTS UPDATED:       ' WS-ACCT-UPDATED.
