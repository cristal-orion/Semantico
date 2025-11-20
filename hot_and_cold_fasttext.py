#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Hot and Cold Game con FastText Italian
Word embeddings VERI ottimizzati per singole parole!
"""

import sys
import io
import pickle
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
import gensim.downloader as api
from tqdm import tqdm

# Fix encoding
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


class HotAndColdGameFastText:
    def __init__(self):
        """
        Inizializza il gioco con FastText Italian
        """
        print("🔄 Caricamento FastText Italian...")
        print("   (Word embeddings REALI ottimizzati per singole parole!)")
        print("   Questo potrebbe richiedere alcuni minuti al primo avvio...\n")

        # Inizializza variabili PRIMA di caricare il modello
        self.secret_word = None
        self.secret_embedding = None
        self.secret_rankings = None
        self.attempts = []
        self.attempt_count = 0
        self.vocab = None
        self.model = None

        # Scarica e carica FastText Italian
        print("⚠️ FastText Italian non disponibile in gensim-data")
        print("   Scaricando manualmente da fastText.cc...")

        self.load_fasttext_italian()

        print("✅ Modello caricato!\n")

    def load_fasttext_italian(self):
        """
        Scarica e carica FastText Italian
        """
        import os
        import urllib.request
        import gzip
        from gensim.models import KeyedVectors

        model_path = "cc.it.300.vec.gz"
        model_cache = "fasttext_it.model"

        # Se già abbiamo il modello processato, caricalo
        if os.path.exists(model_cache):
            print(f"📦 Caricamento da cache: {model_cache}...")
            self.model = KeyedVectors.load(model_cache)
            self.vocab = list(self.model.key_to_index.keys())
            print(f"✅ Modello caricato: {len(self.vocab)} parole\n")
            return

        # Altrimenti scarica da fastText.cc
        if not os.path.exists(model_path):
            print("📥 Download FastText Italian da fastText.cc...")
            print("   URL: https://dl.fbaipublicfiles.com/fasttext/vectors-crawl/cc.it.300.vec.gz")
            print("   Dimensione: ~1.2GB (potrebbe richiedere alcuni minuti)")
            print()

            url = "https://dl.fbaipublicfiles.com/fasttext/vectors-crawl/cc.it.300.vec.gz"

            # Download con progress bar
            def download_progress(block_num, block_size, total_size):
                downloaded = block_num * block_size
                percent = min(100, (downloaded / total_size) * 100)
                bar_length = 50
                filled = int(bar_length * downloaded / total_size)
                bar = '█' * filled + '-' * (bar_length - filled)
                print(f'\r[{bar}] {percent:.1f}%', end='', flush=True)

            urllib.request.urlretrieve(url, model_path, download_progress)
            print("\n✅ Download completato!\n")

        # Carica il modello
        print(f"🔄 Caricamento FastText da {model_path}...")
        print("   (Questo richiede alcuni minuti...)\n")

        # Carica da file .vec.gz
        self.model = KeyedVectors.load_word2vec_format(
            model_path,
            binary=False,
            limit=200000  # Limita a 200k parole per velocità
        )

        # Salva in formato binario per caricamenti futuri più veloci
        print(f"💾 Salvataggio cache in {model_cache}...")
        self.model.save(model_cache)

        self.vocab = list(self.model.key_to_index.keys())
        print(f"✅ FastText pronto: {len(self.vocab)} parole italiane\n")

    def is_valid_word(self, word):
        """Verifica se una parola è nel vocabolario"""
        return word.lower() in self.model

    def get_word_embedding(self, word):
        """Ottiene embedding di una parola"""
        return self.model[word.lower()].reshape(1, -1)

    def calculate_similarity(self, word1, word2):
        """Calcola similarità tra due parole"""
        similarity = self.model.similarity(word1.lower(), word2.lower())
        # Normalizza da [-1, 1] a [0, 1]
        return (similarity + 1) / 2

    def similarity_to_temperature(self, rank, total_words):
        """Converte rank in temperatura"""
        if rank == 1:
            return "🎉 CORRETTO!"
        elif rank <= 10:
            return "🔥🔥🔥 CALDISSIMO! Ci sei quasi!"
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

    def set_secret_word(self, word):
        """Imposta parola segreta e pre-calcola ranking"""
        word = word.strip().lower()

        if not self.is_valid_word(word):
            raise ValueError(f"❌ Parola '{word}' non nel vocabolario!")

        self.secret_word = word

        print(f"🔒 Parola segreta impostata: {'*' * len(word)}")
        print(f"   (Lunghezza: {len(word)} lettere)\n")

        # Pre-calcola ranking usando most_similar di gensim (molto veloce!)
        print("🔄 Calcolo ranking con FastText...")

        # Usa most_similar per trovare le parole più vicine
        # Questo è MOLTO più veloce che calcolare tutte le similarità
        similar_words = self.model.most_similar(
            positive=[word],
            topn=len(self.vocab)
        )

        # Crea dizionario rank
        self.secret_rankings = {
            similar_word: rank + 1
            for rank, (similar_word, similarity) in enumerate(similar_words)
        }

        print(f"✅ Ranking calcolato per {len(self.secret_rankings)} parole\n")

        # Reset tentativi
        self.attempts = []
        self.attempt_count = 0

    def make_guess(self, guess_word):
        """Valuta un tentativo"""
        guess_word = guess_word.strip().lower()
        self.attempt_count += 1

        if not self.is_valid_word(guess_word):
            return {
                'word': guess_word,
                'valid': False,
                'message': f"❌ Parola '{guess_word}' non nel vocabolario!",
                'attempt': self.attempt_count
            }

        if guess_word == self.secret_word:
            return {
                'word': guess_word,
                'valid': True,
                'correct': True,
                'rank': 1,
                'total_words': len(self.vocab),
                'similarity': 1.0,
                'temperature': '🎉 CORRETTO!',
                'attempt': self.attempt_count
            }

        rank = self.secret_rankings.get(guess_word, len(self.vocab))
        similarity = self.calculate_similarity(self.secret_word, guess_word)
        temperature = self.similarity_to_temperature(rank, len(self.vocab))

        result = {
            'word': guess_word,
            'valid': True,
            'correct': False,
            'rank': rank,
            'total_words': len(self.vocab),
            'similarity': similarity,
            'temperature': temperature,
            'attempt': self.attempt_count
        }

        self.attempts.append(result)
        return result

    def print_result(self, result):
        """Stampa risultato"""
        if not result.get('valid', True):
            print(f"\n{result['message']}")
            print(f"Suggerimento: Usa parole italiane comuni.\n")
            return

        if result['correct']:
            print("\n" + "="*60)
            print(f"🎉 CONGRATULAZIONI! HAI VINTO! 🎉")
            print(f"   Parola: {result['word'].upper()}")
            print(f"   Tentativi: {result['attempt']}")
            print("="*60 + "\n")
        else:
            print(f"\n   Tentativo #{result['attempt']}: {result['word']}")
            print(f"   Rank: #{result['rank']}/{result['total_words']} parole")
            print(f"   Similarità: {result['similarity']:.4f}")
            print(f"   {result['temperature']}")
            print()

    def show_top_guesses(self, n=10):
        """Mostra i migliori tentativi"""
        if not self.attempts:
            return

        print(f"\n📊 Top {n} tentativi più vicini:")
        sorted_attempts = sorted(self.attempts, key=lambda x: x['rank'])

        for i, attempt in enumerate(sorted_attempts[:n], 1):
            print(f"   {i:2d}. {attempt['word']:15s} - Rank: #{attempt['rank']:5d}/{attempt['total_words']} - Similarità: {attempt['similarity']:.4f}")

        print()

    def show_closest_words(self, n=10):
        """Mostra le N parole più vicine alla parola segreta"""
        print(f"\n💡 TOP {n} parole più vicine a '{self.secret_word.upper()}':\n")

        similar = self.model.most_similar(self.secret_word, topn=n)

        for i, (word, similarity) in enumerate(similar, 1):
            norm_sim = (similarity + 1) / 2
            print(f"   {i:2d}. {word:15s} - Similarità: {norm_sim:.4f}")

        print()

    def play_interactive(self):
        """Gioco interattivo"""
        print("="*60)
        print("🎮 HOT AND COLD - FastText Edition 🎮")
        print("="*60)
        print("\nBenvenuto! Questo usa FastText per word embeddings REALI.")
        print(f"\n📚 Vocabolario: {len(self.vocab)} parole italiane")
        print("\nRiceverai un RANK per ogni tentativo:")
        print("  - Rank #1-10 = CALDISSIMO 🔥🔥🔥")
        print("  - Rank #500+ = GHIACCIATO 🧊")
        print("\nDigita 'esci', 'top', o 'hint'.\n")

        # Parola segreta
        while True:
            secret = input("🔒 Inserisci la parola segreta: ").strip()

            if not secret:
                continue

            if not self.is_valid_word(secret):
                print(f"❌ '{secret}' non è nel vocabolario!\n")
                continue

            try:
                self.set_secret_word(secret)
                break
            except ValueError as e:
                print(str(e))
                continue

        # Loop di gioco
        while True:
            try:
                guess = input("💡 Indovina una parola: ").strip()

                if not guess:
                    continue

                if guess.lower() == 'esci':
                    print("\n👋 Grazie per aver giocato!")
                    print(f"   Parola segreta: {self.secret_word.upper()}")
                    print(f"   Tentativi: {self.attempt_count}")
                    if self.attempts:
                        self.show_top_guesses()
                    self.show_closest_words()
                    break

                if guess.lower() == 'top':
                    self.show_top_guesses()
                    continue

                if guess.lower() == 'hint':
                    self.show_closest_words(5)
                    continue

                result = self.make_guess(guess)
                self.print_result(result)

                if result.get('correct', False):
                    self.show_top_guesses()
                    self.show_closest_words()
                    play_again = input("Vuoi giocare ancora? (s/n): ").strip().lower()
                    if play_again == 's':
                        print("\n" + "="*60 + "\n")
                        self.play_interactive()
                    break

            except KeyboardInterrupt:
                print("\n\n👋 Gioco interrotto!")
                break
            except Exception as e:
                print(f"❌ Errore: {e}")
                import traceback
                traceback.print_exc()
                continue


def main():
    """Funzione principale"""
    try:
        game = HotAndColdGameFastText()
        game.play_interactive()

    except Exception as e:
        print(f"❌ Errore: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
