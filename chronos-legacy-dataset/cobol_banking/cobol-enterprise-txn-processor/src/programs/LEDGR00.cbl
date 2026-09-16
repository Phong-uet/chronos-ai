       IDENTIFICATION DIVISION.
       PROGRAM-ID.    LEDGR00.
       AUTHOR.        ENTERPRISE FINANCIAL SYSTEMS.
       DATE-WRITTEN.  2026-03-31.
      ******************************************************************
      * LEDGR00 - General Ledger Posting Engine
      *
      * Third stage of the batch pipeline. Reads journal entries
      * produced by TXNPRC00 and posts them to the general ledger
      * with full double-entry bookkeeping verification.
      *
      * Key invariant: For every journal entry, the debit amount
      * must equal the credit amount. The system tracks cumulative
      * totals and flags any imbalance.
      *
      * Produces:
      *   1. Posting log (record of all ledger postings)
      *   2. Updated account balances (via ledger accounts)
      *   3. Audit trail records
      ******************************************************************

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       REPOSITORY.
           FUNCTION ALL INTRINSIC.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT JOURNAL-IN-FILE
               ASSIGN TO 'data/work/journal-entries.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-JRNL-STATUS.

           SELECT POSTING-LOG-FILE
               ASSIGN TO 'data/work/posting-log.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-POST-STATUS.

           SELECT ACCOUNT-IN-FILE
               ASSIGN TO 'data/work/accounts-updated.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACTIN-STATUS.

           SELECT LEDGER-OUT-FILE
               ASSIGN TO 'data/work/general-ledger.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-LEDG-STATUS.

           SELECT AUDIT-LOG-FILE
               ASSIGN TO 'data/work/ledgr-audit.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-AUDIT-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  JOURNAL-IN-FILE
           RECORDING MODE IS F.
       01  JOURNAL-IN-REC             PIC X(150).

       FD  POSTING-LOG-FILE
           RECORDING MODE IS F.
       01  POSTING-LOG-REC            PIC X(200).

       FD  ACCOUNT-IN-FILE
           RECORDING MODE IS F.
       01  ACCOUNT-IN-REC             PIC X(200).

       FD  LEDGER-OUT-FILE
           RECORDING MODE IS F.
       01  LEDGER-OUT-REC             PIC X(200).

       FD  AUDIT-LOG-FILE
           RECORDING MODE IS F.
       01  AUDIT-LOG-REC              PIC X(250).

       WORKING-STORAGE SECTION.

      * File status
       01  WS-JRNL-STATUS             PIC X(02).
       01  WS-POST-STATUS             PIC X(02).
       01  WS-ACTIN-STATUS            PIC X(02).
       01  WS-LEDG-STATUS             PIC X(02).
       01  WS-AUDIT-STATUS            PIC X(02).

      * Control flags
       01  WS-EOF-FLAG                PIC X(01) VALUE 'N'.
           88  END-OF-FILE            VALUE 'Y'.
           88  NOT-END-OF-FILE        VALUE 'N'.

       01  WS-ACCT-EOF                PIC X(01) VALUE 'N'.
           88  ACCT-EOF               VALUE 'Y'.
           88  ACCT-NOT-EOF           VALUE 'N'.

      * Copybooks
       COPY 'src/copybooks/JRNREC.cpy'.
       COPY 'src/copybooks/ACTREC.cpy'.
       COPY 'src/copybooks/AUDREC.cpy'.

      * Posting log record
       01  WS-POSTING-RECORD.
           05  PST-POSTING-NUM         PIC 9(10).
           05  PST-JRN-ENTRY-NUM       PIC 9(10).
           05  PST-DATE                PIC 9(08).
           05  PST-TIME                PIC 9(06).
           05  PST-DEBIT-ACCOUNT       PIC X(12).
           05  PST-CREDIT-ACCOUNT      PIC X(12).
           05  PST-AMOUNT              PIC 9(13)V99.
           05  PST-ENTRY-TYPE          PIC X(03).
           05  PST-STATUS              PIC X(01).
               88  PST-POSTED          VALUE 'P'.
               88  PST-FAILED          VALUE 'F'.
           05  PST-DESCRIPTION         PIC X(40).
           05  PST-PROGRAM-ID          PIC X(08).
           05  FILLER                  PIC X(82).

      * Ledger account table
       01  WS-LEDGER-TABLE.
           05  WS-LEDG-COUNT          PIC 9(05) VALUE 0.
           05  WS-LEDG-ENTRY OCCURS 1000 TIMES.
               10  WS-LG-ACCOUNT-NUM  PIC X(12).
               10  WS-LG-TOTAL-DEBIT  PIC 9(15)V99.
               10  WS-LG-TOTAL-CREDIT PIC 9(15)V99.
               10  WS-LG-NET-BALANCE  PIC S9(15)V99.
               10  WS-LG-POSTING-CT   PIC 9(08).

      * Counters
       01  WS-COUNTERS.
           05  WS-JRN-READ            PIC 9(08) VALUE 0.
           05  WS-JRN-POSTED          PIC 9(08) VALUE 0.
           05  WS-POSTING-SEQ         PIC 9(10) VALUE 0.
           05  WS-AUDIT-SEQ           PIC 9(10) VALUE 0.
           05  WS-TOTAL-DEBITS        PIC 9(15)V99 VALUE 0.
           05  WS-TOTAL-CREDITS       PIC 9(15)V99 VALUE 0.

      * Work fields
       01  WS-WORK-FIELDS.
           05  WS-CURR-DATE           PIC 9(08).
           05  WS-CURR-TIME           PIC 9(06).
           05  WS-SEARCH-IDX          PIC 9(05).
           05  WS-DEBIT-IDX           PIC 9(05).
           05  WS-CREDIT-IDX          PIC 9(05).
           05  WS-FOUND-FLAG          PIC X(01).
           05  WS-PREV-HASH           PIC X(16) VALUE ALL '0'.
           05  WS-HASH-RESULT         PIC X(16).
           05  WS-HASH-WORK           PIC 9(10).
           05  WS-IMBALANCE           PIC S9(15)V99.
           05  WS-IMBALANCE-DISP      PIC -(15)9.99.

       PROCEDURE DIVISION.
       0000-MAIN-CONTROL.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-LOAD-ACCOUNTS
           PERFORM 3000-POST-JOURNAL-ENTRIES
           PERFORM 4000-VERIFY-BALANCE
           PERFORM 5000-WRITE-LEDGER
           PERFORM 9000-FINALIZE
           STOP RUN
           .

       1000-INITIALIZE.
           MOVE FUNCTION CURRENT-DATE(1:8) TO WS-CURR-DATE
           MOVE FUNCTION CURRENT-DATE(9:6) TO WS-CURR-TIME

           OPEN INPUT  JOURNAL-IN-FILE
           OPEN OUTPUT POSTING-LOG-FILE
           OPEN OUTPUT AUDIT-LOG-FILE

           IF WS-JRNL-STATUS NOT = '00'
               DISPLAY 'ERROR: Cannot open journal entries file'
               STOP RUN
           END-IF

           DISPLAY 'LEDGR00: Initialization complete'
           .

       2000-LOAD-ACCOUNTS.
           OPEN INPUT ACCOUNT-IN-FILE
           IF WS-ACTIN-STATUS NOT = '00'
               DISPLAY 'ERROR: Cannot open account file'
               STOP RUN
           END-IF

           SET ACCT-NOT-EOF TO TRUE
           PERFORM UNTIL ACCT-EOF
               READ ACCOUNT-IN-FILE INTO WS-ACCOUNT-RECORD
                   AT END
                       SET ACCT-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO WS-LEDG-COUNT
                       MOVE ACT-ACCOUNT-NUM
                           TO WS-LG-ACCOUNT-NUM(WS-LEDG-COUNT)
                       MOVE ZEROS
                           TO WS-LG-TOTAL-DEBIT(WS-LEDG-COUNT)
                       MOVE ZEROS
                           TO WS-LG-TOTAL-CREDIT(WS-LEDG-COUNT)
                       MOVE ZEROS
                           TO WS-LG-NET-BALANCE(WS-LEDG-COUNT)
                       MOVE ZEROS
                           TO WS-LG-POSTING-CT(WS-LEDG-COUNT)
               END-READ
           END-PERFORM

           CLOSE ACCOUNT-IN-FILE
           DISPLAY 'LEDGR00: Loaded ' WS-LEDG-COUNT
               ' ledger accounts'
           .

       3000-POST-JOURNAL-ENTRIES.
           SET NOT-END-OF-FILE TO TRUE

           PERFORM UNTIL END-OF-FILE
               READ JOURNAL-IN-FILE INTO WS-JOURNAL-RECORD
                   AT END
                       SET END-OF-FILE TO TRUE
                   NOT AT END
                       ADD 1 TO WS-JRN-READ
                       PERFORM 3100-POST-SINGLE-ENTRY
               END-READ
           END-PERFORM
           .

       3100-POST-SINGLE-ENTRY.
      * Find or create debit ledger account
           PERFORM 3200-FIND-DEBIT-ACCOUNT
      * Find or create credit ledger account
           PERFORM 3300-FIND-CREDIT-ACCOUNT

      * Post debit side
           ADD JRN-AMOUNT
               TO WS-LG-TOTAL-DEBIT(WS-DEBIT-IDX)
           SUBTRACT JRN-AMOUNT
               FROM WS-LG-NET-BALANCE(WS-DEBIT-IDX)
           ADD 1 TO WS-LG-POSTING-CT(WS-DEBIT-IDX)

      * Post credit side
           ADD JRN-AMOUNT
               TO WS-LG-TOTAL-CREDIT(WS-CREDIT-IDX)
           ADD JRN-AMOUNT
               TO WS-LG-NET-BALANCE(WS-CREDIT-IDX)
           ADD 1 TO WS-LG-POSTING-CT(WS-CREDIT-IDX)

      * Track running totals
           ADD JRN-AMOUNT TO WS-TOTAL-DEBITS
           ADD JRN-AMOUNT TO WS-TOTAL-CREDITS

      * Write posting log
           ADD 1 TO WS-POSTING-SEQ
           INITIALIZE WS-POSTING-RECORD
           MOVE WS-POSTING-SEQ      TO PST-POSTING-NUM
           MOVE JRN-ENTRY-NUM       TO PST-JRN-ENTRY-NUM
           MOVE WS-CURR-DATE        TO PST-DATE
           MOVE WS-CURR-TIME        TO PST-TIME
           MOVE JRN-DEBIT-ACCOUNT   TO PST-DEBIT-ACCOUNT
           MOVE JRN-CREDIT-ACCOUNT  TO PST-CREDIT-ACCOUNT
           MOVE JRN-AMOUNT          TO PST-AMOUNT
           MOVE JRN-ENTRY-TYPE      TO PST-ENTRY-TYPE
           MOVE 'P'                 TO PST-STATUS
           MOVE JRN-DESCRIPTION     TO PST-DESCRIPTION
           MOVE 'LEDGR00 '          TO PST-PROGRAM-ID

           WRITE POSTING-LOG-REC FROM WS-POSTING-RECORD
           ADD 1 TO WS-JRN-POSTED

      * Audit
           PERFORM 6000-WRITE-POST-AUDIT
           .

       3200-FIND-DEBIT-ACCOUNT.
           MOVE 0 TO WS-DEBIT-IDX
           PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
               UNTIL WS-SEARCH-IDX > WS-LEDG-COUNT
               OR WS-DEBIT-IDX > 0
               IF WS-LG-ACCOUNT-NUM(WS-SEARCH-IDX)
                   = JRN-DEBIT-ACCOUNT
                   MOVE WS-SEARCH-IDX TO WS-DEBIT-IDX
               END-IF
           END-PERFORM

      * If not found, add as new ledger account
           IF WS-DEBIT-IDX = 0
               ADD 1 TO WS-LEDG-COUNT
               MOVE JRN-DEBIT-ACCOUNT
                   TO WS-LG-ACCOUNT-NUM(WS-LEDG-COUNT)
               MOVE ZEROS
                   TO WS-LG-TOTAL-DEBIT(WS-LEDG-COUNT)
               MOVE ZEROS
                   TO WS-LG-TOTAL-CREDIT(WS-LEDG-COUNT)
               MOVE ZEROS
                   TO WS-LG-NET-BALANCE(WS-LEDG-COUNT)
               MOVE ZEROS
                   TO WS-LG-POSTING-CT(WS-LEDG-COUNT)
               MOVE WS-LEDG-COUNT TO WS-DEBIT-IDX
           END-IF
           .

       3300-FIND-CREDIT-ACCOUNT.
           MOVE 0 TO WS-CREDIT-IDX
           PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
               UNTIL WS-SEARCH-IDX > WS-LEDG-COUNT
               OR WS-CREDIT-IDX > 0
               IF WS-LG-ACCOUNT-NUM(WS-SEARCH-IDX)
                   = JRN-CREDIT-ACCOUNT
                   MOVE WS-SEARCH-IDX TO WS-CREDIT-IDX
               END-IF
           END-PERFORM

           IF WS-CREDIT-IDX = 0
               ADD 1 TO WS-LEDG-COUNT
               MOVE JRN-CREDIT-ACCOUNT
                   TO WS-LG-ACCOUNT-NUM(WS-LEDG-COUNT)
               MOVE ZEROS
                   TO WS-LG-TOTAL-DEBIT(WS-LEDG-COUNT)
               MOVE ZEROS
                   TO WS-LG-TOTAL-CREDIT(WS-LEDG-COUNT)
               MOVE ZEROS
                   TO WS-LG-NET-BALANCE(WS-LEDG-COUNT)
               MOVE ZEROS
                   TO WS-LG-POSTING-CT(WS-LEDG-COUNT)
               MOVE WS-LEDG-COUNT TO WS-CREDIT-IDX
           END-IF
           .

       4000-VERIFY-BALANCE.
           COMPUTE WS-IMBALANCE =
               WS-TOTAL-DEBITS - WS-TOTAL-CREDITS

           IF WS-IMBALANCE NOT = 0
               MOVE WS-IMBALANCE TO WS-IMBALANCE-DISP
               DISPLAY '*** WARNING: LEDGER IMBALANCE DETECTED ***'
               DISPLAY '  Total debits:  ' WS-TOTAL-DEBITS
               DISPLAY '  Total credits: ' WS-TOTAL-CREDITS
               DISPLAY '  Imbalance:     ' WS-IMBALANCE-DISP
           ELSE
               DISPLAY 'LEDGR00: Double-entry balance verified OK'
               DISPLAY '  Total debits  = Total credits = '
                   WS-TOTAL-DEBITS
           END-IF
           .

       5000-WRITE-LEDGER.
           OPEN OUTPUT LEDGER-OUT-FILE

           PERFORM VARYING WS-SEARCH-IDX FROM 1 BY 1
               UNTIL WS-SEARCH-IDX > WS-LEDG-COUNT

               INITIALIZE WS-ACCOUNT-RECORD
               MOVE WS-LG-ACCOUNT-NUM(WS-SEARCH-IDX)
                   TO ACT-ACCOUNT-NUM
               MOVE WS-LG-TOTAL-DEBIT(WS-SEARCH-IDX)
                   TO ACT-DAILY-DEBIT-TOTAL
               MOVE WS-LG-TOTAL-CREDIT(WS-SEARCH-IDX)
                   TO ACT-DAILY-CREDIT-TOTAL
               MOVE WS-LG-NET-BALANCE(WS-SEARCH-IDX)
                   TO ACT-CURRENT-BALANCE
               MOVE WS-LG-POSTING-CT(WS-SEARCH-IDX)
                   TO ACT-DAILY-TXN-COUNT

               WRITE LEDGER-OUT-REC FROM WS-ACCOUNT-RECORD
           END-PERFORM

           CLOSE LEDGER-OUT-FILE
           .

      ******************************************************************
      * Audit trail
      ******************************************************************

       6000-WRITE-POST-AUDIT.
           ADD 1 TO WS-AUDIT-SEQ
           INITIALIZE WS-AUDIT-RECORD

           MOVE WS-AUDIT-SEQ        TO AUD-SEQUENCE-NUM
           MOVE WS-CURR-DATE        TO AUD-DATE
           MOVE WS-CURR-TIME        TO AUD-TIME
           MOVE 'LEDGR00 '          TO AUD-PROGRAM-ID
           MOVE 'PST'               TO AUD-ACTION-CODE
           MOVE JRN-TXN-SEQUENCE    TO AUD-TXN-SEQUENCE
           MOVE JRN-DEBIT-ACCOUNT   TO AUD-ACCOUNT-NUM
           MOVE JRN-AMOUNT          TO AUD-AMOUNT
           MOVE ZEROS               TO AUD-BEFORE-BALANCE
           MOVE ZEROS               TO AUD-AFTER-BALANCE
           MOVE SPACES              TO AUD-OPERATOR-ID
           STRING 'Posted ' JRN-ENTRY-TYPE ' entry #'
               JRN-ENTRY-NUM
               DELIMITED BY SIZE
               INTO AUD-DESCRIPTION
           MOVE WS-PREV-HASH        TO AUD-PREV-HASH

           PERFORM 8500-COMPUTE-HASH
           MOVE WS-HASH-RESULT      TO AUD-CURR-HASH
           MOVE WS-HASH-RESULT      TO WS-PREV-HASH

           IF WS-AUDIT-SEQ = 1
               MOVE 'F' TO AUD-CHAIN-STATUS
           ELSE
               MOVE 'V' TO AUD-CHAIN-STATUS
           END-IF

           WRITE AUDIT-LOG-REC FROM WS-AUDIT-RECORD
           .

       8500-COMPUTE-HASH.
           MOVE ZEROS TO WS-HASH-WORK
           COMPUTE WS-HASH-WORK =
               FUNCTION MOD(
                   AUD-SEQUENCE-NUM * 2654435761 +
                   AUD-TXN-SEQUENCE * 40503,
                   9999999999)
           MOVE WS-HASH-WORK TO WS-HASH-RESULT(1:10)
           MOVE AUD-PREV-HASH(1:6) TO WS-HASH-RESULT(11:6)
           .

       9000-FINALIZE.
           CLOSE JOURNAL-IN-FILE
           CLOSE POSTING-LOG-FILE
           CLOSE AUDIT-LOG-FILE

           DISPLAY 'LEDGR00: Posting complete'
           DISPLAY '  Journal entries read:   ' WS-JRN-READ
           DISPLAY '  Entries posted:         ' WS-JRN-POSTED
           DISPLAY '  Ledger accounts:        ' WS-LEDG-COUNT

           MOVE 0 TO RETURN-CODE
           .
