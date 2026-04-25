       IDENTIFICATION DIVISION.
       PROGRAM-ID. BOLLINGER.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT FD-PRICES-FILE ASSIGN TO DYNAMIC WS-PRICES-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-PRICES-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  FD-PRICES-FILE.
       01  FD-PRICE-RECORD.
           05 FD-PRICE-RAW      PIC X(10).
       WORKING-STORAGE SECTION.
       01  WS-PRICES-STATUS   PIC XX.
           88  WS-PRICES-OK           VALUE "00".
           88  WS-PRICES-EOF          VALUE "10".
       01  WS-PRICES-PATH     PIC X(200).
       01  WS-PRICES-TABLE.
           05 WS-PRICE-ENTRY OCCURS 1000 TIMES
              INDEXED BY WS-PRICE-IDX.
              10 WS-PRICE-COMP3  PIC 9(5)V99 COMP-3.
       01  WS-COUNT           PIC 9(4) COMP.
       01  WS-I               PIC 9(4) COMP.
       01  WS-J               PIC 9(4) COMP.
       01  WS-PERIOD          PIC 9(2) COMP VALUE 20.
       01  WS-START-IDX       PIC 9(4) COMP.
       01  WS-SUM             PIC 9(10)V99 COMP-3.
       01  WS-SMA             PIC 9(5)V99.
       01  WS-VARIANCE        PIC 9(10)V99 COMP-3.
       01  WS-STD-DEV         PIC 9(5)V99.
       01  WS-UPPER           PIC 9(5)V99.
       01  WS-LOWER           PIC 9(5)V99.
       01  WS-DIFF            PIC S9(5)V99 COMP-3.
       01  WS-DIFF-SQ         PIC 9(10)V99 COMP-3.
       PROCEDURE DIVISION.
       MAIN.
           PERFORM INPUT-PRICES.
           IF WS-COUNT < WS-PERIOD
               DISPLAY "ERROR: Need at least " WS-PERIOD " prices"
               PERFORM CLEANUP
               STOP RUN
           END-IF.
           PERFORM PROCESS-BOLL.
           PERFORM CLEANUP.
           STOP RUN.

       INPUT-PRICES.
           ACCEPT WS-PRICES-PATH FROM COMMAND-LINE.
           IF WS-PRICES-PATH = SPACES
               MOVE "prices.dat" TO WS-PRICES-PATH
           END-IF.
           OPEN INPUT FD-PRICES-FILE.
           IF NOT WS-PRICES-OK
               DISPLAY "ERROR: Cannot open " WS-PRICES-PATH
               STOP RUN
           END-IF.
           MOVE 0 TO WS-COUNT.
           PERFORM UNTIL WS-PRICES-EOF
               READ FD-PRICES-FILE INTO FD-PRICE-RECORD
                   AT END SET WS-PRICES-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO WS-COUNT
                       COMPUTE WS-PRICE-COMP3(WS-COUNT) = 
                           FUNCTION NUMVAL(FD-PRICE-RAW)
               END-READ
           END-PERFORM.
           CLOSE FD-PRICES-FILE.

       PROCESS-BOLL.
           PERFORM VARYING WS-I FROM WS-PERIOD BY 1
                   UNTIL WS-I > WS-COUNT
               MOVE 0 TO WS-SUM
               COMPUTE WS-START-IDX = WS-I - WS-PERIOD + 1
               PERFORM VARYING WS-J FROM WS-START-IDX BY 1
                       UNTIL WS-J > WS-I
                   ADD WS-PRICE-COMP3(WS-J) TO WS-SUM
               END-PERFORM
               COMPUTE WS-SMA = WS-SUM / WS-PERIOD
               MOVE 0 TO WS-VARIANCE
               PERFORM VARYING WS-J FROM WS-START-IDX BY 1
                       UNTIL WS-J > WS-I
                   COMPUTE WS-DIFF = WS-PRICE-COMP3(WS-J) - WS-SMA
                   COMPUTE WS-DIFF-SQ = WS-DIFF * WS-DIFF
                   ADD WS-DIFF-SQ TO WS-VARIANCE
               END-PERFORM
               COMPUTE WS-VARIANCE = WS-VARIANCE / WS-PERIOD
               COMPUTE WS-STD-DEV = FUNCTION SQRT(WS-VARIANCE)
               COMPUTE WS-UPPER = WS-SMA + (2 * WS-STD-DEV)
               COMPUTE WS-LOWER = WS-SMA - (2 * WS-STD-DEV)
               DISPLAY WS-PRICE-COMP3(WS-I) " " WS-UPPER " " WS-LOWER
           END-PERFORM.

       CLEANUP.
           CLOSE FD-PRICES-FILE.
