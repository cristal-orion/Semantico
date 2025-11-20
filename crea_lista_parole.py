#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script automatico per creare lista di parole giocabili
"""

import sys
import io
from filtra_parole import WordFilter

# Fix encoding per Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


def main():
    """Applica tutti i filtri automaticamente"""

    print("=" * 70)
    print("🎮 CREAZIONE LISTA PAROLE GIOCABILI")
    print("=" * 70)
    print()

    # Inizializza filtro
    filter_tool = WordFilter()

    # 1. Applica filtri di base
    print("STEP 1/6: Filtri di base")
    filter_tool.apply_basic_filters(min_length=4, max_length=12)
    print(f"✅ Risultato: {len(filter_tool.filtered_words)} parole\n")

    # 2. Filtra con dizionario italiano (FONDAMENTALE!)
    print("STEP 2/6: Filtro con dizionario italiano")
    filter_tool.filter_by_italian_dictionary()
    print(f"✅ Risultato: {len(filter_tool.filtered_words)} parole\n")

    # 3. Escludi plurali
    print("STEP 3/6: Esclusione plurali")
    filter_tool.exclude_plurals()
    print(f"✅ Risultato: {len(filter_tool.filtered_words)} parole\n")

    # 4. Escludi verbi
    print("STEP 4/6: Esclusione verbi")
    filter_tool.exclude_verbs()
    print(f"✅ Risultato: {len(filter_tool.filtered_words)} parole\n")

    # 5. Verifica ricchezza semantica
    print("STEP 5/6: Verifica ricchezza semantica")
    print("   (Questo richiederà alcuni minuti...)")
    filter_tool.check_semantic_richness(min_similar=50, min_similarity=0.3)
    print(f"✅ Risultato: {len(filter_tool.filtered_words)} parole\n")

    # 6. Esporta
    print("STEP 6/6: Esportazione")
    filter_tool.export_to_file("parole_giocabili.txt")

    # Mostra sample
    print("=" * 70)
    print("📋 CAMPIONE DI 50 PAROLE CASUALI:")
    print("=" * 70)
    print()
    filter_tool.show_sample(50)

    # Statistiche finali
    print("=" * 70)
    print("📊 STATISTICHE FINALI")
    print("=" * 70)
    print(f"   Vocabolario iniziale: {len(filter_tool.vocab)} parole")
    print(f"   Parole giocabili: {len(filter_tool.filtered_words)} parole")
    print(f"   Percentuale: {len(filter_tool.filtered_words) / len(filter_tool.vocab) * 100:.2f}%")
    print()
    print(f"✅ Lista salvata in 'parole_giocabili.txt'")
    print("=" * 70)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"❌ Errore: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
