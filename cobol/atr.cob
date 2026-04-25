       IDENTIFICATION DIVISION.
       PROGRAM-ID. ATR.
      * B-DEBUG + B-FSTATUS + B-NAMING
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT FD-PRICES-FILE ASSIGN TO DYNAMIC WS-PRICES-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-PRICES-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  FD-PRICES-FILE.
       01  FD-PRICE-RECORD.
           05 FD-PRICE-HIGH-RAW  PIC X(10).
           05 FILLER             PIC X.
           05 FD-PRICE-LOW-RAW   PIC X(10).
           05 FILLER             PIC X.
           05 FD-PRICE-CLOSE-RAW PIC X(10).
       WORKING-STORAGE SECTION.
       01  WS-PRICES-STATUS   PIC XX.
           88  WS-PRICES-OK           VALUE "00".
           88  WS-PRICES-EOF          VALUE "10".
       01  WS-PRICES-PATH     PIC X(200).
       01  WS-PRICES-TABLE.
           05 WS-PRICE-ENTRY OCCURS 1000 TIMES
              INDEXED BY WS-PRICE-IDX.
              10 WS-HIGH-COMP3   PIC 9(5)V99 COMP-3.
              10 WS-LOW-COMP3    PIC 9(5)V99 COMP-3.
              10 WS-CLOSE-COMP3  PIC 9(5)V99 COMP-3.
       01  WS-COUNT           PIC 9(4) COMP VALUE 0.
       01  WS-I               PIC 9(4) COMP.
       01  WS-PERIOD          PIC 9(2) COMP VALUE 14.
       01  WS-TRUE-RANGE      PIC 9(5)V99 COMP-3.
       01  WS-ATR             PIC 9(5)V99 COMP-3.
       01  WS-SUM-TR          PIC 9(10)V99 COMP-3.
       01  WS-DIFF1           PIC 9(5)V99 COMP-3.
       01  WS-DIFF2           PIC 9(5)V99 COMP-3.
       01  WS-DIFF3           PIC 9(5)V99 COMP-3.
       01  WS-MAX-DIFF        PIC 9(5)V99 COMP-3.
       01  WS-PREV-CLOSE      PIC 9(5)V99 COMP-3.
       01  WS-START-IDX       PIC 9(4) COMP.
       01  WS-EXIT-CODE       PIC S9(4) COMP VALUE 0.
       01  WS-ERROR-MSG       PIC X(100).
       PROCEDURE DIVISION.
       MAIN.
           DISPLAY "[DEBUG] 1000-INICIO - Programa ATR iniciado"
           ACCEPT WS-PRICES-PATH FROM COMMAND-LINE
           IF WS-PRICES-PATH = SPACES
               MOVE "prices.dat" TO WS-PRICES-PATH
           END-IF
           DISPLAY "[DEBUG] 2000-LEER-PRECIOS - Leyendo archivo: " 
               WS-PRICES-PATH
           PERFORM 2000-LEER-PRECIOS
           IF WS-EXIT-CODE NOT = 0
               PERFORM 9000-FINALIZAR
               STOP RUN
           END-IF
           DISPLAY "[DEBUG] 3000-CALCULAR-ATR - Procesando " 
               WS-COUNT " precios con periodo " WS-PERIOD
           PERFORM 3000-CALCULAR-ATR
           DISPLAY "[DEBUG] 9000-FINALIZAR - "
                   "Programa ATR finalizado"
           PERFORM 9000-FINALIZAR
           STOP RUN.

       2000-LEER-PRECIOS.
           OPEN INPUT FD-PRICES-FILE
           IF NOT WS-PRICES-OK
               PERFORM 9999-MANEJAR-ERROR-FS
           END-IF
           IF WS-EXIT-CODE NOT = 0
               EXIT PARAGRAPH
           END-IF
           MOVE 0 TO WS-COUNT
           PERFORM UNTIL WS-PRICES-EOF
               READ FD-PRICES-FILE INTO FD-PRICE-RECORD
                   AT END 
                       SET WS-PRICES-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO WS-COUNT
                       COMPUTE WS-HIGH-COMP3(WS-COUNT) ROUNDED = 
                           FUNCTION NUMVAL(FD-PRICE-HIGH-RAW)
                       COMPUTE WS-LOW-COMP3(WS-COUNT) ROUNDED = 
                           FUNCTION NUMVAL(FD-PRICE-LOW-RAW)
                       COMPUTE WS-CLOSE-COMP3(WS-COUNT) ROUNDED = 
                           FUNCTION NUMVAL(FD-PRICE-CLOSE-RAW)
               END-READ
           END-PERFORM
           DISPLAY "[DEBUG] 2000-LEER-PRECIOS - Leidos " WS-COUNT 
               " registros"
           CLOSE FD-PRICES-FILE
           IF WS-COUNT = 0
               MOVE "ERROR: Archivo vacío" TO WS-ERROR-MSG
               DISPLAY WS-ERROR-MSG
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           EXIT.

       3000-CALCULAR-ATR.
           MOVE WS-CLOSE-COMP3(1) TO WS-PREV-CLOSE
           MOVE 0 TO WS-SUM-TR
           PERFORM VARYING WS-I FROM 2 BY 1
                   UNTIL WS-I > WS-PERIOD + 1
               COMPUTE WS-DIFF1 = WS-HIGH-COMP3(WS-I) - 
                   WS-LOW-COMP3(WS-I)
               COMPUTE WS-DIFF2 = WS-HIGH-COMP3(WS-I) - 
                   WS-PREV-CLOSE
               COMPUTE WS-DIFF3 = WS-PREV-CLOSE - 
                   WS-LOW-COMP3(WS-I)
               MOVE WS-DIFF1 TO WS-MAX-DIFF
               IF WS-DIFF2 > WS-MAX-DIFF
                   MOVE WS-DIFF2 TO WS-MAX-DIFF
               END-IF
               IF WS-DIFF3 > WS-MAX-DIFF
                   MOVE WS-DIFF3 TO WS-MAX-DIFF
               END-IF
               ADD WS-MAX-DIFF TO WS-SUM-TR
               MOVE WS-CLOSE-COMP3(WS-I) TO WS-PREV-CLOSE
           END-PERFORM
           COMPUTE WS-ATR ROUNDED = WS-SUM-TR / WS-PERIOD
           COMPUTE WS-START-IDX = WS-PERIOD + 2
           PERFORM VARYING WS-I FROM WS-START-IDX BY 1
                   UNTIL WS-I > WS-COUNT
               COMPUTE WS-DIFF1 = WS-HIGH-COMP3(WS-I) - 
                   WS-LOW-COMP3(WS-I)
               COMPUTE WS-DIFF2 = WS-HIGH-COMP3(WS-I) - 
                   WS-PREV-CLOSE
               COMPUTE WS-DIFF3 = WS-PREV-CLOSE - 
                   WS-LOW-COMP3(WS-I)
               MOVE WS-DIFF1 TO WS-MAX-DIFF
               IF WS-DIFF2 > WS-MAX-DIFF
                   MOVE WS-DIFF2 TO WS-MAX-DIFF
               END-IF
               IF WS-DIFF3 > WS-MAX-DIFF
                   MOVE WS-DIFF3 TO WS-MAX-DIFF
               END-IF
               COMPUTE WS-ATR ROUNDED = 
                   (WS-ATR * (WS-PERIOD - 1) + WS-MAX-DIFF) 
                   / WS-PERIOD
               DISPLAY WS-ATR
               MOVE WS-CLOSE-COMP3(WS-I) TO WS-PREV-CLOSE
           END-PERFORM
           EXIT.

       9000-FINALIZAR.
           CLOSE FD-PRICES-FILE
           EXIT.

       9999-MANEJAR-ERROR-FS.
           EVALUATE WS-PRICES-STATUS
               WHEN "35"
                   MOVE "ERROR: Archivo no encontrado" TO WS-ERROR-MSG
               WHEN "39"
                   MOVE "ERROR: Conflicto de atributos" TO WS-ERROR-MSG
               WHEN OTHER
                   STRING "ERROR: FILE STATUS = " WS-PRICES-STATUS
                       INTO WS-ERROR-MSG
           END-EVALUATE
           DISPLAY WS-ERROR-MSG
           MOVE 1 TO WS-EXIT-CODE
           CLOSE FD-PRICES-FILE
           EXIT.
