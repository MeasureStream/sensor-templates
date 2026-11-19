# Profili d'uso

Un documento per uso (`kind: profile`), pubblicato nel registro come gli altri template e citato
per **(templateId, versione)** dal punto di controllo a cui e' assegnato. Il profilo descrive
l'**uso**, non lo strumento: si assegna al punto di controllo, mai al sensore, e cosi' sostituendo
la MU la serie del punto di controllo resta continua (PIANO_METROLOGIA 4.1–4.3).

| Campo | Significato |
|---|---|
| `quantity`, `dsi` | La grandezza sorvegliata e la sua unita' D-SI |
| `limits` | Limiti fissi del processo: `low`, `high` o entrambi |
| `historicClimate` | In alternativa ai limiti fissi: limiti ricavati dal clima storico (EN 15757) |
| `instrument` | Che cosa si chiede allo strumento: classe, MPE, risoluzione massima |
| `verificationReference` | L'incertezza massima del riferimento delle verifiche intermedie |
| `intervals` | Intervalli di taratura e di verifica intermedia (durate ISO 8601) |
| `recordRetention` | Per quanto conservare le registrazioni |
| `decisionRule` | Banda di guardia U = k·u e dopo quanto la zona di guardia apre un'escursione |
| `sources` | Le norme da cui vengono i numeri |

Il registro rifiuta un profilo senza `quantity`, o senza `limits` e senza `historicClimate`
(`TemplateDocument.requiredFields`).

| Id | Profilo |
|---|---|
| 501 | Conservazione di surgelati, EN 12830 classe 0,5: `high` -18 °C |
| 502 | Beni culturali igroscopici, clima storico secondo la EN 15757 |

## Il clima storico (502)

Il punto di controllo accumula le medie orarie dei suoi valori. Con almeno `minHistoryDays`
giorni di dati, metrology-service calcola per ogni giorno dell'anno la media mobile centrata e la
banda delle fluttuazioni (percentili 7 e 93 degli scarti dalla media, allargata a ±`minHalfBand`
se piu' stretta) e da quel momento valuta i valori nuovi contro il clima dello stesso giorno
dell'anno precedente. Prima, la conformita' e' «non valutabile», ed e' detto nell'interfaccia
con i giorni che mancano.
