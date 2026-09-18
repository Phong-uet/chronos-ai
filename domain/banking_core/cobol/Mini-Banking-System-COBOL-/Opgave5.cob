       IDENTIFICATION DIVISION.
       PROGRAM-ID. OPGAVE5.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01 KUNDEOPL.
           COPY "KUNDER.cpy".

       PROCEDURE DIVISION.

           MOVE 10001 TO KUNDE-ID
           MOVE "Ib" TO FORNAVN
           MOVE "Hej" TO EFTERNAVN

           MOVE "MainStreet" TO VEJNAVN
           MOVE "12" TO HUSNR
           MOVE "2" TO ETAGE
           MOVE "TH" TO SIDE
           MOVE "Copenhagen" TO BYEN
           MOVE "2100" TO POSTNR
           MOVE "DK" TO LANDE-KODE

           MOVE "12345678" TO TELEFON
           MOVE "ib@email.com" TO EMAIL

           DISPLAY "Name: " FORNAVN " " EFTERNAVN
           DISPLAY "Address: " VEJNAVN " " HUSNR
           DISPLAY "City: " POSTNR " " BYEN
           DISPLAY "Phone: " TELEFON
           DISPLAY "Email: " EMAIL

           STOP RUN.
