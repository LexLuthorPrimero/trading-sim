       IDENTIFICATION DIVISION.
       PROGRAM-ID. TRADER.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SIGNALS-FILE ASSIGN TO 'signals.txt'
               ORGANIZATION IS LINE SEQUENTIAL.
       DATA DIVISION.
       FILE SECTION.
       FD  SIGNALS-FILE.
       01  SIGNAL-RECORD.
           05 SIGNAL-PRICE PIC 9(5)V99.
           05 FILLER PIC X.
           05 SIGNAL-TYPE PIC X(1). *> B = Buy, S = Sell
       WORKING-STORAGE SECTION.
       01  WS-CAPITAL        PIC 9(7)V99 VALUE 10000.00.
       01  WS-POSITION       PIC S9(4) VALUE 0.
       01  WS-TRADE-PRICE    PIC 9(5)V99 VALUE 0.
       01  WS-TRADE-COUNT    PIC 9(4) VALUE 0.
       01  WS-WIN-COUNT      PIC 9(4) VALUE 0.
       01  WS-FINAL-CAPITAL  PIC 9(7)V99.
       PROCEDURE DIVISION.
       MAIN.
           OPEN INPUT SIGNALS-FILE
           PERFORM UNTIL EXIT
               READ SIGNALS-FILE INTO SIGNAL-RECORD
                   AT END EXIT PERFORM CYCLE
               END-READ
               EVALUATE TRUE
                   WHEN SIGNAL-TYPE = 'B' AND WS-POSITION = 0
                       MOVE SIGNAL-PRICE TO WS-TRADE-PRICE
                       MOVE 1 TO WS-POSITION
                   WHEN SIGNAL-TYPE = 'S' AND WS-POSITION = 1
                       COMPUTE WS-CAPITAL = WS-CAPITAL + 
                           (SIGNAL-PRICE - WS-TRADE-PRICE) * 1
                       IF SIGNAL-PRICE > WS-TRADE-PRICE
                           ADD 1 TO WS-WIN-COUNT
                       END-IF
                       ADD 1 TO WS-TRADE-COUNT
                       MOVE 0 TO WS-POSITION
               END-EVALUATE
           END-PERFORM.
           CLOSE SIGNALS-FILE.
           DISPLAY WS-CAPITAL " " WS-TRADE-COUNT " " WS-WIN-COUNT.
           STOP RUN.
