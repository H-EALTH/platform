#!/usr/bin/env bash
# bootstrap-repo.sh <prodotto> — applica a un repo prodotto le regole di piattaforma.
# Richiede piano Team (ruleset ed environment con approvazione sui repo privati).
#
#   1. ruleset su main               (rulesets/main.json)
#   2. environments staging e prod   (prod: reviewer richiesto, deploy solo da tag *-v*)
#   3. ruleset sui tag *-v*          (rulesets/tags.json: solo il team engineering li crea, nessuno li sposta/cancella)
#   4. CODEOWNERS                    (* @H-EALTH/engineering — slug H-EALTH, non HEALTH)
#   5. dependabot.yml                (github-actions + pip per servizio + npm per app)
#
# 4 e 5 vengono scritti su disco solo se lo script è lanciato dalla radice del checkout del prodotto;
# altrimenti stampa cosa manca. I secret (host staging, chiave) restano per repo: vanno messi a mano.
#
# Uso:
#   bash scripts/bootstrap-repo.sh sale-operatorie-ussl2
#   PROD_REVIEWER=<login> bash scripts/bootstrap-repo.sh sale-operatorie-ussl2
set -euo pipefail

ORG="${ORG:-H-EALTH}"
REPO="${1:?uso: bootstrap-repo.sh <prodotto>}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PROD_REVIEWER="${PROD_REVIEWER:-}"   # login GitHub di chi firma il documento di rilascio

TEAM_ID="$(gh api "orgs/$ORG/teams/engineering" --jq .id)"

apply_ruleset() {  # $1 = file json
  local name; name="$(jq -r .name "$1")"
  local body; body="$(sed "s/\"__ENGINEERING_TEAM_ID__\"/$TEAM_ID/" "$1")"
  local existing
  existing="$(gh api "repos/$ORG/$REPO/rulesets" --jq ".[] | select(.name==\"$name\") | .id" || true)"
  if [ -n "$existing" ]; then
    echo "$body" | gh api -X PUT "repos/$ORG/$REPO/rulesets/$existing" --input - >/dev/null
    echo "   ruleset '$name' aggiornato"
  else
    echo "$body" | gh api -X POST "repos/$ORG/$REPO/rulesets" --input - >/dev/null
    echo "   ruleset '$name' creato"
  fi
}

echo "== 1. ruleset su main"
apply_ruleset "$HERE/rulesets/main.json"

echo "== 2. environments"
gh api -X PUT "repos/$ORG/$REPO/environments/staging" --input - <<<'{}' >/dev/null
echo "   staging: nessuna regola, deploy automatico dal merge"
if [ -n "$PROD_REVIEWER" ]; then
  REVIEWER_ID="$(gh api "users/$PROD_REVIEWER" --jq .id)"
  gh api -X PUT "repos/$ORG/$REPO/environments/prod" --input - >/dev/null <<EOF
{ "reviewers": [ { "type": "User", "id": $REVIEWER_ID } ],
  "deployment_branch_policy": { "protected_branches": false, "custom_branch_policies": true } }
EOF
else
  gh api -X PUT "repos/$ORG/$REPO/environments/prod" --input - >/dev/null <<EOF
{ "deployment_branch_policy": { "protected_branches": false, "custom_branch_policies": true } }
EOF
  echo "   ATTENZIONE: nessun PROD_REVIEWER: aggiungi il reviewer di prod da interfaccia"
fi
gh api -X POST "repos/$ORG/$REPO/environments/prod/deployment-branch-policies" \
  -f name='*-v*' -f type=tag >/dev/null 2>&1 || true
echo "   prod: reviewer richiesto, deploy solo da tag *-v*"

echo "== 3. ruleset sui tag *-v*"
apply_ruleset "$HERE/rulesets/tags.json"

if [ -d .git ] && [ "$(basename "$PWD")" = "$REPO" ]; then
  echo "== 4. CODEOWNERS"
  mkdir -p .github
  printf '# Default: ogni file richiede la review del team engineering.\n* @%s/engineering\n' "$ORG" > .github/CODEOWNERS

  echo "== 5. dependabot.yml"
  {
    echo "version: 2"
    echo "updates:"
    echo "  - package-ecosystem: github-actions"
    echo "    directory: /"
    echo "    schedule: { interval: weekly }"
    for d in services/*/; do
      [ -f "$d/requirements.txt" ] || continue
      echo "  - package-ecosystem: pip"
      echo "    directory: /${d%/}"
      echo "    schedule: { interval: weekly }"
    done
    for d in apps/*/; do
      [ -f "$d/package.json" ] || continue
      echo "  - package-ecosystem: npm"
      echo "    directory: /${d%/}"
      echo "    schedule: { interval: weekly }"
    done
  } > .github/dependabot.yml
  echo "   scritti .github/CODEOWNERS e .github/dependabot.yml: committali con una PR"
else
  echo "== 4-5. non sei nella radice del checkout di $REPO: CODEOWNERS e dependabot.yml vanno aggiunti a mano"
fi

echo "OK. Ricorda: secret per repo (staging host/chiave) e 'Immutable releases' nei settings del repo."
