# 0004 — Il deploy in produzione è pull dal server, non push dalla pipeline
Data: 2026-09-10 · Stato: accettato

## Contesto
I prodotti girano nella rete dell'ospedale. Quella rete non deve accettare connessioni in ingresso da GitHub, e la pipeline non deve conoscere host, credenziali o topologia del cliente.

## Decisione
La pipeline **pubblica**: immagini su GHCR (0003) e file compose versionato nella Release. Il server del cliente **tira** il tag di rilascio con uno script locale, dopo l'approvazione dell'environment `prod`.
Lo staging fa eccezione: push automatico dal merge su `main` verso una VM nostra.

## Conseguenze
Facile: nessun segreto cliente in GitHub; `platform` riceve input e non conosce clienti; l'approvazione in `prod` è il pulsante che rappresenta `HE-SOP-004` par. 4.
Difficile: il momento del deploy è deciso da chi lancia lo script sul server; la traccia è il documento di rilascio su Drive (tag, digest, URL del run), non un log della pipeline.
Se si cambia idea: aggiungere un job di deploy che consuma secret di environment; nessun cambiamento a build e release.
