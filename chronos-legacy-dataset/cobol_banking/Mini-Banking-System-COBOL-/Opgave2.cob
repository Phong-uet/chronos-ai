       IDENTIFICATION  DIVISION. 
       PROGRAM-ID. OPGAVE2. 
       DATA DIVISION. 
       WORKING-STORAGE SECTION. 

       01 KUNDE-ID      PIC X(10) VALUE SPACES.
       01 FORNAVN       PIC X(20) VALUE SPACES.
       01 EFTERNAVN     PIC X(20) VALUE SPACES.
       01 KONTONUMMER   PIC X(20) VALUE SPACES.
       01 BALANCE       PIC 9(7)V99 VALUE ZEROS.
       01 VALUTAKODE    PIC X(3) VALUE SPACES.
       PROCEDURE DIVISION.
       *> Move values to variables
           MOVE "1234567890" TO KUNDE-ID
           MOVE "Lars" TO FORNAVN
           MOVE "Hansen" TO EFTERNAVN
           MOVE "DK12345678912345" TO KONTONUMMER
           MOVE 2500.75 TO BALANCE
           MOVE "DKK" TO VALUTAKODE
       *> Display variables
           DISPLAY "Kunde-ID       : " KUNDE-ID
           DISPLAY "Navn           : " FORNAVN " " EFTERNAVN
           DISPLAY "Kontonummer    : " KONTONUMMER
           DISPLAY "Balance        : " BALANCE " " VALUTAKODE
           STOP RUN.    