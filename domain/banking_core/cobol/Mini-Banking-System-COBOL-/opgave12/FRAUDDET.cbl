       IDENTIFICATION DIVISION.
       PROGRAM-ID. FRAUDDET.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT KUNDE-FILE ASSIGN TO "KundeOplysninger.txt"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT SANCTION-FILE ASSIGN TO "SanctionList.txt"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT RAPPORT-FILE ASSIGN TO "SanktionsRapport.txt"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  KUNDE-FILE.
       01  KUNDE-REC.
           05 K-ID          PIC X(11).
           05 K-NAVN        PIC X(20).
           05 K-FOEDSEL     PIC X(10).
           05 K-ADRESSE     PIC X(30).
           05 K-LAND        PIC X(02).

       FD  SANCTION-FILE.
       01  SANC-REC.
           05 S-ID          PIC X(05).
           05 S-NAVN        PIC X(20).
           05 S-ALIAS-GRP OCCURS 5 TIMES.
              10 S-ALIAS    PIC X(20).
           05 S-DATE-RAW    PIC X(10).
           05 S-LAND        PIC X(02).

       FD  RAPPORT-FILE.
       01  RAPP-LINE        PIC X(120).

       WORKING-STORAGE SECTION.
       01  WS-FLAGS.
           05 KUNDE-EOF     PIC X VALUE 'N'.
           05 SANC-EOF      PIC X VALUE 'N'.
       
       01  WS-CONVERT-DATE.
           05 S-YY          PIC X(4).
           05 S-MM          PIC X(2).
           05 S-DD          PIC X(2).
       01  WS-SANC-DATE-CMP PIC X(6).
       
       01  WS-PCT-VARS.
           05 NAME-PCT      PIC 9(3) VALUE 0.
           05 DATE-PCT      PIC 9(3) VALUE 0.
           05 LAND-PCT      PIC 9(3) VALUE 0.
           05 TOTAL-PCT     PIC 9(3)V9 VALUE 0.
       
       01  WS-COUNTERS.
           05 ALIAS-IDX     PIC 9 VALUE 0.
           05 FOUND-NAME    PIC X VALUE 'N'.

       01  WS-DISPLAY-FIELDS.
           05 WS-PCT-OUT    PIC ZZ9.9.

       PROCEDURE DIVISION.
       000-MAIN.
           OPEN INPUT KUNDE-FILE SANCTION-FILE
           OPEN OUTPUT RAPPORT-FILE
           
           READ KUNDE-FILE AT END MOVE 'Y' TO KUNDE-EOF END-READ
           PERFORM 100-PROCESS UNTIL KUNDE-EOF = 'Y'
           
           CLOSE KUNDE-FILE SANCTION-FILE RAPPORT-FILE
           STOP RUN.

       100-PROCESS.
           CLOSE SANCTION-FILE
           OPEN INPUT SANCTION-FILE
           MOVE 'N' TO SANC-EOF
           
           READ SANCTION-FILE AT END MOVE 'Y' TO SANC-EOF END-READ
           PERFORM 200-LOGIC UNTIL SANC-EOF = 'Y'
           
           READ KUNDE-FILE AT END MOVE 'Y' TO KUNDE-EOF END-READ.

       200-LOGIC.
           *> 1. Konverter Sanction-dato (YYYY-MM-DD) til ddmmyy
           MOVE S-DATE-RAW(3:2) TO S-YY
           MOVE S-DATE-RAW(6:2) TO S-MM
           MOVE S-DATE-RAW(9:2) TO S-DD
           STRING S-DD S-MM S-YY DELIMITED BY SIZE INTO WS-SANC-DATE-CMP

           *> 2. Navn og Alias Match Logik (50% vægtning)
           MOVE 0 TO NAME-PCT
           MOVE 'N' TO FOUND-NAME
           
           *> Tjek først det primære navn
           IF K-NAVN = S-NAVN
               MOVE 100 TO NAME-PCT
               MOVE 'Y' TO FOUND-NAME
           ELSE
               *> Loop gennem alle 5 aliaser hvis navnet ikke matchede
               PERFORM VARYING ALIAS-IDX FROM 1 BY 1 
                 UNTIL ALIAS-IDX > 5 OR FOUND-NAME = 'Y'
                   IF K-NAVN = S-ALIAS(ALIAS-IDX) AND 
                      S-ALIAS(ALIAS-IDX) NOT = SPACES
                       MOVE 100 TO NAME-PCT
                       MOVE 'Y' TO FOUND-NAME
                   END-IF
               END-PERFORM
           END-IF

           *> 3. Dato Match (30% vægtning)
           IF K-FOEDSEL(1:6) = WS-SANC-DATE-CMP 
               MOVE 100 TO DATE-PCT 
           ELSE 
               MOVE 0 TO DATE-PCT
           END-IF

           *> 4. Land Match (20% vægtning)
           IF K-LAND = S-LAND 
               MOVE 100 TO LAND-PCT 
           ELSE 
               MOVE 0 TO LAND-PCT
           END-IF

           *> 5. Beregn Samlet Match Procent
           COMPUTE TOTAL-PCT ROUNDED = 
               (NAME-PCT * 0.5) + (DATE-PCT * 0.3) + (LAND-PCT * 0.2)
           
           *> Hvis match er over 40%, så skriv til rapporten
           IF TOTAL-PCT > 40 
               PERFORM 300-REPORT
           END-IF

           READ SANCTION-FILE AT END MOVE 'Y' TO SANC-EOF END-READ.

       300-REPORT.
           WRITE RAPP-LINE 
           FROM "------------------------------------------------------"
           
           INITIALIZE RAPP-LINE
           STRING "Kunde-ID: " K-ID DELIMITED BY SIZE INTO RAPP-LINE
           WRITE RAPP-LINE
           
           INITIALIZE RAPP-LINE
           STRING "Kundenavn: " K-NAVN DELIMITED BY SIZE INTO RAPP-LINE
           WRITE RAPP-LINE
           
           INITIALIZE RAPP-LINE
           STRING "Fødselsdato: " K-FOEDSEL(1:6) DELIMITED BY SIZE 
               INTO RAPP-LINE
           WRITE RAPP-LINE
           
           INITIALIZE RAPP-LINE
           STRING "Adresse: " K-ADRESSE ", " K-LAND DELIMITED BY SIZE 
               INTO RAPP-LINE
           WRITE RAPP-LINE
           
           MOVE SPACES TO RAPP-LINE
           WRITE RAPP-LINE
           WRITE RAPP-LINE FROM "Match fundet med:"
           
           INITIALIZE RAPP-LINE
           STRING "Sanction-ID: " S-ID DELIMITED BY SIZE INTO RAPP-LINE
           WRITE RAPP-LINE
           
           INITIALIZE RAPP-LINE
           STRING "Navn: " S-NAVN DELIMITED BY SIZE INTO RAPP-LINE
           WRITE RAPP-LINE
           
           INITIALIZE RAPP-LINE
           STRING "Fødselsdato: " WS-SANC-DATE-CMP DELIMITED BY SIZE 
               INTO RAPP-LINE
           WRITE RAPP-LINE
           
           INITIALIZE RAPP-LINE
           STRING "Land: " S-LAND DELIMITED BY SIZE INTO RAPP-LINE
           WRITE RAPP-LINE

           MOVE SPACES TO RAPP-LINE
           WRITE RAPP-LINE
           WRITE RAPP-LINE FROM "Match-beskrivelse:"
           
           INITIALIZE RAPP-LINE
           MOVE NAME-PCT TO WS-PCT-OUT
           STRING " - Match på navn/alias: " WS-PCT-OUT "%."
                  DELIMITED BY SIZE INTO RAPP-LINE
           WRITE RAPP-LINE
           
           INITIALIZE RAPP-LINE
           MOVE DATE-PCT TO WS-PCT-OUT
           STRING " - Match på fødselsdato: " WS-PCT-OUT "%."
                  DELIMITED BY SIZE INTO RAPP-LINE
           WRITE RAPP-LINE
           
           INITIALIZE RAPP-LINE
           MOVE LAND-PCT TO WS-PCT-OUT
           STRING " - Match på land: " WS-PCT-OUT "%."
                  DELIMITED BY SIZE INTO RAPP-LINE
           WRITE RAPP-LINE

           INITIALIZE RAPP-LINE
           MOVE TOTAL-PCT TO WS-PCT-OUT
           STRING "Samlet match-procent: " WS-PCT-OUT "%"
                  DELIMITED BY SIZE INTO RAPP-LINE
           WRITE RAPP-LINE.
co