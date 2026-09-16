      ******************************************************************
      * RPTFLD.cpy - Report Formatting Fields and Constants
      * Enterprise Financial Transaction Processing System
      *
      * Shared report header, footer, and formatting definitions
      * used across RECON00 and REGRPT00 programs.
      *
      ******************************************************************

       01  WS-REPORT-HEADER.
           05  RPT-SEPARATOR           PIC X(80) VALUE ALL '='.
           05  RPT-DASH-LINE           PIC X(80) VALUE ALL '-'.
           05  RPT-BLANK-LINE          PIC X(80) VALUE SPACES.

       01  WS-REPORT-TITLE-LINE.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  RPT-INSTITUTION-NAME    PIC X(40)
               VALUE 'ENTERPRISE FINANCIAL SERVICES CORP.'.
           05  FILLER                  PIC X(10) VALUE SPACES.
           05  RPT-PAGE-LABEL         PIC X(06) VALUE 'PAGE: '.
           05  RPT-PAGE-NUM           PIC Z(04)9.

       01  WS-REPORT-DATE-LINE.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  RPT-REPORT-NAME         PIC X(40).
           05  FILLER                  PIC X(10) VALUE SPACES.
           05  RPT-DATE-LABEL          PIC X(06) VALUE 'DATE: '.
           05  RPT-RUN-DATE            PIC X(10).

       01  WS-REPORT-FOOTER.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  RPT-FOOTER-TEXT         PIC X(50)
               VALUE '*** END OF REPORT ***'.
           05  FILLER                  PIC X(25) VALUE SPACES.

       01  WS-REPORT-COUNTERS.
           05  RPT-CURRENT-PAGE        PIC 9(05) VALUE 0.
           05  RPT-LINES-ON-PAGE       PIC 9(03) VALUE 0.
           05  RPT-MAX-LINES           PIC 9(03) VALUE 55.
           05  RPT-TOTAL-LINES         PIC 9(07) VALUE 0.

       01  WS-REPORT-CONSTANTS.
           05  RPT-LINES-PER-PAGE      PIC 9(03) VALUE 55.
           05  RPT-BASEL-III-MIN       PIC 9V99   VALUE 0.08.
           05  RPT-LARGE-TXN-THRESH    PIC 9(13)V99
               VALUE 10000.00.
           05  RPT-HIGH-VOLUME-THRESH  PIC 9(05) VALUE 50.
           05  RPT-BALANCE-SWING-PCT   PIC 9(03) VALUE 200.
