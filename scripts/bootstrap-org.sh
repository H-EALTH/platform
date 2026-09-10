#!/usr/bin/env bash
# bootstrap-org.sh — impostazioni dell'organizzazione GitHub H-EALTH. Da eseguire UNA volta,
# dal proprietario dell'org, con `gh auth login` già fatto (scope: admin:org).
# Ripetibile: ogni chiamata è idempotente.
#
# Da interfaccia (non esposto via API o richiede Team):
#   - 2FA obbligatoria per i membri
#   - Dependabot alerts attivi per i nuovi repo
#   - secret di organizzazione per lo staging (host, chiave SSH). GHCR non ne ha bisogno: usa GITHUB_TOKEN.
set -euo pipefail

ORG="${ORG:-H-EALTH}"

echo "== team unico 'engineering' (finché siete meno di dieci)"
gh api "orgs/$ORG/teams/engineering" >/dev/null 2>&1 \
  || gh api "orgs/$ORG/teams" -f name=engineering -f privacy=closed >/dev/null

echo "== Actions: abilitate ovunque, solo action GitHub, verificate o nostre"
gh api -X PUT "orgs/$ORG/actions/permissions" \
  -f enabled_repositories=all -f allowed_actions=selected
gh api -X PUT "orgs/$ORG/actions/permissions/selected-actions" \
  -F github_owned_allowed=true -F verified_allowed=true \
  -f "patterns_allowed[]=$ORG/*"

echo "== GITHUB_TOKEN in sola lettura di default: i workflow chiedono i permessi che servono"
gh api -X PUT "orgs/$ORG/actions/permissions/workflow" \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false

echo "OK. Ora da interfaccia: 2FA obbligatoria, Dependabot alerts sui nuovi repo, secret di org per lo staging."
