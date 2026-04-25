       IDENTIFICATION DIVISION.
       PROGRAM-ID. ATR.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PRICES-FILE ASSIGN TO 'prices.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FS.
       DATA DIVISION.
       FILE SECTION.
       FD  PRICES-FILE.
       01  PRICE-RECORD.
           05 PRICE-HIGH  PIC 9(5)V99.
           05 FILLER     PIC X.
           05 PRICE-LOW   PIC 9(5)V99.
           05 FILLER     PIC X.
           05 PRICE-CLOSE PIC 9(5)V99.
       WORKING-STORAGE SECTION.
       01  WS-FS            PIC XX.
       01  WS-PRICE-TABLE.
           05 WS-PRICE-ENTRY OCCURS 1000 TIMES.
              10 WS-HIGH   PIC 9(5)V99.
              10 WS-LOW    PIC 9(5)V99.
              10 WS-CLOSE  PIC 9(5)V99.
       01  WS-COUNT PIC 9(4) VALUE 0.
       01  WS-I PIC 9(4).
       01  WS-J PIC 9(4).
       01  WS-PERIOD PIC 9(2) VALUE 14.
       01  WS-TRUE-RANGE  PIC 9(5)V99.
       01  WS-ATR         PIC 9(5)V99.
       01  WS-SUM-TR      PIC 9(10)V99.
       01  WS-DIFF1       PIC 9(5)V99.
       01  WS-DIFF2       PIC 9(5)V99.
       01  WS-DIFF3       PIC 9(5)V99.
       01  WS-MAX-DIFF    PIC 9(5)V99.
       01  WS-PREV-CLOSE  PIC 9(5)V99.
       01  WS-START-IDX   PIC 9(4).
       PROCEDURE DIVISION.
       MAIN.
           PERFORM LOAD-PRICES
           IF WS-COUNT <= WS-PERIOD
               DISPLAY "ERROR: Need at least " WS-PERIOD " prices"
               STOP RUN
           END-IF
           MOVE WS-CLOSE(1) TO WS-PREV-CLOSE
           MOVE 0 TO WS-SUM-TR
           PERFORM VARYING WS-I FROM 2 BY 1
                   UNTIL WS-I > WS-PERIOD + 1
               COMPUTE WS-DIFF1 = WS-HIGH(WS-I) - WS-LOW(WS-I)
               COMPUTE WS-DIFF2 = WS-HIGH(WS-I) - WS-PREV-CLOSE
               COMPUTE WS-DIFF3 = WS-PREV-CLOSE - WS-LOW(WS-I)
               MOVE WS-DIFF1 TO WS-MAX-DIFF
               IF WS-DIFF2 > WS-MAX-DIFF
                   MOVE WS-DIFF2 TO WS-MAX-DIFF
               END-IF
               IF WS-DIFF3 > WS-MAX-DIFF
                   MOVE WS-DIFF3 TO WS-MAX-DIFF
               END-IF
               ADD WS-MAX-DIFF TO WS-SUM-TR
               MOVE WS-CLOSE(WS-I) TO WS-PREV-CLOSE
           END-PERFORM
           COMPUTE WS-ATR = WS-SUM-TR / WS-PERIOD
           COMPUTE WS-START-IDX = WS-PERIOD + 2
           PERFORM VARYING WS-I FROM WS-START-IDX BY 1
                   UNTIL WS-I > WS-COUNT
               COMPUTE WS-DIFF1 = WS-HIGH(WS-I) - WS-LOW(WS-I)
               COMPUTE WS-DIFF2 = WS-HIGH(WS-I) - WS-PREV-CLOSE
               COMPUTE WS-DIFF3 = WS-PREV-CLOSE - WS-LOW(WS-I)
               MOVE WS-DIFF1 TO WS-MAX-DIFF
               IF WS-DIFF2 > WS-MAX-DIFF
                   MOVE WS-DIFF2 TO WS-MAX-DIFF
               END-IF
               IF WS-DIFF3 > WS-MAX-DIFF
                   MOVE WS-DIFF3 TO WS-MAX-DIFF
               END-IF
               COMPUTE WS-ATR =
                   (WS-ATR * (WS-PERIOD - 1) + WS-MAX-DIFF) / WS-PERIOD
               DISPLAY WS-ATR
               MOVE WS-CLOSE(WS-I) TO WS-PREV-CLOSE
           END-PERFORM
           STOP RUN.

       LOAD-PRICES.
           OPEN INPUT PRICES-FILE
           IF WS-FS NOT = "00"
               DISPLAY "ERROR: Cannot open prices.dat"
               STOP RUN
           END-IF
           PERFORM WITH TEST AFTER UNTIL WS-FS = "10"
               READ PRICES-FILE
                   AT END CONTINUE
               END-READ
               IF WS-FS = "00"
                   ADD 1 TO WS-COUNT
                   MOVE PRICE-HIGH  TO WS-HIGH(WS-COUNT)
                   MOVE PRICE-LOW   TO WS-LOW(WS-COUNT)
                   MOVE PRICE-CLOSE TO WS-CLOSE(WS-COUNT)
               END-IF
           END-PERFORM
           CLOSE PRICES-FILE.
