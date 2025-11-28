# ============================
# Importaciones
# ============================

from datetime import datetime
from typing import Optional, List

from fastapi import FastAPI, Form, File, UploadFile, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from sqlalchemy import (
    create_engine, Column, Integer, String, TIMESTAMP,
    Float, ForeignKey
)
from sqlalchemy.orm import sessionmaker, declarative_base, relationship, Session

from pydantic import BaseModel
import shutil
import os

# Seguridad
from security import encriptar, crear_token, usuario_actual, verificar_password

# ============================
# Inicializar App
# ============================

app = FastAPI()

os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================
# Conexión MySQL
# ============================

DATABASE_URL = "mysql+mysqlconnector://root:root@localhost:3306/paquexpress"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ============================
# MODELOS SQLAlchemy
# ============================

class Agente(Base):
    __tablename__ = "agentes"

    id = Column(Integer, primary_key=True, index=True)
    usuario = Column(String(100), unique=True, nullable=False)
    correo = Column(String(200))
    contrasena_hash = Column(String(255), nullable=False)
    nombre_completo = Column(String(200))
    fecha_creacion = Column(TIMESTAMP, default=datetime.utcnow)


class Paquete(Base):
    __tablename__ = "paquetes"

    id = Column(Integer, primary_key=True, index=True)
    codigo = Column(String(100))
    descripcion = Column(String(255))
    direccion_entrega = Column(String(255))
    id_mensajero = Column(Integer)
    estado = Column(String(50), default="pendiente")

    foto_entrega = Column(String(255), nullable=True)
    lat_entrega = Column(Float, nullable=True)
    lng_entrega = Column(Float, nullable=True)
    fecha_entrega = Column(TIMESTAMP, nullable=True)


class Entrega(Base):
    __tablename__ = "entregas"

    id = Column(Integer, primary_key=True)
    paquete_id = Column(Integer, ForeignKey("paquetes.id"), nullable=False)
    agente_id = Column(Integer, ForeignKey("agentes.id"), nullable=False)
    foto_ruta = Column(String(255))
    gps_lat = Column(Float)
    gps_lng = Column(Float)
    notas = Column(String(500))
    fecha_entrega = Column(TIMESTAMP, default=datetime.utcnow)
    fecha_registro = Column(TIMESTAMP, default=datetime.utcnow)


Base.metadata.create_all(bind=engine)

# ============================
# MODELOS Pydantic
# ============================

class PaqueteSchema(BaseModel):
    id: int
    codigo: str
    descripcion: str
    direccion_entrega: str
    id_mensajero: int
    estado: str
    foto_entrega: Optional[str]
    lat_entrega: Optional[float]
    lng_entrega: Optional[float]
    fecha_entrega: Optional[datetime]

    class Config:
        from_attributes = True

class LoginRequest(BaseModel):
    username: str
    password: str

# ============================
# LOGIN
# ============================

@app.post("/login")
def login(data: LoginRequest, db: Session = Depends(get_db)):
    agente = db.query(Agente).filter(Agente.usuario == data.usuario).first()

    if not agente:
        raise HTTPException(status_code=400, detail="Usuario no encontrado")

    if not verificar_password(data.contrasena, agente.contrasena_hash):
        raise HTTPException(status_code=400, detail="Contraseña incorrecta")

    token = crear_token({"id": agente.id, "usuario": agente.usuario})
    return {"token": token, "agente_id": agente.id}

# ============================
# LISTAR PAQUETES
# ============================

@app.get("/paquetes/{mensajero_id}")
def listar_paquetes(mensajero_id: int, db: Session = Depends(get_db), user=Depends(usuario_actual)):
    paquetes = db.query(Paquete).filter(Paquete.id_mensajero == mensajero_id).all()
    return [PaqueteSchema.from_orm(p) for p in paquetes]

# ============================
# REGISTRAR ENTREGA
# ============================

@app.post("/paquetes/entregar")
async def entregar_paquete(
    paquete_id: int = Form(...),
    agente_id: int = Form(...),
    lat: float = Form(...),
    lng: float = Form(...),
    notas: str = Form(""),
    foto: UploadFile = File(...),
    db: Session = Depends(get_db),
    user=Depends(usuario_actual)
):
    paquete = db.query(Paquete).filter(Paquete.id == paquete_id).first()

    if not paquete:
        raise HTTPException(status_code=404, detail="Paquete no encontrado")

    filename = f"entrega_{paquete_id}_{int(datetime.now().timestamp())}.jpg"
    filepath = os.path.join("uploads", filename)

    with open(filepath, "wb") as f:
        shutil.copyfileobj(foto.file, f)

    paquete.estado = "entregado"
    paquete.lat_entrega = lat
    paquete.lng_entrega = lng
    paquete.fecha_entrega = datetime.utcnow()
    paquete.foto_entrega = filename

    entrega = Entrega(
        paquete_id=paquete_id,
        agente_id=agente_id,
        gps_lat=lat,
        gps_lng=lng,
        foto_ruta=filename,
        notas=notas
    )

    db.add(entrega)
    db.commit()

    return {"message": "Paquete entregado correctamente", "foto": filename}