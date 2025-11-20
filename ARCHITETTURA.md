# 🏗️ Architettura del Progetto

## 📊 Diagramma Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                      UTENTE FINALE                           │
│                    (Mobile/Web/Desktop)                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ UI Interaction
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    FLUTTER APP                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  UI Layer (Screens & Widgets)                        │  │
│  │  - GameScreen: schermata principale                  │  │
│  │  - GuessInput: input parola                          │  │
│  │  - GuessList: lista tentativi                        │  │
│  │  - GameHeader: header info                           │  │
│  └────────────────────┬─────────────────────────────────┘  │
│                       │                                      │
│  ┌────────────────────▼─────────────────────────────────┐  │
│  │  State Management (Provider)                         │  │
│  │  - GameProvider: gestisce stato gioco                │  │
│  │    • Lista tentativi                                 │  │
│  │    • Info parola giornaliera                         │  │
│  │    • Loading/Error states                            │  │
│  └────────────────────┬─────────────────────────────────┘  │
│                       │                                      │
│  ┌────────────────────▼─────────────────────────────────┐  │
│  │  Services Layer                                      │  │
│  │  - ApiService: comunicazione backend                │  │
│  │    • makeGuess()                                     │  │
│  │    • getDailyWordInfo()                              │  │
│  │    • getStats()                                      │  │
│  └────────────────────┬─────────────────────────────────┘  │
│                       │                                      │
│  ┌────────────────────▼─────────────────────────────────┐  │
│  │  Local Storage (SharedPreferences)                   │  │
│  │  - Salvataggio tentativi giornalieri                │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTP/REST API
                         │ (JSON)
                         │
┌────────────────────────▼────────────────────────────────────┐
│                   FASTAPI BACKEND                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  API Endpoints                                       │  │
│  │  GET  /health                                        │  │
│  │  GET  /stats                                         │  │
│  │  GET  /daily-word-info                               │  │
│  │  POST /guess                                         │  │
│  │  GET  /hint/{date}                                   │  │
│  └────────────────────┬─────────────────────────────────┘  │
│                       │                                      │
│  ┌────────────────────▼─────────────────────────────────┐  │
│  │  Game Logic (GameManager)                            │  │
│  │  - get_daily_word(): parola del giorno              │  │
│  │  - get_or_compute_rankings(): calcola similarità    │  │
│  │  - calculate_similarity(): cosine similarity        │  │
│  │  - rank_to_temperature(): 🔥/🧊 mapping             │  │
│  └────────────────────┬─────────────────────────────────┘  │
│                       │                                      │
│  ┌────────────────────▼─────────────────────────────────┐  │
│  │  Caching Layer                                       │  │
│  │  - Rankings cache (in-memory)                        │  │
│  │  - Max 100 parole cached                             │  │
│  └────────────────────┬─────────────────────────────────┘  │
│                       │                                      │
│  ┌────────────────────▼─────────────────────────────────┐  │
│  │  FastText Model (Gensim)                             │  │
│  │  - KeyedVectors.load()                               │  │
│  │  - most_similar(): trova parole simili               │  │
│  │  - similarity(): calcola cosine similarity           │  │
│  └────────────────────┬─────────────────────────────────┘  │
└────────────────────────┼────────────────────────────────────┘
                         │
                         │
┌────────────────────────▼────────────────────────────────────┐
│              FILE SYSTEM (Modello + Dati)                    │
│  - fasttext_it.model (2GB)                                  │
│  - fasttext_it.model.vectors.npy                            │
│  - daily_words.txt (lista parole giornaliere)               │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Flow di una Partita

```
1. AVVIO APP
   Flutter App
   └─> GET /daily-word-info
       Backend
       ├─> Calcola hash della data
       ├─> Seleziona parola dal array daily_words
       └─> Ritorna: {date, word_length, game_number}

   Flutter App
   ├─> Mostra info nel GameHeader
   ├─> Carica tentativi salvati da SharedPreferences
   └─> Pronto per input

2. TENTATIVO UTENTE
   User: digita "casa"
   └─> Flutter: GuessInput widget
       └─> GameProvider.makeGuess("casa")
           └─> ApiService.makeGuess("casa")
               └─> POST /guess {"word": "casa"}

                   Backend
                   ├─> Valida parola nel vocabolario
                   ├─> Ottiene parola segreta del giorno
                   ├─> Calcola ranking:
                   │   ├─> Cache hit? → Usa ranking cached
                   │   └─> Cache miss? → model.most_similar()
                   ├─> Calcola similarità: model.similarity()
                   ├─> Mappa rank → temperatura (🔥/🧊)
                   └─> Ritorna: {word, rank, similarity, temperature}

               Flutter
               ├─> Aggiunge a lista tentativi
               ├─> Salva in SharedPreferences
               ├─> Aggiorna UI (notifyListeners)
               └─> Mostra GuessCard colorata

3. VITTORIA
   User: indovina parola corretta
   └─> POST /guess {"word": "soluzione"}
       Backend
       └─> word == secret_word
           └─> Ritorna: {correct: true, rank: 1}

       Flutter
       ├─> hasWon = true
       ├─> Mostra messaggio vittoria 🎉
       ├─> Salva stato in SharedPreferences
       └─> Disabilita input

4. NUOVO GIORNO
   User: apre app il giorno dopo
   └─> SharedPreferences: guesses_2025-11-18 → vuoto
       Backend: hash(2025-11-18) → nuova parola
       └─> Nuovo gioco!
```

## 🗂️ Struttura Dati

### Frontend (Flutter)

```dart
// Modello tentativo
class GuessResult {
  String word;
  bool valid;
  bool correct;
  int? rank;
  int? totalWords;
  double? similarity;
  String? temperature;
}

// State in GameProvider
class GameProvider {
  List<GuessResult> guesses = [];
  DailyWordInfo? dailyWordInfo;
  bool hasWon = false;
}

// Storage locale
SharedPreferences:
  key: "guesses_2025-11-17"
  value: JSON array di GuessResult
```

### Backend (Python)

```python
# In-memory cache
rankings_cache = {
  "parola1": {
    "parola_simile1": 1,
    "parola_simile2": 2,
    # ... fino a 200k parole
  }
}

# Lista parole giornaliere
daily_words = [
  "parola1",  # Giorno 1
  "parola2",  # Giorno 2
  # ... 10k parole
]

# Modello FastText
model = KeyedVectors (Gensim)
  - 200k parole italiane
  - Vettori 300 dimensioni
  - Metodi: similarity(), most_similar()
```

## 🚀 Performance

### Caricamento Modello

```
Primo avvio: ~2-3 minuti
├─> Download cc.it.300.vec.gz (1.2GB)
├─> Parse e conversione
└─> Salvataggio cache binaria

Avvii successivi: ~10-20 secondi
└─> Load da fasttext_it.model
```

### Calcolo Ranking

```
Prima parola (cache miss): ~2-3 secondi
└─> model.most_similar() su 200k parole

Stessa parola (cache hit): ~0.01 secondi
└─> Lookup in dizionario Python
```

### Memoria

```
Backend:
├─ Modello FastText: ~1.5 GB
├─ Rankings cache: ~10-50 MB (per 100 parole)
└─ Server overhead: ~100 MB
Total: ~2 GB RAM

Flutter:
├─ App base: ~50 MB
└─ Storage tentativi: ~1-5 KB per giorno
```

## 🔐 Sicurezza

### Frontend

```
✅ CORS configurato su backend
✅ Input validation locale
✅ Nessun dato sensibile in storage
⚠️  URL backend hardcodato (ok per demo)
```

### Backend

```
✅ Parola segreta mai esposta direttamente
✅ Rate limiting (da implementare per prod)
✅ Input validation su tutte le route
⚠️  CORS aperto a tutti (*) - da limitare in prod
⚠️  Nessuna autenticazione - ok per demo
```

## 📈 Scalabilità

### Limitazioni Attuali

```
❌ Ranking cache limitata (100 parole max)
❌ Single-process (un worker)
❌ Nessun database persistente
❌ Cache volatile (restart = perdita cache)
```

### Miglioramenti per Produzione

```
1. Cache Distribuita
   └─> Redis per rankings
       └─> Persistente tra restart
       └─> Condivisa tra workers

2. Database
   └─> PostgreSQL per:
       ├─> Statistiche utenti
       ├─> Storia partite
       └─> Leaderboard

3. Load Balancing
   └─> Nginx + multiple workers
       └─> Gunicorn con 4-8 workers

4. CDN
   └─> Flutter web su CDN
       └─> Edge caching per assets

5. Monitoring
   └─> Prometheus + Grafana
       ├─> Request rate
       ├─> Response time
       └─> Cache hit ratio
```

## 🔧 Configurazione

### Ambiente Development

```
Backend:
- Host: localhost
- Port: 8000
- Workers: 1 (reload attivo)

Flutter:
- Device: Chrome/Windows
- Hot reload: attivo
- Debug mode
```

### Ambiente Production

```
Backend:
- Host: 0.0.0.0
- Port: 8000 (dietro Nginx)
- Workers: 4-8 (gunicorn)
- No reload
- Gunicorn + uvicorn workers

Flutter:
- Build: release
- Minified + obfuscated
- AOT compiled
```

## 📝 Note Tecniche

### FastText

- Embeddings pre-addestrati su Common Crawl italiano
- 300 dimensioni per vettore
- Cosine similarity per calcolare vicinanza semantica
- Normalizzazione [-1, 1] → [0, 1]

### Determinismo Parola Giornaliera

- Hash MD5 della data (ISO format)
- Hash integer % len(daily_words)
- Stessa parola per tutti gli utenti nello stesso giorno
- Nessun random → completamente reproducibile

### Storage Flutter

- SharedPreferences = native storage
  - Android: SharedPreferences XML
  - iOS: NSUserDefaults
  - Web: LocalStorage
- Asincrono
- Key-value store
- Persistente tra sessioni
