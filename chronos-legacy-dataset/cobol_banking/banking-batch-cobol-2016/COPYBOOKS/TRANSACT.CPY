      ******************************************************************
      * COPYBOOK: TRANSACT.CPY
      * DESCRIPTION: TRANSACTION RECORD LAYOUT
      * DATE: 2016-01-15
      * AUTHOR: BANKING SYSTEMS TEAM
      ******************************************************************
       01  TRANSACTION-RECORD.
           05  TRANS-KEY.
               10  TRANS-ID                PIC 9(18).
               10  TRANS-SEQ               PIC 9(6).
           05  TRANS-IDENTIFICATION.
               10  TRANS-TYPE              PIC X(3).
                   88  TRANS-DEPOSIT       VALUE 'DEP'.
                   88  TRANS-WITHDRAWAL    VALUE 'WDR'.
                   88  TRANS-TRANSFER      VALUE 'TRF'.
                   88  TRANS-PAYMENT       VALUE 'PMT'.
                   88  TRANS-FEE           VALUE 'FEE'.
                   88  TRANS-INTEREST      VALUE 'INT'.
                   88  TRANS-ADJUSTMENT    VALUE 'ADJ'.
                   88  TRANS-REVERSAL      VALUE 'REV'.
               10  TRANS-CODE              PIC X(4).
               10  TRANS-CHANNEL           PIC X(3).
                   88  CHANNEL-BRANCH      VALUE 'BRA'.
                   88  CHANNEL-ATM         VALUE 'ATM'.
                   88  CHANNEL-ONLINE      VALUE 'ONL'.
                   88  CHANNEL-MOBILE      VALUE 'MOB'.
                   88  CHANNEL-BATCH       VALUE 'BCH'.
           05  TRANS-ACCOUNT-INFO.
               10  TRANS-ACCT-NUMBER       PIC 9(16).
               10  TRANS-DEST-ACCT         PIC 9(16).
               10  TRANS-CURRENCY          PIC X(3).
           05  TRANS-AMOUNTS.
               10  TRANS-AMOUNT            PIC S9(13)V99.
               10  TRANS-FEE-AMOUNT        PIC 9(9)V99.
               10  TRANS-BALANCE-BEFORE    PIC S9(13)V99.
               10  TRANS-BALANCE-AFTER     PIC S9(13)V99.
           05  TRANS-DATE-TIME.
               10  TRANS-DATE              PIC 9(8).
               10  TRANS-TIME              PIC 9(6).
               10  TRANS-BUSINESS-DATE     PIC 9(8).
               10  TRANS-POST-DATE         PIC 9(8).
           05  TRANS-LOCATION.
               10  TRANS-BRANCH-CODE       PIC X(4).
               10  TRANS-TERMINAL-ID       PIC X(8).
               10  TRANS-ATM-ID            PIC X(10).
           05  TRANS-AUTHORIZATION.
               10  TRANS-AUTH-CODE         PIC X(12).
               10  TRANS-AUTH-USER         PIC X(8).
               10  TRANS-AUTH-METHOD       PIC X(2).
                   88  AUTH-PASSWORD       VALUE 'PW'.
                   88  AUTH-TOKEN          VALUE 'TK'.
                   88  AUTH-BIOMETRIC      VALUE 'BM'.
           05  TRANS-STATUS.
               10  TRANS-STATUS-CODE       PIC X(1).
                   88  TRANS-PENDING       VALUE 'P'.
                   88  TRANS-COMPLETED     VALUE 'C'.
                   88  TRANS-FAILED        VALUE 'F'.
                   88  TRANS-REVERSED      VALUE 'R'.
               10  TRANS-ERROR-CODE        PIC X(4).
               10  TRANS-ERROR-DESC        PIC X(50).
           05  TRANS-DESCRIPTION.
               10  TRANS-REFERENCE         PIC X(20).
               10  TRANS-REMARKS           PIC X(100).
               10  TRANS-CHECK-NUMBER      PIC X(15).
           05  TRANS-AUDIT.
               10  TRANS-CREATE-USER       PIC X(8).
               10  TRANS-CREATE-TIMESTAMP  PIC X(26).
               10  TRANS-UPDATE-USER       PIC X(8).
               10  TRANS-UPDATE-TIMESTAMP  PIC X(26).
           05  FILLER                      PIC X(30).
