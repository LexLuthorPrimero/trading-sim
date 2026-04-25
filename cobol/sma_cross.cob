       IDENTIFICATION DIVISION.
       PROGRAM-ID. SMACROSS.
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
              10 WS-PRICE-COMP3  PIC 9(5)V99 COMP-3.
       01  WS-COUNT         PIC 9(4) COMP VALUE 0.
       01  WS-I             PIC 9(4) COMP.
       01  WS-J             PIC 9(4) COMP.
       01  WS-SMA-FAST      PIC 9(5)V99 COMP-3.
       01  WS-SMA-SLOW      PIC 9(5)V99 COMP-3.
       01  WS-START-FAST    PIC 9(4) COMP.
       01  WS-START-SLOW    PIC 9(4) COMP.
       PROCEDURE DIVISION.
       MAIN.
           PERFORM INPUT-PRICES.
           IF WS-COUNT < 10
               DISPLAY "ERROR: Need at least 10 prices"
               PERFORM CLEANUP
               STOP RUN
           END-IF.
           PERFORM PROCESS-CROSS.
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

       PROCESS-CROSS.
           PERFORM VARYING WS-I FROM 10 BY 1
                   UNTIL WS-I > WS-COUNT
               MOVE 0 TO WS-SMA-FAST
               COMPUTE WS-START-FAST = WS-I - 5
               PERFORM VARYING WS-J FROM WS-START-FAST BY 1
                       UNTIL WS-J >= WS-I
                   ADD WS-PRICE-COMP3(WS-J) TO WS-SMA-FAST
               END-PERFORM
               DIVIDE 5 INTO WS-SMA-FAST

               MOVE 0 TO WS-SMA-SLOW
               COMPUTE WS-START-SLOW = WS-I - 10
               PERFORM VARYING WS-J FROM WS-START-SLOW BY 1
                       UNTIL WS-J >= WS-I
                   ADD WS-PRICE-COMP3(WS-J) TO WS-SMA-SLOW
               END-PERFORM
               DIVIDE 10 INTO WS-SMA-SLOW

               IF WS-SMA-FAST > WS-SMA-SLOW
                   DISPLAY WS-PRICE-COMP3(WS-I) " B"
               ELSE IF WS-SMA-FAST < WS-SMA-SLOW
                   DISPLAY WS-PRICE-COMP3(WS-I) " S"
               END-IF
           END-PERFORM.

       CLEANUP.
           CLOSE PRICES-FILE.
