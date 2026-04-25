      * COPY BOOK: WS-PRICES-LOAD
      * Dominio: Carga de precios desde archivo secuencial
      * Usado por: SMA, RSI, MACD, Bollinger, ATR, Stochastic
      * Aplica: B-FSTATUS + B-DEBUG
      * Responsabilidad única: leer archivo y llenar tabla.

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
                       COMPUTE WS-PRICE-COMP3(WS-COUNT) ROUNDED = 
                           FUNCTION NUMVAL(FD-PRICE-RAW)
               END-READ
           END-PERFORM
           DISPLAY "[DEBUG] 2000-LEER-PRECIOS - Leidos " WS-COUNT 
               " registros"
           CLOSE FD-PRICES-FILE
           IF WS-COUNT = 0
               MOVE "ERROR: Archivo vacío" TO WS-ERROR-MSG
               DISPLAY WS-ERROR-MSG
               MOVE 1 TO WS-EXIT-CODE
           END-IF.
