# Dizionario di protocollo

Un documento per versione di protocollo (`kind: protocol`). C'e' una sola famiglia, quindi
`templateId` vale 1 e a identificare il dizionario e' la **versione**: `protocol_v1_2.json`
descrive il protocollo v1.2.

## Cosa contiene

- **Le scale non lineari dei periodi**, campionamento e trasmissione, in forma uniforme:
  `secondi(idx) = base + (idx - from) * step`. Chi la legge non deve conoscere gli scalini,
  li ricava.
- **Gli indici delle tacche** degli slider: sono indici veri, l'etichetta la calcola chi
  disegna con la stessa funzione che etichetta il cursore.
- **Le sentinelle**: batteria 254 (rete) e 255 (in carica); metrica 0xFFFF su media e varianza
  insieme (nessun dato nuovo). `0x0000` e' invece un valore legittimo.

## Cosa non contiene ancora

`statusBits`, `eventCodes` e `alarmBits` sono presenti ma **vuoti**, e il motivo e' scritto
dentro il documento: il byte di stato della CU arriva ma nessun bit e' documentato. Riempirli
di ipotesi significherebbe scriverle nel posto in cui tutti le leggeranno come vere.

I codici evento che il server conosce (0x01, 0x40-0x43) stanno per ora in
`sensor-manager/template/AlarmCatalog.kt`; si spostano qui quando il dizionario cresce.

## Chi lo legge

- `sensor-manager`: `ProtocolService` per il periodo di trasmissione, che serve a decidere se
  una CU e' online. Se il dizionario manca, il server **non** usa una tabella di scorta:
  ricade sulla soglia minima.
- `frontend`: lo scarica all'avvio (`API/protocol/protocolAPI.ts`) e da quel momento gli
  slider usano la scala pubblicata.
