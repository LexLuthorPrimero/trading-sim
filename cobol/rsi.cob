       IDENTIFICATION DIVISION.
       PROGRAM-ID. RSI.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PRICES-FILE ASSIGN TO 'prices.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-PRICE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  PRICES-FILE.
       01  PRICE-RECORD PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01  WS-PRICE-STATUS PIC XX.
       01  WS-PRICE        PIC 9(7)V99.
       01  WS-COUNT        PIC 9(4) VALUE 0.
       01  WS-PERIOD       PIC 9(2) VALUE 14.
       01  WS-IDX          PIC 9(4).
       01  WS-I-START      PIC 9(4).
       01  WS-PRICES-TABLE.
           05 WS-PRICE-ENTRY OCCURS 1000 TIMES INDEXED BY I.
              10 WS-PRICE-VAL PIC 9(7)V99.
       01  WS-GAIN          PIC 9(7)V99 VALUE 0.
       01  WS-LOSS          PIC 9(7)V99 VALUE 0.
       01  WS-AVG-GAIN      PIC 9(7)V99.
       01  WS-AVG-LOSS      PIC 9(7)V99.
       01  WS-DIFF          PIC 9(7)V99.
       01  WS-RS            PIC 9(3)V9(5).
       01  WS-RSI           PIC 9(3).
       01  WS-CHANGE        PIC S9(7)V99.
       01  WS-TEMP1         PIC 9(7)V99.
       01  WS-TEMP2         PIC 9(7)V99.
       01  WS-TEMP3         PIC 9(7)V99.
       01  WS-TEMP4         PIC 9(7)V99.
       01  WS-TEMP5         PIC 9(7)V99.
       01  WS-TEMP6         PIC 9(7)V99.
       PROCEDURE DIVISION.
       MAIN.
           PERFORM LOAD-PRICES
           IF WS-COUNT <= WS-PERIOD
               DISPLAY "ERROR: Not enough data for RSI"
               STOP RUN
           END-IF
           MOVE 0 TO WS-GAIN
           MOVE 0 TO WS-LOSS
           PERFORM VARYING I FROM 2 BY 1 UNTIL I > WS-PERIOD + 1
               COMPUTE WS-CHANGE =
                   WS-PRICE-VAL(I) - WS-PRICE-VAL(I - 1)
               IF WS-CHANGE > 0
                   ADD WS-CHANGE TO WS-GAIN
               ELSE
                   COMPUTE WS-DIFF = 0 - WS-CHANGE
                   ADD WS-DIFF TO WS-LOSS
               END-IF
           END-PERFORM
           COMPUTE WS-AVG-GAIN = WS-GAIN / WS-PERIOD
           COMPUTE WS-AVG-LOSS = WS-LOSS / WS-PERIOD
           COMPUTE WS-I-START = WS-PERIOD + 2
           PERFORM VARYING I FROM WS-I-START BY 1
                   UNTIL I > WS-COUNT
               COMPUTE WS-CHANGE =
                   WS-PRICE-VAL(I) - WS-PRICE-VAL(I - 1)
               IF WS-CHANGE > 0
                   COMPUTE WS-TEMP1 =
                       WS-AVG-GAIN * (WS-PERIOD - 1)
                   COMPUTE WS-TEMP2 = WS-TEMP1 + WS-CHANGE
                   COMPUTE WS-AVG-GAIN = WS-TEMP2 / WS-PERIOD
                   COMPUTE WS-TEMP3 =
                       WS-AVG-LOSS * (WS-PERIOD - 1)
                   COMPUTE WS-AVG-LOSS = WS-TEMP3 / WS-PERIOD
               ELSE
                   COMPUTE WS-DIFF = 0 - WS-CHANGE
                   COMPUTE WS-TEMP4 =
                       WS-AVG-GAIN * (WS-PERIOD - 1)
                   COMPUTE WS-AVG-GAIN = WS-TEMP4 / WS-PERIOD
                   COMPUTE WS-TEMP5 =
                       WS-AVG-LOSS * (WS-PERIOD - 1)
                   COMPUTE WS-TEMP6 = WS-TEMP5 + WS-DIFF
                   COMPUTE WS-AVG-LOSS = WS-TEMP6 / WS-PERIOD
               END-IF
           END-PERFORM
           IF WS-AVG-LOSS = 0
               DISPLAY "100.00"
               STOP RUN
           END-IF
           COMPUTE WS-RS = WS-AVG-GAIN / WS-AVG-LOSS
           COMPUTE WS-RSI = 100 - (100 / (1 + WS-RS))
           DISPLAY WS-RSI
           STOP RUN.

       LOAD-PRICES.
           OPEN INPUT PRICES-FILE
           IF WS-PRICE-STATUS NOT = "00"
               DISPLAY "ERROR: Could not open prices.dat"
               STOP RUN
           END-IF
           MOVE 0 TO WS-COUNT
           PERFORM UNTIL WS-COUNT >= 1000
               READ PRICES-FILE INTO WS-PRICE
                   AT END EXIT PERFORM
               END-READ
               ADD 1 TO WS-COUNT
               MOVE WS-PRICE TO WS-PRICE-VAL(WS-COUNT)
           END-PERFORM
           CLOSE PRICES-FILE.
