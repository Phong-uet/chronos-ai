       IDENTIFICATION  DIVISION. 
       PROGRAM-ID. HELLO. 
       DATA DIVISION. 
       WORKING-STORAGE SECTION. 
       01 VAR-TEXT         PIC X(30) VALUE "HELLO med Variabel".

       PROCEDURE DIVISION. 
      *Nedenfor kommer en display - Cobols måde at skrive i konsollen 
           DISPLAY VAR-TEXT
           STOP RUN.
       