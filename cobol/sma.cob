       IDENTIFICATION DIVISION.
       PROGRAM-ID. SMA.
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
       01  WS-WINDOW       PIC 9(2) VALUE 5.
       01  WS-COUNT        PIC 9(4) VALUE 0.
       01  WS-IDX          PIC 9(4).
       01  WS-SUM          PIC 9(10)V99.
       01  WS-SMA          PIC 9(7)V99.
       01  WS-PRICES-TABLE.
           05 WS-PRICE-ENTRY OCCURS 1000 TIMES INDEXED BY I.
              10 WS-PRICE-VAL PIC 9(7)V99.
       01  WS-START-IDX     PIC 9(4).
       01  WS-END-IDX       PIC 9(4).
       PROCEDURE DIVISION.
       MAIN.
           PERFORM LOAD-PRICES
           IF WS-COUNT < WS-WINDOW
               DISPLAY "ERROR: Not enough data for SMA window"
               STOP RUN
           END-IF
           COMPUTE WS-START-IDX = WS-COUNT - WS-WINDOW + 1
           COMPUTE WS-END-IDX = WS-COUNT
           MOVE 0 TO WS-SUM
           PERFORM VARYING I FROM WS-START-IDX BY 1 UNTIL I > WS-END-IDX
               ADD WS-PRICE-VAL(I) TO WS-SUM
           END-PERFORM
           COMPUTE WS-SMA = WS-SUM / WS-WINDOW
           DISPLAY WS-SMA
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
