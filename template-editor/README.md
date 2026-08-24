# Editor Template Sensori — MeasureStream

Editor e validatore dei template JSON di `sensor-templates` (quelli che
`TemplateService` carica da `/app/templates`). File singolo, zero dipendenze,
nessuna installazione:

```bash
start "" "sensor-templates/template-editor/index.html"
```

Oppure, se serve servirlo via HTTP (è già registrato in `.claude/launch.json`,
con radice `sensor-templates/` così che i template siano raggiungibili):

```bash
python -m http.server 8777 --directory sensor-templates
```

Funziona offline, non invia niente in rete, non tocca i file del repo: si apre un
JSON esistente (bottone **Apri** o drag & drop) e si scarica il risultato.

## Due modi d'uso

**Editor** — *Apri* (o trascina un singolo file) per modificare o creare un template,
con anteprima e validazione live.

**Validazione** — *Valida file…* (selezione multipla), *Valida cartella…* (l'intera
`sensor-templates/`) oppure il trascinamento di più file insieme: nessuna modifica,
solo un referto. Per ogni file: sintassi JSON, campi obbligatori mancanti, avvisi,
presenza di old semantic. In più i controlli **fra file**, che l'editor da solo non
può fare:

- `modelName` duplicati — `TemplateService` li indicizza sulla stessa chiave e
  l'ultimo caricato sovrascrive silenziosamente gli altri;
- `templateId` duplicati;
- nome file diverso da `modelName` — il caricamento indicizza per `modelName` mentre
  `TemplateService.removeTemplate` usa il nome del file, quindi alla cancellazione di
  un template la mappa in memoria non si svuota.

Da ogni riga del referto si passa direttamente all'editor, e il referto si copia
come testo con *Copia report*.

## Cosa fa

- form completo su tutti i campi del template, con **anteprima JSON live** e
  **validazione** dei campi obbligatori (errori rossi / avvisi gialli);
- **duplica / aggiungi / rimuovi** sui blocchi ripetibili;
- **preserva tutto ciò che non conosce**: chiavi ignote, commenti `usercomment_*`
  (con la loro posizione), blocchi annidati. Il round-trip apri → salva è verificato
  a parità di contenuto su tutti e 5 i template del repo;
- **banner rosso sulla old semantic** (vedi sotto);
- controllo incrociato su `type` / `quantity`: segnala i template in cui `type`
  contiene ancora una grandezza (vecchia convenzione), i due campi invertiti o
  valorizzati uguali;
- preset D-SI (`\degreeCelsius`, `\coulomb`, `\millibar`, …) che riempiono in un
  colpo `dsi` + `si[8]` + `siExp`;
- lettura tollerante dei file con virgole finali, con avviso esplicito.

## Classificazione dei campi

### Obbligatori e fissi (uno solo, non eliminabili)

| Campo | Note |
|---|---|
| `schemaVersion` | forma `X.Y.Z`; attuale `2.0.0` |
| `modelName` | chiave di lookup lato backend (`TemplateService`, case-insensitive) |
| `mpn`, `manufacturer`, `datasheet` | identificazione del componente |
| `templateId` | intero univoco (in uso: 201–204, 301) |
| `type` | tipo di sensore (es. `accelerometer`, `thermometer`, `barometer`) |
| `quantity` | grandezza misurata (es. `acceleration`, `temperature`, `pressure`) |
| `unit` | unità dei valori restituiti |
| `elecUnit` | unità della lettura elettrica grezza |
| `calibration.type` | `none` disattiva i controlli sulla formula |
| `metrology.evaluationFormula` | `varName` da usare come incertezza tipo, oppure `RSS` |
| `metrology.calDate` / `calPeriod` / `certificateId` | epoch (0 = non calibrato) / giorni / stringa anche vuota |

### Obbligatori ma con struttura ripetibile

| Blocco | Voci obbligatorie | Voci aggiungibili |
|---|---|---|
| `ranges` | `phys`, `elec`, `sampling`, `threshold` | qualunque altro range (`physROC` è raccomandato; `operatingEnvironment` esiste già in `fluke_9142`) |
| `properties` | `responseTime`, `readingConsumption` | qualunque grandezza `<nome>` + `<nome>SiExp` / `Si` / `Dsi` (es. `selfHeat`, `immersionDepth`) |
| `calibration.c[]` | ≥ 1 coefficiente se `type != none` | coefficienti `c[0..n]` |
| `metrology.readingUncertainty[]` | ≥ 1 voce | voci `varName` / `value` / `PDF` / `coverageFactor` \| `k` / `description` |

Ogni range può essere *solo min/max* (come `threshold`) oppure completo di unità
(`siExp` + `si[8]` + `dsi`).

### Opzionali

- `metrology.requiredInputs[]`, `metrology.Uncertainty[]`;
- **campi personalizzati**: alla radice, dentro `calibration`, dentro `metrology`,
  dentro `properties` e dentro il singolo range. Possono essere valori semplici
  (testo / numero / booleano) oppure **blocchi JSON annidati** arbitrari;
- **commenti inline** `usercomment_*`: si possono aggiungere, e si sceglie davanti
  a quale chiave devono comparire.

## Old semantic

L'editor **non genera più** `calibration.coefficients` né
`calibration.calibrationCoefficients`, e nemmeno `metrology.UncertaintyPdf` /
`metrology.Uncertainty` in forma `referenceValue` / `absUncertainty` / `uc` / `k`.

Se un file aperto li contiene (o dichiara `schemaVersion < 2.0.0`) compare un
**banner rosso** in testa alla pagina e i blocchi legacy vengono mostrati in sola
lettura e **ricopiati identici nel file di output**. C'è un bottone esplicito per
rimuoverli, ma è una scelta manuale.

Al loro posto, nuova semantica:

```jsonc
"calibration": {
  "type": "steinhart_201",
  "steinhart_201": "1.0 / (c[0] + c[1] * ln(4095.0 / x - 1.0) + ...)",
  "input": ["x"],
  "c": [ { "id": 0, "value": 3.19414e-3, "siExp": 0, "si": [...], "dsi": "\\kelvin\\tothe{-1}" } ]
}
```

## Vettore `si[8]`

Gli slot sono etichettati in cima al `<script>` (costante `SI_LABELS`):

```
[ ? , m , s , A , K , mol , kg , cd ]
```

Gli indici **1 (m), 2 (s), 3 (A), 4 (K), 6 (kg)** sono ricavati con certezza dai
template esistenti (`\coulomb` → `[0,0,1,1,0,0,0,0]` = s·A; `\millibar` →
`[0,-1,-2,0,0,0,1,0]` = kg·m⁻¹·s⁻²). Gli slot **0, 5, 7** non sono mai valorizzati
in nessun template, quindi le etichette sono un'ipotesi: se la convenzione è
diversa, si corregge solo `SI_LABELS` / `SI_TITLES`.

## Limiti noti

- i numeri vengono riscritti da `JSON.stringify`: il valore è identico, la notazione
  può cambiare (`3.19414e-3` → `0.00319414`). Vale anche per i blocchi legacy,
  che sono ricopiati per contenuto, non per byte;
- i campi ignoti alla radice vengono riemessi in coda al file, non nella posizione
  originale (l'ordine dello schema noto è invece rispettato).
