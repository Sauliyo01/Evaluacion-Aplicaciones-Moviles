PaquExpress – Sistema de Gestión de Entregas

Aplicación móvil + API en FastAPI + Base de Datos MySQL
Proyecto final de evaluación

Contenido del Repositorio
/API/                → Código de la API (FastAPI + SQLAlchemy)
/APP/                → Aplicación móvil Flutter
/BD/                 → Script SQL con creación de tablas
README.md            → Este archivo

Descripción General

Este proyecto implementa un sistema de gestión de entregas tipo mensajería:

La API (FastAPI) permite:

Registrar agentes

Login con JWT

Listar paquetes asignados

Registrar entregas con fotografía y GPS

La App Flutter permite que el mensajero:

Inicie sesión

Vea sus paquetes

Tome fotografía (Android/Web)

Obtenga ubicación GPS

Envía evidencia a la API

La Base de Datos MySQL almacena usuarios, paquetes y entregas.

Tecnologías Utilizadas
Componente	Tecnología
Backend	FastAPI, SQLAlchemy, JWT
Base de Datos	MySQL
App Móvil	Flutter
Autenticación	Tokens JWT
Frontend Web (foto)	ImagePicker Web
Geolocalización	Geolocator
Instalación de la API (FastAPI)
1. Crear entorno virtual
python -m venv env


Activar:

Windows

env\Scripts\activate


Linux/Mac

source env/bin/activate

2. Instalar dependencias
pip install fastapi uvicorn sqlalchemy python-multipart mysql-connector-python passlib python-jose

3. Configurar la base de datos

Crear la BD en MySQL:

CREATE DATABASE paquexpress;


Luego ejecutar el script SQL ubicado en:

/BD/paquexpress.sql

4. Ejecutar la API
uvicorn main:app --reload


La API estará en:

 http://localhost:8000

Documentación automática:

http://localhost:8000/docs

Instalación de la App Flutter
1. Abrir carpeta /APP
cd APP

2. Instalar dependencias
flutter pub get

3. Ejecutar en Android / Web

Android:

flutter run


Web:

flutter run -d chrome

🗄 Script de Base de Datos (MySQL)

Ubicado en:

/BD/paquexpress.sql


Incluye:

Tabla agentes

Tabla paquetes

Tabla entregas

Relacionamientos

Seeds opcionales

Endpoints Principales de la API
Login

POST /login

Registro de agentes

POST /registro

Listar paquetes de mensajero

GET /paquetes/{mensajero_id}

Registrar entrega

POST /paquetes/entregar
Envío multipart con:

foto

lat

lng

paquete_id

agente_id

Estructura recomendada del repositorio
PaquExpress/
│
├── API/
│   ├── main.py
│   ├── security.py
│   ├── requirements.txt
│   └── uploads/
│
├── APP/
│   ├── lib/
│   ├── android/
│   ├── web/
│   ├── pubspec.yaml
│   └── README_APP.md
│
├── BD/
│   └── paquexpress.sql
│
└── README.md

Autor: Caltzontzi Arredondo Jesus Saul LITIID007

Proyecto para evaluación
Año 2025