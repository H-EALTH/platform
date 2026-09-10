# 0001 — Il repository `platform` è pubblico
Data: 2026-09-10 · Stato: accettato

## Contesto
`platform` contiene solo logica di build e rilascio: reusable workflows, composite actions, ruleset, scaffold. Nessun segreto, nessun dato cliente. Su GitHub i repo pubblici hanno minuti Actions illimitati e sono leggibili da chiunque, anche da un auditor esterno senza account nell'org.

## Decisione
`H-EALTH/platform` è public. I prodotti restano private.
Se in futuro la struttura interna fosse ritenuta riservata, passa a private: nella stessa org i reusable workflows funzionano comunque, anche su piano Free.

## Conseguenze
Facile: nessun problema di accesso dai prodotti, evidenza verificabile dall'esterno, minuti gratis.
Difficile: nulla di riservato può entrare in questo repo, mai. Chi apre una PR qui lo sa.
Se si cambia idea: `gh repo edit --visibility private`, nessuna modifica ai prodotti.
