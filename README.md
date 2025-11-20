# 🔥 Hot & Cold - Gioco Semantico 🧊

Un gioco stile **Semantle** dove devi indovinare la parola del giorno usando la similarità semantica.

## 📁 Struttura Progetto

```
Hotncold/
├── backend/              # Server FastAPI
│   ├── main.py          # API endpoints
│   ├── requirements.txt # Dipendenze Python
│   └── README.md        # Documentazione backend
│
├── flutter_app/         # App Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/      # Modelli dati
│   │   ├── providers/   # State management
│   │   ├── screens/     # Schermate UI
│   │   ├── services/    # API service
│   │   └── widgets/     # Componenti UI
│   └── pubspec.yaml
│
├── fasttext_it.model    # Modello FastText (generato)
├── cc.it.300.vec.gz     # Dati FastText originali
└── hot_and_cold_fasttext.py  # Versione terminale originale
```

## 🚀 Quick Start

### 1. Setup Backend

```powershell
# Vai nella cartella backend
cd backend

# Crea ambiente virtuale (opzionale ma consigliato)
python -m venv venv
.\venv\Scripts\Activate.ps1

# Installa dipendenze
pip install -r requirements.txt

# Avvia il server
python main.py
```

Il server sarà disponibile su: http://localhost:8000

### 2. Setup Flutter App

```powershell
# Vai nella cartella flutter_app
cd flutter_app

# Installa dipendenze
flutter pub get

# Avvia l'app (scegli device)
flutter run
```

## 🔧 Configurazione

### Backend

Il backend cerca il modello FastText in `../fasttext_it.model`.

Se non hai ancora il modello:

1. Esegui lo script originale una volta: `python hot_and_cold_fasttext.py`
2. Questo scaricherà e processerà il modello FastText

### Flutter App

Modifica l'URL del backend in `lib/services/api_service.dart`:

```dart
// Per localhost (emulatore/desktop)
static const String baseUrl = 'http://localhost:8000';

// Per emulatore Android
static const String baseUrl = 'http://10.0.2.2:8000';

// Per device fisico (usa IP del tuo PC)
static const String baseUrl = 'http://192.168.1.XXX:8000';
```

## 🎮 Come Si Gioca

1. Ogni giorno c'è una **parola segreta** diversa
2. Provi a indovinarla inserendo parole italiane
3. Per ogni tentativo ricevi:

   - **Rank**: posizione nella classifica di similarità (#1 = parola corretta)
   - **Temperatura**: 🔥 = caldissimo, 🧊 = freddissimo
   - **Similarità**: valore numerico 0-1

4. Più il rank è basso, più sei vicino!
   - 🔥🔥🔥 = Top 10
   - 🔥🔥 = Top 50
   - 🔥 = Top 100
   - 🌡️ = Top 500
   - ❄️ = Top 1000
   - 🧊 = Oltre 1000

## 🛠️ API Endpoints

### GET /stats

Statistiche del server

### GET /daily-word-info

Info parola del giorno (senza rivelarla)

### POST /guess

```json
{
  "word": "casa",
  "date": "2025-11-17"
}
```

### GET /hint/{date}

Ottieni suggerimenti (per debug)

### GET /health

Health check

## 📱 Testing

### Test Backend

```powershell
# Test manuale
curl http://localhost:8000/health

# Prova un tentativo
curl -X POST http://localhost:8000/guess `
  -H "Content-Type: application/json" `
  -d '{"word":"casa"}'
```

### Test Flutter

```powershell
# Test su Chrome
flutter run -d chrome

# Test su emulatore Android
flutter run -d emulator

# Test su Windows
flutter run -d windows
```

## 🐛 Troubleshooting

### Il backend non si avvia

- Verifica che il modello `fasttext_it.model` esista
- Controlla che tutte le dipendenze siano installate
- Controlla la porta 8000 non sia occupata

### L'app non si connette al backend

- Verifica che il backend sia avviato
- Controlla l'URL in `api_service.dart`
- Per device fisico, usa l'IP del PC nella stessa rete

### Il modello è troppo grande

- Il modello completo è ~1.2GB
- È ottimizzato a 200k parole per performance
- Salva in cache binaria per caricamenti veloci

## 🚀 Deploy Produzione

### Backend

Usa **Gunicorn** per produzione:

```bash
pip install gunicorn
gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

Oppure deploy su:

- **Heroku**: con Procfile
- **DigitalOcean App Platform**
- **AWS EC2**
- **Google Cloud Run**

### Flutter App

Build per produzione:

```powershell
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 📝 Note

- La parola giornaliera è deterministica basata sulla data
- I tentativi sono salvati in locale (SharedPreferences)
- Il ranking viene calcolato e cachato per performance
- Il modello FastText usa word embeddings italiani reali

## 🔮 Prossimi Miglioramenti

- [ ] Sistema di statistiche utente
- [ ] Condivisione risultati (tipo Wordle)
- [ ] Modalità allenamento con parole passate
- [ ] Classifiche globali
- [ ] Suggerimenti progressivi
- [ ] Dark mode
- [ ] Animazioni migliorate
- [ ] PWA per web

## 📄 Licenza

Progetto personale - Usa come preferisci!

## 🙏 Credits

- FastText: https://fasttext.cc/
- Ispirato da Semantle: https://semantle.com/
