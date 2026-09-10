# 0002 — I prodotti pinnano `platform` al tag completo; le action terze allo SHA
Data: 2026-09-10 · Stato: accettato

## Contesto
`HE-SOP-004` e `HE-SOP-005` chiedono che un rilascio sia riproducibile e che la CI eseguita sia dimostrabile. Un riferimento mobile (`@v1`, `@main`) domani punta ad altro: non è evidenza.

## Decisione
Ogni cambiamento a `platform` passa da PR e produce un tag immutabile `vX.Y.Z` con Release.
I prodotti usano `H-EALTH/platform/...@vX.Y.Z`, mai `@v1` né `@main`. Dentro `platform` le action di terze parti (docker/*, anchore/*, dorny/*) si pinnano allo SHA del commit; quelle GitHub-owned (`actions/*`) al tag maggiore.
Dependabot (`github-actions`) apre la PR di aggiornamento nei prodotti: il merge di quella PR è la traccia di quando il prodotto ha adottato la nuova versione.

## Conseguenze
Facile: dal run CI si risale esattamente alla logica eseguita; il documento di rilascio cita una versione precisa.
Difficile: ogni fix di piattaforma richiede una PR di adozione per prodotto (Dependabot la apre, un umano la mergia).
Se si cambia idea: sostituire i tag nei `ci.yml` dei prodotti; nessun cambiamento in `platform`.
