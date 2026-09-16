       IDENTIFICATION DIVISION.
       PROGRAM-ID. OPGAVE11.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANS-FIL ASSIGN TO "Transaktioner.txt"
           ORGANIZATION IS LINE SEQUENTIAL.
           SELECT STAT-FIL  ASSIGN TO "Statistik.txt"
           ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD TRANS-FIL.
       01 TRANS-REC. COPY "TRANS.cpy".
       FD STAT-FIL.
       01 STAT-REC PIC X(120).

       WORKING-STORAGE SECTION.
       01 EOF              PIC X VALUE 'N'.
       01 IX               PIC 9(3).
       01 M-IX             PIC 9(2).
       01 B-IX             PIC 9(3).
       01 DKK-VAL          PIC S9(12)V99.
       01 DISP-SUM          PIC ZZZ,ZZZ,ZZZ,ZZ9.99.
       01 DISP-COUNT        PIC ZZZ,ZZ9.

       
       *> Månedsstatistik (12 måneder)
       01 MAANED-TABLE.
          05 MAANED-STAT OCCURS 12 TIMES.
             10 M-IND      PIC S9(15)V99 VALUE 0.
             10 M-UD       PIC S9(15)V99 VALUE 0.

       *> Butikstatistik (Vi gemmer op til 50 butikker)
       01 BUTIK-TABLE.
          05 B-MAX         PIC 9(3) VALUE 0.
          05 BUTIK-STAT OCCURS 500 TIMES.
             10 BS-NAVN    PIC X(20).
             10 BS-ANTAL   PIC 9(9) VALUE 0.
             10 BS-TOTAL   PIC S9(15)V99 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           OPEN INPUT TRANS-FIL OPEN OUTPUT STAT-FIL.
           PERFORM UNTIL EOF = 'Y'
               READ TRANS-FIL AT END MOVE 'Y' TO EOF
               NOT AT END PERFORM PROCESS-STATS
               END-READ
           END-PERFORM.
           PERFORM WRITE-REPORT.
           CLOSE TRANS-FIL STAT-FIL.
           STOP RUN.

       PROCESS-STATS.
           *> 1. Beregn DKK (Forenklet fra Opgave 10)
           COMPUTE DKK-VAL = FUNCTION NUMVAL(T-BELOEB-RAW)
           IF T-VALUTA = "USD " COMPUTE DKK-VAL = DKK-VAL * 6.8 END-IF
           IF T-VALUTA = "EUR " COMPUTE DKK-VAL = DKK-VAL * 7.5 END-IF

           *> 2. Månedsstatistik (Find måned fra YYYY-MM-DD...)
           MOVE T-TIMESTAMP(6:2) TO M-IX
           IF M-IX >= 1 AND M-IX <= 12
               IF DKK-VAL > 0
                   ADD DKK-VAL TO M-IND(M-IX)
               ELSE
                  ADD DKK-VAL TO M-UD(M-IX)
               END-IF
           END-IF. 

           *> 3. Butikstatistik
           PERFORM UPDATE-BUTIK.

       UPDATE-BUTIK.
           MOVE 0 TO B-IX
           *> Clean spaces (English: Trim spaces)
           IF B-MAX > 0
               PERFORM VARYING IX FROM 1 BY 1 
                 UNTIL IX > B-MAX OR B-IX > 0
                   IF FUNCTION TRIM(T-BUTIK) = 
                      FUNCTION TRIM(BS-NAVN(IX))
                       MOVE IX TO B-IX
                   END-IF
               END-PERFORM
           END-IF

           *> Add new store if not found
           IF B-IX = 0 AND B-MAX < 50
               ADD 1 TO B-MAX
               MOVE B-MAX TO B-IX
               MOVE FUNCTION TRIM(T-BUTIK) TO BS-NAVN(B-IX)
           END-IF

           IF B-IX > 0
               ADD 1 TO BS-ANTAL(B-IX)
               ADD DKK-VAL TO BS-TOTAL(B-IX)
           END-IF.

       WRITE-REPORT.
           MOVE "--- MAANEDS STATISTIK (DKK) ---" TO STAT-REC.
           WRITE STAT-REC.
           PERFORM VARYING M-IX FROM 1 BY 1 UNTIL M-IX > 12
               MOVE M-IND(M-IX) TO DISP-SUM
               MOVE SPACES TO STAT-REC
               STRING "Maaned " M-IX ": Ind: " DISP-SUM INTO STAT-REC
               WRITE STAT-REC
               
               MOVE M-UD(M-IX) TO DISP-SUM
               MOVE SPACES TO STAT-REC
               STRING "            Ud:  " DISP-SUM INTO STAT-REC
               WRITE STAT-REC
           END-PERFORM.

           MOVE SPACES TO STAT-REC. WRITE STAT-REC.
           MOVE "--- BUTIK STATISTIK ---" TO STAT-REC. WRITE STAT-REC.
           PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > B-MAX
               MOVE BS-ANTAL(IX) TO DISP-COUNT
               MOVE BS-TOTAL(IX) TO DISP-SUM
               MOVE SPACES TO STAT-REC
               STRING BS-NAVN(IX) " Antal: " DISP-COUNT
                      " Omsaetning: " DISP-SUM INTO STAT-REC
               WRITE STAT-REC
           END-PERFORM.

