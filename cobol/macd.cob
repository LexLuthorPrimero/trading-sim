       IDENTIFICATION DIVISION.
       PROGRAM-ID. MACD.
      * Indicador: Moving Average Convergence Divergence
      * Versión:   B-COPY + B-DEBUG + B-FSTATUS + B-NAMING
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
           05 FD-PRICE-RAW      PIC X(10).
       WORKING-STORAGE SECTION.
       01  WS-PRICES-STATUS   PIC XX.
           88  WS-PRICES-OK           VALUE "00".
           88  WS-PRICES-EOF          VALUE "10".
       01  WS-PRICES-PATH     PIC X(200).
       01  WS-PRICES-TABLE.
           05 WS-PRICE-ENTRY OCCURS 1000 TIMES
              INDEXED BY WS-PRICE-IDX.
              10 WS-PRICE-COMP3  PIC 9(5)V99 COMP-3.
       01  WS-COUNT           PIC 9(4) COMP VALUE 0.
       01  WS-I               PIC 9(4) COMP.
       01  WS-FAST            PIC 9(2) COMP VALUE 12.
       01  WS-SLOW            PIC 9(2) COMP VALUE 26.
       01  WS-SIGNAL          PIC 9(2) COMP VALUE 9.
       01  WS-EMA-FAST        PIC 9(7)V99 COMP-3.
       01  WS-EMA-SLOW        PIC 9(7)V99 COMP-3.
       01  WS-EMA-SIGNAL      PIC 9(7)V99 COMP-3.
       01  WS-MACD-LINE       PIC S9(7)V99 COMP-3.
       01  WS-HISTOGRAM       PIC S9(7)V99 COMP-3.
       01  WS-ALPHA-FAST      PIC V99.
       01  WS-ALPHA-SLOW      PIC V99.
       01  WS-ALPHA-SIGNAL    PIC V99.
       01  WS-TEMP1           PIC 9(7)V99 COMP-3.
       01  WS-TEMP2           PIC 9(7)V99 COMP-3.
       01  WS-TEMP3           PIC 9(7)V99 COMP-3.
       01  WS-TEMP4           PIC 9(7)V99 COMP-3.
       01  WS-EXIT-CODE       PIC S9(4) COMP VALUE 0.
       01  WS-ERROR-MSG       PIC X(100).
       PROCEDURE DIVISION.
       MAIN.
           DISPLAY "[DEBUG] 1000-INICIO - Programa MACD iniciado"
           ACCEPT WS-PRICES-PATH FROM COMMAND-LINE
           IF WS-PRICES-PATH = SPACES
               MOVE "prices.dat" TO WS-PRICES-PATH
           END-IF
           DISPLAY "[DEBUG] 2000-LEER-PRECIOS - Leyendo archivo: " 
               WS-PRICES-PATH
           COPY WS-PRICES-LOAD.
           IF WS-EXIT-CODE NOT = 0
               PERFORM 9000-FINALIZAR
               STOP RUN
           END-IF
           DISPLAY "[DEBUG] 3000-CALCULAR-MACD - Procesando " WS-COUNT 
               " precios"
           PERFORM 3000-CALCULAR-MACD
           DISPLAY "[DEBUG] 9000-FINALIZAR - "
                   "Programa MACD finalizado"
           PERFORM 9000-FINALIZAR
           STOP RUN.

       3000-CALCULAR-MACD.
           COMPUTE WS-ALPHA-FAST = 2 / (WS-FAST + 1)
           COMPUTE WS-ALPHA-SLOW = 2 / (WS-SLOW + 1)
           COMPUTE WS-ALPHA-SIGNAL = 2 / (WS-SIGNAL + 1)
           MOVE WS-PRICE-COMP3(1) TO WS-EMA-FAST
           MOVE WS-PRICE-COMP3(1) TO WS-EMA-SLOW
           PERFORM VARYING WS-I FROM 2 BY 1
                   UNTIL WS-I > WS-COUNT
               COMPUTE WS-TEMP1 = WS-PRICE-COMP3(WS-I) *
                   WS-ALPHA-FAST
               COMPUTE WS-TEMP2 = WS-EMA-FAST *
                   (1 - WS-ALPHA-FAST)
               COMPUTE WS-EMA-FAST ROUNDED = WS-TEMP1 + WS-TEMP2
               COMPUTE WS-TEMP3 = WS-PRICE-COMP3(WS-I) *
                   WS-ALPHA-SLOW
               COMPUTE WS-TEMP4 = WS-EMA-SLOW *
                   (1 - WS-ALPHA-SLOW)
               COMPUTE WS-EMA-SLOW ROUNDED = WS-TEMP3 + WS-TEMP4
           END-PERFORM
           COMPUTE WS-MACD-LINE ROUNDED = WS-EMA-FAST - WS-EMA-SLOW
           MOVE WS-MACD-LINE TO WS-EMA-SIGNAL
           PERFORM VARYING WS-I FROM 2 BY 1
                   UNTIL WS-I > WS-SIGNAL
               COMPUTE WS-EMA-SIGNAL ROUNDED = WS-MACD-LINE *
                   WS-ALPHA-SIGNAL + WS-EMA-SIGNAL *
                   (1 - WS-ALPHA-SIGNAL)
           END-PERFORM
           COMPUTE WS-HISTOGRAM ROUNDED = WS-MACD-LINE -
               WS-EMA-SIGNAL
           DISPLAY WS-MACD-LINE " " WS-EMA-SIGNAL " "
               WS-HISTOGRAM
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
