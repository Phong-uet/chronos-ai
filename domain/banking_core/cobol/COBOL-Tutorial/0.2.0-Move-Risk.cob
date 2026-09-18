       
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MOVE-RISK-DAY-3.
       AUTHOR. Mevlut KAMALI.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       *> Metin Tipi Değişkenler
       01 WS-CUSTOMER-NAME PIC X(20)   VALUE 'Mevlut KAMALI'.
       01 WS-TRG-SHORT   PIC 9(5).

       *> Sayısal Tipi Değişkenler
       01 WS-SRC-AMOUNT    PIC 9(5)    VALUE 98765.
       01 WS-TRG-SMALL     PIC 9(3)    VALUE 0.

       PROCEDURE DIVISION.
       0000-MAIN-LOGIC.
           *> 1. Metin Kopyalama (Sağdan Kesilme)
           MOVE WS-CUSTOMER-NAME TO WS-TRG-SHORT.
           DISPLAY 'Customer Name Truncation: ' WS-TRG-SHORT.

           *> 2. Sayısal Kopyalama (Soldan Kesilme)
           MOVE WS-SRC-AMOUNT TO WS-TRG-SMALL.
           DISPLAY 'Source Amount - Numeric Truncation: ' WS-TRG-SMALL.
           
           STOP RUN.
