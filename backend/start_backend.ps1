# Script per avviare il backend Hot & Cold
# Encoding: UTF-8

Write-Host ""
Write-Host "=== Hot & Cold - Avvio Backend ===" -ForegroundColor Cyan
Write-Host ""

# Controlla se siamo nella cartella corretta
if (-not (Test-Path "main.py")) {
    Write-Host "[ERRORE] main.py non trovato!" -ForegroundColor Red
    Write-Host "Esegui questo script dalla cartella backend/" -ForegroundColor Yellow
    pause
    exit 1
}

# Controlla se il modello esiste
if (-not (Test-Path "../fasttext_it.model")) {
    Write-Host "[ATTENZIONE] Modello FastText non trovato!" -ForegroundColor Yellow
    Write-Host "Path cercato: ../fasttext_it.model" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Per generare il modello:" -ForegroundColor Cyan
    Write-Host "  1. Torna alla cartella parent: cd .." -ForegroundColor White
    Write-Host "  2. Esegui: python hot_and_cold_fasttext.py" -ForegroundColor White
    Write-Host ""
    $continue = Read-Host "Vuoi continuare comunque? (s/n)"
    if ($continue -ne "s") {
        exit 0
    }
}

# Controlla se Python è installato
try {
    $pythonVersion = python --version 2>&1
    Write-Host "[OK] Python trovato: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERRORE] Python non trovato!" -ForegroundColor Red
    Write-Host "Installa Python da: https://www.python.org/downloads/" -ForegroundColor Yellow
    pause
    exit 1
}

# Controlla se le dipendenze sono installate
Write-Host ""
Write-Host "Controllo dipendenze..." -ForegroundColor Cyan

$pipList = pip list 2>&1 | Out-String
$missingDeps = @()

@("fastapi", "uvicorn", "gensim") | ForEach-Object {
    if (-not ($pipList -match $_)) {
        $missingDeps += $_
    }
}

if ($missingDeps.Count -gt 0) {
    Write-Host "[ATTENZIONE] Dipendenze mancanti: $($missingDeps -join ', ')" -ForegroundColor Yellow
    Write-Host ""
    $install = Read-Host "Vuoi installarle ora? (s/n)"
    
    if ($install -eq "s") {
        Write-Host ""
        Write-Host "Installazione dipendenze..." -ForegroundColor Cyan
        pip install -r requirements.txt
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Dipendenze installate!" -ForegroundColor Green
        } else {
            Write-Host "[ERRORE] Errore durante installazione!" -ForegroundColor Red
            pause
            exit 1
        }
    } else {
        Write-Host "[ERRORE] Impossibile continuare senza dipendenze" -ForegroundColor Red
        pause
        exit 1
    }
}

Write-Host ""
Write-Host "Avvio server FastAPI..." -ForegroundColor Green
Write-Host "  URL: http://localhost:8000" -ForegroundColor Cyan
Write-Host "  Docs: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Premi Ctrl+C per fermare il server" -ForegroundColor Yellow
Write-Host ""

# Avvia il server
python main.py
