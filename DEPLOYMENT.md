# ✅ Checklist Deployment - Hot & Cold

## 📋 Pre-Deployment

### Backend

- [ ] **Modello FastText**

  - [ ] Modello generato e testato localmente
  - [ ] File `fasttext_it.model` disponibile
  - [ ] Dimensione verificata (~1.5 GB)

- [ ] **Dipendenze**

  - [ ] Tutte le dipendenze in `requirements.txt`
  - [ ] Versioni specificate (no `>=`)
  - [ ] Test con `pip install -r requirements.txt`

- [ ] **Configurazione**

  - [ ] CORS configurato per domini specifici
  - [ ] Variabili ambiente per secrets
  - [ ] Logging configurato
  - [ ] Health check endpoint attivo

- [ ] **Testing**
  - [ ] Tutti gli endpoint testati
  - [ ] Test di carico eseguiti
  - [ ] Gestione errori verificata
  - [ ] Timeout configurati

### Flutter App

- [ ] **Build**

  - [ ] Build release testato localmente
  - [ ] Asset inclusi correttamente
  - [ ] Icone e splash screen configurati

- [ ] **Configurazione**

  - [ ] URL backend aggiornato per produzione
  - [ ] Timeout HTTP configurati
  - [ ] Error handling completo

- [ ] **Testing**
  - [ ] Test su device Android reale
  - [ ] Test su device iOS reale (se applicabile)
  - [ ] Test connessione lenta
  - [ ] Test offline graceful

## 🚀 Deploy Backend

### Opzione 1: Server VPS (DigitalOcean, AWS EC2, etc.)

```bash
# Setup server
sudo apt update
sudo apt install python3-pip python3-venv nginx

# Clone repo
git clone <your-repo-url>
cd Hotncold/backend

# Virtual environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Upload modello FastText
# (usa scp o sftp per caricare il file .model)
scp fasttext_it.model user@server:/path/to/backend/

# Gunicorn
pip install gunicorn

# Test
gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

#### Systemd Service

Crea `/etc/systemd/system/hotncold.service`:

```ini
[Unit]
Description=Hot & Cold FastAPI Backend
After=network.target

[Service]
Type=notify
User=www-data
WorkingDirectory=/path/to/backend
Environment="PATH=/path/to/backend/venv/bin"
ExecStart=/path/to/backend/venv/bin/gunicorn main:app \
    --workers 4 \
    --worker-class uvicorn.workers.UvicornWorker \
    --bind 0.0.0.0:8000 \
    --timeout 120

[Install]
WantedBy=multi-user.target
```

Attiva:

```bash
sudo systemctl daemon-reload
sudo systemctl enable hotncold
sudo systemctl start hotncold
sudo systemctl status hotncold
```

#### Nginx Reverse Proxy

Crea `/etc/nginx/sites-available/hotncold`:

```nginx
server {
    listen 80;
    server_name api.yourdomaih.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
    }
}
```

Attiva:

```bash
sudo ln -s /etc/nginx/sites-available/hotncold /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

#### SSL con Let's Encrypt

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.yourdomain.com
```

### Opzione 2: Docker

Crea `Dockerfile` in `backend/`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Dipendenze
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Codice
COPY . .

# Modello (assumi che sia già nel progetto o montato come volume)
# COPY fasttext_it.model .

EXPOSE 8000

CMD ["gunicorn", "main:app", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]
```

Build e run:

```bash
docker build -t hotncold-backend .
docker run -d -p 8000:8000 -v /path/to/fasttext_it.model:/app/fasttext_it.model hotncold-backend
```

### Opzione 3: Cloud Run (Google Cloud)

```bash
# Build
gcloud builds submit --tag gcr.io/PROJECT_ID/hotncold-backend

# Deploy
gcloud run deploy hotncold-backend \
  --image gcr.io/PROJECT_ID/hotncold-backend \
  --platform managed \
  --region europe-west1 \
  --memory 4Gi \
  --timeout 120s \
  --allow-unauthenticated
```

### Checklist Post-Deploy Backend

- [ ] Server risponde su URL pubblico
- [ ] Health check `/health` ritorna 200
- [ ] HTTPS attivo (certificato SSL)
- [ ] CORS configurato correttamente
- [ ] Logs accessibili
- [ ] Monitoring attivo
- [ ] Auto-restart configurato

## 📱 Deploy Flutter App

### Android

#### 1. Configurazione

```bash
cd flutter_app

# Aggiorna URL backend in lib/services/api_service.dart
# static const String baseUrl = 'https://api.yourdomain.com';
```

#### 2. Build APK

```bash
flutter build apk --release
```

Build ottimizzato per dimensioni:

```bash
flutter build apk --release --split-per-abi
```

File generato: `build/app/outputs/flutter-apk/app-release.apk`

#### 3. Build App Bundle (per Play Store)

```bash
flutter build appbundle --release
```

File generato: `build/app/outputs/bundle/release/app-release.aab`

#### 4. Firma App

Genera keystore:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Configura in `android/key.properties`:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

#### 5. Play Store

- [ ] Account Google Play Developer ($25 una tantum)
- [ ] Crea app nella console
- [ ] Upload AAB
- [ ] Compila scheda store
- [ ] Screenshot e icona
- [ ] Privacy policy
- [ ] Invia per review

### iOS

#### 1. Setup

```bash
# Apri progetto iOS
cd ios
open Runner.xcworkspace
```

#### 2. Configurazione Xcode

- [ ] Team di sviluppo selezionato
- [ ] Bundle ID configurato
- [ ] Versione app impostata
- [ ] Signing & Capabilities configurati

#### 3. Build

```bash
flutter build ios --release
```

#### 4. Archive e Upload

- [ ] Product > Archive in Xcode
- [ ] Validate archive
- [ ] Upload to App Store Connect

#### 5. App Store Connect

- [ ] Crea app
- [ ] Configura metadata
- [ ] Upload screenshots
- [ ] Privacy policy
- [ ] Invia per review

### Web

#### 1. Build

```bash
flutter build web --release
```

File generati in: `build/web/`

#### 2. Deploy su Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Init
firebase init hosting

# Deploy
firebase deploy --only hosting
```

#### 3. Deploy su Netlify

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
cd build/web
netlify deploy --prod
```

#### 4. Deploy su GitHub Pages

```bash
# Copia build in gh-pages branch
cp -r build/web/* /path/to/gh-pages-branch/
cd /path/to/gh-pages-branch/
git add .
git commit -m "Deploy"
git push origin gh-pages
```

### Desktop (Windows)

#### 1. Build

```bash
flutter build windows --release
```

File generato in: `build/windows/runner/Release/`

#### 2. Distribuzione

- [ ] Crea installer con Inno Setup
- [ ] Firma eseguibile (opzionale)
- [ ] Upload su sito/GitHub releases

### Checklist Post-Deploy App

- [ ] App si connette al backend di produzione
- [ ] Tutte le funzionalità funzionanti
- [ ] Performance accettabili
- [ ] No crash o errori critici
- [ ] Store listing completo
- [ ] Analytics configurato (opzionale)

## 📊 Monitoring & Manutenzione

### Backend Monitoring

```python
# Aggiungi a main.py

from prometheus_client import Counter, Histogram
import time

REQUEST_COUNT = Counter('request_count', 'App Request Count')
REQUEST_LATENCY = Histogram('request_latency_seconds', 'Request latency')

@app.middleware("http")
async def add_metrics(request, call_next):
    REQUEST_COUNT.inc()
    start = time.time()
    response = await call_next(request)
    REQUEST_LATENCY.observe(time.time() - start)
    return response
```

### Logs

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('app.log'),
        logging.StreamHandler()
    ]
)
```

### Health Checks

Configura monitoring esterno (UptimeRobot, Pingdom):

- [ ] Ping `/health` ogni 5 minuti
- [ ] Alert se down > 2 minuti
- [ ] Email/SMS notifications

### Backup

Backend:

- [ ] Backup modello FastText
- [ ] Backup daily_words.txt
- [ ] Backup configurazione

Database (se implementato):

- [ ] Backup automatico quotidiano
- [ ] Retention 30 giorni
- [ ] Test restore periodico

## 🔄 Update Workflow

### Backend Update

```bash
# Su server
cd /path/to/backend
git pull origin main
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart hotncold
```

### App Update

Android:

1. Incrementa version in `pubspec.yaml`
2. Build nuovo APK/AAB
3. Upload su Play Store
4. Attendi review (1-3 giorni)

iOS:

1. Incrementa version in `pubspec.yaml`
2. Build in Xcode
3. Upload su App Store Connect
4. Invia per review (1-3 giorni)

Web:

1. Build nuovo
2. Deploy (istantaneo)

## 🐛 Rollback Plan

Se qualcosa va storto:

Backend:

```bash
# Torna alla versione precedente
git checkout <previous-commit>
sudo systemctl restart hotncold
```

App:

- Android/iOS: Release precedente rimane disponibile per rollback manuale
- Web: Git revert + redeploy

## 📈 Metriche da Monitorare

- [ ] Uptime backend (target: 99.9%)
- [ ] Response time API (target: <500ms)
- [ ] Crash rate app (target: <1%)
- [ ] Active users (DAU/MAU)
- [ ] Tentativi medi per partita
- [ ] Tasso di vittoria
- [ ] Cache hit ratio backend

## 🎯 Post-Launch

- [ ] Monitoring attivo
- [ ] Analytics configurato
- [ ] Feedback utenti monitorato
- [ ] Bug fixing prioritizzato
- [ ] Feature roadmap definita

---

Buon deploy! 🚀
