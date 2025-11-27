"""
Test script for authentication endpoints
Run the server first: python main.py
Then run this script: python test_auth.py
"""

import requests
import json

BASE_URL = "http://localhost:8000"

def test_register():
    """Test user registration"""
    print("\n=== Testing Registration ===")

    response = requests.post(
        f"{BASE_URL}/api/auth/register",
        json={
            "username": "testuser",
            "email": "test@example.com",
            "password": "password123"
        }
    )

    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")

    if response.status_code == 200:
        return response.json()["access_token"]
    return None


def test_login():
    """Test user login"""
    print("\n=== Testing Login ===")

    response = requests.post(
        f"{BASE_URL}/api/auth/login",
        json={
            "username": "testuser",
            "password": "password123"
        }
    )

    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")

    if response.status_code == 200:
        return response.json()["access_token"]
    return None


def test_me(token: str):
    """Test getting current user info"""
    print("\n=== Testing /me ===")

    response = requests.get(
        f"{BASE_URL}/api/auth/me",
        headers={"Authorization": f"Bearer {token}"}
    )

    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")


def test_logout(token: str):
    """Test logout"""
    print("\n=== Testing Logout ===")

    response = requests.post(
        f"{BASE_URL}/api/auth/logout",
        headers={"Authorization": f"Bearer {token}"}
    )

    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")


def test_duplicate_registration():
    """Test duplicate username/email"""
    print("\n=== Testing Duplicate Registration ===")

    response = requests.post(
        f"{BASE_URL}/api/auth/register",
        json={
            "username": "testuser",
            "email": "test2@example.com",
            "password": "password123"
        }
    )

    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")


def test_invalid_login():
    """Test invalid credentials"""
    print("\n=== Testing Invalid Login ===")

    response = requests.post(
        f"{BASE_URL}/api/auth/login",
        json={
            "username": "testuser",
            "password": "wrongpassword"
        }
    )

    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")


def test_search_users(token: str):
    """Test user search"""
    print("\n=== Testing User Search ===")

    response = requests.get(
        f"{BASE_URL}/api/users/search?q=test",
        headers={"Authorization": f"Bearer {token}"}
    )

    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")


if __name__ == "__main__":
    print("Auth API Tests")
    print("=" * 50)

    # Test registration
    token = test_register()

    if not token:
        # Try login if user already exists
        token = test_login()

    if token:
        # Test authenticated endpoints
        test_me(token)
        test_search_users(token)
        test_logout(token)

    # Test error cases
    test_duplicate_registration()
    test_invalid_login()

    print("\n" + "=" * 50)
    print("Tests completed!")
