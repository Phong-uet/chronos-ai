       
       *> IDENTIFICATION DIVISION: Programın kimlik bilgilerini tanımlar.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBOL-HELLO-WORLD.
       AUTHOR. Mevlut KAMALI.

       *> ENVIRONMENT DIVISION: Çalışma ortamı tanımları.
       ENVIRONMENT DIVISION.

       *> DATA DIVISION: Değişkenlerin tanımlandığı bölüm.
       DATA DIVISION.

       *> PROCEDURE DIVISION: İş mantığı ve kodların çalıştığı alan.
       PROCEDURE DIVISION.
       0000-MAIN-LOGIC.
           DISPLAY "Hello World".
           STOP RUN.
           