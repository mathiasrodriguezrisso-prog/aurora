
import sys
import os
from jose import jwt, JWTError
from datetime import datetime, timedelta

# Mock settings
SECRET = "test-secret-key-1234567890"

def verify_jwt_logic(token):
    try:
        payload = jwt.decode(
            token,
            SECRET,
            algorithms=["HS256"],
            audience="authenticated",
            options={"verify_aud": True},
        )
        return payload
    except Exception as e:
        return str(e)

# Create a valid token
payload = {
    "sub": "user-123",
    "aud": "authenticated",
    "exp": datetime.utcnow() + timedelta(hours=1),
    "iat": datetime.utcnow(),
    "role": "authenticated"
}
token = jwt.encode(payload, SECRET, algorithm="HS256")

print(f"Generated Token: {token}")

# Test Verification
try:
    decoded = verify_jwt_logic(token)
    print(f"Decoded Successfully: {decoded}")
except Exception as e:
    print(f"Verification Failed: {e}")

# Test Invalid Secret
try:
    jwt.decode(token, "wrong-secret", algorithms=["HS256"], audience="authenticated")
    print("Error: Verified with wrong secret!")
except JWTError:
    print("Success: Rejected wrong secret")

# Test Wrong Algo
try:
    # Force RS256 or something else if we could, but let's just test happy path mostly
    pass
except Exception:
    pass
