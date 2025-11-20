# 🎯 Guida Rapida - Hot & Cold

## 🚀 Avvio Rapido (3 Passi)

### 1️⃣ Avvia il Backend

```powershell
cd backend
.\start_backend.ps1
```

**Oppure manualmente:**

```powershell
cd backend
pip install -r requirements.txt
python main.py
```

✅ Il server sarà su: **http://localhost:8000**

### 2️⃣ Configura l'App Flutter

Apri `flutter_app/lib/services/api_service.dart` e verifica l'URL:

```dart
static const String baseUrl = 'http://localhost:8000';
```

### 3️⃣ Avvia l'App

```powershell
cd flutter_app
.\start_app.ps1
```

**Oppure manualmente:**

```powershell
cd flutter_app
flutter pub get
flutter run -d chrome   # oppure -d windows, -d android
```

## 🎮 Come Funziona

### Architettura

```
┌─────────────────┐
│  Flutter App    │
│  (Frontend)     │
│                 │
│  - UI/UX        │
│  - State Mgmt   │
│  - Local Save   │
└────────┬────────┘
         │ HTTP/REST
         │
┌────────▼────────┐
│  FastAPI Server │
│  (Backend)      │
│                 │
│  - API Logic    │
│  - FastText ML  │
│  - Daily Word   │
└────────┬────────┘
         │
┌────────▼────────┐
│  FastText Model │
│  (1.2 GB)       │
│                 │
│  200k words     │
│  Italian vocab  │
└─────────────────┘
```

### Flow del Gioco

1. **App richiede info gioco** → `GET /daily-word-info`

   - Ottiene: data, lunghezza parola, numero gioco

2. **Utente prova una parola** → `POST /guess`

   - Invia: `{ "word": "casa" }`
   - Backend calcola similarità con FastText
   - Ritorna: rank, temperatura, similarità

3. **App mostra risultato**

   - Colore della card in base al rank
   - Temperatura emoji (🔥/🧊)
   - Statistiche dettagliate

4. **Salvataggio automatico**
   - Tentativi salvati in locale (SharedPreferences)
   - Ogni giorno è un nuovo gioco

## 📊 Sistema di Ranking

Il backend confronta la tua parola con TUTTE le 200k parole del vocabolario:

```
Rank #1      🎉 CORRETTO!
Rank #2-10   🔥🔥🔥 Caldissimo!
Rank #11-50  🔥🔥 Molto caldo!
Rank #51-100 🔥 Caldo!
Rank #500    🌡️ Tiepido
Rank #1000   ❄️ Freddo
Rank #5000   ❄️❄️ Molto freddo
Rank #10000+ 🧊 Ghiacciato!
```

## 🛠️ Testing

### Test Backend

```powershell
# Health check
curl http://localhost:8000/health

# Statistiche
curl http://localhost:8000/stats

# Prova tentativo
curl -X POST http://localhost:8000/guess `
  -H "Content-Type: application/json" `
  -d '{\"word\":\"casa\"}'
```

### Test Flutter

```powershell
# Chrome (più veloce per debug)
flutter run -d chrome

# Windows Desktop
flutter run -d windows

# Android Emulator
flutter run -d emulator
```

## 🐛 Problemi Comuni

### ❌ Backend non si avvia

**Problema:** `FileNotFoundError: fasttext_it.model`

**Soluzione:**

```powershell
cd ..
python hot_and_cold_fasttext.py
# Questo scaricherà e processerà il modello
```

---

### ❌ App non si connette

**Problema:** `Impossibile connettersi al server`

**Soluzioni:**

1. Verifica backend attivo su http://localhost:8000
2. Per emulatore Android, usa `http://10.0.2.2:8000`
3. Per device fisico, usa IP del PC (es. `http://192.168.1.10:8000`)

---

### ❌ Flutter non trovato

**Problema:** `flutter: command not found`

**Soluzione:**

1. Installa Flutter: https://flutter.dev/docs/get-started/install
2. Aggiungi al PATH di sistema
3. Riavvia PowerShell

## 📱 Device Specifici

### Chrome (Web)

```powershell
flutter run -d chrome
```

- ✅ Più veloce per development
- ✅ Hot reload immediato
- ✅ DevTools nel browser

### Windows (Desktop)

```powershell
flutter run -d windows
```

- ✅ App nativa Windows
- ✅ Buone performance
- ⚠️ Richiede Visual Studio Build Tools

### Android (Emulatore/Fisico)

```powershell
# Emulatore
flutter run -d emulator

# Device fisico
flutter run -d <device-id>
```

- ✅ Test su mobile
- ⚠️ Modifica URL backend per IP del PC

## 🔮 Prossimi Step

### Funzionalità da Aggiungere

1. **Sistema di Statistiche**

   - Streak giorni consecutivi
   - Media tentativi
   - Distribuzione rank

2. **Condivisione Risultati**

   - Share come Wordle
   - Emoji grid dei tentativi

3. **Modalità Allenamento**

   - Gioca giorni passati
   - Pratica illimitata

4. **Hint Progressivi**

   - Sistema di suggerimenti
   - Penalità sui tentativi

5. **Classifiche**
   - Leaderboard globale
   - Confronto con amici

### Miglioramenti Tecnici

1. **Backend**

   - Cache Redis per ranking
   - Database per statistiche
   - WebSocket per multiplayer

2. **Frontend**

   - Animazioni fluide
   - Dark mode
   - PWA per web

3. **Deploy**
   - Backend su Cloud Run
   - App su Play Store
   - Web hosting

## 📚 Risorse

- **FastAPI Docs**: https://fastapi.tiangolo.com/
- **Flutter Docs**: https://flutter.dev/docs
- **FastText**: https://fasttext.cc/
- **Semantle (ispirazione)**: https://semantle.com/

## 🎓 Learning Points

Questo progetto dimostra:

- ✅ Architettura client-server moderna
- ✅ Machine Learning (NLP embeddings)
- ✅ State management (Provider)
- ✅ API REST design
- ✅ Local storage
- ✅ Responsive UI
- ✅ Cross-platform development

Perfetto per portfolio o learning project! 🚀
