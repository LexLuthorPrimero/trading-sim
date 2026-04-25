       IDENTIFICATION DIVISION.
       PROGRAM-ID. MACD.
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
              10 WS-PRICE-COMP3 PIC 9(5)V99 COMP-3.
       01  WS-COUNT         PIC 9(4) COMP.
       01  WS-I             PIC 9(4) COMP.
       01  WS-FAST          PIC 9(2) COMP VALUE 12.
       01  WS-SLOW          PIC 9(2) COMP VALUE 26.
       01  WS-SIGNAL        PIC 9(2) COMP VALUE 9.
       01  WS-EMA-FAST      PIC 9(7)V99 COMP-3.
       01  WS-EMA-SLOW      PIC 9(7)V99 COMP-3.
       01  WS-EMA-SIGNAL    PIC 9(7)V99 COMP-3.
       01  WS-MACD-LINE     PIC S9(7)V99 COMP-3.
       01  WS-HISTOGRAM     PIC S9(7)V99 COMP-3.
       01  WS-ALPHA-FAST    PIC V99.
       01  WS-ALPHA-SLOW    PIC V99.
       01  WS-ALPHA-SIGNAL  PIC V99.
       01  WS-TEMP1         PIC 9(7)V99 COMP-3.
       01  WS-TEMP2         PIC 9(7)V99 COMP-3.
       01  WS-TEMP3         PIC 9(7)V99 COMP-3.
       01  WS-TEMP4         PIC 9(7)V99 COMP-3.
       PROCEDURE DIVISION.
       MAIN.
           PERFORM INPUT-PRICES.
           IF WS-COUNT < WS-SLOW
               DISPLAY "ERROR: Need at least " WS-SLOW " prices"
               PERFORM CLEANUP
               STOP RUN
           END-IF.
           PERFORM PROCESS-MACD.
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

       PROCESS-MACD.
           COMPUTE WS-ALPHA-FAST = 2 / (WS-FAST + 1).
           COMPUTE WS-ALPHA-SLOW = 2 / (WS-SLOW + 1).
           COMPUTE WS-ALPHA-SIGNAL = 2 / (WS-SIGNAL + 1).
           MOVE WS-PRICE-COMP3(1) TO WS-EMA-FAST.
           MOVE WS-PRICE-COMP3(1) TO WS-EMA-SLOW.
           PERFORM VARYING WS-I FROM 2 BY 1
                   UNTIL WS-I > WS-COUNT
               COMPUTE WS-TEMP1 = WS-PRICE-COMP3(WS-I) *
                   WS-ALPHA-FAST
               COMPUTE WS-TEMP2 = WS-EMA-FAST *
                   (1 - WS-ALPHA-FAST)
               COMPUTE WS-EMA-FAST = WS-TEMP1 + WS-TEMP2
               COMPUTE WS-TEMP3 = WS-PRICE-COMP3(WS-I) *
                   WS-ALPHA-SLOW
               COMPUTE WS-TEMP4 = WS-EMA-SLOW *
                   (1 - WS-ALPHA-SLOW)
               COMPUTE WS-EMA-SLOW = WS-TEMP3 + WS-TEMP4
           END-PERFORM.
           COMPUTE WS-MACD-LINE = WS-EMA-FAST - WS-EMA-SLOW.
           MOVE WS-MACD-LINE TO WS-EMA-SIGNAL.
           PERFORM VARYING WS-I FROM 2 BY 1
                   UNTIL WS-I > WS-SIGNAL
               COMPUTE WS-EMA-SIGNAL = WS-MACD-LINE *
                   WS-ALPHA-SIGNAL + WS-EMA-SIGNAL *
                   (1 - WS-ALPHA-SIGNAL)
           END-PERFORM.
           COMPUTE WS-HISTOGRAM = WS-MACD-LINE -
               WS-EMA-SIGNAL.
           DISPLAY WS-MACD-LINE " " WS-EMA-SIGNAL " "
               WS-HISTOGRAM.

       CLEANUP.
           CLOSE PRICES-FILE.
