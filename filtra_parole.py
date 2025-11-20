#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script Helper per filtrare e trovare parole "giocabili" dal vocabolario FastText
"""

import sys
import io
import os
import re
from gensim.models import KeyedVectors
from collections import Counter

# Fix encoding per Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


class WordFilter:
    def __init__(self):
        """
        Inizializza il filtro con FastText Italian
        """
        print("🔄 Caricamento FastText Italian...\n")

        self.model = None
        self.vocab = None
        self.filtered_words = []

        self.load_fasttext_italian()

        print("✅ Modello caricato!\n")

    def load_fasttext_italian(self):
        """
        Carica FastText Italian
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

        self.model = KeyedVectors.load_word2vec_format(
            model_path,
            binary=False,
            limit=200000
        )

        print(f"💾 Salvataggio cache in {model_cache}...")
        self.model.save(model_cache)

        self.vocab = list(self.model.key_to_index.keys())
        print(f"✅ FastText pronto: {len(self.vocab)} parole italiane\n")

    def apply_basic_filters(self, min_length=4, max_length=12):
        """
        Applica filtri di base per trovare parole candidate

        Filtri applicati:
        - Lunghezza tra min_length e max_length
        - Solo lettere alfabetiche lowercase (no numeri, punteggiatura, maiuscole)
        - No parole che iniziano/finiscono con caratteri speciali
        """
        print(f"🔍 Applicazione filtri di base...")
        print(f"   - Lunghezza: {min_length}-{max_length} caratteri")
        print(f"   - Solo lettere alfabetiche minuscole")
        print()

        candidates = []

        for word in self.vocab:
            # Solo lettere minuscole
            if not word.isalpha() or not word.islower():
                continue

            # Lunghezza
            if len(word) < min_length or len(word) > max_length:
                continue

            # No caratteri accentati multipli (es. "perché" ok, "àèìòù" no)
            accents = sum(1 for c in word if c in 'àèéìíòóùú')
            if accents > 2:
                continue

            candidates.append(word)

        self.filtered_words = candidates
        print(f"✅ Trovate {len(candidates)} parole candidate\n")
        return candidates

    def exclude_plurals(self):
        """
        Esclude probabili plurali italiani
        """
        print("🔍 Esclusione plurali...")

        before = len(self.filtered_words)

        # Pattern comuni per plurali italiani
        filtered = []
        excluded = []

        for word in self.filtered_words:
            # Escludi parole che finiscono in -i ma il singolare esiste
            if word.endswith('i'):
                singular = word[:-1] + 'o'
                if singular in self.vocab and singular in self.filtered_words:
                    excluded.append(f"{word} -> {singular}")
                    continue

                singular = word[:-1] + 'e'
                if singular in self.vocab and singular in self.filtered_words:
                    excluded.append(f"{word} -> {singular}")
                    continue

            # Escludi parole che finiscono in -e se esiste versione in -a
            if word.endswith('e') and len(word) > 4:
                singular = word[:-1] + 'a'
                if singular in self.vocab and singular in self.filtered_words:
                    excluded.append(f"{word} -> {singular}")
                    continue

            filtered.append(word)

        self.filtered_words = filtered
        after = len(filtered)

        print(f"   Escluse: {before - after} parole")
        if excluded[:10]:
            print(f"   Esempi: {', '.join(excluded[:10])}")
        print()

        return filtered

    def exclude_verbs(self):
        """
        Esclude probabili verbi e forme coniugate
        """
        print("🔍 Esclusione verbi...")

        before = len(self.filtered_words)

        # Pattern comuni per verbi italiani
        verb_endings = [
            'are', 'ere', 'ire',  # Infiniti
            'ando', 'endo', 'endo',  # Gerundi
            'ato', 'uto', 'ito',  # Participi passati comuni
            'ano', 'ono', 'isco', 'iscono',  # Forme coniugate
            'ava', 'eva', 'iva',  # Imperfetti
            'erà', 'erò', 'eremo', 'erete'  # Futuri
        ]

        filtered = []
        excluded = []

        for word in self.filtered_words:
            is_verb = False

            for ending in verb_endings:
                if word.endswith(ending) and len(word) > len(ending) + 2:
                    is_verb = True
                    excluded.append(word)
                    break

            if not is_verb:
                filtered.append(word)

        self.filtered_words = filtered
        after = len(filtered)

        print(f"   Escluse: {before - after} parole")
        if excluded[:10]:
            print(f"   Esempi: {', '.join(excluded[:10])}")
        print()

        return filtered

    def load_italian_dictionary(self):
        """
        Carica un dizionario di parole italiane verificate (60k parole)
        """
        dict_file = "60000_parole_italiane.txt"
        
        if not os.path.exists(dict_file):
            print(f"❌ File '{dict_file}' non trovato!")
            print("   Assicurati di avere il file nella directory corrente\n")
            return None
        
        print(f"📖 Caricamento dizionario italiano da {dict_file}...")
        with open(dict_file, 'r', encoding='utf-8') as f:
            italian_words = set(line.strip().lower() for line in f if line.strip())
        
        print(f"✅ Dizionario caricato: {len(italian_words)} parole italiane\n")
        return italian_words
    
    def filter_by_italian_dictionary(self):
        """
        Mantiene SOLO parole presenti nel dizionario italiano
        Questo è il metodo più affidabile per escludere parole inglesi
        """
        print("🔍 Filtro con dizionario italiano...")
        
        # Carica dizionario
        italian_dict = self.load_italian_dictionary()
        
        if not italian_dict:
            print("⚠️ Dizionario non disponibile, salto questo filtro\n")
            return self.filtered_words
        
        before = len(self.filtered_words)
        
        filtered = []
        excluded = []
        
        for word in self.filtered_words:
            if word in italian_dict:
                filtered.append(word)
            else:
                excluded.append(word)
        
        self.filtered_words = filtered
        after = len(filtered)
        
        print(f"   Mantenute: {after} parole italiane verificate")
        print(f"   Escluse: {before - after} parole non nel dizionario")
        if excluded[:10]:
            print(f"   Esempi esclusi: {', '.join(excluded[:10])}")
        print()
        
        return filtered

    def check_semantic_richness(self, min_similar=50, min_similarity=0.3):
        """
        Verifica che le parole abbiano abbastanza connessioni semantiche

        Una parola "giocabile" deve avere almeno min_similar parole
        con similarità >= min_similarity
        """
        print(f"🔍 Verifica ricchezza semantica...")
        print(f"   - Minimo {min_similar} parole correlate")
        print(f"   - Similarità minima: {min_similarity}")
        print()

        before = len(self.filtered_words)
        filtered = []
        excluded = []

        for i, word in enumerate(self.filtered_words):
            if (i + 1) % 100 == 0:
                print(f"   Processate: {i + 1}/{len(self.filtered_words)}", end='\r')

            try:
                # Trova parole simili
                similar = self.model.most_similar(word, topn=100)

                # Conta quante hanno similarità >= min_similarity
                count = sum(1 for _, sim in similar if (sim + 1) / 2 >= min_similarity)

                if count >= min_similar:
                    filtered.append(word)
                else:
                    excluded.append(f"{word} ({count} simili)")

            except Exception:
                excluded.append(f"{word} (errore)")
                continue

        print()  # Newline dopo progress

        self.filtered_words = filtered
        after = len(filtered)

        print(f"   Escluse: {before - after} parole")
        if excluded[:5]:
            print(f"   Esempi escluse: {', '.join(excluded[:5])}")
        print()

        return filtered

    def analyze_word(self, word):
        """
        Analizza una singola parola in dettaglio
        """
        word = word.lower().strip()

        if word not in self.vocab:
            print(f"❌ '{word}' non nel vocabolario!\n")
            return

        print("=" * 70)
        print(f"📊 ANALISI PAROLA: '{word.upper()}'")
        print("=" * 70)
        print()

        # Informazioni di base
        print(f"✅ Presente nel vocabolario: Sì")
        print(f"   Lunghezza: {len(word)} caratteri")
        print(f"   Solo lettere: {'Sì' if word.isalpha() else 'No'}")
        print(f"   Lowercase: {'Sì' if word.islower() else 'No'}")
        print()

        # Pattern sospetti
        print("🔍 Pattern rilevati:")
        suspicious = []

        if word.endswith('i'):
            singular_o = word[:-1] + 'o'
            singular_e = word[:-1] + 'e'
            if singular_o in self.vocab:
                suspicious.append(f"Possibile plurale di '{singular_o}'")
            elif singular_e in self.vocab:
                suspicious.append(f"Possibile plurale di '{singular_e}'")

        if word.endswith(('are', 'ere', 'ire')):
            suspicious.append("Possibile infinito verbale")

        if word.endswith(('ando', 'endo')):
            suspicious.append("Possibile gerundio")

        if word.endswith(('ato', 'uto', 'ito')):
            suspicious.append("Possibile participio passato")

        if suspicious:
            for s in suspicious:
                print(f"   ⚠️ {s}")
        else:
            print(f"   ✅ Nessun pattern sospetto")
        print()

        # Ricchezza semantica
        print("🌐 Ricchezza semantica:")
        try:
            similar = self.model.most_similar(word, topn=100)

            ranges = [
                (0.8, 1.0, "CALDISSIME"),
                (0.7, 0.8, "CALDE"),
                (0.6, 0.7, "TIEPIDE"),
                (0.5, 0.6, "FREDDE"),
                (0.0, 0.5, "GELIDE")
            ]

            for min_sim, max_sim, label in ranges:
                count = sum(1 for _, sim in similar if min_sim <= (sim + 1) / 2 < max_sim)
                print(f"   {label:12s} ({min_sim:.1f}-{max_sim:.1f}): {count:3d} parole")

            print()
            print("   Top 10 parole più simili:")
            for i, (sim_word, similarity) in enumerate(similar[:10], 1):
                norm_sim = (similarity + 1) / 2
                print(f"      {i:2d}. {sim_word:20s} - {norm_sim:.4f}")

        except Exception as e:
            print(f"   ❌ Errore nel calcolo: {e}")

        print()
        print("=" * 70)
        print()

        # Giudizio finale
        is_good = (
            word.isalpha() and
            word.islower() and
            4 <= len(word) <= 12 and
            not suspicious
        )

        if is_good:
            print(f"✅ '{word}' sembra una BUONA parola per il gioco!")
        else:
            print(f"⚠️ '{word}' potrebbe NON essere ideale per il gioco")

        print()

    def show_sample(self, n=50):
        """
        Mostra un campione casuale delle parole filtrate
        """
        import random

        if not self.filtered_words:
            print("⚠️ Nessuna parola filtrata. Applica prima i filtri!\n")
            return

        sample = random.sample(self.filtered_words, min(n, len(self.filtered_words)))
        sample.sort()

        print(f"📋 Campione di {len(sample)} parole filtrate:\n")

        for i, word in enumerate(sample, 1):
            print(f"   {i:3d}. {word}")

        print()

    def export_to_file(self, filename="parole_giocabili.txt"):
        """
        Esporta le parole filtrate in un file
        """
        if not self.filtered_words:
            print("⚠️ Nessuna parola da esportare!\n")
            return

        with open(filename, 'w', encoding='utf-8') as f:
            for word in sorted(self.filtered_words):
                f.write(word + '\n')

        print(f"✅ Esportate {len(self.filtered_words)} parole in '{filename}'\n")

    def interactive_mode(self):
        """
        Modalità interattiva per filtrare parole
        """
        print("=" * 70)
        print("🔍 FILTRO PAROLE GIOCABILI - Modalità Interattiva")
        print("=" * 70)
        print()
        print("Comandi disponibili:")
        print("  1. filtri         - Applica filtri di base")
        print("  2. dizionario     - Filtra con dizionario italiano")
        print("  3. plurali        - Escludi plurali")
        print("  4. verbi          - Escludi verbi")
        print("  5. semantica      - Verifica ricchezza semantica")
        print("  6. sample [N]     - Mostra N parole casuali (default 50)")
        print("  7. analizza PAROLA - Analizza una parola specifica")
        print("  8. esporta [FILE] - Esporta in file (default: parole_giocabili.txt)")
        print("  9. stats          - Mostra statistiche")
        print("  10. esci          - Esci")
        print()

        while True:
            try:
                cmd = input("💡 Comando: ").strip().lower()

                if not cmd:
                    continue

                parts = cmd.split()
                action = parts[0]

                if action == 'esci':
                    print("\n👋 Arrivederci!")
                    break

                elif action == 'filtri':
                    self.apply_basic_filters()

                elif action == 'dizionario':
                    if not self.filtered_words:
                        print("⚠️ Applica prima i filtri di base!\n")
                    else:
                        self.filter_by_italian_dictionary()

                elif action == 'plurali':
                    if not self.filtered_words:
                        print("⚠️ Applica prima i filtri di base!\n")
                    else:
                        self.exclude_plurals()

                elif action == 'verbi':
                    if not self.filtered_words:
                        print("⚠️ Applica prima i filtri di base!\n")
                    else:
                        self.exclude_verbs()

                elif action == 'semantica':
                    if not self.filtered_words:
                        print("⚠️ Applica prima i filtri di base!\n")
                    else:
                        self.check_semantic_richness()

                elif action == 'sample':
                    n = int(parts[1]) if len(parts) > 1 else 50
                    self.show_sample(n)

                elif action == 'analizza':
                    if len(parts) < 2:
                        print("⚠️ Specifica una parola da analizzare!\n")
                    else:
                        self.analyze_word(parts[1])

                elif action == 'esporta':
                    filename = parts[1] if len(parts) > 1 else "parole_giocabili.txt"
                    self.export_to_file(filename)

                elif action == 'stats':
                    print(f"\n📊 Statistiche:")
                    print(f"   Vocabolario totale: {len(self.vocab)} parole")
                    print(f"   Parole filtrate: {len(self.filtered_words)} parole")
                    if self.filtered_words:
                        avg_len = sum(len(w) for w in self.filtered_words) / len(self.filtered_words)
                        print(f"   Lunghezza media: {avg_len:.1f} caratteri")
                    print()

                else:
                    print(f"⚠️ Comando '{action}' non riconosciuto\n")

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
        filter_tool = WordFilter()
        filter_tool.interactive_mode()

    except Exception as e:
        print(f"❌ Errore: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
