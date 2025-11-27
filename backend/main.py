#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Hot and Cold Game - FastAPI Backend
Gestisce il modello FastText e la logica del gioco
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import Optional, List, Dict
import uvicorn
from datetime import datetime, timezone
import hashlib
import os
from gensim.models import KeyedVectors
import numpy as np
import logging

# Import database and auth
from database import init_db
from routers.auth_router import router as auth_router
from routers.users_router import router as users_router
from routers.game_router import router as game_router
from routers.friends_router import router as friends_router

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Inizializza FastAPI
app = FastAPI(
    title="Hot and Cold Game API",
    description="API per gioco di indovinare parole con similarità semantica",
    version="1.0.0"
)

# CORS per permettere richieste da Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In produzione, specifica i domini esatti
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router)
app.include_router(users_router)
app.include_router(game_router)
app.include_router(friends_router)

# Create uploads directory for avatars
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Serve static files (avatars)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# Modelli Pydantic per richieste/risposte
class GuessRequest(BaseModel):
    word: str
    date: Optional[str] = None  # Formato: YYYY-MM-DD

class GuessResponse(BaseModel):
    word: str
    valid: bool
    correct: bool
    rank: Optional[int] = None
    total_words: Optional[int] = None
    similarity: Optional[float] = None
    temperature: Optional[str] = None
    message: Optional[str] = None

class DailyWordInfo(BaseModel):
    date: str
    word_length: int
    total_words: int
    game_number: int

class StatsResponse(BaseModel):
    vocab_size: int
    model_loaded: bool
    today_date: str
    today_word_length: int
    game_number: int

class HintResponse(BaseModel):
    hint_word: str
    message: str

class ShotNewGameResponse(BaseModel):
    game_id: str
    clue_words: List[str]

class ShotGuessRequest(BaseModel):
    game_id: str
    guess: str

class ShotGuessResponse(BaseModel):
    correct: bool
    target_word: Optional[str] = None
    message: str

# Game Manager Singleton
class GameManager:
    def __init__(self):
        self.model = None
        self.vocab = None
        self.daily_words = []  # Lista di parole per ogni giorno
        self.rankings_cache = {}  # Cache dei ranking pre-calcolati
        self.shot_word_database = []  # Database di parole con indizi per gioco Shot
        self.active_shot_games = {}  # game_id -> target_word
        
    def load_model(self, model_path: str = "fasttext_it.model"):
        """Carica il modello FastText"""
        logger.info("🔄 Caricamento modello FastText...")
        
        if not os.path.exists(model_path):
            logger.error(f"❌ Modello non trovato: {model_path}")
            raise FileNotFoundError(f"Modello non trovato: {model_path}")
        
        self.model = KeyedVectors.load(model_path)
        self.vocab = list(self.model.key_to_index.keys())
        logger.info(f"✅ Modello caricato: {len(self.vocab)} parole")
        
        # Carica dizionario italiano (60k parole verificate)
        self.load_italian_dictionary()
        
        # Carica/genera lista parole giornaliere
        self.load_daily_words()
        
        # Carica parole per gioco Shot
        self.load_shot_words()
    
    def load_italian_dictionary(self, dict_file: str = "280000_parole_italiane.txt"):
        """
        Carica dizionario di parole italiane verificate
        Questo serve per validare gli input degli utenti (solo parole italiane)
        """
        self.italian_words = set()
        
        if os.path.exists(dict_file):
            with open(dict_file, 'r', encoding='utf-8') as f:
                self.italian_words = set(line.strip().lower() for line in f if line.strip())
            logger.info(f"📖 Dizionario italiano: {len(self.italian_words)} parole")
        else:
            logger.warning(f"⚠️ Dizionario italiano '{dict_file}' non trovato!")
            logger.warning("   Le parole NON saranno validate come italiane!")
    
    def load_daily_words(self, words_file: str = "1000_parole_italiane_comuni.txt"):
        """
        Carica lista di parole giornaliere dal file delle 1000 parole comuni
        Queste sono parole italiane verificate e ben distillate
        """
        if os.path.exists(words_file):
            with open(words_file, 'r', encoding='utf-8') as f:
                self.daily_words = [line.strip().lower() for line in f if line.strip()]
            logger.info(f"✅ Caricate {len(self.daily_words)} parole giornaliere")
        else:
            logger.warning(f"⚠️ File '{words_file}' non trovato!")
            logger.info("🔄 Uso lista di backup dal vocabolario...")
            
            # Fallback: usa parole dal vocabolario (solo se nel dizionario italiano)
            italian_dict_file = "280000_parole_italiane.txt"
            italian_words = set()
            
            if os.path.exists(italian_dict_file):
                with open(italian_dict_file, 'r', encoding='utf-8') as f:
                    italian_words = set(line.strip().lower() for line in f if line.strip())
                logger.info(f"📖 Caricato dizionario italiano: {len(italian_words)} parole")
            
            # Filtra vocabolario per tenere solo parole italiane
            common_words = []
            for word in self.vocab[:50000]:
                if (4 <= len(word) <= 12 and 
                    word.isalpha() and 
                    (not italian_words or word in italian_words)):
                    common_words.append(word)
            
            self.daily_words = common_words[:1000]
            logger.info(f"✅ Generate {len(self.daily_words)} parole giornaliere")

    def load_shot_words(self, database_file: str = "shot_words_database.json"):
        """Carica il database di parole con indizi per il gioco Shot"""
        import json

        if os.path.exists(database_file):
            with open(database_file, 'r', encoding='utf-8') as f:
                self.shot_word_database = json.load(f)
            logger.info(f"✅ Caricato database Shot con {len(self.shot_word_database)} parole")
        else:
            logger.warning(f"⚠️ File '{database_file}' non trovato!")
            self.shot_word_database = []

    def start_new_shot_game(self) -> Dict:
        """Avvia una nuova partita Shot"""
        import uuid
        import random

        if not self.shot_word_database:
            raise HTTPException(status_code=500, detail="Database parole Shot non caricato")

        # 1. Seleziona una entry casuale dal database (già con target e indizi)
        word_entry = random.choice(self.shot_word_database)

        target_word = word_entry['target'].lower()
        clue_words = [clue.upper() for clue in word_entry['clues']]

        # 2. Genera ID e salva stato
        game_id = str(uuid.uuid4())
        self.active_shot_games[game_id] = target_word

        # 3. Opzionale: pulizia vecchie partite se troppe
        if len(self.active_shot_games) > 1000:
            # Rimuovi una a caso (semplice garbage collection)
            self.active_shot_games.pop(next(iter(self.active_shot_games)))

        logger.info(f"🎮 Nuova partita Shot: {game_id} -> {target_word.upper()}")

        return {
            "game_id": game_id,
            "clue_words": clue_words,
            "target_word": target_word  # Solo per debug/log
        }

    def check_shot_guess(self, game_id: str, guess: str) -> Dict:
        """Verifica un tentativo Shot"""
        if game_id not in self.active_shot_games:
            raise HTTPException(status_code=404, detail="Partita non trovata o scaduta")
            
        target_word = self.active_shot_games[game_id]
        guess = guess.strip().lower()
        
        is_correct = (guess == target_word)
        
        result = {
            "correct": is_correct,
            "message": "Hai indovinato! 🎉" if is_correct else "Non è la parola corretta."
        }
        
        if is_correct:
            result["target_word"] = target_word
            # Rimuovi partita attiva? O lasciala per permettere refresh?
            # Meglio lasciarla o rimuoverla dopo un po'. Per ora lasciamo.
            del self.active_shot_games[game_id]
            
        return result
    
    def get_daily_word(self, date_str: Optional[str] = None) -> str:
        """Ottiene la parola del giorno (deterministica basata su data)"""
        if not date_str:
            # Usa data UTC corrente
            today = datetime.now(timezone.utc).date()
            date_str = today.isoformat()
        
        # Genera indice deterministico dalla data
        hash_obj = hashlib.md5(date_str.encode())
        hash_int = int(hash_obj.hexdigest(), 16)
        word_index = hash_int % len(self.daily_words)
        
        return self.daily_words[word_index]
    
    def get_game_number(self, date_str: str) -> int:
        """Calcola il numero del gioco dalla data di inizio"""
        # Data di inizio del gioco (modifica questa data)
        start_date = datetime(2025, 11, 1, tzinfo=timezone.utc).date()
        current_date = datetime.fromisoformat(date_str).date()
        delta = (current_date - start_date).days
        return max(1, delta + 1)
    
    def get_or_compute_rankings(self, secret_word: str) -> Dict[str, int]:
        """Ottiene o calcola ranking per parola segreta (con cache)"""
        if secret_word in self.rankings_cache:
            return self.rankings_cache[secret_word]
        
        logger.info(f"🔄 Calcolo ranking per '{secret_word}'...")
        
        # Calcola ranking usando most_similar
        similar_words = self.model.most_similar(
            positive=[secret_word],
            topn=len(self.vocab)
        )
        
        rankings = {
            word: rank + 1
            for rank, (word, _) in enumerate(similar_words)
        }
        
        # Cache (limitata a 100 parole per non usare troppa RAM)
        if len(self.rankings_cache) < 100:
            self.rankings_cache[secret_word] = rankings
        
        logger.info(f"✅ Ranking calcolato per {len(rankings)} parole")
        
        return rankings
    
    def calculate_similarity(self, word1: str, word2: str) -> float:
        """Calcola similarità tra due parole (normalizzata 0-1)"""
        similarity = self.model.similarity(word1.lower(), word2.lower())
        return (similarity + 1) / 2
    
    def is_valid_word(self, word: str) -> bool:
        """
        Verifica se parola è nel vocabolario E nel dizionario italiano
        Questo esclude tutte le parole inglesi e non-italiane
        """
        word = word.lower()
        
        # Deve essere nel modello FastText
        if word not in self.model:
            return False
        
        # Deve essere nel dizionario italiano (se caricato)
        if self.italian_words and word not in self.italian_words:
            return False
        
        return True
    
    def rank_to_temperature(self, rank: int) -> str:
        """Converte rank in temperatura"""
        if rank == 1:
            return "🎉 PERFETTO!"
        elif rank <= 10:
            return "🔥🔥🔥 Caldissimo!"
        elif rank <= 50:
            return "🔥🔥 Molto caldo!"
        elif rank <= 100:
            return "🔥 Caldo!"
        elif rank <= 500:
            return "🌡️ Tiepido"
        elif rank <= 1000:
            return "❄️ Freddo"
        elif rank <= 5000:
            return "❄️❄️ Molto freddo"
        else:
            return "🧊 Ghiacciato!"

# Istanza globale del game manager
game_manager = GameManager()

# Startup event
@app.on_event("startup")
async def startup_event():
    """Inizializza il gioco al avvio del server"""
    try:
        # Initialize database
        init_db()
        logger.info("✅ Database inizializzato!")

        game_manager.load_model()
        game_manager.load_shot_words()
        logger.info("✅ Server pronto!")
    except Exception as e:
        logger.error(f"❌ Errore durante inizializzazione: {e}")
        raise

# Routes
@app.get("/")
async def root():
    """Endpoint di benvenuto"""
    return {
        "message": "Hot and Cold Game API",
        "version": "1.0.0",
        "endpoints": {
            "stats": "/stats",
            "daily_word_info": "/daily-word-info",
            "guess": "/guess (POST)",
            "daily_word_info": "/daily-word-info",
            "guess": "/guess (POST)",
            "hint": "/hint/{date}",
            "shot_new_game": "/shot/new-game (POST)",
            "shot_guess": "/shot/guess (POST)",
        }
    }

@app.get("/stats", response_model=StatsResponse)
async def get_stats():
    """Statistiche del server"""
    today = datetime.now(timezone.utc).date().isoformat()
    daily_word = game_manager.get_daily_word(today)
    game_number = game_manager.get_game_number(today)
    
    return StatsResponse(
        vocab_size=len(game_manager.vocab),
        model_loaded=game_manager.model is not None,
        today_date=today,
        today_word_length=len(daily_word),
        game_number=game_number
    )

@app.get("/daily-word-info", response_model=DailyWordInfo)
async def get_daily_word_info(date: Optional[str] = None):
    """Info sulla parola giornaliera (senza rivelarla)"""
    if not date:
        date = datetime.now(timezone.utc).date().isoformat()
    
    daily_word = game_manager.get_daily_word(date)
    game_number = game_manager.get_game_number(date)
    
    return DailyWordInfo(
        date=date,
        word_length=len(daily_word),
        total_words=len(game_manager.vocab),
        game_number=game_number
    )

@app.post("/guess", response_model=GuessResponse)
async def make_guess(request: GuessRequest):
    """Valuta un tentativo"""
    guess_word = request.word.strip().lower()
    
    # Ottieni parola del giorno
    if not request.date:
        date = datetime.now(timezone.utc).date().isoformat()
    else:
        date = request.date
    
    secret_word = game_manager.get_daily_word(date)
    
    # Valida parola
    if not game_manager.is_valid_word(guess_word):
        return GuessResponse(
            word=guess_word,
            valid=False,
            correct=False,
            message=f"Parola '{guess_word}' non nel vocabolario"
        )
    
    # Verifica se corretta
    if guess_word == secret_word:
        return GuessResponse(
            word=guess_word,
            valid=True,
            correct=True,
            rank=1,
            total_words=len(game_manager.vocab),
            similarity=1.0,
            temperature="🎉 PERFETTO!",
            message="Congratulazioni! Hai indovinato!"
        )
    
    # Calcola rank e similarità
    rankings = game_manager.get_or_compute_rankings(secret_word)
    rank = rankings.get(guess_word, len(game_manager.vocab))
    similarity = game_manager.calculate_similarity(secret_word, guess_word)
    temperature = game_manager.rank_to_temperature(rank)
    
    return GuessResponse(
        word=guess_word,
        valid=True,
        correct=False,
        rank=rank,
        total_words=len(game_manager.vocab),
        similarity=similarity,
        temperature=temperature
    )

@app.get("/hint", response_model=HintResponse)
async def get_hint(date: Optional[str] = None):
    """Ottiene un suggerimento casuale tra le top 500 parole più vicine"""
    if not date:
        date = datetime.now(timezone.utc).date().isoformat()
    
    secret_word = game_manager.get_daily_word(date)
    
    # Ottieni top 1000 parole più simili (ne prendiamo di più per filtrare)
    similar = game_manager.model.most_similar(secret_word, topn=1000)
    
    # Filtra solo parole valide
    valid_similar = [
        (word, sim) for word, sim in similar 
        if game_manager.is_valid_word(word) and word != secret_word
    ]
    
    if not valid_similar:
        # Fallback se non troviamo nulla (improbabile)
        return HintResponse(
            hint_word="...",
            message="Nessun suggerimento disponibile al momento."
        )

    # Scegli una parola casuale tra le top 100 valide (per dare aiuti buoni)
    # Limitiamo alle prime 100 per dare suggerimenti utili
    top_valid = valid_similar[:100]
    
    import random
    hint_word, similarity = random.choice(top_valid)
    
    return HintResponse(
        hint_word=hint_word,
        message=f"💡 Suggerimento: prova parole vicine a '{hint_word}'"
    )

@app.get("/hint/{date}")
async def get_hint_debug(date: str, top_n: int = 5):
    """Ottiene suggerimento (parole più vicine) - per debug/aiuto"""
    secret_word = game_manager.get_daily_word(date)
    
    similar = game_manager.model.most_similar(secret_word, topn=top_n)
    
    hints = [
        {
            "word": word,
            "similarity": float((sim + 1) / 2),
            "rank": i + 1
        }
        for i, (word, sim) in enumerate(similar)
    ]
    
    return {
        "date": date,
        "hints": hints,
        "note": "Queste sono le parole più vicine alla soluzione"
    }

@app.post("/shot/new-game", response_model=ShotNewGameResponse)
async def shot_new_game():
    """Avvia una nuova partita Shot"""
    game_data = game_manager.start_new_shot_game()
    return ShotNewGameResponse(
        game_id=game_data["game_id"],
        clue_words=game_data["clue_words"]
    )

@app.post("/shot/guess", response_model=ShotGuessResponse)
async def shot_guess(request: ShotGuessRequest):
    """Valuta un tentativo Shot"""
    result = game_manager.check_shot_guess(request.game_id, request.guess)
    return ShotGuessResponse(
        correct=result["correct"],
        target_word=result.get("target_word"),
        message=result["message"]
    )

@app.get("/health")
async def health_check():
    """Health check per monitoring"""
    return {
        "status": "healthy",
        "model_loaded": game_manager.model is not None,
        "vocab_size": len(game_manager.vocab) if game_manager.vocab else 0
    }

# Main per esecuzione diretta
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
