      ******************************************************************
      * AUDREC.cpy - Audit Trail Record Layout
      * Enterprise Financial Transaction Processing System
      *
      * Implements a tamper-evident audit chain. Each record contains
      * a hash derived from its own key fields and the hash of the
      * previous record. Breaking any record invalidates all
      * subsequent hashes in the chain.
      *
      * Record Length: 250 bytes
      ******************************************************************

       01  WS-AUDIT-RECORD.
           05  AUD-SEQUENCE-NUM        PIC 9(10).
           05  AUD-DATE                PIC 9(08).
           05  AUD-TIME                PIC 9(06).
           05  AUD-PROGRAM-ID          PIC X(08).
           05  AUD-ACTION-CODE         PIC X(03).
               88  AUD-ACT-VALIDATE    VALUE 'VAL'.
               88  AUD-ACT-PROCESS     VALUE 'PRC'.
               88  AUD-ACT-POST        VALUE 'PST'.
               88  AUD-ACT-RECONCILE   VALUE 'REC'.
               88  AUD-ACT-REPORT      VALUE 'RPT'.
               88  AUD-ACT-REJECT      VALUE 'REJ'.
               88  AUD-ACT-SUSPEND     VALUE 'SUS'.
           05  AUD-TXN-SEQUENCE        PIC 9(10).
           05  AUD-ACCOUNT-NUM         PIC X(12).
           05  AUD-AMOUNT              PIC 9(13)V99.
           05  AUD-BEFORE-BALANCE      PIC S9(13)V99.
           05  AUD-AFTER-BALANCE       PIC S9(13)V99.
           05  AUD-OPERATOR-ID         PIC X(08).
           05  AUD-DESCRIPTION         PIC X(50).
           05  AUD-PREV-HASH           PIC X(16).
           05  AUD-CURR-HASH           PIC X(16).
           05  AUD-CHAIN-STATUS        PIC X(01).
               88  AUD-CHAIN-VALID     VALUE 'V'.
               88  AUD-CHAIN-BROKEN    VALUE 'B'.
               88  AUD-CHAIN-FIRST     VALUE 'F'.
           05  FILLER                  PIC X(57).
