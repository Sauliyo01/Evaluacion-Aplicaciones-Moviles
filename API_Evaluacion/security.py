# security.py
from datetime import datetime, timedelta
from passlib.context import CryptContext
import jwt
from jwt import PyJWTError

from fastapi import HTTPException, Header

SECRET_KEY = "CAMBIAR_ESTE_SECRET_KEY"   # <-- Usa el MISMO en login y validación
ALGORITHM = "HS256"

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# --------------------
# ENCRIPTAR CONTRASEÑA
# --------------------
def encriptar(password: str):
    return pwd_context.hash(password)

def verificar_password(password: str, hashed: str) -> bool:
    return pwd_context.verify(password, hashed)


# --------------------
# CREAR TOKEN
# --------------------
def crear_token(data: dict, exp_min: int = 120):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=exp_min)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


# --------------------
# VALIDAR TOKEN
# --------------------
def usuario_actual(authorization: str = Header(None)):
    if authorization is None:
        raise HTTPException(status_code=401, detail="Falta Authorization Header")

    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Formato inválido. Use: Bearer <token>")

    token = authorization.replace("Bearer ", "")

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except PyJWTError:
        raise HTTPException(status_code=401, detail="Token inválido o expirado")
