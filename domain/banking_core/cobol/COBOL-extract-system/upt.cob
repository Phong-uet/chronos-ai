IDENTIFICATION DIVISION.
PROGRAM-ID. UpdateRecord.

ENVIRONMENT DIVISION.

DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-DB2-CONNECTION.
    05  WS-USERID     PIC X(08) VALUE 'youruserid'.
    05  WS-PASSWORD   PIC X(08) VALUE 'yourpassword'.

01  WS-SQLCODE     PIC S9(9) COMP.
01  WS-RECORD.
    05  EMP-ID      PIC X(05) VALUE 'E1234'.
    05  EMP-NAME    PIC X(20) VALUE 'Jane Doe'.

PROCEDURE DIVISION.
MAIN-SECTION.
    EXEC SQL
        CONNECT TO 'yourdatabase'
        USER :WS-USERID
        USING :WS-PASSWORD
    END-EXEC.

    IF SQLCODE = 0 THEN
        EXEC SQL
            UPDATE EMPLOYEE
            SET EMP_NAME = :EMP-NAME
            WHERE EMP_ID = :EMP-ID
        END-EXEC
        IF SQLCODE = 0 THEN
            DISPLAY 'Record updated successfully.'
        ELSE
            DISPLAY 'Update failed: ' SQLCODE
        END-IF
    ELSE
        DISPLAY 'Connection failed: ' SQLCODE
    END-IF.

    EXEC SQL
        COMMIT
    END-EXEC.

    STOP RUN.
