# Hot and Cold Game - Backend API

Backend FastAPI per gestire il modello FastText e la logica del gioco.

## Setup

1. **Installa dipendenze:**

```bash
pip install -r requirements.txt
```

2. **Assicurati che il modello FastText sia disponibile:**

   - Il file `fasttext_it.model` deve essere nella directory parent
   - Path: `../fasttext_it.model`

3. **Avvia il server:**

```bash
python main.py
```

Oppure con uvicorn:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## Endpoints API

### GET /

Informazioni generali sull'API

### GET /stats

Statistiche del server (vocabolario, data corrente, etc.)

### GET /daily-word-info?date=YYYY-MM-DD

Informazioni sulla parola del giorno (lunghezza, numero gioco)

### POST /guess

Valuta un tentativo

```json
{
  "word": "casa",
  "date": "2025-11-17" // opzionale
}
```

Response:

```json
{
  "word": "casa",
  "valid": true,
  "correct": false,
  "rank": 1234,
  "total_words": 200000,
  "similarity": 0.45,
  "temperature": "❄️ Freddo"
}
```

### GET /hint/{date}?top_n=5

Ottiene suggerimenti (per debug/testing)

### GET /health

Health check

## Deployment

Per produzione, usa gunicorn con uvicorn workers:

```bash
pip install gunicorn
gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

## Note

- Il server carica il modello all'avvio (richiede alcuni minuti)
- La parola giornaliera è deterministica basata sulla data
- Il ranking viene calcolato e cachato per performance
