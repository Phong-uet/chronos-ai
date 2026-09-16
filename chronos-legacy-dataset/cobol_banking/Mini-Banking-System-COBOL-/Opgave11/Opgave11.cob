       IDENTIFICATION DIVISION.
       PROGRAM-ID. OPGAVE11.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANS-FILE ASSIGN TO "Transaktioner.txt"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT STAT-FILE ASSIGN TO "Statistik.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD TRANS-FILE.
       01 TRANS-LINE PIC X(300).

       FD STAT-FILE.
       01 STAT-LINE PIC X(200).

       WORKING-STORAGE SECTION.
       01 EOF PIC X VALUE 'N'.
       01 WS-BELOEB PIC S9(10)V99.
       01 WS-MONTH-ALPHA PIC X(2).
       01 WS-MONTH PIC 99.
       01 FOUND-FLAG PIC X.
       01 I PIC 9(5).
       01 J PIC 9(5).
       
       01 WS-DISP-AMT    PIC ZZZ,ZZZ,ZZ9.99.
       01 WS-DISP-USD    PIC ZZZ,ZZZ,ZZ9.99.
       01 WS-DISP-EUR    PIC ZZZ,ZZZ,ZZ9.99.
       01 WS-DISP-DKK    PIC ZZZ,ZZZ,ZZ9.99.
       01 WS-TEMP-MAX    PIC S9(12)V99.
       01 WS-MAX-IDX     PIC 9(5).

       01 K-TABLE.    *> Customer Table - Array of 500 customers
          05 K-REC OCCURS 10000.
             10 K-ID    PIC X(15).
             10 K-NAVN  PIC X(30).
             10 K-SALDO PIC S9(12)V99 VALUE 50000.
       01 K-COUNT PIC 9(5) VALUE 0.

       01 M-TABLE.    *> Monthly Table - Array of 12 months
          05 MONTH-DATA OCCURS 12 TIMES.
             10 M-IN       PIC S9(12)V99 VALUE 0.
             10 M-OUT      PIC S9(12)V99 VALUE 0.
             10 M-USD-DKK  PIC S9(12)V99 VALUE 0.
             10 M-EUR-DKK  PIC S9(12)V99 VALUE 0.
             10 M-DKK-ONLY PIC S9(12)V99 VALUE 0.
             10 T-IN-CNT   PIC 9(7) VALUE 0.
             10 T-OUT-CNT  PIC 9(7) VALUE 0.
             10 T-OVE-CNT  PIC 9(7) VALUE 0.

       01 S-TABLE.    *> Store Table - Array of 100 stores
          05 S-REC OCCURS 100.
             10 S-NAME     PIC X(20).
             10 S-COUNT    PIC 9(7) VALUE 0.
             10 S-SUM      PIC S9(12)V99 VALUE 0.
       01 S-TOTAL PIC 9(3) VALUE 0.

       PROCEDURE DIVISION.
       MAIN-PROC.
           OPEN INPUT TRANS-FILE
           OPEN OUTPUT STAT-FILE

           PERFORM UNTIL EOF = 'Y'
               READ TRANS-FILE
                   AT END MOVE 'Y' TO EOF
                   NOT AT END PERFORM PROCESS-LINE
               END-READ
           END-PERFORM.

           PERFORM PRINT-REPORT-TOP3.
           PERFORM PRINT-REPORT-MONTH.
           PERFORM PRINT-REPORT-STORES.
           PERFORM PRINT-REPORT-TOP5.
           PERFORM PRINT-REPORT-TYPE.
           PERFORM PRINT-VISUALIZATION.

           CLOSE TRANS-FILE STAT-FILE
           DISPLAY "Success! Full report generated in Statistik.txt"
           STOP RUN.

       PROCESS-LINE.
           *> Extract Month from Position 191 (YYYY-MM-DD starts at 186)
           MOVE TRANS-LINE(191:2) TO WS-MONTH-ALPHA
           IF WS-MONTH-ALPHA IS NUMERIC
               MOVE WS-MONTH-ALPHA TO WS-MONTH
           ELSE
               MOVE 0 TO WS-MONTH
           END-IF.

           IF WS-MONTH > 0 AND WS-MONTH <= 12
               *> Extract Amount from Position 127
               COMPUTE WS-BELOEB = FUNCTION NUMVAL(TRANS-LINE(127:15))
               
            *> Currency Logic & Visualization Tracking (Currency at 142)
               IF TRANS-LINE(142:3) = "USD"
                   ADD WS-BELOEB TO M-USD-DKK(WS-MONTH)
                 *>COMPUTE WS-BELOEB = WS-BELOEB * 6.8
                   COMPUTE WS-BELOEB ROUNDED = WS-BELOEB * 6.80
               ELSE IF TRANS-LINE(142:3) = "EUR"
                   ADD WS-BELOEB TO M-EUR-DKK(WS-MONTH)
                 *>COMPUTE WS-BELOEB = WS-BELOEB * 7.5
                   COMPUTE WS-BELOEB ROUNDED = WS-BELOEB * 7.50
               ELSE
                   ADD WS-BELOEB TO M-DKK-ONLY(WS-MONTH)
               END-IF

               *> Transaction Type Counters (Type at 146)
               IF TRANS-LINE(146:11) = "Indbetaling"
                   ADD 1 TO T-IN-CNT(WS-MONTH)
                   ADD WS-BELOEB TO M-IN(WS-MONTH)
               ELSE IF TRANS-LINE(146:10) = "Udbetaling"
                   ADD 1 TO T-OUT-CNT(WS-MONTH)
                   ADD WS-BELOEB TO M-OUT(WS-MONTH)
               ELSE
                   ADD 1 TO T-OVE-CNT(WS-MONTH)
                   IF WS-BELOEB < 0
                       ADD WS-BELOEB TO M-OUT(WS-MONTH)
                   ELSE
                       ADD WS-BELOEB TO M-IN(WS-MONTH)
                   END-IF
               END-IF

               *> Customer Logic
               MOVE 'N' TO FOUND-FLAG
               PERFORM VARYING I FROM 1 BY 1 UNTIL I > K-COUNT 
                       OR FOUND-FLAG = 'Y'
                   IF K-ID(I) = TRANS-LINE(1:15)
                       ADD WS-BELOEB TO K-SALDO(I)
                       MOVE 'Y' TO FOUND-FLAG
                   END-IF
               END-PERFORM
               IF FOUND-FLAG = 'N' AND K-COUNT < 500
                   ADD 1 TO K-COUNT
                   MOVE TRANS-LINE(1:15) TO K-ID(K-COUNT)
                   MOVE TRANS-LINE(16:30) TO K-NAVN(K-COUNT)
                   ADD WS-BELOEB TO K-SALDO(K-COUNT)
               END-IF

               *> Store Logic (Shop Name at 166)
               MOVE 'N' TO FOUND-FLAG
               PERFORM VARYING J FROM 1 BY 1 UNTIL J > S-TOTAL 
                       OR FOUND-FLAG = 'Y'
                   IF S-NAME(J) = TRANS-LINE(166:20)
                       ADD 1 TO S-COUNT(J)
                       ADD FUNCTION ABS(WS-BELOEB) TO S-SUM(J)
                       MOVE 'Y' TO FOUND-FLAG
                   END-IF
               END-PERFORM
               IF FOUND-FLAG = 'N' AND S-TOTAL < 100
                   ADD 1 TO S-TOTAL
                   MOVE TRANS-LINE(166:20) TO S-NAME(S-TOTAL)
                   ADD 1 TO S-COUNT(S-TOTAL)
                   ADD FUNCTION ABS(WS-BELOEB) TO S-SUM(S-TOTAL)
               END-IF
           END-IF.

       PRINT-REPORT-TOP3.
           WRITE STAT-LINE FROM "1. Top 3 kunder med hoejeste saldo:".
           PERFORM 3 TIMES
               MOVE -9999999999 TO WS-TEMP-MAX
               MOVE 0 TO WS-MAX-IDX
               PERFORM VARYING I FROM 1 BY 1 UNTIL I > K-COUNT
                   IF K-SALDO(I) > WS-TEMP-MAX
                       MOVE K-SALDO(I) TO WS-TEMP-MAX
                       MOVE I TO WS-MAX-IDX
                   END-IF
               END-PERFORM
               IF WS-MAX-IDX > 0
                   MOVE K-SALDO(WS-MAX-IDX) TO WS-DISP-AMT
                   MOVE SPACES TO STAT-LINE
                   STRING "ID: " K-ID(WS-MAX-IDX) " Name: " 
                           K-NAVN(WS-MAX-IDX)
                          " Saldo: " WS-DISP-AMT " DKK" INTO STAT-LINE
                   WRITE STAT-LINE
                   MOVE -9999999999 TO K-SALDO(WS-MAX-IDX)
               END-IF
           END-PERFORM.

       PRINT-REPORT-MONTH.
           WRITE STAT-LINE FROM " ".
           WRITE STAT-LINE FROM "2. Maanedsvis statistik:".
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > 12
               MOVE M-IN(I) TO WS-DISP-AMT
               MOVE SPACES TO STAT-LINE
               STRING "Month " I " Ind (DKK): " WS-DISP-AMT 
                       INTO STAT-LINE
               WRITE STAT-LINE
           END-PERFORM.

       PRINT-REPORT-STORES.
           WRITE STAT-LINE FROM " ".
           WRITE STAT-LINE FROM "3. Statistik for butikker:".
           PERFORM VARYING J FROM 1 BY 1 UNTIL J > S-TOTAL
               MOVE SPACES TO STAT-LINE
               STRING S-NAME(J) " Antal: " S-COUNT(J) INTO STAT-LINE
               WRITE STAT-LINE
           END-PERFORM.

       PRINT-REPORT-TOP5.
           WRITE STAT-LINE FROM " ".
           WRITE STAT-LINE FROM "4. Top 5 butikker (Omsaetning):".
           PERFORM 5 TIMES
               MOVE -1 TO WS-TEMP-MAX
               MOVE 0 TO WS-MAX-IDX
               PERFORM VARYING J FROM 1 BY 1 UNTIL J > S-TOTAL
                   IF S-SUM(J) > WS-TEMP-MAX
                       MOVE S-SUM(J) TO WS-TEMP-MAX
                       MOVE J TO WS-MAX-IDX
                   END-IF
               END-PERFORM
               IF WS-MAX-IDX > 0
                   MOVE S-SUM(WS-MAX-IDX) TO WS-DISP-AMT
                   MOVE SPACES TO STAT-LINE
                   STRING S-NAME(WS-MAX-IDX) " DKK: " WS-DISP-AMT 
                           INTO STAT-LINE
                   WRITE STAT-LINE
                   MOVE -1 TO S-SUM(WS-MAX-IDX)
               END-IF
           END-PERFORM.

       PRINT-REPORT-TYPE.
           WRITE STAT-LINE FROM " ".
           WRITE STAT-LINE FROM 
                   "Del 2.1: Most Frequent type per month:".
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > 12
               MOVE SPACES TO STAT-LINE
               IF T-IN-CNT(I) >= T-OUT-CNT(I) AND 
                  T-IN-CNT(I) >= T-OVE-CNT(I)
                   STRING "Month " I ": Indbetaling" INTO STAT-LINE
               ELSE IF T-OUT-CNT(I) >= T-IN-CNT(I) AND 
                       T-OUT-CNT(I) >= T-OVE-CNT(I)
                   STRING "Month " I ": Udbetaling" INTO STAT-LINE
               ELSE
                   STRING "Month " I ": Overfoersel" INTO STAT-LINE
               END-IF
               WRITE STAT-LINE
           END-PERFORM.

       PRINT-VISUALIZATION.
           WRITE STAT-LINE FROM " ".
           WRITE STAT-LINE FROM 
                   "Del 2.2: Visualization (Currency Breakdown):".
           WRITE STAT-LINE FROM 
           "Maaned    USD (in DKK)      EUR (in DKK)      DKK (only)".
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > 12
               MOVE M-USD-DKK(I)  TO WS-DISP-USD
               MOVE M-EUR-DKK(I)  TO WS-DISP-EUR
               MOVE M-DKK-ONLY(I) TO WS-DISP-DKK
               MOVE SPACES TO STAT-LINE
               STRING "Month " I "  " WS-DISP-USD 
                      "  " WS-DISP-EUR "  " WS-DISP-DKK
                      DELIMITED BY SIZE INTO STAT-LINE
               WRITE STAT-LINE
           END-PERFORM.
