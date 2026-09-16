      ******************************************************************
      * ERRREC.cpy - Error / Exception Record Layout
      * Enterprise Financial Transaction Processing System
      *
      * Captures validation and processing errors with full context
      * for reprocessing and audit purposes. The original transaction
      * data is preserved alongside the error classification.
      *
      * Record Length: 180 bytes
      ******************************************************************

       01  WS-ERROR-RECORD.
           05  ERR-SEQUENCE-NUM        PIC 9(10).
           05  ERR-TXN-SEQUENCE        PIC 9(10).
           05  ERR-DATE                PIC 9(08).
           05  ERR-TIME                PIC 9(06).
           05  ERR-CODE                PIC X(03).
               88  ERR-INVALID-ACCT    VALUE 'E01'.
               88  ERR-INSUF-FUNDS     VALUE 'E02'.
               88  ERR-ACCT-FROZEN     VALUE 'E03'.
               88  ERR-DAILY-LIMIT     VALUE 'E04'.
               88  ERR-CURRENCY-MIS    VALUE 'E05'.
               88  ERR-DUPLICATE       VALUE 'E06'.
               88  ERR-INVALID-TYPE    VALUE 'E07'.
               88  ERR-AMOUNT-BOUNDS   VALUE 'E08'.
           05  ERR-SEVERITY            PIC X(01).
               88  ERR-SEV-WARNING     VALUE 'W'.
               88  ERR-SEV-ERROR       VALUE 'E'.
               88  ERR-SEV-CRITICAL    VALUE 'C'.
           05  ERR-PROGRAM-ID          PIC X(08).
           05  ERR-DESCRIPTION         PIC X(50).
           05  ERR-SOURCE-ACCOUNT      PIC X(12).
           05  ERR-TARGET-ACCOUNT      PIC X(12).
           05  ERR-AMOUNT              PIC 9(13)V99.
           05  ERR-ORIGINAL-TYPE       PIC X(03).
           05  ERR-REPROCESS-FLAG      PIC X(01).
               88  ERR-CAN-REPROCESS   VALUE 'Y'.
               88  ERR-NO-REPROCESS    VALUE 'N'.
           05  FILLER                  PIC X(26).
