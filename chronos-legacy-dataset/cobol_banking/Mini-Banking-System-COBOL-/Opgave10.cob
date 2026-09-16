       IDENTIFICATION DIVISION.
       PROGRAM-ID. OPGAVE10.
       
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           ALPHABET DANISH-EXTENDED IS STANDARD-1.
       
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT BANK-FIL ASSIGN TO "Banker.txt"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT TRANS-FIL ASSIGN TO "Transaktioner.txt"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUT-FIL ASSIGN TO "Kontoudskrifter.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  BANK-FIL.
       01  BANK-REC.
           COPY "BANKER.cpy".

       FD  TRANS-FIL.
       01  TRANS-REC.
           COPY "TRANS.cpy".

       FD  OUT-FIL.
       01  OUT-REC          PIC X(120).

       WORKING-STORAGE SECTION.
       01  BANK-TABLE-DATA.
           05 BANK-ENTRY OCCURS 100 TIMES.
              10 BT-REG-NR     PIC X(4).
              10 BT-NAVN       PIC X(30).
       
       01  IX               PIC 9(3).
       01  EOF              PIC X VALUE 'N'.
       
       01  DKK-VAL          PIC S9(12)V99.
       01  DISP-DKK         PIC -(12)9.99.
       
       01  TOTAL-IND        PIC S9(12)V99 VALUE 0.
       01  TOTAL-UD         PIC S9(12)V99 VALUE 0.
       01  CURRENT-SALDO    PIC S9(12)V99 VALUE 50000.00.
       01  BANK-NAVN-OUT    PIC X(30).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           OPEN INPUT BANK-FIL.
           MOVE 'N' TO EOF.
           PERFORM VARYING IX FROM 1 BY 1 
             UNTIL EOF = 'Y' OR IX > 100
               READ BANK-FIL AT END MOVE 'Y' TO EOF
               NOT AT END 
                   MOVE B-REG-NR TO BT-REG-NR(IX)
                   MOVE B-NAVN TO BT-NAVN(IX)
               END-READ
           END-PERFORM.
           CLOSE BANK-FIL.

           OPEN INPUT TRANS-FIL OPEN OUTPUT OUT-FIL.
           MOVE 'N' TO EOF.
           READ TRANS-FIL AT END MOVE 'Y' TO EOF END-READ.
           
           PERFORM UNTIL EOF = 'Y'
               PERFORM PROCESS-TRANS
               READ TRANS-FIL AT END MOVE 'Y' TO EOF END-READ
           END-PERFORM.

           PERFORM WRITE-SUMMARY.
           CLOSE TRANS-FIL OUT-FIL.
           STOP RUN.

       PROCESS-TRANS.
           IF TR-REG-NR = SPACES OR TR-NAVN = SPACES
               EXIT PARAGRAPH
           END-IF.

           MOVE "Ukendt Bank" TO BANK-NAVN-OUT.
           PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 100
               IF TR-REG-NR = BT-REG-NR(IX)
                   MOVE BT-NAVN(IX) TO BANK-NAVN-OUT
               END-IF
           END-PERFORM.

           COMPUTE DKK-VAL = FUNCTION NUMVAL(TR-BELOEB-RAW).
           
           IF TR-VALUTA = "USD" COMPUTE DKK-VAL = DKK-VAL * 6.8.
           IF TR-VALUTA = "EUR" COMPUTE DKK-VAL = DKK-VAL * 7.5.

           IF DKK-VAL > 0
               ADD DKK-VAL TO TOTAL-IND
           ELSE
               ADD DKK-VAL TO TOTAL-UD
           END-IF.
           ADD DKK-VAL TO CURRENT-SALDO.

           MOVE DKK-VAL TO DISP-DKK.

           MOVE SPACES TO OUT-REC.
           STRING TR-DATE " | " 
                  TR-NAVN(1:15) " | "
                  BANK-NAVN-OUT(1:15) " | DKK: " 
                  DISP-DKK
                  DELIMITED BY SIZE INTO OUT-REC.
           WRITE OUT-REC.

       WRITE-SUMMARY.
           MOVE SPACES TO OUT-REC. WRITE OUT-REC.
           WRITE OUT-REC FROM "====================================".
           WRITE OUT-REC FROM "TOTAL OPSUMMERING FOR SYSTEMET".
           
           MOVE TOTAL-IND TO DISP-DKK.
           STRING "Total indbetalt : " DISP-DKK INTO OUT-REC.
           WRITE OUT-REC.
           
           MOVE TOTAL-UD TO DISP-DKK.
           STRING "Total udbetalt  : " DISP-DKK INTO OUT-REC.
           WRITE OUT-REC.
           
           MOVE CURRENT-SALDO TO DISP-DKK.
           STRING "Slut Saldo      : " DISP-DKK INTO OUT-REC.
           WRITE OUT-REC.
