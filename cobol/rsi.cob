       IDENTIFICATION DIVISION.
       PROGRAM-ID. RSI.
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
           05 PRICE-RAW      PIC X(10).
       WORKING-STORAGE SECTION.
       01  WS-FS            PIC XX.
           88  WS-FS-OK     VALUE "00".
           88  WS-FS-EOF    VALUE "10".
       01  WS-PRICES-PATH   PIC X(200).
       01  WS-PRICES-TABLE.
           05 WS-PRICE-ENTRY OCCURS 1000 TIMES
              INDEXED BY PRICE-IDX.
              10 WS-PRICE-COMP3  PIC 9(5)V99 COMP-3.
       01  WS-COUNT         PIC 9(4) COMP.
       01  WS-I             PIC 9(4) COMP.
       01  WS-PERIOD        PIC 9(2) COMP VALUE 14.
       01  WS-GAIN          PIC 9(7)V99 COMP-3 VALUE 0.
       01  WS-LOSS          PIC 9(7)V99 COMP-3 VALUE 0.
       01  WS-AVG-GAIN      PIC 9(7)V99 COMP-3.
       01  WS-AVG-LOSS      PIC 9(7)V99 COMP-3.
       01  WS-RS            PIC 9(3)V9(5) COMP-3.
       01  WS-RSI           PIC 9(3) COMP.
       01  WS-CHANGE        PIC S9(7)V99 COMP-3.
       01  WS-DIFF          PIC 9(7)V99 COMP-3.
       01  WS-START-IDX     PIC 9(4) COMP.
       PROCEDURE DIVISION.
       MAIN.
           PERFORM INPUT-PRICES.
           IF WS-COUNT <= WS-PERIOD
               DISPLAY "ERROR: Need at least " WS-PERIOD " prices"
               PERFORM CLEANUP
               STOP RUN
           END-IF.
           PERFORM PROCESS-RSI.
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
                       COMPUTE WS-PRICE-COMP3(WS-COUNT) = 
                           FUNCTION NUMVAL(PRICE-RAW)
               END-READ
           END-PERFORM.
           CLOSE PRICES-FILE.

       PROCESS-RSI.
           MOVE 0 TO WS-GAIN. MOVE 0 TO WS-LOSS.
           PERFORM VARYING WS-I FROM 2 BY 1
                   UNTIL WS-I > WS-PERIOD + 1
               COMPUTE WS-CHANGE = WS-PRICE-COMP3(WS-I) - 
                   WS-PRICE-COMP3(WS-I - 1)
               IF WS-CHANGE > 0
                   ADD WS-CHANGE TO WS-GAIN
               ELSE
                   COMPUTE WS-DIFF = 0 - WS-CHANGE
                   ADD WS-DIFF TO WS-LOSS
               END-IF
           END-PERFORM.
           COMPUTE WS-AVG-GAIN = WS-GAIN / WS-PERIOD.
           COMPUTE WS-AVG-LOSS = WS-LOSS / WS-PERIOD.
           COMPUTE WS-START-IDX = WS-PERIOD + 2.
           PERFORM VARYING WS-I FROM WS-START-IDX BY 1
                   UNTIL WS-I > WS-COUNT
               COMPUTE WS-CHANGE = WS-PRICE-COMP3(WS-I) - 
                   WS-PRICE-COMP3(WS-I - 1)
               IF WS-CHANGE > 0
                   COMPUTE WS-AVG-GAIN = 
                       (WS-AVG-GAIN * (WS-PERIOD - 1) + WS-CHANGE) 
                       / WS-PERIOD
                   COMPUTE WS-AVG-LOSS = 
                       WS-AVG-LOSS * (WS-PERIOD - 1) / WS-PERIOD
               ELSE
                   COMPUTE WS-DIFF = 0 - WS-CHANGE
                   COMPUTE WS-AVG-GAIN = 
                       WS-AVG-GAIN * (WS-PERIOD - 1) / WS-PERIOD
                   COMPUTE WS-AVG-LOSS = 
                       (WS-AVG-LOSS * (WS-PERIOD - 1) + WS-DIFF) 
                       / WS-PERIOD
               END-IF
           END-PERFORM.
           IF WS-AVG-LOSS = 0
               DISPLAY "100"
           ELSE
               COMPUTE WS-RS = WS-AVG-GAIN / WS-AVG-LOSS
               COMPUTE WS-RSI = 100 - (100 / (1 + WS-RS))
               DISPLAY WS-RSI
           END-IF.

       CLEANUP.
           CLOSE PRICES-FILE.
