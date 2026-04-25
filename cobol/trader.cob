       IDENTIFICATION DIVISION.
       PROGRAM-ID. TRADER.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SIGNALS-FILE ASSIGN TO DYNAMIC WS-SIGNALS-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FS.
       DATA DIVISION.
       FILE SECTION.
       FD  SIGNALS-FILE.
       01  SIGNAL-RECORD.
           05 SIGNAL-PRICE    PIC 9(5)V99.
           05 FILLER          PIC X.
           05 SIGNAL-TYPE     PIC X(1).
       WORKING-STORAGE SECTION.
       01  WS-FS              PIC XX.
           88  WS-FS-OK       VALUE "00".
           88  WS-FS-EOF      VALUE "10".
       01  WS-SIGNALS-PATH    PIC X(200).
       01  WS-CAPITAL         PIC 9(7)V99 COMP-3 VALUE 10000.00.
       01  WS-POSITION        PIC S9(4) COMP.
       01  WS-TRADE-PRICE     PIC 9(5)V99 COMP-3.
       01  WS-TRADE-COUNT     PIC 9(4) COMP VALUE 0.
       01  WS-WIN-COUNT       PIC 9(4) COMP VALUE 0.
       PROCEDURE DIVISION.
       MAIN.
           PERFORM INPUT-SIGNALS.
           IF WS-TRADE-COUNT = 0
               DISPLAY "10000.00 0 0"
               PERFORM CLEANUP
               STOP RUN
           END-IF.
           PERFORM PROCESS-TRADES.
           PERFORM CLEANUP.
           STOP RUN.

       INPUT-SIGNALS.
           ACCEPT WS-SIGNALS-PATH FROM COMMAND-LINE.
           IF WS-SIGNALS-PATH = SPACES
               MOVE "signals.txt" TO WS-SIGNALS-PATH
           END-IF.
           OPEN INPUT SIGNALS-FILE.
           IF NOT WS-FS-OK
               DISPLAY "ERROR: Cannot open " WS-SIGNALS-PATH
               STOP RUN
           END-IF.
           MOVE 0 TO WS-TRADE-COUNT.
           MOVE 0 TO WS-WIN-COUNT.
           MOVE 0 TO WS-POSITION.
           MOVE 10000.00 TO WS-CAPITAL.
           PERFORM UNTIL WS-FS-EOF
               READ SIGNALS-FILE INTO SIGNAL-RECORD
                   AT END SET WS-FS-EOF TO TRUE
                   NOT AT END
                       EVALUATE TRUE
                           WHEN SIGNAL-TYPE = 'B' AND WS-POSITION = 0
                               MOVE SIGNAL-PRICE TO WS-TRADE-PRICE
                               MOVE 1 TO WS-POSITION
                           WHEN SIGNAL-TYPE = 'S' AND WS-POSITION = 1
                               COMPUTE WS-CAPITAL = WS-CAPITAL +
                                   (SIGNAL-PRICE - WS-TRADE-PRICE)
                               IF SIGNAL-PRICE > WS-TRADE-PRICE
                                   ADD 1 TO WS-WIN-COUNT
                               END-IF
                               ADD 1 TO WS-TRADE-COUNT
                               MOVE 0 TO WS-POSITION
                       END-EVALUATE
               END-READ
           END-PERFORM.
           CLOSE SIGNALS-FILE.

       PROCESS-TRADES.
           DISPLAY WS-CAPITAL " " WS-TRADE-COUNT " " WS-WIN-COUNT.

       CLEANUP.
           CLOSE SIGNALS-FILE.
