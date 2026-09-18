       IDENTIFICATION  DIVISION. 
       PROGRAM-ID. OPGAVE3. 
       DATA DIVISION. 
       WORKING-STORAGE SECTION. 

       01 KUNDE-ID        PIC X(10) VALUE SPACES.
       01 FORNAVN         PIC X(20) VALUE SPACES.
       01 EFTERNAVN       PIC X(20) VALUE SPACES.
       01 KONTONUMMER     PIC X(20) VALUE SPACES.
       01 BALANCE         PIC 9(7)V99 VALUE ZEROS.
       01 VALUTAKODE      PIC X(3) VALUE SPACES.

       01 FULDT-NAVN      PIC X(40) VALUE SPACES.
       01 RENS-FULDT-NAVN PIC X(40) VALUE SPACES.

       *> Index variables for loop
       01 IX               PIC 9(3) VALUE ZEROS.
       01 IX2              PIC 9(3) VALUE ZEROS.

       01 CURRENT-CHAR     PIC X VALUE SPACE.
       01 PREVIOUS-CHAR    PIC X VALUE SPACE.
       PROCEDURE DIVISION.
       *> Move values to variables
           MOVE "1234567890" TO KUNDE-ID
           MOVE "Lars" TO FORNAVN
           MOVE "Hansen" TO EFTERNAVN
           MOVE "DK12345678912345" TO KONTONUMMER
           MOVE 2500.75 TO BALANCE
           MOVE "DKK" TO VALUTAKODE
           *> Combine first name and last name into FULDT-NAVN
           STRING FORNAVN DELIMITED BY SIZE
                  " " DELIMITED BY SIZE
                  EFTERNAVN DELIMITED BY SIZE
           INTO FULDT-NAVN
       *> Display combined name
           DISPLAY "----------------------------------------" 
           DISPLAY "Combined name (with spaces): " FULDT-NAVN
       *> Display variables
           DISPLAY "----------------------------------------" 
           DISPLAY "Kunde-ID       : " KUNDE-ID
           DISPLAY "Navn           : " FORNAVN " " EFTERNAVN
           DISPLAY "Kontonummer    : " KONTONUMMER
           DISPLAY "Balance        : " BALANCE " " VALUTAKODE
           *> Initialize index
           MOVE 1 TO IX
           MOVE 1 TO IX2
           MOVE SPACE TO PREVIOUS-CHAR
           PERFORM VARYING IX FROM 1 BY 1
               UNTIL IX > LENGTH OF FULDT-NAVN
               MOVE FULDT-NAVN(IX:1) TO CURRENT-CHAR       
               IF CURRENT-CHAR NOT = SPACE OR PREVIOUS-CHAR NOT = SPACE
                   MOVE CURRENT-CHAR TO RENS-FULDT-NAVN(IX2:1)
                   ADD 1 TO IX2
               END-IF
               MOVE CURRENT-CHAR TO PREVIOUS-CHAR
           END-PERFORM.
       *> Display cleaned name
           DISPLAY "----------------------------------------" 
           DISPLAY "Cleaned name (no extra spaces): " RENS-FULDT-NAVN.
           DISPLAY "----------------------------------------" 
           STOP RUN.