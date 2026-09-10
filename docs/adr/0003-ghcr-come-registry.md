# 0003 — GHCR è il registry delle immagini
Data: 2026-09-10 · Stato: accettato

## Contesto
Serve un registry per le immagini dei servizi. Le alternative (Docker Hub, registry self-hosted, cloud) aggiungono un login, un set di permessi e un costo separati.

## Decisione
Le immagini vanno su `ghcr.io/h-ealth/<prodotto>/<servizio>`.
Una immagine per servizio. Tag: `sha-<short>` a ogni merge su `main`, più il tag di rilascio `<prodotto>-vX.Y.Z` quando esiste. L'identificativo che finisce nel documento di rilascio è il **digest**, non il tag.
Login con `GITHUB_TOKEN` e permesso `packages: write`: nessun secret dedicato.

## Conseguenze
Facile: stessi permessi del repo, gratis per i repo pubblici e incluso nello storage dei privati, nessuna credenziale da ruotare.
Difficile: il server del cliente deve poter fare pull da `ghcr.io` con un token in sola lettura (vedi 0004).
Se si cambia idea: cambia l'input `image` di `build-image.yml` nei prodotti e il login; il resto della pipeline è indifferente.
