# platform

La "fabbrica di viti standard" di H-EALTH: i workflow di CI, build e rilascio che ogni prodotto usa senza copiarli. Cambi qui, cambia per tutti al prossimo aggiornamento di versione.

Questo README spiega **come** si usa. Il **perché** è su Notion ([Engineering hub](https://app.notion.com/p/3cf4af5aa4ca80f0b68add41f4ef1d43), [Continuous Delivery](https://app.notion.com/p/3d64af5aa4ca806a882ce4330eec9347)); le decisioni sono in [`docs/adr/`](docs/adr/); la regola formale è `HE-SOP-004` e `HE-SOP-005` su Drive `H-EALTH_AZIENDA`, che prevale su tutto.

## Layout

```
platform/
├── .github/workflows/
│   ├── ci-python.yml          # workflow_call: lint + test di un servizio Python
│   ├── ci-node.yml            # workflow_call: lint + test + build di un'app web
│   ├── build-image.yml        # workflow_call: build + push GHCR, output digest
│   └── release.yml            # workflow_call: valida il tag <prodotto>-vX.Y.Z, crea la Release + SBOM
├── actions/
│   └── setup-python/          # composite: python + cache + pip install
├── rulesets/
│   ├── main.json              # ruleset applicato a main in ogni prodotto
│   └── tags.json              # ruleset sui tag *-v*
├── scaffold/
│   ├── service-py/            # copiato in services/<nome>/
│   └── app-web/               # copiato in apps/<nome>/
├── scripts/
│   ├── bootstrap-org.sh       # impostazioni dell'org, una volta
│   └── bootstrap-repo.sh      # ruleset, environments, CODEOWNERS, dependabot a un prodotto
└── docs/
    ├── adr/                   # decisioni di piattaforma
    └── runbook-rilascio.md
```

## Versionamento

Ogni cambiamento passa da PR e produce un tag `vX.Y.Z` con Release GitHub. I prodotti pinnano **sempre il tag completo**: `@v1.0.0`, mai `@v1` né `@main` ([ADR 0002](docs/adr/0002-pin-tag-completo-e-sha.md)). Dependabot apre la PR di aggiornamento nei prodotti.

## Workflow riusabili

| Workflow | Input | Output | Cosa fa |
|---|---|---|---|
| `ci-python.yml` | `service`, `path`, `python-version` (3.12), `libs` ("") | artifact `junit-<service>` | ruff check + format, pytest con JUnit |
| `ci-node.yml` | `path`, `node-version` (22) | artifact `dist-<sha>` | npm ci, lint/test se presenti, build |
| `build-image.yml` | `path`, `image`, `context` (.), `dockerfile` (`<path>/Dockerfile`) | `digest` | login GHCR con `GITHUB_TOKEN`, tag `sha-<short>` + tag di rilascio |
| `release.yml` | `product`, `images` (una per riga) | Release GitHub | regex sul tag, SBOM syft per immagine, note dalle PR |

`libs` in `ci-python` serve ai monorepo in cui un servizio dipende da una libreria interna, es. `libs: libs/py/or-scheduler`.

## Collegare un prodotto

Il `ci.yml` del prodotto è un instradatore: capisce quali servizi sono cambiati e per ciascuno chiama la piattaforma. Lo starter è in `H-EALTH/.github/workflow-templates/ci.yml` (tab Actions → "H-EALTH CI").

```yaml
# <prodotto>/.github/workflows/ci.yml
name: ci
on:
  pull_request:
  push: { branches: [main] }

jobs:
  changes:
    runs-on: ubuntu-latest
    permissions: { contents: read, pull-requests: read }
    outputs:
      py: ${{ steps.f.outputs.changes }}
    steps:
      - uses: actions/checkout@v4
      - id: f
        uses: dorny/paths-filter@v3
        with:
          filters: |
            solver-api:  ['services/solver-api/**', 'libs/py/**']
            planner-api: ['services/planner-api/**', 'libs/py/**']

  python:
    needs: changes
    if: needs.changes.outputs.py != '[]'
    strategy:
      matrix:
        service: ${{ fromJSON(needs.changes.outputs.py) }}
    uses: H-EALTH/platform/.github/workflows/ci-python.yml@v1.0.0
    with:
      service: ${{ matrix.service }}
      path: services/${{ matrix.service }}
      libs: libs/py/or-scheduler

  web:
    uses: H-EALTH/platform/.github/workflows/ci-node.yml@v1.0.0
    with:
      path: apps/planner-web
```

Poi, dalla radice del checkout del prodotto (richiede piano Team):

```bash
PROD_REVIEWER=<login> bash <(curl -sL https://raw.githubusercontent.com/H-EALTH/platform/v1.0.0/scripts/bootstrap-repo.sh) <prodotto>
```

Applica: ruleset su `main` (PR obbligatoria, 1 approvazione, code owner, check `ci / python` e `ci / web`, cronologia lineare), environments `staging` e `prod` (reviewer, solo tag `*-v*`), ruleset sui tag, `CODEOWNERS` (`* @H-EALTH/engineering`, slug con il trattino), `dependabot.yml`.

Il job saltato perché nessun file è cambiato conta come superato.

## Nuovo servizio o app

```bash
cp -r platform/scaffold/service-py services/<nome-servizio>   # poi sostituisci <nome-servizio>
cp -r platform/scaffold/app-web    apps/<nome-app>
```

E aggiungi il filtro in `ci.yml`.

## Nuovo prodotto

```bash
gh repo create H-EALTH/<dominio>-<tipo> --template H-EALTH/template-product --private \
  --description "una riga" && gh repo edit H-EALTH/<dominio>-<tipo> --add-topic <dominio>
```

Poi `bootstrap-repo.sh` come sopra. Description e topic sono richiesti da Style Guides.

## Cosa non fare

- Copiare i passi della CI dentro un prodotto. Dopo tre repo hai tre pipeline diverse.
- Pinnare `@v1` o `@main`.
- Mettere logica di deploy o segreti qui. `platform` riceve input, non conosce clienti ([ADR 0004](docs/adr/0004-deploy-pull-based.md)).
- Spiegare il perché in questo README. Un link a Notion o a un ADR, non un riassunto.
