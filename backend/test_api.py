#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test script per API Hot & Cold
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000"

def print_section(title):
    """Stampa intestazione sezione"""
    print("\n" + "="*60)
    print(f"  {title}")
    print("="*60 + "\n")

def test_health():
    """Test health check"""
    print_section("🏥 Health Check")
    
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        print(f"✅ Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Errore: {e}")
        return False

def test_stats():
    """Test statistiche server"""
    print_section("📊 Statistiche Server")
    
    try:
        response = requests.get(f"{BASE_URL}/stats")
        data = response.json()
        print(f"✅ Status Code: {response.status_code}")
        print(f"\nVocabolario: {data['vocab_size']} parole")
        print(f"Modello caricato: {data['model_loaded']}")
        print(f"Data corrente: {data['today_date']}")
        print(f"Lunghezza parola: {data['today_word_length']} lettere")
        print(f"Gioco numero: #{data['game_number']}")
        return True
    except Exception as e:
        print(f"❌ Errore: {e}")
        return False

def test_daily_word_info():
    """Test info parola giornaliera"""
    print_section("📅 Info Parola Giornaliera")
    
    try:
        response = requests.get(f"{BASE_URL}/daily-word-info")
        data = response.json()
        print(f"✅ Status Code: {response.status_code}")
        print(f"\nData: {data['date']}")
        print(f"Lunghezza parola: {data['word_length']} lettere")
        print(f"Vocabolario: {data['total_words']} parole")
        print(f"Gioco #: {data['game_number']}")
        return True
    except Exception as e:
        print(f"❌ Errore: {e}")
        return False

def test_guess(word):
    """Test singolo tentativo"""
    try:
        response = requests.post(
            f"{BASE_URL}/guess",
            json={"word": word}
        )
        data = response.json()
        
        print(f"\n🎯 Tentativo: {word.upper()}")
        
        if not data['valid']:
            print(f"   ❌ {data.get('message', 'Non valida')}")
            return data
        
        if data['correct']:
            print(f"   🎉 CORRETTO!")
        else:
            print(f"   Rank: #{data['rank']}/{data['total_words']}")
            print(f"   Similarità: {data['similarity']:.4f}")
            print(f"   {data['temperature']}")
        
        return data
    except Exception as e:
        print(f"   ❌ Errore: {e}")
        return None

def test_guess_sequence():
    """Test sequenza di tentativi"""
    print_section("🎮 Sequenza Tentativi")
    
    words = [
        "casa",
        "amore",
        "vita",
        "felice",
        "bello",
        "mondo",
        "tempo",
        "parola",
    ]
    
    results = []
    for word in words:
        result = test_guess(word)
        if result and result['valid'] and not result['correct']:
            results.append(result)
    
    # Mostra top 3
    if results:
        print("\n📊 Top 3 Tentativi:")
        sorted_results = sorted(results, key=lambda x: x['rank'])
        for i, r in enumerate(sorted_results[:3], 1):
            print(f"   {i}. {r['word']:10s} - Rank #{r['rank']}")

def test_hint():
    """Test suggerimenti"""
    print_section("💡 Suggerimenti (Hint)")
    
    try:
        today = datetime.now().date().isoformat()
        response = requests.get(f"{BASE_URL}/hint/{today}?top_n=5")
        data = response.json()
        
        print(f"✅ Status Code: {response.status_code}")
        print(f"\nData: {data['date']}")
        print(f"\nTop 5 parole più vicine:")
        
        for hint in data['hints']:
            print(f"   {hint['rank']}. {hint['word']:15s} - Similarità: {hint['similarity']:.4f}")
        
        print(f"\n💬 {data['note']}")
        return True
    except Exception as e:
        print(f"❌ Errore: {e}")
        return False

def test_invalid_words():
    """Test parole non valide"""
    print_section("🚫 Test Parole Non Valide")
    
    invalid_words = [
        "xyz123",
        "qwerty",
        "asdfgh",
        "",
    ]
    
    for word in invalid_words:
        if word:
            response = requests.post(
                f"{BASE_URL}/guess",
                json={"word": word}
            )
            data = response.json()
            print(f"❌ '{word}': {data.get('message', 'Non valida')}")

def run_all_tests():
    """Esegue tutti i test"""
    print("\n" + "🔥"*20)
    print("  HOT & COLD - Test Suite")
    print("🔥"*20)
    
    # Test connessione
    if not test_health():
        print("\n❌ Server non raggiungibile!")
        print("   Assicurati che il backend sia avviato su http://localhost:8000")
        return
    
    # Test vari
    test_stats()
    test_daily_word_info()
    test_guess_sequence()
    test_invalid_words()
    test_hint()
    
    print("\n" + "="*60)
    print("  ✅ Test completati!")
    print("="*60 + "\n")

if __name__ == "__main__":
    run_all_tests()
