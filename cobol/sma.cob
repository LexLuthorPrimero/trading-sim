       IDENTIFICATION DIVISION.
       PROGRAM-ID. SMA.
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
       01  WS-COUNT         PIC 9(4) COMP.
       01  WS-I             PIC 9(4) COMP.
       01  WS-WINDOW        PIC 9(2) COMP VALUE 5.
       01  WS-SUM           PIC 9(10)V99 COMP-3.
       01  WS-SMA           PIC 9(5)V99.
       01  WS-START-IDX     PIC 9(4) COMP.
       01  WS-END-IDX       PIC 9(4) COMP.
       PROCEDURE DIVISION.
       MAIN.
           PERFORM INPUT-PRICES.
           IF WS-COUNT < WS-WINDOW
               DISPLAY "ERROR: Need at least " WS-WINDOW " prices"
               PERFORM CLEANUP
               STOP RUN
           END-IF.
           PERFORM PROCESS-SMA.
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

       PROCESS-SMA.
           COMPUTE WS-START-IDX = WS-COUNT - WS-WINDOW + 1.
           COMPUTE WS-END-IDX = WS-COUNT.
           MOVE 0 TO WS-SUM.
           PERFORM VARYING WS-I FROM WS-START-IDX BY 1
                   UNTIL WS-I > WS-END-IDX
               ADD WS-PRICE-COMP3(WS-I) TO WS-SUM
           END-PERFORM.
           COMPUTE WS-SMA = WS-SUM / WS-WINDOW.
           DISPLAY WS-SMA.

       CLEANUP.
           CLOSE PRICES-FILE.
