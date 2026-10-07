# Repository `platform`

Versione di riferimento: `H-EALTH/platform@v0.4.0`

`platform` contiene i workflow riusabili che ogni prodotto H-EALTH chiama per verificare,
costruire, pubblicare e rilasciare i propri componenti. È una catena di montaggio a stazioni: il
prodotto non scrive logica di CI, dichiara i suoi componenti e chiama la stazione giusta.

## Flussi

| Flusso | Quando parte | Documento |
|---|---|---|
| CI del prodotto | ogni PR e ogni push su `main` | [ci.md](ci.md) |
| Rilascio del prodotto | push di un tag `<prodotto>-vX.Y.Z` | [release.md](release.md) |
| Rilascio di `platform` | nuova versione dei workflow riusabili | [versionamento.md](versionamento.md) |

## Principi

- **Un componente, un artefatto, un digest.** Ogni componente produce un artefatto immutabile su
  GHCR, identificato dal digest `sha256:…`. Il rilascio è la lista dei digest (ADR 0001).
- **Il componente si dichiara.** Un componente è una cartella con un `component.yaml` che ne dice
  il genere: la struttura delle cartelle la decide il prodotto (ADR 0007).
- **Una stazione, una responsabilità.** Chi verifica non costruisce, chi costruisce non rilascia,
  chi rilascia non costruisce.
- **GHCR, senza secret.** Percorso `ghcr.io/h-ealth/<prodotto>/<componente>`, login con il
  `GITHUB_TOKEN` del run (ADR 0002).
- **Riferimenti immutabili.** I prodotti chiamano `platform` con il tag completo (`@v0.3.0`), mai
  `@v1` o `@main`; le action di terze parti sono pinnate allo SHA (ADR 0003).

## Workflow

Tutti hanno `on: workflow_call`: non partono da soli, li chiama un prodotto con `uses:`.

| Workflow | Cosa fa | Flusso |
|---|---|---|
| `discover.yml` | trova i componenti dai `component.yaml` e ne verifica le convenzioni | CI, rilascio |
| `verify-python.yml` | lint, formato e test di un componente Python | CI |
| `verify-node.yml` | `npm ci`, lint, tipi, test e build di un componente Node | CI |
| `scan.yml` | scansione Trivy di sorgenti e, se richiesto, dell'immagine | CI |
| `build-image.yml` | costruisce e pubblica un'immagine su GHCR | CI (via `image`) |
| `image.yml` | catena `build-image` → `scan` dell'immagine, per un componente | CI |
| `publish.yml` | pubblica un artefatto non container (firmware, modello, dist); oggi non usato | — |
| `release.yml` | crea la Release di un prodotto con i digest e le prove | rilascio |

## Stato dell'enforcement

Alcune regole sono oggi **convenzioni, non vincoli applicati da GitHub** (piano Free, repository
dei prodotti privati). Vedi H-93.

| Regola | Stato |
|---|---|
| `ci-ok` obbligatorio per il merge su `main` dei prodotti | non applicato |
| review di `@H-EALTH/engineering` obbligatoria | non applicata (solo `CODEOWNERS`) |
| tag di `platform` non spostabili né cancellabili | non applicato (nessun ruleset) |
