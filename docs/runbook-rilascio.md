# Runbook — rilascio di un prodotto

Prerequisito: `HE-SOP-004` par. 4 soddisfatto (verifica e approvazione documentate su Drive).

1. **Tag** dal commit di `main` già passato in staging:
   ```bash
   git tag <prodotto>-vX.Y.Z <sha> && git push origin <prodotto>-vX.Y.Z
   ```
   Solo il team `engineering` può creare tag `*-v*`; nessuno può spostarli o cancellarli.
2. **Release automatica**: `release.yml` valida il formato, ritagga le immagini, genera la Release con note dalle PR e allega l'SBOM di ogni immagine. Un tag non conforme fa fallire il run.
3. **Approvazione `prod`**: chi firma il documento di rilascio approva il deployment nell'environment.
4. **Pull sul server** del cliente con lo script locale, indicando il tag.
5. **Documento di rilascio su Drive**: tag, digest di ogni immagine (dal summary di `build-image`), URL del run. È l'unico punto in cui un umano trascrive qualcosa, ed è quello che l'auditor confronta.

Esercitazione consigliata prima del primo rilascio vero: `<prodotto>-v0.1.0` a vuoto, documentata su Drive come prova.
