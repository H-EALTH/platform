# Rende importabile `app` dai test senza installare il servizio come pacchetto.
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
