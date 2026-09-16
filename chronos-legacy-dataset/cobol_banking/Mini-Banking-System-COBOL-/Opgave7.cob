       IDENTIFICATION DIVISION.
       PROGRAM-ID. OPGAVE7.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO "Kundeoplysninger.txt"
           ORGANIZATION IS LINE SEQUENTIAL.

           SELECT OUT-FILE ASSIGN TO "KundeoplysningerOut.txt"
           ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD IN-FILE.
       01 IN-REC.
          COPY "KUNDER.cpy".

       FD OUT-FILE.
       01 OUT-REC PIC X(100).

       WORKING-STORAGE SECTION.
       01 EOF-FLAG PIC X VALUE "N".

       PROCEDURE DIVISION.
       
           OPEN INPUT IN-FILE
           OPEN OUTPUT OUT-FILE

           PERFORM UNTIL EOF-FLAG = "Y"
               READ IN-FILE
                   AT END MOVE "Y" TO EOF-FLAG
                   NOT AT END
                       PERFORM PROCESS-CUSTOMER
               END-READ
           END-PERFORM

           CLOSE IN-FILE
           CLOSE OUT-FILE
           STOP RUN.

       PROCESS-CUSTOMER.
           *> Her kalder vi de forskellige paragraffer jf. Del 3
           PERFORM WRITE-ID
           PERFORM WRITE-NAVN
           PERFORM WRITE-ADRESSE
           PERFORM WRITE-BY
           PERFORM WRITE-KONTAKT
           PERFORM WRITE-BLANK-LINE.

       WRITE-ID.
           MOVE SPACES TO OUT-REC
           MOVE KUNDE-ID TO OUT-REC
           WRITE OUT-REC.

       WRITE-NAVN.
           MOVE SPACES TO OUT-REC
           STRING FORNAVN  DELIMITED BY SPACE
                  " "      DELIMITED BY SIZE
                  EFTERNAVN DELIMITED BY SPACE
             INTO OUT-REC
           END-STRING
           WRITE OUT-REC.

       WRITE-ADRESSE.
           MOVE SPACES TO OUT-REC
           STRING VEJNAVN DELIMITED BY SPACE 
                  " "     DELIMITED BY SIZE
                  HUSNR   DELIMITED BY SPACE
                  " "     DELIMITED BY SIZE
                  ETAGE   DELIMITED BY SPACE
                  " "     DELIMITED BY SIZE
                  SIDE    DELIMITED BY SPACE
             INTO OUT-REC
           END-STRING
           WRITE OUT-REC.

       WRITE-BY.
           MOVE SPACES TO OUT-REC
           STRING POSTNR DELIMITED BY SPACE 
                  " "    DELIMITED BY SIZE
                  BYEN     DELIMITED BY SPACE
             INTO OUT-REC
           END-STRING
           WRITE OUT-REC.

       WRITE-KONTAKT.
           MOVE SPACES TO OUT-REC
           MOVE TELEFON TO OUT-REC
           WRITE OUT-REC
           
           MOVE SPACES TO OUT-REC
           MOVE EMAIL TO OUT-REC
           WRITE OUT-REC.

       WRITE-BLANK-LINE.
           MOVE SPACES TO OUT-REC
           WRITE OUT-REC.
