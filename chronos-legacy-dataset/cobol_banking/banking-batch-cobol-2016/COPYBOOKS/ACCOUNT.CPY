      ******************************************************************
      * COPYBOOK: ACCOUNT.CPY
      * DESCRIPTION: ACCOUNT MASTER RECORD LAYOUT
      * DATE: 2016-01-15
      * AUTHOR: BANKING SYSTEMS TEAM
      ******************************************************************
       01  ACCOUNT-RECORD.
           05  ACCT-KEY.
               10  ACCT-NUMBER             PIC 9(16).
           05  ACCT-IDENTIFICATION.
               10  ACCT-TYPE               PIC X(2).
                   88  ACCT-SAVINGS        VALUE 'SA'.
                   88  ACCT-CHECKING       VALUE 'CC'.
                   88  ACCT-CREDIT-CARD    VALUE 'TC'.
                   88  ACCT-LOAN           VALUE 'LN'.
                   88  ACCT-INVESTMENT     VALUE 'IN'.
               10  ACCT-SUBTYPE            PIC X(3).
               10  ACCT-CURRENCY           PIC X(3).
                   88  CURRENCY-PEN        VALUE 'PEN'.
                   88  CURRENCY-USD        VALUE 'USD'.
                   88  CURRENCY-EUR        VALUE 'EUR'.
               10  ACCT-BRANCH-CODE        PIC X(4).
           05  ACCT-OWNERSHIP.
               10  ACCT-CUST-ID            PIC 9(10).
               10  ACCT-CO-OWNER-ID        PIC 9(10).
               10  ACCT-OWNERSHIP-TYPE     PIC X(1).
                   88  SINGLE-OWNER        VALUE 'S'.
                   88  JOINT-OWNER         VALUE 'J'.
           05  ACCT-BALANCE-INFO.
               10  ACCT-CURRENT-BALANCE    PIC S9(13)V99.
               10  ACCT-AVAILABLE-BALANCE  PIC S9(13)V99.
               10  ACCT-HOLD-AMOUNT        PIC 9(13)V99.
               10  ACCT-OVERDRAFT-LIMIT    PIC 9(11)V99.
               10  ACCT-MIN-BALANCE        PIC 9(11)V99.
           05  ACCT-INTEREST-INFO.
               10  ACCT-INTEREST-RATE      PIC 9(3)V9(4).
               10  ACCT-INTEREST-ACCUM     PIC 9(11)V99.
               10  ACCT-LAST-INT-DATE      PIC 9(8).
           05  ACCT-DATES.
               10  ACCT-OPEN-DATE          PIC 9(8).
               10  ACCT-LAST-TRANS-DATE    PIC 9(8).
               10  ACCT-LAST-STMT-DATE     PIC 9(8).
               10  ACCT-CLOSE-DATE         PIC 9(8).
               10  ACCT-MATURITY-DATE      PIC 9(8).
           05  ACCT-TRANSACTION-COUNTS.
               10  ACCT-MTD-DEBITS         PIC 9(7).
               10  ACCT-MTD-CREDITS        PIC 9(7).
               10  ACCT-YTD-DEBITS         PIC 9(9).
               10  ACCT-YTD-CREDITS        PIC 9(9).
           05  ACCT-STATUS-FLAGS.
               10  ACCT-STATUS             PIC X(1).
                   88  ACCT-ACTIVE         VALUE 'A'.
                   88  ACCT-INACTIVE       VALUE 'I'.
                   88  ACCT-SUSPENDED      VALUE 'S'.
                   88  ACCT-CLOSED         VALUE 'C'.
                   88  ACCT-DORMANT        VALUE 'D'.
               10  ACCT-FREEZE-FLAG        PIC X(1).
                   88  ACCT-FROZEN         VALUE 'Y'.
               10  ACCT-ALERT-FLAG         PIC X(1).
                   88  HAS-ALERT           VALUE 'Y'.
           05  ACCT-FEES.
               10  ACCT-MONTHLY-FEE        PIC 9(7)V99.
               10  ACCT-FEES-CHARGED-MTD   PIC 9(9)V99.
               10  ACCT-FEES-CHARGED-YTD   PIC 9(11)V99.
           05  ACCT-AUDIT-FIELDS.
               10  ACCT-CREATE-USER        PIC X(8).
               10  ACCT-CREATE-DATE        PIC 9(8).
               10  ACCT-CREATE-TIME        PIC 9(6).
               10  ACCT-UPDATE-USER        PIC X(8).
               10  ACCT-UPDATE-DATE        PIC 9(8).
               10  ACCT-UPDATE-TIME        PIC 9(6).
           05  FILLER                      PIC X(40).
