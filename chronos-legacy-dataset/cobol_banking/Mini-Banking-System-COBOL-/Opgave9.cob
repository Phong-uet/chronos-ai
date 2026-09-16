       IDENTIFICATION DIVISION.
       PROGRAM-ID. OPGAVE9.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT KONTO-FIL ASSIGN TO "KontoOpl.txt"
           ORGANIZATION IS LINE SEQUENTIAL.

           SELECT KUNDE-FIL ASSIGN TO "Kundeoplysninger.txt"
           ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.

       FD KONTO-FIL.
       01 KONTO-REC.
          COPY "KONTOOPL.cpy".

       FD KUNDE-FIL.
       01 KUNDE-REC.
          COPY "KUNDER.cpy".

       WORKING-STORAGE SECTION.

       01 KONTO-ARRAY OCCURS 20 TIMES.
          COPY "KONTOOPL.cpy".

       01 IX PIC 99 VALUE 1.
       01 MAX-IX PIC 99 VALUE 0.

       01 EOF PIC X VALUE "N".

       PROCEDURE DIVISION.

      * Load accounts into array
           OPEN INPUT KONTO-FIL
           PERFORM UNTIL EOF = "Y"
               READ KONTO-FIL
                   AT END MOVE "Y" TO EOF
                   NOT AT END
                       MOVE KONTO-REC TO KONTO-ARRAY(IX)
                       ADD 1 TO IX
               END-READ
           END-PERFORM
           CLOSE KONTO-FIL

           SUBTRACT 1 FROM IX GIVING MAX-IX

      * Now read customers
           OPEN INPUT KUNDE-FIL
           MOVE "N" TO EOF

           PERFORM UNTIL EOF = "Y"
               READ KUNDE-FIL
                   AT END MOVE "Y" TO EOF
                   NOT AT END
                       PERFORM CHECK-KONTO
               END-READ
           END-PERFORM

           CLOSE KUNDE-FIL
           STOP RUN.

       CHECK-KONTO.
           PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > MAX-IX
               IF KUNDE-ID OF KUNDE-REC = KUNDE-ID OF KONTO-ARRAY(IX)
                   DISPLAY "Match account: " KONTO-ID OF KONTO-ARRAY(IX)
               END-IF
           END-PERFORM
           EXIT.
