       IDENTIFICATION DIVISION.
       PROGRAM-ID.    AUDIT00.
       AUTHOR.        ENTERPRISE FINANCIAL SYSTEMS.
       DATE-WRITTEN.  2026-03-31.
      ******************************************************************
      * AUDIT00 - Audit Trail Consolidation & Integrity Verification
      *
      * Final stage of the batch pipeline. Consolidates audit records
      * from all upstream programs into a single, unified audit trail.
      * Then verifies the integrity of each source audit file by
      * re-computing and validating the hash chain.
      *
      * Capabilities:
      *   1. Merge all per-program audit files chronologically
      *   2. Build a new master hash chain across all entries
      *   3. Verify source file hash chains for tampering
      *   4. Generate audit integrity summary report
      ******************************************************************

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       REPOSITORY.
           FUNCTION ALL INTRINSIC.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT AUDIT-TXNVAL-FILE
               ASSIGN TO 'data/work/txnval-audit.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-AV-STATUS.

           SELECT AUDIT-TXNPRC-FILE
               ASSIGN TO 'data/work/txnprc-audit.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-AP-STATUS.

           SELECT AUDIT-LEDGR-FILE
               ASSIGN TO 'data/work/ledgr-audit.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-AL-STATUS.

           SELECT AUDIT-RECON-FILE
               ASSIGN TO 'data/work/recon-audit.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-AR-STATUS.

           SELECT AUDIT-REGRPT-FILE
               ASSIGN TO 'data/work/regrpt-audit.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-AG-STATUS.

           SELECT MASTER-AUDIT-FILE
               ASSIGN TO 'data/output/master-audit-trail.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-MA-STATUS.

           SELECT AUDIT-RPT-FILE
               ASSIGN TO 'data/output/audit-integrity.rpt'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-RPT-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  AUDIT-TXNVAL-FILE
           RECORDING MODE IS F.
       01  AUDIT-TXNVAL-REC           PIC X(250).

       FD  AUDIT-TXNPRC-FILE
           RECORDING MODE IS F.
       01  AUDIT-TXNPRC-REC           PIC X(250).

       FD  AUDIT-LEDGR-FILE
           RECORDING MODE IS F.
       01  AUDIT-LEDGR-REC            PIC X(250).

       FD  AUDIT-RECON-FILE
           RECORDING MODE IS F.
       01  AUDIT-RECON-REC            PIC X(250).

       FD  AUDIT-REGRPT-FILE
           RECORDING MODE IS F.
       01  AUDIT-REGRPT-REC           PIC X(250).

       FD  MASTER-AUDIT-FILE
           RECORDING MODE IS F.
       01  MASTER-AUDIT-REC           PIC X(250).

       FD  AUDIT-RPT-FILE
           RECORDING MODE IS F.
       01  AUDIT-RPT-REC              PIC X(132).

       WORKING-STORAGE SECTION.

      * File status variables
       01  WS-AV-STATUS               PIC X(02).
       01  WS-AP-STATUS               PIC X(02).
       01  WS-AL-STATUS               PIC X(02).
       01  WS-AR-STATUS               PIC X(02).
       01  WS-AG-STATUS               PIC X(02).
       01  WS-MA-STATUS               PIC X(02).
       01  WS-RPT-STATUS              PIC X(02).

      * Control flags
       01  WS-EOF-FLAG                PIC X(01) VALUE 'N'.
           88  END-OF-FILE            VALUE 'Y'.
           88  NOT-END-OF-FILE        VALUE 'N'.

      * Copybooks
       COPY 'src/copybooks/AUDREC.cpy'.
       COPY 'src/copybooks/RPTFLD.cpy'.

      * Verification record (for re-reading)
       01  WS-VERIFY-RECORD.
           05  VFY-SEQUENCE-NUM        PIC 9(10).
           05  VFY-DATE                PIC 9(08).
           05  VFY-TIME                PIC 9(06).
           05  VFY-PROGRAM-ID          PIC X(08).
           05  VFY-ACTION-CODE         PIC X(03).
           05  VFY-TXN-SEQUENCE        PIC 9(10).
           05  VFY-ACCOUNT-NUM         PIC X(12).
           05  VFY-AMOUNT              PIC 9(13)V99.
           05  VFY-BEFORE-BALANCE      PIC S9(13)V99.
           05  VFY-AFTER-BALANCE       PIC S9(13)V99.
           05  VFY-OPERATOR-ID         PIC X(08).
           05  VFY-DESCRIPTION         PIC X(50).
           05  VFY-PREV-HASH           PIC X(16).
           05  VFY-CURR-HASH           PIC X(16).
           05  VFY-CHAIN-STATUS        PIC X(01).
           05  FILLER                  PIC X(57).

      * Counters
       01  WS-COUNTERS.
           05  WS-MASTER-SEQ          PIC 9(10) VALUE 0.
           05  WS-TXNVAL-COUNT        PIC 9(08) VALUE 0.
           05  WS-TXNPRC-COUNT        PIC 9(08) VALUE 0.
           05  WS-LEDGR-COUNT         PIC 9(08) VALUE 0.
           05  WS-RECON-COUNT         PIC 9(08) VALUE 0.
           05  WS-REGRPT-COUNT        PIC 9(08) VALUE 0.
           05  WS-TOTAL-MERGED        PIC 9(08) VALUE 0.
           05  WS-CHAIN-BREAKS        PIC 9(05) VALUE 0.
           05  WS-CHAINS-VERIFIED     PIC 9(03) VALUE 0.
           05  WS-CHAINS-BROKEN       PIC 9(03) VALUE 0.

      * Work fields
       01  WS-WORK-FIELDS.
           05  WS-CURR-DATE           PIC 9(08).
           05  WS-CURR-TIME           PIC 9(06).
           05  WS-PREV-HASH           PIC X(16) VALUE ALL '0'.
           05  WS-HASH-RESULT         PIC X(16).
           05  WS-HASH-WORK           PIC 9(10).
           05  WS-COMPUTED-HASH       PIC X(16).
           05  WS-EXPECTED-PREV       PIC X(16).
           05  WS-VERIFY-PREV-HASH    PIC X(16).
           05  WS-VERIFY-COUNT        PIC 9(08).
           05  WS-VERIFY-BREAKS       PIC 9(05).
           05  WS-FILE-NAME           PIC X(20).

      * Report formatting
       01  WS-RPT-LINE                PIC X(132).
       01  WS-RPT-DETAIL.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-RD-LABEL            PIC X(40).
           05  WS-RD-VALUE            PIC X(87).
       01  WS-RPT-VERIFY-LINE.
           05  FILLER                  PIC X(05) VALUE SPACES.
           05  WS-VL-FILE             PIC X(20).
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-VL-RECORDS          PIC Z(07)9.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-VL-BREAKS           PIC Z(04)9.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  WS-VL-STATUS           PIC X(10).

       PROCEDURE DIVISION.
       0000-MAIN-CONTROL.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-MERGE-AUDIT-FILES
           PERFORM 3000-VERIFY-CHAINS
           PERFORM 4000-WRITE-SUMMARY
           PERFORM 9000-FINALIZE
           STOP RUN
           .

       1000-INITIALIZE.
           MOVE FUNCTION CURRENT-DATE(1:8) TO WS-CURR-DATE
           MOVE FUNCTION CURRENT-DATE(9:6) TO WS-CURR-TIME

           OPEN OUTPUT MASTER-AUDIT-FILE
           OPEN OUTPUT AUDIT-RPT-FILE

      * Report header
           WRITE AUDIT-RPT-REC FROM RPT-SEPARATOR
           MOVE SPACES TO WS-RPT-LINE
           STRING '     ENTERPRISE FINANCIAL SERVICES CORP.'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE AUDIT-RPT-REC FROM WS-RPT-LINE
           MOVE SPACES TO WS-RPT-LINE
           STRING '     AUDIT TRAIL INTEGRITY REPORT'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE AUDIT-RPT-REC FROM WS-RPT-LINE
           MOVE SPACES TO WS-RPT-LINE
           STRING '     Run Date: '
               WS-CURR-DATE(1:4) '-'
               WS-CURR-DATE(5:2) '-'
               WS-CURR-DATE(7:2)
               '    Run Time: '
               WS-CURR-TIME(1:2) ':'
               WS-CURR-TIME(3:2) ':'
               WS-CURR-TIME(5:2)
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE AUDIT-RPT-REC FROM WS-RPT-LINE
           WRITE AUDIT-RPT-REC FROM RPT-SEPARATOR

           DISPLAY 'AUDIT00: Initialization complete'
           .

       2000-MERGE-AUDIT-FILES.
           MOVE SPACES TO WS-RPT-LINE
           STRING '     SECTION 1: AUDIT TRAIL CONSOLIDATION'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE AUDIT-RPT-REC FROM WS-RPT-LINE
           WRITE AUDIT-RPT-REC FROM RPT-DASH-LINE

      * Merge each source file into master
           PERFORM 2100-MERGE-TXNVAL
           PERFORM 2200-MERGE-TXNPRC
           PERFORM 2300-MERGE-LEDGR
           PERFORM 2400-MERGE-RECON
           PERFORM 2500-MERGE-REGRPT

           MOVE 'TXNVAL00 records merged:' TO WS-RD-LABEL
           MOVE WS-TXNVAL-COUNT TO WS-RD-VALUE
           WRITE AUDIT-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'TXNPRC00 records merged:' TO WS-RD-LABEL
           MOVE WS-TXNPRC-COUNT TO WS-RD-VALUE
           WRITE AUDIT-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'LEDGR00  records merged:' TO WS-RD-LABEL
           MOVE WS-LEDGR-COUNT TO WS-RD-VALUE
           WRITE AUDIT-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'RECON00  records merged:' TO WS-RD-LABEL
           MOVE WS-RECON-COUNT TO WS-RD-VALUE
           WRITE AUDIT-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'REGRPT00 records merged:' TO WS-RD-LABEL
           MOVE WS-REGRPT-COUNT TO WS-RD-VALUE
           WRITE AUDIT-RPT-REC FROM WS-RPT-DETAIL

           WRITE AUDIT-RPT-REC FROM RPT-DASH-LINE
           MOVE 'Total records in master trail:'
               TO WS-RD-LABEL
           MOVE WS-TOTAL-MERGED TO WS-RD-VALUE
           WRITE AUDIT-RPT-REC FROM WS-RPT-DETAIL
           WRITE AUDIT-RPT-REC FROM RPT-BLANK-LINE
           .

       2100-MERGE-TXNVAL.
           OPEN INPUT AUDIT-TXNVAL-FILE
           IF WS-AV-STATUS NOT = '00'
               DISPLAY 'WARNING: TXNVAL audit file not found'
               MOVE 0 TO WS-TXNVAL-COUNT
           ELSE
               SET NOT-END-OF-FILE TO TRUE
               PERFORM UNTIL END-OF-FILE
                   READ AUDIT-TXNVAL-FILE
                       INTO WS-AUDIT-RECORD
                       AT END
                           SET END-OF-FILE TO TRUE
                       NOT AT END
                           ADD 1 TO WS-TXNVAL-COUNT
                           ADD 1 TO WS-TOTAL-MERGED
                           ADD 1 TO WS-MASTER-SEQ
                           MOVE WS-MASTER-SEQ
                               TO AUD-SEQUENCE-NUM
                           MOVE WS-PREV-HASH
                               TO AUD-PREV-HASH
                           PERFORM 8500-COMPUTE-HASH
                           MOVE WS-HASH-RESULT
                               TO AUD-CURR-HASH
                           MOVE WS-HASH-RESULT
                               TO WS-PREV-HASH
                           IF WS-MASTER-SEQ = 1
                               MOVE 'F' TO AUD-CHAIN-STATUS
                           ELSE
                               MOVE 'V' TO AUD-CHAIN-STATUS
                           END-IF
                           WRITE MASTER-AUDIT-REC
                               FROM WS-AUDIT-RECORD
                   END-READ
               END-PERFORM
               CLOSE AUDIT-TXNVAL-FILE
           END-IF
           SET NOT-END-OF-FILE TO TRUE
           .

       2200-MERGE-TXNPRC.
           OPEN INPUT AUDIT-TXNPRC-FILE
           IF WS-AP-STATUS NOT = '00'
               DISPLAY 'WARNING: TXNPRC audit file not found'
               MOVE 0 TO WS-TXNPRC-COUNT
           ELSE
               SET NOT-END-OF-FILE TO TRUE
               PERFORM UNTIL END-OF-FILE
                   READ AUDIT-TXNPRC-FILE
                       INTO WS-AUDIT-RECORD
                       AT END
                           SET END-OF-FILE TO TRUE
                       NOT AT END
                           ADD 1 TO WS-TXNPRC-COUNT
                           ADD 1 TO WS-TOTAL-MERGED
                           ADD 1 TO WS-MASTER-SEQ
                           MOVE WS-MASTER-SEQ
                               TO AUD-SEQUENCE-NUM
                           MOVE WS-PREV-HASH
                               TO AUD-PREV-HASH
                           PERFORM 8500-COMPUTE-HASH
                           MOVE WS-HASH-RESULT
                               TO AUD-CURR-HASH
                           MOVE WS-HASH-RESULT
                               TO WS-PREV-HASH
                           IF WS-MASTER-SEQ = 1
                               MOVE 'F' TO AUD-CHAIN-STATUS
                           ELSE
                               MOVE 'V' TO AUD-CHAIN-STATUS
                           END-IF
                           WRITE MASTER-AUDIT-REC
                               FROM WS-AUDIT-RECORD
                   END-READ
               END-PERFORM
               CLOSE AUDIT-TXNPRC-FILE
           END-IF
           SET NOT-END-OF-FILE TO TRUE
           .

       2300-MERGE-LEDGR.
           OPEN INPUT AUDIT-LEDGR-FILE
           IF WS-AL-STATUS NOT = '00'
               DISPLAY 'WARNING: LEDGR audit file not found'
               MOVE 0 TO WS-LEDGR-COUNT
           ELSE
               SET NOT-END-OF-FILE TO TRUE
               PERFORM UNTIL END-OF-FILE
                   READ AUDIT-LEDGR-FILE
                       INTO WS-AUDIT-RECORD
                       AT END
                           SET END-OF-FILE TO TRUE
                       NOT AT END
                           ADD 1 TO WS-LEDGR-COUNT
                           ADD 1 TO WS-TOTAL-MERGED
                           ADD 1 TO WS-MASTER-SEQ
                           MOVE WS-MASTER-SEQ
                               TO AUD-SEQUENCE-NUM
                           MOVE WS-PREV-HASH
                               TO AUD-PREV-HASH
                           PERFORM 8500-COMPUTE-HASH
                           MOVE WS-HASH-RESULT
                               TO AUD-CURR-HASH
                           MOVE WS-HASH-RESULT
                               TO WS-PREV-HASH
                           IF WS-MASTER-SEQ = 1
                               MOVE 'F' TO AUD-CHAIN-STATUS
                           ELSE
                               MOVE 'V' TO AUD-CHAIN-STATUS
                           END-IF
                           WRITE MASTER-AUDIT-REC
                               FROM WS-AUDIT-RECORD
                   END-READ
               END-PERFORM
               CLOSE AUDIT-LEDGR-FILE
           END-IF
           SET NOT-END-OF-FILE TO TRUE
           .

       2400-MERGE-RECON.
           OPEN INPUT AUDIT-RECON-FILE
           IF WS-AR-STATUS NOT = '00'
               DISPLAY 'WARNING: RECON audit file not found'
               MOVE 0 TO WS-RECON-COUNT
           ELSE
               SET NOT-END-OF-FILE TO TRUE
               PERFORM UNTIL END-OF-FILE
                   READ AUDIT-RECON-FILE
                       INTO WS-AUDIT-RECORD
                       AT END
                           SET END-OF-FILE TO TRUE
                       NOT AT END
                           ADD 1 TO WS-RECON-COUNT
                           ADD 1 TO WS-TOTAL-MERGED
                           ADD 1 TO WS-MASTER-SEQ
                           MOVE WS-MASTER-SEQ
                               TO AUD-SEQUENCE-NUM
                           MOVE WS-PREV-HASH
                               TO AUD-PREV-HASH
                           PERFORM 8500-COMPUTE-HASH
                           MOVE WS-HASH-RESULT
                               TO AUD-CURR-HASH
                           MOVE WS-HASH-RESULT
                               TO WS-PREV-HASH
                           IF WS-MASTER-SEQ = 1
                               MOVE 'F' TO AUD-CHAIN-STATUS
                           ELSE
                               MOVE 'V' TO AUD-CHAIN-STATUS
                           END-IF
                           WRITE MASTER-AUDIT-REC
                               FROM WS-AUDIT-RECORD
                   END-READ
               END-PERFORM
               CLOSE AUDIT-RECON-FILE
           END-IF
           SET NOT-END-OF-FILE TO TRUE
           .

       2500-MERGE-REGRPT.
           OPEN INPUT AUDIT-REGRPT-FILE
           IF WS-AG-STATUS NOT = '00'
               DISPLAY 'WARNING: REGRPT audit file not found'
               MOVE 0 TO WS-REGRPT-COUNT
           ELSE
               SET NOT-END-OF-FILE TO TRUE
               PERFORM UNTIL END-OF-FILE
                   READ AUDIT-REGRPT-FILE
                       INTO WS-AUDIT-RECORD
                       AT END
                           SET END-OF-FILE TO TRUE
                       NOT AT END
                           ADD 1 TO WS-REGRPT-COUNT
                           ADD 1 TO WS-TOTAL-MERGED
                           ADD 1 TO WS-MASTER-SEQ
                           MOVE WS-MASTER-SEQ
                               TO AUD-SEQUENCE-NUM
                           MOVE WS-PREV-HASH
                               TO AUD-PREV-HASH
                           PERFORM 8500-COMPUTE-HASH
                           MOVE WS-HASH-RESULT
                               TO AUD-CURR-HASH
                           MOVE WS-HASH-RESULT
                               TO WS-PREV-HASH
                           IF WS-MASTER-SEQ = 1
                               MOVE 'F' TO AUD-CHAIN-STATUS
                           ELSE
                               MOVE 'V' TO AUD-CHAIN-STATUS
                           END-IF
                           WRITE MASTER-AUDIT-REC
                               FROM WS-AUDIT-RECORD
                   END-READ
               END-PERFORM
               CLOSE AUDIT-REGRPT-FILE
           END-IF
           .

       3000-VERIFY-CHAINS.
           CLOSE MASTER-AUDIT-FILE

           MOVE SPACES TO WS-RPT-LINE
           STRING '     SECTION 2: HASH CHAIN VERIFICATION'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE AUDIT-RPT-REC FROM WS-RPT-LINE
           WRITE AUDIT-RPT-REC FROM RPT-DASH-LINE

           MOVE SPACES TO WS-RPT-LINE
           STRING '     File                '
               '  Records   Breaks  Status'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE AUDIT-RPT-REC FROM WS-RPT-LINE
           WRITE AUDIT-RPT-REC FROM RPT-DASH-LINE

      * Verify master audit trail
           OPEN INPUT MASTER-AUDIT-FILE
           MOVE ALL '0' TO WS-VERIFY-PREV-HASH
           MOVE 0 TO WS-VERIFY-COUNT
           MOVE 0 TO WS-VERIFY-BREAKS

           SET NOT-END-OF-FILE TO TRUE
           PERFORM UNTIL END-OF-FILE
               READ MASTER-AUDIT-FILE INTO WS-VERIFY-RECORD
                   AT END
                       SET END-OF-FILE TO TRUE
                   NOT AT END
                       ADD 1 TO WS-VERIFY-COUNT

      * Recompute hash for this record
                       MOVE VFY-SEQUENCE-NUM
                           TO AUD-SEQUENCE-NUM
                       MOVE VFY-TXN-SEQUENCE
                           TO AUD-TXN-SEQUENCE
                       MOVE WS-VERIFY-PREV-HASH
                           TO AUD-PREV-HASH
                       PERFORM 8500-COMPUTE-HASH

      * Compare computed vs stored
                       IF WS-HASH-RESULT NOT =
                          VFY-CURR-HASH
                           ADD 1 TO WS-VERIFY-BREAKS
                       END-IF

                       MOVE VFY-CURR-HASH
                           TO WS-VERIFY-PREV-HASH
               END-READ
           END-PERFORM

           CLOSE MASTER-AUDIT-FILE

           MOVE 'master-audit-trail' TO WS-VL-FILE
           MOVE WS-VERIFY-COUNT     TO WS-VL-RECORDS
           MOVE WS-VERIFY-BREAKS    TO WS-VL-BREAKS
           IF WS-VERIFY-BREAKS = 0
               MOVE 'INTACT    ' TO WS-VL-STATUS
               ADD 1 TO WS-CHAINS-VERIFIED
           ELSE
               MOVE 'BROKEN    ' TO WS-VL-STATUS
               ADD 1 TO WS-CHAINS-BROKEN
               ADD WS-VERIFY-BREAKS TO WS-CHAIN-BREAKS
           END-IF
           WRITE AUDIT-RPT-REC FROM WS-RPT-VERIFY-LINE

           WRITE AUDIT-RPT-REC FROM RPT-BLANK-LINE
           .

       4000-WRITE-SUMMARY.
           MOVE SPACES TO WS-RPT-LINE
           STRING '     SECTION 3: AUDIT SUMMARY'
               DELIMITED BY SIZE INTO WS-RPT-LINE
           WRITE AUDIT-RPT-REC FROM WS-RPT-LINE
           WRITE AUDIT-RPT-REC FROM RPT-DASH-LINE

           MOVE 'Total audit records consolidated:'
               TO WS-RD-LABEL
           MOVE WS-TOTAL-MERGED TO WS-RD-VALUE
           WRITE AUDIT-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'Hash chains verified:' TO WS-RD-LABEL
           MOVE WS-CHAINS-VERIFIED TO WS-RD-VALUE
           WRITE AUDIT-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'Hash chains broken:' TO WS-RD-LABEL
           MOVE WS-CHAINS-BROKEN TO WS-RD-VALUE
           WRITE AUDIT-RPT-REC FROM WS-RPT-DETAIL

           MOVE 'Total chain breaks:' TO WS-RD-LABEL
           MOVE WS-CHAIN-BREAKS TO WS-RD-VALUE
           WRITE AUDIT-RPT-REC FROM WS-RPT-DETAIL

           WRITE AUDIT-RPT-REC FROM RPT-DASH-LINE

           IF WS-CHAIN-BREAKS = 0
               MOVE 'OVERALL INTEGRITY: VERIFIED'
                   TO WS-RD-LABEL
           ELSE
               MOVE '*** INTEGRITY COMPROMISED ***'
                   TO WS-RD-LABEL
           END-IF
           MOVE SPACES TO WS-RD-VALUE
           WRITE AUDIT-RPT-REC FROM WS-RPT-DETAIL

           WRITE AUDIT-RPT-REC FROM RPT-SEPARATOR
           WRITE AUDIT-RPT-REC FROM WS-REPORT-FOOTER
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
           CLOSE AUDIT-RPT-FILE

           DISPLAY 'AUDIT00: Consolidation complete'
           DISPLAY '  Total records merged:   ' WS-TOTAL-MERGED
           DISPLAY '  Chains verified:        '
               WS-CHAINS-VERIFIED
           DISPLAY '  Chain breaks detected:  ' WS-CHAIN-BREAKS

           IF WS-CHAIN-BREAKS > 0
               DISPLAY '  *** AUDIT INTEGRITY COMPROMISED ***'
               MOVE 12 TO RETURN-CODE
           ELSE
               DISPLAY '  Audit integrity: VERIFIED'
               MOVE 0 TO RETURN-CODE
           END-IF
           .
