      ******************************************************************
      * JRNREC.cpy - Journal Entry Record Layout
      * Enterprise Financial Transaction Processing System
      *
      * Implements double-entry bookkeeping. Every financial event
      * produces at least one journal entry with matching debit and
      * credit legs. The sum of all debits must equal the sum of all
      * credits — this invariant is verified during reconciliation.
      *
      * Record Length: 150 bytes
      ******************************************************************

       01  WS-JOURNAL-RECORD.
           05  JRN-ENTRY-NUM          PIC 9(10).
           05  JRN-TXN-SEQUENCE       PIC 9(10).
           05  JRN-DATE               PIC 9(08).
           05  JRN-TIME               PIC 9(06).
           05  JRN-DEBIT-ACCOUNT      PIC X(12).
           05  JRN-CREDIT-ACCOUNT     PIC X(12).
           05  JRN-AMOUNT             PIC 9(13)V99.
           05  JRN-ENTRY-TYPE         PIC X(03).
               88  JRN-IS-PRINCIPAL   VALUE 'PRI'.
               88  JRN-IS-FEE         VALUE 'FEE'.
               88  JRN-IS-INTEREST    VALUE 'INT'.
               88  JRN-IS-ADJUSTMENT  VALUE 'ADJ'.
           05  JRN-DESCRIPTION        PIC X(40).
           05  JRN-PROGRAM-ID         PIC X(08).
           05  JRN-STATUS             PIC X(01).
               88  JRN-POSTED         VALUE 'P'.
               88  JRN-PENDING        VALUE 'N'.
               88  JRN-REVERSED       VALUE 'R'.
           05  FILLER                 PIC X(20).
