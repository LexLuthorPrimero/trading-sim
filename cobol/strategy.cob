       IDENTIFICATION DIVISION.
       PROGRAM-ID. STRATEGY.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SIGNALS-FILE ASSIGN TO 'signals_combined.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FS.
       DATA DIVISION.
       FILE SECTION.
       FD  SIGNALS-FILE.
       01  SIGNAL-RECORD.
           05 SIG-MACD-CURR  PIC S9(3)V99.
           05 FILLER         PIC X.
           05 SIG-MACD-PREV  PIC S9(3)V99.
       WORKING-STORAGE SECTION.
       01  WS-FS            PIC XX.
       01  WS-DECISION      PIC X(4).
       PROCEDURE DIVISION.
       MAIN.
           OPEN INPUT SIGNALS-FILE
           IF WS-FS NOT = "00"
               DISPLAY "ERROR: Cannot open signals_combined.dat"
               STOP RUN
           END-IF
           READ SIGNALS-FILE
               AT END
                   DISPLAY "HOLD"
                   CLOSE SIGNALS-FILE
                   STOP RUN
           END-READ
           CLOSE SIGNALS-FILE.

           IF SIG-MACD-CURR > SIG-MACD-PREV
               MOVE "BUY " TO WS-DECISION
           ELSE IF SIG-MACD-CURR < SIG-MACD-PREV
               MOVE "SELL" TO WS-DECISION
           ELSE
               MOVE "HOLD" TO WS-DECISION
           END-IF.
           DISPLAY WS-DECISION.
           STOP RUN.
