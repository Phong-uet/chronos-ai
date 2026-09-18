       
       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBOL-BANK-EXAMPLE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
         *> Ham bakiye verisi
         01 WS-BALANCE        PIC 9(10) VALUE 12500.
         *> Bakiye görüntüleme için formatlanmış değişken
         01 WS-DISP-BALANCE   PIC Z,ZZZ,ZZ9.
         01 WS-INCOMING-MONEY PIC 9(10) VALUE 3750.

       PROCEDURE DIVISION.
       0000-MAIN-LOGIC.
            MOVE WS-BALANCE TO WS-DISP-BALANCE
            DISPLAY 'Baslangic bakiyesi: $' WS-DISP-BALANCE.
            DISPLAY 'Hesaba para aktariliyor. . .'.

            *> ADD komutu ile toplama işlemi.
            ADD WS-INCOMING-MONEY TO WS-BALANCE.

            *> Güncellenen yeni bakiyeyi tekrar formatlı değişkene taşıyoruz:
            MOVE WS-BALANCE TO WS-DISP-BALANCE.
            DISPLAY 'Güncel toplam bakiye: $' WS-DISP-BALANCE.

            STOP RUN.
            