       IDENTIFICATION DIVISION.
       PROGRAM-ID. SMACROSS.
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
       01  WS-SMA-FAST PIC 9(5)V99.
       01  WS-SMA-SLOW PIC 9(5)V99.
       01  WS-TEMP-PRICE PIC 9(5)V99.
       01  WS-START-FAST PIC 9(4).
       01  WS-START-SLOW PIC 9(4).
       PROCEDURE DIVISION.
       MAIN.
           PERFORM LOAD-PRICES
           IF WS-COUNT < 10
               DISPLAY "ERROR: Need at least 10 prices"
               STOP RUN
           END-IF
           PERFORM VARYING WS-I FROM 10 BY 1 UNTIL WS-I > WS-COUNT
               COMPUTE WS-SMA-FAST = 0
               COMPUTE WS-START-FAST = WS-I - 5
               PERFORM VARYING WS-J FROM WS-START-FAST BY 1
                       UNTIL WS-J >= WS-I
                   ADD WS-PRICE-VAL(WS-J) TO WS-SMA-FAST
               END-PERFORM
               DIVIDE 5 INTO WS-SMA-FAST

               COMPUTE WS-SMA-SLOW = 0
               COMPUTE WS-START-SLOW = WS-I - 10
               PERFORM VARYING WS-J FROM WS-START-SLOW BY 1
                       UNTIL WS-J >= WS-I
                   ADD WS-PRICE-VAL(WS-J) TO WS-SMA-SLOW
               END-PERFORM
               DIVIDE 10 INTO WS-SMA-SLOW

               IF WS-SMA-FAST > WS-SMA-SLOW
                   DISPLAY WS-PRICE-VAL(WS-I) " B"
               ELSE IF WS-SMA-FAST < WS-SMA-SLOW
                   DISPLAY WS-PRICE-VAL(WS-I) " S"
               END-IF
           END-PERFORM
           STOP RUN.

       LOAD-PRICES.
           OPEN INPUT PRICES-FILE
           IF WS-FS NOT = "00"
               DISPLAY "ERROR: Cannot open prices.dat"
               STOP RUN
           END-IF
           PERFORM UNTIL WS-FS NOT = "00"
               READ PRICES-FILE INTO WS-TEMP-PRICE
                   AT END
                       EXIT PERFORM
                   NOT AT END
                       ADD 1 TO WS-COUNT
                       MOVE WS-TEMP-PRICE TO WS-PRICE-VAL(WS-COUNT)
               END-READ
           END-PERFORM
           CLOSE PRICES-FILE.
