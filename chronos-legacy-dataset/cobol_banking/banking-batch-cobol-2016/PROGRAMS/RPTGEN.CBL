       IDENTIFICATION DIVISION.
       PROGRAM-ID. RPTGEN.
      ******************************************************************
      * PROGRAM NAME: RPTGEN
      * DESCRIPTION:  MONTHLY ACCOUNT STATEMENT REPORT GENERATOR
      *               - GENERATES CUSTOMER ACCOUNT STATEMENTS
      *               - CALCULATES INTEREST
      *               - SUMMARIZES TRANSACTIONS
      *               - PRODUCES PDF REPORTS
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
           SELECT CUSTOMER-FILE
               ASSIGN TO CUSTMAST
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS CUST-ID
               FILE STATUS IS WS-CUST-STATUS.
               
           SELECT ACCOUNT-FILE
               ASSIGN TO ACCTMAST
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS ACCT-NUMBER
               ALTERNATE RECORD KEY IS ACCT-CUST-ID
                   WITH DUPLICATES
               FILE STATUS IS WS-ACCT-STATUS.
               
           SELECT STATEMENT-FILE
               ASSIGN TO STMTFILE
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-STMT-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       
       FD  CUSTOMER-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 550 CHARACTERS.
       COPY CUSTOMER.
       
       FD  ACCOUNT-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 600 CHARACTERS.
       COPY ACCOUNT.
       
       FD  STATEMENT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 133 CHARACTERS.
       01  STATEMENT-RECORD            PIC X(133).
       
       WORKING-STORAGE SECTION.
       
       01  WS-CUST-STATUS              PIC XX.
           88  WS-CUST-EOF             VALUE '10'.
           88  WS-CUST-OK              VALUE '00'.
           
       01  WS-ACCT-STATUS              PIC XX.
           88  WS-ACCT-EOF             VALUE '10'.
           88  WS-ACCT-OK              VALUE '00'.
           
       01  WS-STMT-STATUS              PIC XX.
       
       01  WS-COUNTERS.
           05  WS-CUSTOMERS-PROCESSED  PIC 9(9) VALUE ZERO.
           05  WS-ACCOUNTS-PROCESSED   PIC 9(9) VALUE ZERO.
           05  WS-STATEMENTS-PRINTED   PIC 9(9) VALUE ZERO.
           05  WS-LINE-COUNT           PIC 999 VALUE ZERO.
           05  WS-PAGE-COUNT           PIC 9999 VALUE ZERO.
           
       01  WS-CURRENT-DATE.
           05  WS-CURR-YEAR            PIC 9(4).
           05  WS-CURR-MONTH           PIC 99.
           05  WS-CURR-DAY             PIC 99.
           
       01  WS-REPORT-MONTH             PIC 99.
       01  WS-REPORT-YEAR              PIC 9(4).
       
       01  WS-SAVED-CUST-ID            PIC 9(10).
       
      * STATEMENT HEADER
       01  WS-STMT-HEADER-1.
           05  FILLER                  PIC X(30) VALUE SPACES.
           05  FILLER                  PIC X(30) 
               VALUE 'BANCO NACIONAL DEL PERU'.
           05  FILLER                  PIC X(73) VALUE SPACES.
           
       01  WS-STMT-HEADER-2.
           05  FILLER                  PIC X(25) VALUE SPACES.
           05  FILLER                  PIC X(40) 
               VALUE 'ESTADO DE CUENTA MENSUAL'.
           05  FILLER                  PIC X(68) VALUE SPACES.
           
       01  WS-STMT-DATE-LINE.
           05  FILLER                  PIC X(10) VALUE 'PERIODO: '.
           05  WS-STMT-PERIOD          PIC X(20).
           05  FILLER                  PIC X(103) VALUE SPACES.
           
       01  WS-CUST-INFO-LINE.
           05  FILLER                  PIC X(10) VALUE 'CLIENTE: '.
           05  WS-CUST-NAME            PIC X(60).
           05  FILLER                  PIC X(63) VALUE SPACES.
           
       01  WS-ACCT-HEADER.
           05  FILLER                  PIC X(20) 
               VALUE 'CUENTA'.
           05  FILLER                  PIC X(20) 
               VALUE 'TIPO'.
           05  FILLER                  PIC X(20) 
               VALUE 'MONEDA'.
           05  FILLER                  PIC X(25) 
               VALUE 'SALDO ANTERIOR'.
           05  FILLER                  PIC X(25) 
               VALUE 'MOVIMIENTOS'.
           05  FILLER                  PIC X(23) 
               VALUE 'SALDO ACTUAL'.
           
       01  WS-ACCT-DETAIL.
           05  WS-DET-ACCT-NUM         PIC X(20).
           05  WS-DET-ACCT-TYPE        PIC X(20).
           05  WS-DET-CURRENCY         PIC X(20).
           05  WS-DET-PREV-BAL         PIC ZZZ,ZZZ,ZZ9.99-.
           05  WS-DET-MOVEMENTS        PIC ---,---,--9.99-.
           05  WS-DET-CURR-BAL         PIC ZZZ,ZZZ,ZZ9.99-.
       
       01  WS-FOOTER.
           05  FILLER                  PIC X(50) VALUE SPACES.
           05  FILLER                  PIC X(10) VALUE 'PAGINA: '.
           05  WS-PAGE-NUM             PIC ZZZ9.
           05  FILLER                  PIC X(69) VALUE SPACES.
       
      * DB2 HOST VARIABLES
       EXEC SQL
           INCLUDE SQLCA
       END-EXEC.
       
       EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01  HV-ACCT-NUMBER              PIC X(16).
       01  HV-TRANS-DATE               PIC X(8).
       01  HV-TRANS-TYPE               PIC X(3).
       01  HV-TRANS-AMOUNT             PIC S9(13)V99 COMP-3.
       01  HV-TRANS-BALANCE            PIC S9(13)V99 COMP-3.
       EXEC SQL END DECLARE SECTION END-EXEC.
       
       EXEC SQL
           DECLARE TRANS_CURSOR CURSOR FOR
           SELECT TRANS_DATE, TRANS_TYPE, TRANS_AMOUNT, 
                  TRANS_BALANCE_AFTER
           FROM TRANSACTIONS
           WHERE TRANS_ACCT_NUMBER = :HV-ACCT-NUMBER
             AND TRANS_DATE BETWEEN :WS-REPORT-MONTH 
                                AND :WS-REPORT-YEAR
           ORDER BY TRANS_DATE, TRANS_TIME
       END-EXEC.
       
       PROCEDURE DIVISION.
       
       0000-MAIN-LOGIC.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-CUSTOMERS
               UNTIL WS-CUST-EOF
           PERFORM 9000-FINALIZE
           STOP RUN.
       
       1000-INITIALIZE.
           DISPLAY '*** STATEMENT GENERATION STARTED ***'
           
           ACCEPT WS-CURRENT-DATE FROM DATE YYYYMMDD
           
           IF WS-CURR-MONTH = 01
               COMPUTE WS-REPORT-MONTH = 12
               COMPUTE WS-REPORT-YEAR = WS-CURR-YEAR - 1
           ELSE
               COMPUTE WS-REPORT-MONTH = WS-CURR-MONTH - 1
               MOVE WS-CURR-YEAR TO WS-REPORT-YEAR
           END-IF
           
           OPEN INPUT CUSTOMER-FILE
           OPEN INPUT ACCOUNT-FILE
           OPEN OUTPUT STATEMENT-FILE
           
           EXEC SQL
               CONNECT TO BANKDB
           END-EXEC
           
           IF SQLCODE NOT = 0
               DISPLAY 'DB2 CONNECTION FAILED: ' SQLCODE
               MOVE 16 TO RETURN-CODE
               STOP RUN
           END-IF.
       
       2000-PROCESS-CUSTOMERS.
           PERFORM 2100-READ-CUSTOMER
           
           IF WS-CUST-EOF
               GO TO 2000-EXIT
           END-IF
           
           IF NOT CUST-ACTIVE
               GO TO 2000-EXIT
           END-IF
           
           MOVE CUST-ID TO WS-SAVED-CUST-ID
           PERFORM 2200-GENERATE-CUSTOMER-STATEMENT
           ADD 1 TO WS-CUSTOMERS-PROCESSED.
           
       2000-EXIT.
           EXIT.
       
       2100-READ-CUSTOMER.
           READ CUSTOMER-FILE NEXT
               AT END
                   SET WS-CUST-EOF TO TRUE
           END-READ.
       
       2200-GENERATE-CUSTOMER-STATEMENT.
           PERFORM 2210-PRINT-STATEMENT-HEADER
           PERFORM 2220-PROCESS-CUSTOMER-ACCOUNTS
           PERFORM 2230-PRINT-FOOTER
           ADD 1 TO WS-STATEMENTS-PRINTED.
       
       2210-PRINT-STATEMENT-HEADER.
           ADD 1 TO WS-PAGE-COUNT
           MOVE ZERO TO WS-LINE-COUNT
           
           WRITE STATEMENT-RECORD FROM WS-STMT-HEADER-1
           ADD 1 TO WS-LINE-COUNT
           
           WRITE STATEMENT-RECORD FROM WS-STMT-HEADER-2
           ADD 1 TO WS-LINE-COUNT
           
           MOVE SPACES TO STATEMENT-RECORD
           WRITE STATEMENT-RECORD
           ADD 1 TO WS-LINE-COUNT
           
           STRING WS-REPORT-MONTH '/' WS-REPORT-YEAR
                  DELIMITED BY SIZE
                  INTO WS-STMT-PERIOD
           END-STRING
           WRITE STATEMENT-RECORD FROM WS-STMT-DATE-LINE
           ADD 1 TO WS-LINE-COUNT
           
           STRING CUST-FIRST-NAME ' ' CUST-LAST-NAME
                  DELIMITED BY '  '
                  INTO WS-CUST-NAME
           END-STRING
           WRITE STATEMENT-RECORD FROM WS-CUST-INFO-LINE
           ADD 1 TO WS-LINE-COUNT
           
           MOVE SPACES TO STATEMENT-RECORD
           WRITE STATEMENT-RECORD
           ADD 1 TO WS-LINE-COUNT
           
           WRITE STATEMENT-RECORD FROM WS-ACCT-HEADER
           ADD 1 TO WS-LINE-COUNT
           
           MOVE SPACES TO STATEMENT-RECORD
           WRITE STATEMENT-RECORD
           ADD 1 TO WS-LINE-COUNT.
       
       2220-PROCESS-CUSTOMER-ACCOUNTS.
           MOVE WS-SAVED-CUST-ID TO ACCT-CUST-ID
           
           START ACCOUNT-FILE KEY >= ACCT-CUST-ID
               INVALID KEY
                   GO TO 2220-EXIT
           END-START
           
           PERFORM UNTIL WS-ACCT-EOF OR 
                        ACCT-CUST-ID NOT = WS-SAVED-CUST-ID
               READ ACCOUNT-FILE NEXT
                   AT END
                       SET WS-ACCT-EOF TO TRUE
                   NOT AT END
                       IF ACCT-CUST-ID = WS-SAVED-CUST-ID
                           PERFORM 2221-PRINT-ACCOUNT-SUMMARY
                           ADD 1 TO WS-ACCOUNTS-PROCESSED
                       END-IF
               END-READ
           END-PERFORM.
           
       2220-EXIT.
           EXIT.
       
       2221-PRINT-ACCOUNT-SUMMARY.
           MOVE SPACES TO WS-ACCT-DETAIL
           MOVE ACCT-NUMBER TO WS-DET-ACCT-NUM
           
           EVALUATE ACCT-TYPE
               WHEN 'SA'
                   MOVE 'AHORROS' TO WS-DET-ACCT-TYPE
               WHEN 'CC'
                   MOVE 'CORRIENTE' TO WS-DET-ACCT-TYPE
               WHEN 'TC'
                   MOVE 'TARJETA CREDITO' TO WS-DET-ACCT-TYPE
               WHEN OTHER
                   MOVE ACCT-TYPE TO WS-DET-ACCT-TYPE
           END-EVALUATE
           
           MOVE ACCT-CURRENCY TO WS-DET-CURRENCY
           MOVE ACCT-CURRENT-BALANCE TO WS-DET-CURR-BAL
           
           COMPUTE WS-DET-PREV-BAL = 
               ACCT-CURRENT-BALANCE - 
               (ACCT-MTD-CREDITS - ACCT-MTD-DEBITS)
           
           COMPUTE WS-DET-MOVEMENTS = 
               ACCT-MTD-CREDITS - ACCT-MTD-DEBITS
           
           WRITE STATEMENT-RECORD FROM WS-ACCT-DETAIL
           ADD 1 TO WS-LINE-COUNT.
       
       2230-PRINT-FOOTER.
           MOVE SPACES TO STATEMENT-RECORD
           WRITE STATEMENT-RECORD
           ADD 1 TO WS-LINE-COUNT
           
           MOVE WS-PAGE-COUNT TO WS-PAGE-NUM
           WRITE STATEMENT-RECORD FROM WS-FOOTER
           ADD 1 TO WS-LINE-COUNT
           
           MOVE SPACES TO STATEMENT-RECORD
           WRITE STATEMENT-RECORD AFTER ADVANCING PAGE.
       
       9000-FINALIZE.
           CLOSE CUSTOMER-FILE
           CLOSE ACCOUNT-FILE
           CLOSE STATEMENT-FILE
           
           EXEC SQL
               DISCONNECT
           END-EXEC
           
           DISPLAY '*** STATEMENT GENERATION COMPLETED ***'
           DISPLAY 'CUSTOMERS PROCESSED:  ' WS-CUSTOMERS-PROCESSED
           DISPLAY 'ACCOUNTS PROCESSED:   ' WS-ACCOUNTS-PROCESSED
           DISPLAY 'STATEMENTS PRINTED:   ' WS-STATEMENTS-PRINTED.
