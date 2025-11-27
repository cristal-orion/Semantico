#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script per scoprire la parola segreta del giorno
"""

import hashlib
from datetime import datetime, timezone

# Carica la lista di parole giornaliere
try:
    with open('1000_parole_italiane_comuni.txt', 'r', encoding='utf-8') as f:
        daily_words = [line.strip().lower() for line in f if line.strip()]
except FileNotFoundError:
    print("❌ File daily_words.txt non trovato!")
    print("   Avvia il backend almeno una volta per generarlo.")
    exit(1)

# Ottieni la parola di oggi
today = datetime.now(timezone.utc).date()
date_str = today.isoformat()

# Usa lo stesso algoritmo del backend
hash_obj = hashlib.md5(date_str.encode())
hash_int = int(hash_obj.hexdigest(), 16)
word_index = hash_int % len(daily_words)

secret_word = daily_words[word_index]

print(f"Data: {date_str}")
print(f"Parola segreta del giorno: {secret_word.upper()}")
print(f"Lunghezza: {len(secret_word)} lettere")
print(f"Indice: {word_index}/{len(daily_words)}")
