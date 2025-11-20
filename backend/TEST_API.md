# Test API - Hot & Cold Backend

Collezione di test per verificare che il backend funzioni correttamente.

## Prerequisiti

Backend avviato su http://localhost:8000

## Test con cURL (PowerShell)

### 1. Health Check

```powershell
curl http://localhost:8000/health
```

**Response attesa:**

```json
{
  "status": "healthy",
  "model_loaded": true,
  "vocab_size": 200000
}
```

### 2. Root Endpoint

```powershell
curl http://localhost:8000/
```

### 3. Statistiche Server

```powershell
curl http://localhost:8000/stats
```

**Response:**

```json
{
  "vocab_size": 200000,
  "model_loaded": true,
  "today_date": "2025-11-17",
  "today_word_length": 7,
  "game_number": 17
}
```

### 4. Info Parola Giornaliera

```powershell
curl http://localhost:8000/daily-word-info
```

**Response:**

```json
{
  "date": "2025-11-17",
  "word_length": 7,
  "total_words": 200000,
  "game_number": 17
}
```

### 5. Tentativo di Indovinare

```powershell
curl -X POST http://localhost:8000/guess `
  -H "Content-Type: application/json" `
  -d '{\"word\":\"casa\"}'
```

**Response (esempio):**

```json
{
  "word": "casa",
  "valid": true,
  "correct": false,
  "rank": 1234,
  "total_words": 200000,
  "similarity": 0.4567,
  "temperature": "❄️ Freddo"
}
```

### 6. Hint (suggerimenti)

```powershell
curl http://localhost:8000/hint/2025-11-17?top_n=5
```

**Response:**

```json
{
  "date": "2025-11-17",
  "hints": [
    {
      "word": "parola1",
      "similarity": 0.95,
      "rank": 1
    },
    ...
  ],
  "note": "Queste sono le parole più vicine alla soluzione"
}
```

## Test con Python

Crea un file `test_api.py`:

```python
import requests
import json

BASE_URL = "http://localhost:8000"

def test_health():
    print("🧪 Test Health Check...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}\n")

def test_stats():
    print("🧪 Test Stats...")
    response = requests.get(f"{BASE_URL}/stats")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}\n")

def test_daily_word():
    print("🧪 Test Daily Word Info...")
    response = requests.get(f"{BASE_URL}/daily-word-info")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}\n")

def test_guess(word):
    print(f"🧪 Test Guess: {word}...")
    response = requests.post(
        f"{BASE_URL}/guess",
        json={"word": word}
    )
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}\n")

if __name__ == "__main__":
    test_health()
    test_stats()
    test_daily_word()

    # Prova alcune parole
    test_guess("casa")
    test_guess("amore")
    test_guess("felice")
```

Esegui:

```powershell
python test_api.py
```

## Test con Browser

Apri nel browser:

1. **API Docs (Swagger):**
   http://localhost:8000/docs

   - Interfaccia interattiva per testare tutti gli endpoints
   - Documentazione automatica
   - "Try it out" per ogni endpoint

2. **Alternative API Docs (ReDoc):**
   http://localhost:8000/redoc

## Test Sequenza Completa

Test di una partita completa:

```powershell
# 1. Verifica server
curl http://localhost:8000/health

# 2. Ottieni info gioco
curl http://localhost:8000/daily-word-info

# 3. Sequenza di tentativi
curl -X POST http://localhost:8000/guess -H "Content-Type: application/json" -d '{\"word\":\"casa\"}'
curl -X POST http://localhost:8000/guess -H "Content-Type: application/json" -d '{\"word\":\"amore\"}'
curl -X POST http://localhost:8000/guess -H "Content-Type: application/json" -d '{\"word\":\"vita\"}'

# 4. Ottieni hint (per vedere quanto eri lontano)
curl http://localhost:8000/hint/2025-11-17?top_n=10
```

## Performance Testing

Test di carico con Python:

```python
import requests
import time
from concurrent.futures import ThreadPoolExecutor

BASE_URL = "http://localhost:8000"

def make_guess(word):
    start = time.time()
    response = requests.post(f"{BASE_URL}/guess", json={"word": word})
    duration = time.time() - start
    return duration, response.status_code

words = ["casa", "amore", "vita", "felice", "triste", "cane", "gatto"]

# Test sequenziale
print("🧪 Test Sequenziale...")
times = []
for word in words:
    duration, status = make_guess(word)
    times.append(duration)
    print(f"{word}: {duration:.3f}s - Status {status}")

print(f"\nMedia: {sum(times)/len(times):.3f}s")

# Test parallelo
print("\n🧪 Test Parallelo...")
start = time.time()
with ThreadPoolExecutor(max_workers=5) as executor:
    results = list(executor.map(make_guess, words))
total_duration = time.time() - start

print(f"Tempo totale: {total_duration:.3f}s")
print(f"Throughput: {len(words)/total_duration:.2f} req/s")
```

## Monitoraggio

### Logs del Server

Il server mostra logs per:

- Richieste ricevute
- Calcolo ranking
- Errori

Esempio:

```
INFO: Calcolo ranking per 'esempio'...
INFO: Ranking calcolato per 200000 parole
INFO: 127.0.0.1:12345 - "POST /guess HTTP/1.1" 200 OK
```

### Metriche Importanti

- **Tempo caricamento modello**: ~1-3 minuti al primo avvio
- **Tempo risposta /guess**: ~0.1-0.5s (con ranking cached)
- **Memoria RAM**: ~2-3 GB (per modello + server)
- **Cache ranking**: Max 100 parole

## Troubleshooting Test

### Errore: Connection Refused

```
❌ requests.exceptions.ConnectionError
```

**Soluzione:** Backend non avviato. Esegui `python main.py`

### Errore: 500 Internal Server Error

```json
{ "detail": "Internal server error" }
```

**Soluzione:** Controlla logs del server. Possibile problema con modello.

### Errore: Timeout

```
❌ requests.exceptions.Timeout
```

**Soluzione:** Primo calcolo ranking può richiedere tempo. Riprova.

### Parola non valida

```json
{
  "word": "xyz",
  "valid": false,
  "correct": false,
  "message": "Parola 'xyz' non nel vocabolario"
}
```

**OK:** Comportamento atteso per parole non italiane.

## Note

- Il primo calcolo ranking per una nuova parola può richiedere 2-3 secondi
- Ranking successivi sono istantanei (cached)
- Il server può gestire ~10-20 richieste/secondo
- Per produzione, usa gunicorn con multiple workers
