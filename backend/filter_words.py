#!/usr/bin/env python3
"""
Script per filtrare le parole giornaliere
Tiene solo le parole presenti nel vocabolario FastText
"""

from gensim.models import KeyedVectors
import os

def main():
    print("[*] Caricamento modello FastText...")
    model = KeyedVectors.load("fasttext_it.model")
    vocab = set(model.key_to_index.keys())
    print(f"[OK] Modello caricato: {len(vocab)} parole nel vocabolario")

    # Leggi le parole attuali
    words_file = "1000_parole_italiane_comuni.txt"
    with open(words_file, 'r', encoding='utf-8') as f:
        words = [line.strip().lower() for line in f if line.strip()]

    print(f"[*] Parole nel file: {len(words)}")

    # Filtra solo le parole presenti nel vocabolario
    valid_words = []
    invalid_words = []

    for word in words:
        if word in vocab:
            valid_words.append(word)
        else:
            invalid_words.append(word)

    print(f"\n[OK] Parole VALIDE (nel vocabolario): {len(valid_words)}")
    print(f"[X] Parole NON VALIDE (non nel vocabolario): {len(invalid_words)}")

    if invalid_words:
        print(f"\n[*] Parole rimosse:")
        for w in invalid_words:
            print(f"   - {w}")

    # Salva backup del file originale
    backup_file = "1000_parole_italiane_comuni_backup.txt"
    if os.path.exists(backup_file):
        os.remove(backup_file)
    os.rename(words_file, backup_file)
    print(f"\n[*] Backup salvato in: {backup_file}")

    # Scrivi le parole valide
    with open(words_file, 'w', encoding='utf-8') as f:
        for word in valid_words:
            f.write(word + '\n')

    print(f"[OK] Salvate {len(valid_words)} parole valide in: {words_file}")
    print("\n[!] Riavvia il server per caricare le nuove parole!")

if __name__ == "__main__":
    main()
