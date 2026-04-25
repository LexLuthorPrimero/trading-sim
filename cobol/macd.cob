       IDENTIFICATION DIVISION.
       PROGRAM-ID. MACD.
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
       01  WS-IDX          PIC 9(4).
       01  WS-PRICES-TABLE.
           05 WS-PRICE-ENTRY OCCURS 1000 TIMES INDEXED BY I.
              10 WS-PRICE-VAL PIC 9(7)V99.
       01  WS-FAST          PIC 9(2) VALUE 12.
       01  WS-SLOW          PIC 9(2) VALUE 26.
       01  WS-SIGNAL        PIC 9(2) VALUE 9.
       01  WS-EMA-FAST      PIC 9(7)V99.
       01  WS-EMA-SLOW      PIC 9(7)V99.
       01  WS-EMA-SIGNAL    PIC 9(7)V99.
       01  WS-MACD-LINE     PIC 9(7)V99.
       01  WS-HISTOGRAM     PIC 9(7)V99.
       01  WS-ALPHA-FAST    PIC V99.
       01  WS-ALPHA-SLOW    PIC V99.
       01  WS-ALPHA-SIGNAL  PIC V99.
       01  WS-FAST-TEMP     PIC 9(7)V99.
       01  WS-SLOW-TEMP     PIC 9(7)V99.
       01  WS-SIGNAL-TEMP   PIC 9(7)V99.
       PROCEDURE DIVISION.
       MAIN.
           PERFORM LOAD-PRICES
           IF WS-COUNT < WS-SLOW
               DISPLAY "ERROR: Not enough data for MACD"
               STOP RUN
           END-IF
           COMPUTE WS-ALPHA-FAST = 2 / (WS-FAST + 1)
           COMPUTE WS-ALPHA-SLOW = 2 / (WS-SLOW + 1)
           COMPUTE WS-ALPHA-SIGNAL = 2 / (WS-SIGNAL + 1)
           MOVE WS-PRICE-VAL(1) TO WS-EMA-FAST
           MOVE WS-PRICE-VAL(1) TO WS-EMA-SLOW
           PERFORM VARYING I FROM 2 BY 1 UNTIL I > WS-COUNT
               COMPUTE WS-FAST-TEMP =
                   WS-PRICE-VAL(I) * WS-ALPHA-FAST
               COMPUTE WS-EMA-FAST =
                   WS-FAST-TEMP + WS-EMA-FAST
                   * (1 - WS-ALPHA-FAST)
               COMPUTE WS-SLOW-TEMP =
                   WS-PRICE-VAL(I) * WS-ALPHA-SLOW
               COMPUTE WS-EMA-SLOW =
                   WS-SLOW-TEMP + WS-EMA-SLOW
                   * (1 - WS-ALPHA-SLOW)
           END-PERFORM
           COMPUTE WS-MACD-LINE =
               WS-EMA-FAST - WS-EMA-SLOW
           MOVE WS-MACD-LINE TO WS-EMA-SIGNAL
           COMPUTE WS-SIGNAL-TEMP =
               WS-MACD-LINE * WS-ALPHA-SIGNAL
           COMPUTE WS-EMA-SIGNAL =
               WS-SIGNAL-TEMP + WS-EMA-SIGNAL
               * (1 - WS-ALPHA-SIGNAL)
           COMPUTE WS-HISTOGRAM =
               WS-MACD-LINE - WS-EMA-SIGNAL
           DISPLAY WS-MACD-LINE " "
               WS-EMA-SIGNAL " " WS-HISTOGRAM
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
