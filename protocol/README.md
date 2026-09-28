# Dizionario di protocollo

Un documento per versione di protocollo (`kind: protocol`). C'e' una sola famiglia, quindi
`templateId` vale 1 e a identificare il dizionario e' la **versione**: `protocol_v1_2.json`
descrive il protocollo v1.2, ed e' oggi alla **1.2.1**.

## Cosa contiene

- **Le scale non lineari dei periodi**, campionamento e trasmissione, in forma uniforme:
  `secondi(idx) = base + (idx - from) * step`. Chi la legge non deve conoscere gli scalini,
  li ricava.
- **Gli indici delle tacche** degli slider: sono indici veri, l'etichetta la calcola chi
  disegna con la stessa funzione che etichetta il cursore.
- **Le sentinelle**: batteria 254 (rete) e 255 (in carica); metrica 0xFFFF su media e varianza
  insieme (nessun dato nuovo). `0x0000` e' invece un valore legittimo.
- **L'ordine canonico delle metriche** (`metrics`): nome, dimensione in byte, classe di
  cadenza e bit nella `Stat bitmap`. E' l'ordine in cui i campi viaggiano nel report, quindi
  una metrica nuova si aggiunge **solo in coda**.
- **Le classi del byte CONTENT** (`contentClasses`) e le **regole di frammentazione**
  (`fragmentation`): quest'ultima non e' nel protocollo, perche' `FRAG` non porta un
  identificatore di report — la regola che il server applica e' scritta qui.
- **I bit della parola di stato della CU** (`statusBits`) e **di una MU** (`muStatusBits`),
  con la distinzione fra stati, che si spengono da soli, ed eventi, che restano latchati
  finche' il server non li conferma.

## Cosa non contiene ancora

`eventCodes` e `alarmBits` sono presenti ma **vuoti**. I codici che il server conosce stanno
in `sensor-manager/template/AlarmCatalog.kt`, insieme alla logica che risolve quelli dei
costruttori dai modelli di MU: duplicarli qui adesso significherebbe avere due verita' diverse
sullo stesso byte. Si spostano quando saranno una tabella sola con quella del firmware.

## Chi lo legge

- `sensor-manager`: `ProtocolService`. Ne ricava il periodo di trasmissione (per decidere se
  una CU e' online), l'ordine e la dimensione delle metriche del report, le classi del
  CONTENT, le regole dei frammenti e i testi dei bit di stato. Se il dizionario manca, il
  server **non** usa una tabella di scorta: ricade sul proprio valore di sicurezza.
- `frontend`: lo scarica all'avvio (`API/protocol/protocolAPI.ts`) e da quel momento gli
  slider usano la scala pubblicata. I testi dei bit di stato **non** li risolve: arrivano
  gia' tradotti nel DTO della CU e della MU.

## Versionare il dizionario

La 1.2.0 e' pubblicata, quindi immutabile: le tabelle aggiunte dopo sono uscite come 1.2.1.
Vale la regola generale — si aggiunge in coda e si pubblica una versione nuova, non si
modifica una versione esistente, perche' uno storico va riletto con le codifiche con cui e'
stato scritto.
