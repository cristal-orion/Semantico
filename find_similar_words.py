#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Trova le parole più simili a una parola data usando FastText Italian
"""

import sys
import io
import os
from gensim.models import KeyedVectors

# Fix encoding per Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


class SimilarWordFinder:
    def __init__(self):
        """
        Inizializza il finder con FastText Italian
        """
        print("🔄 Caricamento FastText Italian...\n")

        self.model = None
        self.vocab = None

        self.load_fasttext_italian()

        print("✅ Modello caricato!\n")

    def load_fasttext_italian(self):
        """
        Carica FastText Italian (usa la stessa cache del gioco)
        """
        import urllib.request

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

    def find_similar(self, word, n=100):
        """
        Trova le N parole più simili a una parola data

        Args:
            word: Parola di riferimento
            n: Numero di parole simili da trovare (default 100)

        Returns:
            Lista di tuple (parola, similarità)
        """
        word = word.strip().lower()

        if not self.is_valid_word(word):
            raise ValueError(f"❌ Parola '{word}' non nel vocabolario!")

        # Trova le N parole più simili
        similar_words = self.model.most_similar(word, topn=n)

        return similar_words

    def print_similar_words(self, word, n=100):
        """
        Stampa le N parole più simili a una parola data
        """
        try:
            similar_words = self.find_similar(word, n)

            print("=" * 70)
            print(f"🔍 TOP {n} PAROLE PIÙ SIMILI A: '{word.upper()}'")
            print("=" * 70)
            print()

            # Stampa in colonne per migliore leggibilità
            for i, (similar_word, similarity) in enumerate(similar_words, 1):
                # Normalizza similarità da [-1, 1] a [0, 1]
                norm_sim = (similarity + 1) / 2

                # Indica temperatura basata su similarità
                if norm_sim >= 0.8:
                    temp = "🔥🔥🔥"
                elif norm_sim >= 0.7:
                    temp = "🔥🔥"
                elif norm_sim >= 0.6:
                    temp = "🔥"
                elif norm_sim >= 0.5:
                    temp = "🌡️"
                else:
                    temp = "❄️"

                print(f"   {i:3d}. {similar_word:20s} - Similarità: {norm_sim:.4f} {temp}")

            print()
            print("=" * 70)

        except ValueError as e:
            print(f"\n{str(e)}")
            print(f"Suggerimento: Usa parole italiane comuni.\n")

    def interactive_mode(self):
        """
        Modalità interattiva per cercare parole simili
        """
        print("=" * 70)
        print("🔍 TROVA PAROLE SIMILI - FastText Edition")
        print("=" * 70)
        print()
        print(f"📚 Vocabolario: {len(self.vocab)} parole italiane")
        print()
        print("Inserisci una parola per trovare le 100 parole più simili.")
        print("Comandi: 'esci' per uscire, oppure specifica un numero (es. '50' per top 50)")
        print()

        while True:
            try:
                user_input = input("💡 Inserisci una parola: ").strip()

                if not user_input:
                    continue

                if user_input.lower() == 'esci':
                    print("\n👋 Arrivederci!")
                    break

                # Controlla se l'utente ha specificato un numero
                parts = user_input.split()
                if len(parts) == 2 and parts[1].isdigit():
                    word = parts[0]
                    n = int(parts[1])
                elif len(parts) == 1 and parts[0].isdigit():
                    print("⚠️ Specifica prima la parola, poi il numero (es. 'cane 50')")
                    continue
                else:
                    word = user_input
                    n = 100

                print()
                self.print_similar_words(word, n)
                print()

            except KeyboardInterrupt:
                print("\n\n👋 Arrivederci!")
                break
            except Exception as e:
                print(f"❌ Errore: {e}")
                import traceback
                traceback.print_exc()
                continue


def main():
    """Funzione principale"""
    try:
        # Se viene passata una parola come argomento, usa quella
        if len(sys.argv) > 1:
            finder = SimilarWordFinder()
            word = sys.argv[1]
            n = int(sys.argv[2]) if len(sys.argv) > 2 else 100
            finder.print_similar_words(word, n)
        else:
            # Altrimenti modalità interattiva
            finder = SimilarWordFinder()
            finder.interactive_mode()

    except Exception as e:
        print(f"❌ Errore: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
