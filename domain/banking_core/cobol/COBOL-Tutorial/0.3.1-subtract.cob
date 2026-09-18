       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBOL-BANK-EXAMPLE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

           *> Bakiye için 2 ondalık hassasiyeti koruyoruz
           01 WS-BALANCE        PIC 9(10)V99 VALUE 16500.00.

           *> Okunabilirliği yüksek, boşlukları optimize edilmiş format
           01 WS-DISP-BALANCE   PIC ZZZ,ZZ9.99.

           01 WS-DEBT           PIC 9(10)V99 VALUE 2000.00.

           *> Faiz oranı
           01 WS-INTEREST        PIC 9V99 VALUE 1.05.

           01 WS-DAY            PIC 99 VALUE 0.

       PROCEDURE DIVISION.

       0000-MAIN-LOGIC.

           MOVE WS-BALANCE TO WS-DISP-BALANCE.
           DISPLAY 'Guncel bakiye: $' WS-DISP-BALANCE.
           DISPLAY '2000 TL tutarindaki borc odeniyor...'.

           SUBTRACT WS-DEBT FROM WS-BALANCE.

           MOVE WS-BALANCE TO WS-DISP-BALANCE.
           DISPLAY 'Borc odendikten sonraki net bakiye: $'
                   WS-DISP-BALANCE.

           DISPLAY '----------------------------------------'.
           DISPLAY '30 gun boyunca %5 gunluk faiz uygulanacak.'.
           DISPLAY '----------------------------------------'.

           PERFORM 30 TIMES
               ADD 1 TO WS-DAY

               *> ON SIZE ERROR ile olası veri taşmasını yakalıyoruz
               *> ROUNDED ile finansal yuvarlama yapıyoruz
               MULTIPLY WS-INTEREST BY WS-BALANCE ROUNDED
                   ON SIZE ERROR
                       DISPLAY 'HATA: Bakiye degisken boyutunu asti!'
               END-MULTIPLY

               MOVE WS-BALANCE TO WS-DISP-BALANCE
               DISPLAY 'Gun ' WS-DAY ': $' WS-DISP-BALANCE
           END-PERFORM.

           DISPLAY '----------------------------------------'.
           MOVE WS-BALANCE TO WS-DISP-BALANCE.
           DISPLAY '30 gun sonraki bakiye: $' WS-DISP-BALANCE.

           STOP RUN.
