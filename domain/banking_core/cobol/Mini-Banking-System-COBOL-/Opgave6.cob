       IDENTIFICATION DIVISION.
       PROGRAM-ID. OPGAVE6.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT KUNDE-FIL ASSIGN TO "Kundeoplysninger.txt"
           ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.

       FD KUNDE-FIL.
       01 FILE-REC.
          COPY "KUNDER.cpy".

       WORKING-STORAGE SECTION.
       01 EOF-FLAG PIC X VALUE "N".

       PROCEDURE DIVISION.

           OPEN INPUT KUNDE-FIL

           PERFORM UNTIL EOF-FLAG = "Y"
               READ KUNDE-FIL
                   AT END MOVE "Y" TO EOF-FLAG
                   NOT AT END
                       DISPLAY FORNAVN " " EFTERNAVN
               END-READ
           END-PERFORM

           CLOSE KUNDE-FIL
           STOP RUN.
           