       IDENTIFICATION DIVISION.
       PROGRAM-ID. BOLLINGER.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PRICES-FILE ASSIGN TO 'prices.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FS.
       DATA DIVISION.
       FILE SECTION.
       FD  PRICES-FILE.
       01  PRICE-RECORD PIC 9(5)V99.
       WORKING-STORAGE SECTION.
       01  WS-FS            PIC XX.
       01  WS-PRICE-TABLE.
           05 WS-PRICE-ENTRY OCCURS 1000 TIMES.
              10 WS-PRICE-VAL PIC 9(5)V99.
       01  WS-COUNT PIC 9(4) VALUE 0.
       01  WS-I PIC 9(4).
       01  WS-J PIC 9(4).
       01  WS-TEMP-PRICE PIC 9(5)V99.
       01  WS-PERIOD PIC 9(2) VALUE 20.
       01  WS-START-IDX PIC 9(4).
       01  WS-SUM        PIC 9(10)V99.
       01  WS-SMA        PIC 9(5)V99.
       01  WS-VARIANCE   PIC 9(10)V99.
       01  WS-STD-DEV    PIC 9(5)V99.
       01  WS-UPPER      PIC 9(5)V99.
       01  WS-LOWER      PIC 9(5)V99.
       01  WS-DIFF       PIC S9(5)V99.
       01  WS-DIFF-SQ    PIC 9(10)V99.
       PROCEDURE DIVISION.
       MAIN.
           PERFORM LOAD-PRICES
           IF WS-COUNT < WS-PERIOD
               DISPLAY "ERROR: Need at least " WS-PERIOD " prices"
               STOP RUN
           END-IF
           PERFORM VARYING WS-I FROM WS-PERIOD BY 1
                   UNTIL WS-I > WS-COUNT
               COMPUTE WS-SUM = 0
               COMPUTE WS-START-IDX = WS-I - WS-PERIOD + 1
               PERFORM VARYING WS-J FROM WS-START-IDX BY 1
                       UNTIL WS-J > WS-I
                   ADD WS-PRICE-VAL(WS-J) TO WS-SUM
               END-PERFORM
               COMPUTE WS-SMA = WS-SUM / WS-PERIOD
               COMPUTE WS-VARIANCE = 0
               PERFORM VARYING WS-J FROM WS-START-IDX BY 1
                       UNTIL WS-J > WS-I
                   COMPUTE WS-DIFF = WS-PRICE-VAL(WS-J) - WS-SMA
                   COMPUTE WS-DIFF-SQ = WS-DIFF * WS-DIFF
                   ADD WS-DIFF-SQ TO WS-VARIANCE
               END-PERFORM
               COMPUTE WS-VARIANCE = WS-VARIANCE / WS-PERIOD
               COMPUTE WS-STD-DEV = FUNCTION SQRT(WS-VARIANCE)
               COMPUTE WS-UPPER = WS-SMA + (2 * WS-STD-DEV)
               COMPUTE WS-LOWER = WS-SMA - (2 * WS-STD-DEV)
               DISPLAY WS-PRICE-VAL(WS-I) " " WS-UPPER " " WS-LOWER
           END-PERFORM
           STOP RUN.

       LOAD-PRICES.
           OPEN INPUT PRICES-FILE
           IF WS-FS NOT = "00"
               DISPLAY "ERROR: Cannot open prices.dat"
               STOP RUN
           END-IF
           PERFORM WITH TEST AFTER UNTIL WS-FS = "10"
               READ PRICES-FILE INTO WS-TEMP-PRICE
                   AT END CONTINUE
               END-READ
               IF WS-FS = "00"
                   ADD 1 TO WS-COUNT
                   MOVE WS-TEMP-PRICE TO WS-PRICE-VAL(WS-COUNT)
               END-IF
           END-PERFORM
           CLOSE PRICES-FILE.
