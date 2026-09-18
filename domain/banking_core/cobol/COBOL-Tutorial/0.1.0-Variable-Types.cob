       
       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBOL-Variable-Types-DAY-2.
       AUTHOR. Mevlut KAMALI.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-CUSTOMER-NAME PIC X(20)   VALUE 'Mevlut KAMALI'.
       01 WS-ACCOUNT-ID    PIC 9(6)    VALUE 102030.
       01 WS-BALANCE       PIC 9(5)V99 VALUE 1500.50.

       PROCEDURE DIVISION.
       0000-MAIN-LOGIC.
           DISPLAY 'Customer Name: ' WS-CUSTOMER-NAME.
           DISPLAY 'Account ID   : ' WS-ACCOUNT-ID.
           DISPLAY 'Balance      : ' WS-BALANCE.

           STOP RUN.
           