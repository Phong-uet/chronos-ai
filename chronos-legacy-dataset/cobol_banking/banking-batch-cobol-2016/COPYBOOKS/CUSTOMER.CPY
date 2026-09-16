      ******************************************************************
      * COPYBOOK: CUSTOMER.CPY
      * DESCRIPTION: CUSTOMER MASTER RECORD LAYOUT
      * DATE: 2016-01-15
      * AUTHOR: BANKING SYSTEMS TEAM
      ******************************************************************
       01  CUSTOMER-RECORD.
           05  CUST-KEY.
               10  CUST-ID                 PIC 9(10).
           05  CUST-PERSONAL-DATA.
               10  CUST-FIRST-NAME         PIC X(30).
               10  CUST-LAST-NAME          PIC X(30).
               10  CUST-MIDDLE-INIT        PIC X(1).
               10  CUST-DOC-TYPE           PIC X(3).
                   88  DOC-DNI             VALUE 'DNI'.
                   88  DOC-CE              VALUE 'CE '.
                   88  DOC-RUC             VALUE 'RUC'.
               10  CUST-DOC-NUMBER         PIC X(15).
               10  CUST-BIRTH-DATE         PIC 9(8).
               10  CUST-GENDER             PIC X(1).
                   88  GENDER-MALE         VALUE 'M'.
                   88  GENDER-FEMALE       VALUE 'F'.
           05  CUST-CONTACT-INFO.
               10  CUST-ADDRESS            PIC X(100).
               10  CUST-CITY               PIC X(30).
               10  CUST-STATE              PIC X(30).
               10  CUST-ZIP-CODE           PIC X(10).
               10  CUST-PHONE              PIC X(15).
               10  CUST-EMAIL              PIC X(50).
           05  CUST-FINANCIAL-DATA.
               10  CUST-CREDIT-RATING      PIC 9(3).
               10  CUST-CREDIT-LIMIT       PIC 9(11)V99.
               10  CUST-TOTAL-BALANCE      PIC S9(13)V99.
               10  CUST-OPEN-DATE          PIC 9(8).
               10  CUST-LAST-TRANS-DATE    PIC 9(8).
           05  CUST-STATUS-FLAGS.
               10  CUST-STATUS             PIC X(1).
                   88  CUST-ACTIVE         VALUE 'A'.
                   88  CUST-INACTIVE       VALUE 'I'.
                   88  CUST-SUSPENDED      VALUE 'S'.
                   88  CUST-CLOSED         VALUE 'C'.
               10  CUST-VIP-FLAG           PIC X(1).
                   88  IS-VIP              VALUE 'Y'.
               10  CUST-MARKETING-FLAG     PIC X(1).
                   88  ACCEPTS-MARKETING   VALUE 'Y'.
           05  CUST-AUDIT-FIELDS.
               10  CUST-CREATE-USER        PIC X(8).
               10  CUST-CREATE-DATE        PIC 9(8).
               10  CUST-CREATE-TIME        PIC 9(6).
               10  CUST-UPDATE-USER        PIC X(8).
               10  CUST-UPDATE-DATE        PIC 9(8).
               10  CUST-UPDATE-TIME        PIC 9(6).
           05  FILLER                      PIC X(50).
