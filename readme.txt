================================================================================
  sensor-templates - stato e lavori aperti
  aggiornato: 1 settembre 2026
================================================================================

I template descrivono un MODELLO DI SENSORE: una grandezza, un'unita', un range,
una taratura, un'incertezza. Non descrivono un canale ne' un dispositivo.

  template          = il modello di sensore (questo repo)
  slot sensore      = una posizione nel protocollo, con un Sampl.T, una coppia
                      di soglie, un valore grezzo e un set di metriche
  modello di MU     = la mappa che dice quale slot usa quale template

Un template puo' essere istanziato piu' volte. Tre slot che puntano allo stesso
modelName sono tre canali dello stesso modello: e' il caso degli assi dell'IMU.

Template presenti:

  201  TemperatureSensorNTC      temperature        ntc_temperature.json
  202  HumiditySensorHTU21D      humidity           humidity_hpp845e.json
  203  PressureSensorMS5837      pressure           pressure_ms5837.json
  204  AccelerometerLSM6DSM      acceleration       accelerometer_lsm6dsm.json
  205  GyroscopeLSM6DSM          angular_velocity   gyroscope_lsm6dsm.json
  301  FieldMetrologyWell_9142   temperature        fluke_9142.json   (campione)


================================================================================
  TODO 1 - Modello di MU con l'IMU a sei assi                      [ APERTO ]
================================================================================

OBIETTIVO
  Trattare i sei assi dell'LSM6DSM come sensori a se' stanti, in modo da
  ottenere da ciascuno media, varianza e le altre metriche.

MAPPA DEGLI SLOT da adottare nel modello di MU:

    slot 1  ->  accel X      template 204  AccelerometerLSM6DSM
    slot 2  ->  accel Y      template 204  AccelerometerLSM6DSM
    slot 3  ->  accel Z      template 204  AccelerometerLSM6DSM
    slot 4  ->  gyro  X      template 205  GyroscopeLSM6DSM
    slot 5  ->  gyro  Y      template 205  GyroscopeLSM6DSM
    slot 6  ->  gyro  Z      template 205  GyroscopeLSM6DSM
    slot 7  ->  pressione    template 203
    slot 8  ->  umidita'     template 202
    slot 9  ->  NTC          template 201

  L'ordine degli slot e' quello in cui i sensori compaiono nei comandi di
  configurazione (0x21) e nei report dati (0x30): cambiarlo dopo il rilascio
  rompe i dispositivi in campo, quindi va congelato con la Template version
  della MU.

PERCHE' DUE TEMPLATE E NON SEI
  I tre assi dell'accelerometro sono identici in ogni campo che il template
  trasporta: stesso fondo scala, stessa sensibilita', stesso rumore, stesso ODR.
  Non c'e' un solo valore che cambi fra X, Y e Z, quindi un file per i tre assi
  non e' un compromesso ma la descrizione corretta.
  Accelerometro e giroscopio sono invece grandezze diverse, con unita', range,
  sensibilita' e rumore propri: due file separati servono davvero.

DOVE VIVE L'IDENTITA' DELL'ASSE
  NON nel template, che e' condiviso fra i tre assi e non potrebbe distinguerli.
  Vive nella mappa dei sensori della MU, cioe' nel modello di dispositivo.
  Se serve mostrarla in interfaccia, e' un attributo dell'istanza sensore
  (accanto a sensorIndex), non un campo del template.

COSA SERVE LATO SERVER
  - un modello di MU che elenchi i nove slot con il rispettivo template
  - un'etichetta di canale sull'istanza sensore (X / Y / Z), opzionale ma utile
  - nessuna modifica allo schema dei template: tre righe Sensor possono gia'
    puntare allo stesso modelName

COSA SERVE LATO FIRMWARE MU  (il costo vero, da dimensionare prima)
  - peripheral.h:25   #define MAX_MODULE_SENSORS 4   ->   9
  - ogni sensor_config_t contiene data[BUFF_MAX_DIM] di uint16, cioe' 512 byte
    di buffer piu' il resto della struttura: nove sensori sono circa 5.4 kB di
    RAM sui 48 dell'STM32WB30, condivisi con lo stack BLE. Va verificato, non
    dato per scontato.
  - lettura effettiva del giroscopio, che oggi non e' implementata
  - la risposta al comando 0x30 (numero sensori) passa da 4 a 9, e con essa la
    lunghezza dello stream di configurazione e la dimensione dei report

ALTERNATIVA SCARTATA
  Un unico file con un blocco channels[] sarebbe piu' fedele all'hardware (un
  solo mpn, un solo datasheet, un solo templateId), ma richiede che il backend
  impari il concetto di canale. Da riprendere solo se il numero di file
  diventasse un problema.


================================================================================
  TODO 2 - Deserializzazione dei template lato backend        [ DA VERIFICARE ]
================================================================================

  SensorTemplate.kt dichiara sette campi e non ha
  @JsonIgnoreProperties(ignoreUnknown = true); TemplateService usa un
  ObjectMapper() costruito a mano, quindi con FAIL_ON_UNKNOWN_PROPERTIES a true,
  che e' il default di Jackson e non quello rilassato di Spring Boot.

  Ne segue che readValue dovrebbe sollevare sul primo campo sconosciuto, cioe'
  templateVersion, che e' la prima chiave di ogni file. Anche superandolo,
  ranges e' dichiarato Map<String, Map<String, Double>> e non puo' contenere
  ne' si (array) ne' dsi (stringa).

  Da verificare avviando il servizio e guardando se loadTemplates solleva
  UnrecognizedPropertyException. Se confermato, nessun template viene caricato
  oggi, e la sezione calibration non e' l'unica cosa che si perde.

  Conseguenze da sistemare:
  - allineare i nomi: i file usano "calibration", la data class usa "conversion"
  - tipizzare ranges in modo da reggere siExp / si / dsi
  - accettare i campi nuovi: templateVersion, supportedMetrics, quantity,
    elecUnit, mpn, manufacturer, datasheet, templateId, usercomment_*
  - avvolgere il caricamento in un try/catch per template, cosi' un file rotto
    non fa fallire l'intera cartella


================================================================================
  TODO 3 - Migrazione alla semantica 2.0.0                         [ APERTO ]
================================================================================

  ntc_temperature e gyroscope_lsm6dsm usano la semantica corrente: formula
  esplicita sotto una chiave omonima a calibration.type, ingressi in input[],
  coefficienti in c[] con unita' individuali.

  accelerometer, humidity, pressure e fluke usano ancora la vecchia:
  coefficients (array piatto) piu' calibrationCoefficients (mappa A, B, C, D con
  le sole unita'), senza formula. Sul lato incertezze l'equivalente superato e'
  UncertaintyPdf con voci referenceValue / absUncertainty / uc / k.

  Regola operativa: non produrre piu' quei blocchi nei file nuovi. In quelli
  esistenti vanno ricopiati invariati finche' non si decide una migrazione
  completa, che va fatta consapevolmente perche' richiede di scrivere le formule
  di conversione che oggi non ci sono.


================================================================================
  TODO 4 - Punti minori ancora aperti
================================================================================

  - metrology.Uncertainty convive in due forme (varName/value/PDF della 2.0.0 e
    referenceValue/absUncertainty/uc/k della 1.0.0). Decidere se la seconda e'
    transitoria o se devono coesistere stabilmente.

  - vettore si[8]: gli indici 1 (m), 2 (s), 3 (A), 4 (K), 6 (kg) sono deducibili
    con certezza dai template. Gli indici 0, 5 e 7 non compaiono mai valorizzati:
    l'ipotesi e' adimensionale, mole, candela. Da confermare con chi ha definito
    lo schema.

  - grafie D-SI non uniformi: convivono \meter\per\second\squared e la forma
    \tothe{2}. Fissare una convenzione prima che i file si moltiplichino.

  - unicita' di templateId e modelName non verificata a caricamento: due
    template omonimi si sovrascrivono in silenzio nella mappa di TemplateService,
    la cui chiave e' modelName in minuscolo. Oggi non ci sono duplicati.

  - template-editor: conosce templateVersion ma non supportedMetrics, che
    conserva come campo libero rimettendolo in coda al file invece che prima di
    ranges. Aggiungere il blocco all'editor quando il formato sara' stabile.

  - accelerometer_lsm6dsm: metrology contiene ancora "comment": "To be
    implemented" e valori a zero. Da riempire con i dati di targa, come e' stato
    fatto per il giroscopio.


================================================================================
  Riferimenti
================================================================================

  Protocollo v1.0            ordine canonico delle metriche, classi BASE /
                             EXTENDED / RARE, report dati su FPort 0x30
  Struttura_Template_Sensori campi obbligatori, blocchi ripetibili, semantiche
  Schede_Template_Sensori    ../Schede_Template_Sensori_MeasureStream.docx
                             una scheda per sensore: da dove viene ogni valore
                             del template, che sia di targa, derivato, una
                             convenzione o da determinare in taratura.
                             Va aggiornata insieme al file JSON, non dopo.
  template-editor/README.md  uso dell'editor e regole di validazione
