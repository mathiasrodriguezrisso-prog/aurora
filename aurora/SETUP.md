# Aurora — Guía de Setup

## Prerequisitos
- Flutter SDK >= 3.3.0
- Dart SDK >= 3.3.0
- Python >= 3.10 (para el backend)
- Cuenta Supabase
- API Key de Groq
- (Opcional) Proyecto Firebase para Notificaciones Push

## 1. Clonar el repositorio
```bash
git clone <url-del-repositorio>
cd aurora
```

## 2. Configurar variables de entorno
Copia el archivo de ejemplo y edítalo con tus credenciales:
```bash
cp .env.example .env
# Edita .env con tus valores reales
```

## 3. Configurar Supabase
### 3.1 Crear proyecto
Crea un nuevo proyecto en [supabase.com](https://supabase.com).

### 3.2 Ejecutar el schema SQL
Copia el contenido de `backend/schema.sql` (en el repositorio del backend) y ejecútalo en el **SQL Editor** de Supabase.

### 3.3 Crear Storage Buckets
En el Dashboard de Supabase > Storage, crea los siguientes buckets:
- `posts` (Público)
- `diagnostics` (Privado, acceso solo para usuarios autenticados)
- `avatars` (Público)
- `covers` (Público)

### 3.4 Configurar RLS Policies
Asegúrate de configurar las políticas de Row Level Security (RLS) apropiadas para cada tabla y bucket para garantizar la privacidad de los datos de los usuarios.

## 4. Configurar Backend
```bash
cd backend
python -m venv venv
# Windows:
venv\Scripts\activate
# Linux/macOS:
source venv/bin/activate

pip install -r requirements.txt
# Configura las variables de entorno en el backend (crea un archivo .env en la carpeta backend)
uvicorn app.main:app --reload
```

## 5. Configurar Frontend Flutter
```bash
cd ..  # Volver a la raíz del proyecto
flutter pub get
# Si se realizaron cambios en modelos con code generation:
dart run build_runner build --delete-conflicting-outputs
```

## 6. Configurar Firebase (Opcional)
Para notificaciones push, instala el CLI de FlutterFire y configura el proyecto:
```bash
flutterfire configure
```

## 7. Ejecutar
Para desarrollo local con el backend corriendo:
```bash
flutter run --dart-define=APP_ENV=development
```

## Troubleshooting

### Error: "No active grow found"
La app redirige al wizard de onboarding. Debes completar los 5 pasos para crear tu primer cultivo activo.

### Error de red / "Connection refused"
- Verifica que el backend esté corriendo.
- Si usas emulador Android, la URL del backend debe ser `http://10.0.2.2:8000`. Esto se maneja automáticamente en `EnvConfig`.
- Si usas un dispositivo físico, asegúrate de que esté en la misma red y usa la IP de tu computadora.

### Error de Supabase Auth
- Verifica `SUPABASE_URL` y `SUPABASE_ANON_KEY` en tu configuración.
- Asegúrate de que el proyecto Supabase tiene habilitado el método de Auth "Email/Password".

### Imágenes no se muestran
- Verifica que los buckets de Storage existan en Supabase.
- Comprueba que las políticas de acceso (RLS) permiten leer los archivos.

### flutter analyze muestra warnings
- Los warnings de 'unused import' en archivos generados por Riverpod/Freezed son normales.
- Asegúrate de que no haya errores críticos (rojos).
