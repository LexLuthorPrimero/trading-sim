       IDENTIFICATION DIVISION.
       PROGRAM-ID. STOCHASTIC.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PRICES-FILE ASSIGN TO DYNAMIC WS-PRICES-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FS.
       DATA DIVISION.
       FILE SECTION.
       FD  PRICES-FILE.
       01  PRICE-RECORD.
           05 PRICE-HIGH-RAW PIC X(10).
           05 FILLER         PIC X.
           05 PRICE-LOW-RAW  PIC X(10).
           05 FILLER         PIC X.
           05 PRICE-CLOSE-RAW PIC X(10).
       WORKING-STORAGE SECTION.
       01  WS-FS            PIC XX.
           88  WS-FS-OK     VALUE "00".
           88  WS-FS-EOF    VALUE "10".
       01  WS-PRICES-PATH   PIC X(200).
       01  WS-PRICES-TABLE.
           05 WS-PRICE-ENTRY OCCURS 1000 TIMES
              INDEXED BY PRICE-IDX.
              10 WS-HIGH-COMP3   PIC 9(5)V99 COMP-3.
              10 WS-LOW-COMP3    PIC 9(5)V99 COMP-3.
              10 WS-CLOSE-COMP3  PIC 9(5)V99 COMP-3.
       01  WS-COUNT         PIC 9(4) COMP.
       01  WS-I             PIC 9(4) COMP.
       01  WS-J             PIC 9(4) COMP.
       01  WS-K-PERIOD      PIC 9(2) COMP VALUE 14.
       01  WS-D-PERIOD      PIC 9(2) COMP VALUE 3.
       01  WS-HIGHEST       PIC 9(5)V99 COMP-3.
       01  WS-LOWEST        PIC 9(5)V99 COMP-3.
       01  WS-PCT-K         PIC 9(3)V99.
       01  WS-PCT-D         PIC 9(3)V99.
       01  WS-SUM-D         PIC 9(5)V99 COMP-3.
       01  WS-START-IDX     PIC 9(4) COMP.
       01  WS-START-D       PIC 9(4) COMP.
       PROCEDURE DIVISION.
       MAIN.
           PERFORM INPUT-PRICES.
           IF WS-COUNT < WS-K-PERIOD
               DISPLAY "ERROR: Need at least " WS-K-PERIOD " prices"
               PERFORM CLEANUP
               STOP RUN
           END-IF.
           PERFORM PROCESS-STOCH.
           PERFORM CLEANUP.
           STOP RUN.

       INPUT-PRICES.
           ACCEPT WS-PRICES-PATH FROM COMMAND-LINE.
           IF WS-PRICES-PATH = SPACES
               MOVE "prices.dat" TO WS-PRICES-PATH
           END-IF.
           OPEN INPUT PRICES-FILE.
           IF NOT WS-FS-OK
               DISPLAY "ERROR: Cannot open " WS-PRICES-PATH
               STOP RUN
           END-IF.
           MOVE 0 TO WS-COUNT.
           PERFORM UNTIL WS-FS-EOF
               READ PRICES-FILE INTO PRICE-RECORD
                   AT END SET WS-FS-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO WS-COUNT
                       COMPUTE WS-HIGH-COMP3(WS-COUNT) = 
                           FUNCTION NUMVAL(PRICE-HIGH-RAW)
                       COMPUTE WS-LOW-COMP3(WS-COUNT) = 
                           FUNCTION NUMVAL(PRICE-LOW-RAW)
                       COMPUTE WS-CLOSE-COMP3(WS-COUNT) = 
                           FUNCTION NUMVAL(PRICE-CLOSE-RAW)
               END-READ
           END-PERFORM.
           CLOSE PRICES-FILE.

       PROCESS-STOCH.
           PERFORM VARYING WS-I FROM WS-K-PERIOD BY 1
                   UNTIL WS-I > WS-COUNT
               MOVE WS-HIGH-COMP3(WS-I) TO WS-HIGHEST
               MOVE WS-LOW-COMP3(WS-I) TO WS-LOWEST
               COMPUTE WS-START-IDX = WS-I - WS-K-PERIOD + 1
               PERFORM VARYING WS-J FROM WS-START-IDX BY 1
                       UNTIL WS-J > WS-I
                   IF WS-HIGH-COMP3(WS-J) > WS-HIGHEST
                       MOVE WS-HIGH-COMP3(WS-J) TO WS-HIGHEST
                   END-IF
                   IF WS-LOW-COMP3(WS-J) < WS-LOWEST
                       MOVE WS-LOW-COMP3(WS-J) TO WS-LOWEST
                   END-IF
               END-PERFORM
               COMPUTE WS-PCT-K = 100 *
                   (WS-CLOSE-COMP3(WS-I) - WS-LOWEST) /
                   (WS-HIGHEST - WS-LOWEST + 0.0001)
               MOVE 0 TO WS-SUM-D
               COMPUTE WS-START-D = WS-I - WS-D-PERIOD + 1
               PERFORM VARYING WS-J FROM WS-START-D BY 1
                       UNTIL WS-J > WS-I
                   ADD WS-PCT-K TO WS-SUM-D
               END-PERFORM
               COMPUTE WS-PCT-D = WS-SUM-D / WS-D-PERIOD
               DISPLAY WS-PCT-K " " WS-PCT-D
           END-PERFORM.

       CLEANUP.
           CLOSE PRICES-FILE.
