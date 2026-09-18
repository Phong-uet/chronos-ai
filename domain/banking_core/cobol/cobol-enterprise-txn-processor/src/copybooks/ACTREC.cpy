      ******************************************************************
      * ACTREC.cpy - Account Master Record Layout
      * Enterprise Financial Transaction Processing System
      *
      * Defines the account master file record. Each account carries
      * its balance, tier classification, risk weighting, and status.
      *
      * Record Length: 200 bytes
      ******************************************************************

       01  WS-ACCOUNT-RECORD.
           05  ACT-ACCOUNT-NUM         PIC X(12).
           05  ACT-ACCOUNT-NAME        PIC X(30).
           05  ACT-ACCOUNT-TYPE        PIC X(03).
               88  ACT-IS-CHECKING     VALUE 'CHK'.
               88  ACT-IS-SAVINGS      VALUE 'SAV'.
               88  ACT-IS-LOAN         VALUE 'LON'.
               88  ACT-IS-SUSPENSE     VALUE 'SUS'.
               88  ACT-IS-INTERNAL     VALUE 'INT'.
           05  ACT-TIER                PIC X(01).
               88  ACT-TIER-STANDARD   VALUE 'S'.
               88  ACT-TIER-PREMIUM    VALUE 'P'.
               88  ACT-TIER-INSTITUT   VALUE 'I'.
           05  ACT-STATUS              PIC X(01).
               88  ACT-ACTIVE          VALUE 'A'.
               88  ACT-FROZEN          VALUE 'F'.
               88  ACT-CLOSED          VALUE 'C'.
               88  ACT-DORMANT         VALUE 'D'.
           05  ACT-CURRENCY            PIC X(03).
           05  ACT-OPENING-BALANCE     PIC S9(13)V99.
           05  ACT-CURRENT-BALANCE     PIC S9(13)V99.
           05  ACT-DAILY-DEBIT-TOTAL   PIC 9(13)V99.
           05  ACT-DAILY-CREDIT-TOTAL  PIC 9(13)V99.
           05  ACT-DAILY-TXN-COUNT     PIC 9(05).
           05  ACT-DAILY-XFR-TOTAL     PIC 9(13)V99.
           05  ACT-DAILY-XFR-LIMIT     PIC 9(13)V99.
           05  ACT-OVERDRAFT-LIMIT     PIC 9(13)V99.
           05  ACT-RISK-WEIGHT         PIC 9V99.
           05  ACT-SECTOR-CODE         PIC X(04).
           05  ACT-OPEN-DATE           PIC 9(08).
           05  ACT-LAST-TXN-DATE       PIC 9(08).
           05  ACT-BRANCH-CODE         PIC X(06).
           05  FILLER                  PIC X(13).
