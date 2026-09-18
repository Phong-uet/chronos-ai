      ******************************************************************
      * TXNREC.cpy - Transaction Record Layout
      * Enterprise Financial Transaction Processing System
      *
      * Defines the canonical transaction record used across all
      * pipeline stages. Fixed-width sequential file format.
      *
      * Record Length: 200 bytes
      ******************************************************************

       01  WS-TRANSACTION-RECORD.
           05  TXN-SEQUENCE-NUM        PIC 9(10).
           05  TXN-DATE                PIC 9(08).
           05  TXN-TIME                PIC 9(06).
           05  TXN-TYPE                PIC X(03).
               88  TXN-IS-DEPOSIT      VALUE 'DEP'.
               88  TXN-IS-WITHDRAWAL   VALUE 'WDR'.
               88  TXN-IS-TRANSFER     VALUE 'XFR'.
               88  TXN-IS-FEE          VALUE 'FEE'.
               88  TXN-IS-INTEREST     VALUE 'INT'.
               88  TXN-IS-ADJUSTMENT   VALUE 'ADJ'.
           05  TXN-SOURCE-ACCOUNT      PIC X(12).
           05  TXN-TARGET-ACCOUNT      PIC X(12).
           05  TXN-AMOUNT              PIC 9(13)V99.
           05  TXN-CURRENCY            PIC X(03).
           05  TXN-DESCRIPTION         PIC X(40).
           05  TXN-OPERATOR-ID         PIC X(08).
           05  TXN-BRANCH-CODE         PIC X(06).
           05  TXN-REASON-CODE         PIC X(04).
           05  TXN-STATUS              PIC X(01).
               88  TXN-PENDING         VALUE 'P'.
               88  TXN-VALIDATED       VALUE 'V'.
               88  TXN-PROCESSED       VALUE 'C'.
               88  TXN-REJECTED        VALUE 'R'.
               88  TXN-SUSPENDED       VALUE 'S'.
           05  TXN-ERROR-CODE          PIC X(03).
           05  TXN-BATCH-ID            PIC 9(06).
           05  TXN-CHECKSUM            PIC X(16).
           05  FILLER                  PIC X(48).
