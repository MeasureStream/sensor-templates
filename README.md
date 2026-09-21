# sensor-templates — struttura del repository

Un template descrive un **modello**, mai un esemplare e mai un canale. È un documento
JSON versionato: una volta pubblicato non si modifica più, si pubblica la versione
successiva. Il server non legge più questi file a ogni avvio come unica fonte: li importa
una volta come seme nel registro dei template di `sensor-manager`, che da lì in poi è
l'unica fonte a runtime (`GET /API/templates`).

## Le cinque famiglie

| Cartella | `kind` | `templateId` | Che cosa descrive | Chi lo referenzia |
|---|---|---|---|---|
| `sensors/` | `sensor` | 2xx | Un modello di sensore: grandezza, range, metriche trasmesse, calibrazione, incertezza | Gli slot di un modello di MU |
| `references/` | `reference` | 3xx | Un modello di campione di riferimento usato in taratura (il Fluke 9142) | La sezione Metrologia, non le MU |
| `mu/` | `mu` | modello di MU (0x0001, 0x0003, 0x0064…) | Ordine canonico degli slot, template di ciascuno, presenza della flash | Le MU censite dal server |
| `cu/` | `cu` | modello di CU | Limiti e capacità della CU: numero di MU, GPS, alimentazione | Le CU censite dal server |
| `protocol/` | `protocol` | `ProtocolVer` | Dizionario del protocollo: codifiche dei periodi, bit di stato, codici evento | Server e interfaccia |

`mu/`, `cu/` e `protocol/` sono predisposte: i primi documenti arrivano con i passi 9 e 12
della scaletta. Ogni documento è identificato dalla coppia **(`templateId`, MAJOR)**: un
riferimento cita sempre il MAJOR, mai la versione completa, e il registro risolve la
versione pubblicata più alta dentro quel MAJOR.

## Le due versioni di un template

| Campo | Significato |
|---|---|
| `schemaVersion` | Versione dello **schema del documento** — oggi `2.1.0` per tutti |
| `templateVersion` | Versione di **questo modello**. Il MAJOR viaggia sul filo su 1 byte; cambiarlo significa ordine canonico incompatibile. MINOR e PATCH sono aggiunte in coda, retrocompatibili |

MAJOR `0` è lo sviluppo: si può sovrascrivere. Dal MAJOR 1 in poi una versione pubblicata
è immutabile e nessuna versione si cancella, perché i dati storici vanno decodificati con
il template con cui sono stati letti.

## Che cosa aggiunge lo schema 2.1.0

Solo aggiunte: nessun campo esistente cambia significato.

| Campo | Dove | A che serve |
|---|---|---|
| `schemaVersion` | radice | Separare la versione dello schema da quella del modello |
| `outputFormat` | radice | `uncalibrated`: il dispositivo trasmette la **lettura grezza** e il server applica `calibration`. `calibrated`: trasmette la **stima del misurando** già tarata e il server non converte. È il default del modello; la singola metrica può dire la sua con `domain` |
| `encoding` | ogni `supportedMetrics[]` | `u16` · `i16` · `u32` · `i32`: leggere il segno giusto. Accelerometro e giroscopio sono con segno, la varianza mai |
| `domain` | ogni `supportedMetrics[]` | `elec` (valore grezzo) o `phys` (già tarato a bordo). Oggi sempre `elec`: quando la MU trasmetterà valori già convertiti basterà pubblicare una versione con `domain: "phys"` e `encoding: "i16"`, senza toccare il server |
| `transform` | ogni `supportedMetrics[]` | Come si converte: `calibration` (media, max, min), `variance` (propagazione con la derivata locale), `integral` (salvato grezzo), `none` |
| `adcBits` | `ranges.elec` | Ampiezza del **campo trasmesso** nel report (oggi 16 bit per tutti). `min` e `max` restano il valore elettrico che il sensore puo' assumere: per l'NTC 4095, perche' la formula di Steinhart contiene `4095/x - 1` |
| `ranges.sampling` | — | Definito come **periodo di acquisizione** accettato dallo slot, non come ODR del chip |

## Calibrazione

Tutti i sensori usano ora la forma introdotta con la 2.0.0: `type`, una formula sotto la
chiave omonima, `input[]` e `c[]` con valore e unità di ogni coefficiente. La vecchia
coppia `coefficients[]` + `calibrationCoefficients{}` non va più prodotta.

```json
"calibration": {
  "type": "linear",
  "linear": "c[0] + c[1] * x",
  "input": ["x"],
  "c": [ { "id": 0, "value": 0.0, "dsi": "..." }, { "id": 1, "value": 0.0047856, "dsi": "..." } ]
}
```

Il backend legge `calibration`; la chiave `conversion` non esiste più in nessun file.

## Aggiungere o modificare un template

1. Si lavora su un branch e si apre una pull request: la revisione umana è ancora l'unica
   validazione completa (il validatore automatico arriva con il passo 8).
2. Il registro rifiuta comunque un documento che non sia JSON valido, che non dichiari
   `templateId` e `templateVersion`, o la cui versione sia già pubblicata.
3. Alla pubblicazione il registro calcola l'impronta SHA-256 del contenuto normalizzato:
   due documenti identici non si duplicano.
4. La scheda corrispondente in `docs/Schede_Template_Sensori_MeasureStream.docx` va
   aggiornata insieme al JSON, non dopo.

Lo stato dei lavori aperti e le decisioni ancora da prendere stanno in `readme.txt`.
