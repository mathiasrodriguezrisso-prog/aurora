# GitHub Authentication Setup para Aurora

## 🔑 Opción 1: SSH (Recomendado)

**Status:** ✅ Clave SSH ED25519 generada

### Paso 1: Agregar clave pública a GitHub
1. Ve a https://github.com/settings/keys
2. Clic en "New SSH key"
3. **Title:** `Aurora SSH ED25519`
4. **Key type:** Authentication Key
5. **Key:** Copia esto:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIyA4GhPpN244YwhLK1UdadI5mabAzUZxTkXOi3E5IHG aurora-github
```
6. Clic "Add SSH key"

### Paso 2: Verificar SSH configuration en Windows
```powershell
# Verificar que SSH agent está corriendo y clave está agregada
ssh-add -l

# Si la clave no aparece, agregarla:
ssh-add "C:\Users\MMaTTz\.ssh\id_ed25519"

# Verificar conexión a GitHub
ssh -T git@github.com
# Deberías ver: "Hi mathiasrodriguez... You've successfully authenticated..."
```

### Paso 3: Push con SSH
```powershell
cd "c:\Users\MMaTTz\Desktop\Nueva carpeta"
git push -u origin main
```

**Ventajas:**
- ✅ No necesita tokens (más seguro)
- ✅ Ya configurado localmente
- ✅ Funciona con SSH agent de Windows
- ✅ Ideal para desarrollo local

---

## 💳 Opción 2: Personal Access Token (PAT)

### Paso 1: Crear token en GitHub
1. Ve a https://github.com/settings/tokens/new
2. **Token name:** `Aurora Desktop`
3. **Expiration:** 90 days (ajusta según necesites)
4. **Scopes:** Selecciona `repo` (acceso completo a repos privados/públicos)
5. Clic "Generate token" 
6. **⚠️ Copia el token ahora** (no lo volverás a ver)

### Paso 2: Configurar credential helper de Windows
```powershell
# Usa el credential manager de Windows
git config --global credential.helper manager-core
```

### Paso 3: Push (te pedirá credenciales)
```powershell
cd "c:\Users\MMaTTz\Desktop\Nueva carpeta"
git push -u origin main
```
**Ingresa:**
- **Username:** `mathiasrodriber` (tu usuario GitHub)
- **Password:** `tu_token_PAT` (el que generaste en Paso 1)

El token se guardará en Windows Credential Manager automáticamente.

**Ventajas:**
- ✅ Funciona con credential helpers
- ✅ Revocable y con vencimiento
- ✅ Control granular de permisos
- ✅ Ideal para CI/CD pipelines

---

## 🔐 Opción 3: Git Credential Manager (GCM)

### Paso 1: Verificar si GCM está instalado
```powershell
# Versión instalada (si existe)
git credential-manager --version
gcm-core ./

# Si ves versión, ya está instalado. Si no:
# Instalar vía winget (Windows 10+)
winget install -e --id Microsoft.GitCredentialManager

# O descargar desde: https://github.com/git-ecosystem/git-credential-manager/releases
```

### Paso 2: Configurar GCM como credential helper
```powershell
git config --global credential.helper manager-core
# O más específicamente para GitHub:
git config --global credential.https://github.com.helper manager-core
```

### Paso 3: Push (GCM manejará Auth)
```powershell
cd "c:\Users\MMaTTz\Desktop\Nueva carpeta"
git push -u origin main
```
GCM abrirá navegador o ventana interactiva de autenticación. Sigue el flujo de login de GitHub.

**Ventajas:**
- ✅ UI interactivo y fácil de usar
- ✅ Maneja OAuth automáticamente
- ✅ Almacenamiento seguro en Windows Credential Manager
- ✅ No necesita tokens manuales
- ✅ Recomendado por Microsoft

---

## 📊 Comparación Rápida

| Método | Seguridad | Setup | Ideal para |
|--------|-----------|-------|-----------|
| **SSH** | ⭐⭐⭐⭐⭐ | Medio | Dev local, sin tokens |
| **PAT** | ⭐⭐⭐⭐ | Bajo | CI/CD, automación |
| **GCM** | ⭐⭐⭐⭐⭐ | Bajo | Usuario Windows interactivo |

---

## ✅ Próximos Pasos

1. **Ahora:** Elige UNA opción arriba y sigue los pasos (recomendado SSH)
2. **Verifica conexión:** 
   ```powershell
   ssh -T git@github.com  # Para SSH
   # O simplemente:
   git push -u origin main  # Para PAT/GCM (te pedirá credenciales)
   ```
3. **Espera CI/CD:** Una vez pusheado, GitHub Actions ejecutará:
   - Tests: `pytest -q` en backend/
   - Docker build: `docker build -t aurora-backend:ci .`

---

## 🆘 Si algo falla

### SSH no funciona ("Permission denied")
```powershell
# 1. Verifica que la clave conozca el host
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts

# 2. Debug SSH
ssh -vvv git@github.com

# 3. Asegúrate que SSH agent conoce tu clave
ssh-add -l
ssh-add "C:\Users\MMaTTz\.ssh\id_ed25519"
```

### Credential helper no guarda token
```powershell
# Borra cached credentials y reintenta
git credential reject https://github.com
git push -u origin main
```

### "fatal: authentication required but no credentials provided"
- PAT expiró → genera uno nuevo
- Usuario incorrecto → verifica GitHub username
- Token inválido → copia del settings nuevamente

---

## 🎯 Status Actual

- ✅ Clave SSH: Generada (`id_ed25519` en `~/.ssh/`)
- ✅ Remote: Configurado a SSH (`git@github.com:...`)
- ✅ Commit: Listo para push (dcb0348)
- ⏳ **PRÓXIMO:** Ejecuta el comando push después de elegir un método

**Recomendación:** Comienza con **SSH (Opción 1)** ya que está completamente configurado.
