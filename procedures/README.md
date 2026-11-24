# Procedure di taratura

Un documento per metodo (`kind: procedure`), pubblicato nel registro come gli altri template
e citato per **(templateId, versione)** da ogni sessione di taratura e da ogni DCC
(`usedMethods`). Le procedure prendono il posto dei metodi scelti a mano nel wizard di Mario
(`calibration_method`).

| Campo | Significato |
|---|---|
| `quantity`, `dsi` | La grandezza tarata e la sua unita' D-SI |
| `reference` | Il modello di campione richiesto, per (templateId, MAJOR) |
| `points` | I punti del fit, nell'unita' della grandezza |
| `stability` | Quando un gradino e' stabile: pendenza massima su una finestra ISO 8601 |
| `readings` | Quante letture per gradino: blocchi da `blockSize`, `blocks` volte |
| `hysteresis` | Se percorrere i punti in salita e in discesa (umidita') |
| `asLeft.points` | Punti di verifica indipendenti, per l'as-left |
| `methodUncertainty` | Contributi del metodo, come incertezza tipo |
| `decisionRule` | La regola decisionale: `guarded` con la PFA massima |

Il registro rifiuta una procedura senza `quantity` o senza `points` numerici, e un
`reference` che non citi `templateId` e `major` (`TemplateParser.requiredFields`).

| Id | Procedura |
|---|---|
| 401 | Taratura per confronto in pozzetto a secco (Fluke 9142, template 301) |

I **profili** (`kind: profile`, cartella `profiles/`) seguono le stesse regole e arrivano con
la fase 4 del piano: 501 per la conservazione dei surgelati secondo la EN 12830.
