#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script per impostare una parola segreta specifica
"""

import sys
import hashlib
from datetime import datetime, timezone

def set_secret_word(target_word, date_str=None):
    """Imposta una parola segreta per una data specifica"""
    
    # Usa data di oggi se non specificata
    if not date_str:
        today = datetime.now(timezone.utc).date()
        date_str = today.isoformat()
    
    # Carica parole giornaliere
    try:
        with open('daily_words.txt', 'r', encoding='utf-8') as f:
            daily_words = [line.strip().lower() for line in f if line.strip()]
    except FileNotFoundError:
        print("❌ File daily_words.txt non trovato!")
        return False
    
    target_word = target_word.lower().strip()
    
    # Verifica che la parola sia nella lista
    if target_word not in daily_words:
        print(f"❌ La parola '{target_word}' non è nella lista delle parole giornaliere!")
        print(f"   Aggiungila manualmente a daily_words.txt")
        return False
    
    # Trova l'indice della parola
    target_index = daily_words.index(target_word)
    
    # Calcola quale data produrrebbe questo indice
    print(f"📝 Parola target: {target_word.upper()}")
    print(f"📊 Indice nella lista: {target_index}/{len(daily_words)}")
    print(f"📅 Data richiesta: {date_str}")
    
    # Verifica l'hash attuale
    hash_obj = hashlib.md5(date_str.encode())
    hash_int = int(hash_obj.hexdigest(), 16)
    current_index = hash_int % len(daily_words)
    current_word = daily_words[current_index]
    
    print(f"\n🔍 Parola attuale per {date_str}: {current_word.upper()}")
    
    if current_word == target_word:
        print(f"✅ La parola '{target_word.upper()}' è già la parola del giorno!")
        return True
    
    # Per cambiare la parola, devi modificare la lista
    # Scambia la parola target con quella all'indice corrente
    print(f"\n🔄 Scambio parole nella lista...")
    daily_words[current_index], daily_words[target_index] = daily_words[target_index], daily_words[current_index]
    
    # Salva la lista modificata
    with open('daily_words.txt', 'w', encoding='utf-8') as f:
        f.write('\n'.join(daily_words))
    
    print(f"✅ Parola del giorno cambiata in: {target_word.upper()}")
    print(f"⚠️  Riavvia il backend per applicare le modifiche!")
    
    return True

def show_usage():
    """Mostra istruzioni uso"""
    print("Uso:")
    print("  python set_secret_word.py <parola> [data]")
    print("")
    print("Esempi:")
    print("  python set_secret_word.py casa")
    print("  python set_secret_word.py amore 2025-11-18")
    print("")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        show_usage()
        sys.exit(1)
    
    word = sys.argv[1]
    date = sys.argv[2] if len(sys.argv) > 2 else None
    
    set_secret_word(word, date)
