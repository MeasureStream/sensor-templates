# Modelli di MU

Un documento per modello di MU (`kind: mu`). Dice **quali sensori ci sono e in che ordine**:
l'ordine degli slot è l'ordine dei campi nei comandi di configurazione (0x21) e nei report
dati (0x30), quindi è la parte del documento che non si può cambiare senza rompere i
dispositivi in campo. È congelato dal MAJOR di `templateVersion`, che viaggia sul filo come
`MU_TEMPLATE_VERSION` su un byte.

## Modelli presenti

| File | `templateId` | Versione | Slot |
|---|---|---|---|
| `mu_0001.json` | 1 (0x0001) | 0.1.0 | accelerazione (compatibilità), pressione, umidità, NTC |
| `mu_0003.json` | 3 (0x0003) | 0.1.0 | accelerazione X/Y/Z, velocità angolare X/Y/Z |
| `mu_0064.json` | 100 (0x0064) | 0.1.0 | accelerazione, temperatura |

Lo 0x0001 è in MAJOR 0 perché descrive la MU **com'è ora**, non come dovrà essere: il
firmware attuale trasmette ancora un canale di accelerometro in posizione 0 che vale sempre
`0x0000`. Lo slot resta dichiarato perché occupa comunque due byte nel report, e toglierlo
sposterebbe di uno le posizioni di tutti gli altri. Quando il firmware perderà quello slot
si pubblica la 1.0.0 con i soli pressione, umidità e NTC — e sarà un MAJOR nuovo, non una
MINOR. Il sei assi vero è lo 0x0003.

## Com'è fatto uno slot

```json
{ "index": 0, "sensor": { "templateId": 203, "major": 1 }, "label": "pressure", "channel": null }
```

- `index` parte da **0**, come le posizioni sul filo.
- `sensor` cita il template come coppia **(`templateId`, MAJOR)**, mai la versione completa:
  una correzione MINOR del template del sensore non obbliga a ripubblicare il modello di MU.
- `label` è la grandezza dello slot, `channel` l'asse (`X`, `Y`, `Z`) quando lo stesso
  template è istanziato più volte. L'identità dell'asse vive qui, non nel template del
  sensore, che è identico per i tre assi.

## Regole di versione

- **MAJOR 0** è sviluppo: si può sovrascrivere ripubblicando. È lo stato giusto finché il
  firmware non è pronto.
- Dal MAJOR 1 in poi il documento è immutabile. Aggiungere uno slot **in coda** è una MINOR
  solo se il firmware lo trasmette sempre dopo quelli esistenti; spostare o togliere uno
  slot è sempre un nuovo MAJOR.
- Il numero massimo di slot sta in `properties.maxSlots` e deve stare dentro
  `MAX_MODULE_SENSORS` del firmware.

## Da fare

- Template dei sensori **IIM-42652** e **TMP126**, da scrivere dai datasheet: sono quelli
  montati davvero sulla 0x0064, che oggi punta all'LSM6DSM e all'NTC.
- Confermare col firmware la presenza della flash su ciascun modello: oggi `hasFlash` è
  `null`, che significa «non dichiarato», non «assente».
