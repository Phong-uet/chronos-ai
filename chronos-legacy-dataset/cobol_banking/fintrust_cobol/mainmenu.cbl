       IDENTIFICATION DIVISION.
       PROGRAM-ID. MAINMENU.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 USER-CHOICE        PIC 9 VALUE ZEROS.

       PROCEDURE DIVISION.

       *> Main program logic for FinTrust COBOL menu interface
       MAIN-PARAGRAPH.
           PERFORM UNTIL USER-CHOICE = 9
               DISPLAY "==========================================="
               DISPLAY "      WELCOME TO FINTRUST COBOL             "
               DISPLAY "==========================================="
               DISPLAY " Please select an option:"
               DISPLAY " 1 - Account Management"
               DISPLAY " 2 - View Transactions"
               DISPLAY " 3 - Ledger Summary"
               DISPLAY " 4 - Authenticate User"
               DISPLAY " 9 - Exit"
               ACCEPT USER-CHOICE

               EVALUATE USER-CHOICE
                   WHEN 1
                       DISPLAY ">> Loading Account Management Module..."
                       CALL "ACCTMGMT"
                   WHEN 2
                       DISPLAY ">> Loading View Transactions Module..."
                       CALL "VIEWTRANS"
                   WHEN 3
                       DISPLAY ">> Loading Ledger Summary Module..."
                       CALL "LEDGERSM"
                   WHEN 4
                       DISPLAY ">> Loading Authenticate User Module..."
                       CALL "AUTHUSER"
                   WHEN 9
                       DISPLAY ">> Exiting FinTrust COBOL. Goodbye! :)"
                   WHEN OTHER
                       DISPLAY ">> Invalid choice. Please restart."
               END-EVALUATE
           END-PERFORM.

           STOP RUN.
