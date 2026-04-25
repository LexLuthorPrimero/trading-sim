       IDENTIFICATION DIVISION.
       PROGRAM-ID. STOCHASTIC.
      * Indicador: Stochastic Oscillator
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
       01  WS-J               PIC 9(4) COMP.
       01  WS-K-PERIOD        PIC 9(2) COMP VALUE 14.
       01  WS-D-PERIOD        PIC 9(2) COMP VALUE 3.
       01  WS-HIGHEST         PIC 9(5)V99 COMP-3.
       01  WS-LOWEST          PIC 9(5)V99 COMP-3.
       01  WS-PCT-K           PIC 9(3)V99.
       01  WS-PCT-D           PIC 9(3)V99.
       01  WS-SUM-D           PIC 9(5)V99 COMP-3.
       01  WS-START-IDX       PIC 9(4) COMP.
       01  WS-START-D         PIC 9(4) COMP.
       01  WS-EXIT-CODE       PIC S9(4) COMP VALUE 0.
       01  WS-ERROR-MSG       PIC X(100).
       PROCEDURE DIVISION.
       MAIN.
           DISPLAY "[DEBUG] 1000-INICIO - Programa STOCHASTIC iniciado"
           ACCEPT WS-PRICES-PATH FROM COMMAND-LINE
           IF WS-PRICES-PATH = SPACES
               MOVE "prices.dat" TO WS-PRICES-PATH
           END-IF
           DISPLAY "[DEBUG] 2000-LEER-PRECIOS - Leyendo archivo: " 
               WS-PRICES-PATH
           COPY WS-PRICES-LOAD-HLC.
           IF WS-EXIT-CODE NOT = 0
               PERFORM 9000-FINALIZAR
               STOP RUN
           END-IF
           DISPLAY "[DEBUG] 3000-CALCULAR-STOCH - Procesando " 
               WS-COUNT " precios con K=" WS-K-PERIOD " D=" WS-D-PERIOD
           PERFORM 3000-CALCULAR-STOCH
           DISPLAY "[DEBUG] 9000-FINALIZAR - "
                   "Programa STOCHASTIC finalizado"
           PERFORM 9000-FINALIZAR
           STOP RUN.

       3000-CALCULAR-STOCH.
           PERFORM VARYING WS-I FROM WS-K-PERIOD BY 1
                   UNTIL WS-I > WS-COUNT
               MOVE WS-HIGH-COMP3(WS-I) TO WS-HIGHEST
               MOVE WS-LOW-COMP3(WS-I) TO WS-LOWEST
               COMPUTE WS-START-IDX = WS-I - WS-K-PERIOD + 1
               PERFORM VARYING WS-J FROM WS-START-IDX BY 1
                       UNTIL WS-J > WS-I
                   IF WS-HIGH-COMP3(WS-J) > WS-HIGHEST
                       MOVE WS-HIGH-COMP3(WS-J) TO WS-HIGHEST
                   END-IF
                   IF WS-LOW-COMP3(WS-J) < WS-LOWEST
                       MOVE WS-LOW-COMP3(WS-J) TO WS-LOWEST
                   END-IF
               END-PERFORM
               COMPUTE WS-PCT-K ROUNDED = 100 *
                   (WS-CLOSE-COMP3(WS-I) - WS-LOWEST) /
                   (WS-HIGHEST - WS-LOWEST + 0.0001)
               MOVE 0 TO WS-SUM-D
               COMPUTE WS-START-D = WS-I - WS-D-PERIOD + 1
               PERFORM VARYING WS-J FROM WS-START-D BY 1
                       UNTIL WS-J > WS-I
                   ADD WS-PCT-K TO WS-SUM-D
               END-PERFORM
               COMPUTE WS-PCT-D ROUNDED = WS-SUM-D / WS-D-PERIOD
               DISPLAY WS-PCT-K " " WS-PCT-D
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
