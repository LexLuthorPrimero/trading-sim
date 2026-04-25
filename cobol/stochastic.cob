       IDENTIFICATION DIVISION.
       PROGRAM-ID. STOCHASTIC.
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
       01  WS-K-PERIOD PIC 9(2) VALUE 14.
       01  WS-D-PERIOD PIC 9(2) VALUE 3.
       01  WS-HIGHEST   PIC 9(5)V99.
       01  WS-LOWEST    PIC 9(5)V99.
       01  WS-PCT-K     PIC 9(3)V99.
       01  WS-PCT-D     PIC 9(3)V99.
       01  WS-SUM-D     PIC 9(5)V99.
       01  WS-START-IDX PIC 9(4).
       01  WS-START-D   PIC 9(4).
       PROCEDURE DIVISION.
       MAIN.
           PERFORM LOAD-PRICES
           IF WS-COUNT < WS-K-PERIOD
               DISPLAY "ERROR: Need at least " WS-K-PERIOD " prices"
               STOP RUN
           END-IF
           PERFORM VARYING WS-I FROM WS-K-PERIOD BY 1
                   UNTIL WS-I > WS-COUNT
               MOVE WS-HIGH(WS-I) TO WS-HIGHEST
               MOVE WS-LOW(WS-I) TO WS-LOWEST
               COMPUTE WS-START-IDX = WS-I - WS-K-PERIOD + 1
               PERFORM VARYING WS-J FROM WS-START-IDX BY 1
                       UNTIL WS-J > WS-I
                   IF WS-HIGH(WS-J) > WS-HIGHEST
                       MOVE WS-HIGH(WS-J) TO WS-HIGHEST
                   END-IF
                   IF WS-LOW(WS-J) < WS-LOWEST
                       MOVE WS-LOW(WS-J) TO WS-LOWEST
                   END-IF
               END-PERFORM
               COMPUTE WS-PCT-K = 100 *
                   (WS-CLOSE(WS-I) - WS-LOWEST) /
                   (WS-HIGHEST - WS-LOWEST + 0.0001)
               COMPUTE WS-SUM-D = 0
               COMPUTE WS-START-D = WS-I - WS-D-PERIOD + 1
               PERFORM VARYING WS-J FROM WS-START-D BY 1
                       UNTIL WS-J > WS-I
                   ADD WS-PCT-K TO WS-SUM-D
               END-PERFORM
               COMPUTE WS-PCT-D = WS-SUM-D / WS-D-PERIOD
               DISPLAY WS-PCT-K " " WS-PCT-D
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
