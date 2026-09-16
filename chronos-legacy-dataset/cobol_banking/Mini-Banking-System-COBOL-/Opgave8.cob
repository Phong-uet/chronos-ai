       IDENTIFICATION DIVISION.
       PROGRAM-ID. OPGAVE8.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT KUNDE-FIL ASSIGN TO "Kundeoplysninger.txt"
           ORGANIZATION IS LINE SEQUENTIAL.
           SELECT KONTO-FIL ASSIGN TO "KontoOpl.txt"
           ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUT-FIL   ASSIGN TO "KUNDEKONTO.txt"
           ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD KUNDE-FIL.
       01 KUNDE-REC.
          COPY "KUNDER.cpy".

       FD KONTO-FIL.
       01 KONTO-REC.
          COPY "KONTOOPL.cpy".

       FD OUT-FIL.
       01 OUT-REC.
          05 OUTPUT-TEXT PIC X(100).

       WORKING-STORAGE SECTION.
       01 EOF-KUNDE      PIC X VALUE "N".
       01 EOF-KONTO      PIC X VALUE "N".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           OPEN INPUT KUNDE-FIL
           OPEN OUTPUT OUT-FIL

           PERFORM UNTIL EOF-KUNDE = "Y"
               READ KUNDE-FIL
                   AT END MOVE "Y" TO EOF-KUNDE
                   NOT AT END
                       PERFORM WRITE-KUNDE
                       PERFORM PROCESS-KONTO
               END-READ
           END-PERFORM

           CLOSE KUNDE-FIL
           CLOSE OUT-FIL
           STOP RUN.

       WRITE-KUNDE.
           MOVE SPACES TO OUTPUT-TEXT
           *> Brug 'OF' for at undgå ambiguity
           STRING "Kunde: " FORNAVN OF KUNDE-REC " " 
                  EFTERNAVN OF KUNDE-REC 
                  DELIMITED BY SPACE INTO OUTPUT-TEXT
           WRITE OUT-REC.

       PROCESS-KONTO.
           OPEN INPUT KONTO-FIL
           MOVE "N" TO EOF-KONTO
           PERFORM UNTIL EOF-KONTO = "Y"
               READ KONTO-FIL
                   AT END MOVE "Y" TO EOF-KONTO
                   NOT AT END
                       *> Sammenlign KUNDE-ID fra begge filer
                       IF KUNDE-ID OF KONTO-REC = KUNDE-ID OF KUNDE-REC
                           PERFORM WRITE-KONTO
                       END-IF
               END-READ
           END-PERFORM
           CLOSE KONTO-FIL.

       WRITE-KONTO.
           MOVE SPACES TO OUTPUT-TEXT
           STRING "   Konto: " KONTO-ID OF KONTO-REC 
                  " Type: "  KONTO-TYPE OF KONTO-REC
                  DELIMITED BY SIZE INTO OUTPUT-TEXT
           WRITE OUT-REC.
