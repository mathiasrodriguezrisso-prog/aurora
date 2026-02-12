# 🔥 Configurar Firebase para Aurora

## Android

1. Ir a [console.firebase.google.com](https://console.firebase.google.com)
2. Crear proyecto **"Aurora"**
3. Agregar app Android:
   - Package name: `com.aurora.app`
   - Nickname: `Aurora Android`
4. Descargar `google-services.json`
5. Colocar en: `aurora/android/app/google-services.json`
6. En `android/build.gradle` (project-level), agregar en `plugins`:
   ```groovy
   id 'com.google.gms.google-services' version '4.4.2' apply false
   ```
7. En `android/app/build.gradle` (app-level), agregar en `plugins`:
   ```groovy
   id 'com.google.gms.google-services'
   ```
8. En `android/app/build.gradle`, verificar `minSdkVersion 21` o superior

## iOS

1. En Firebase Console → Agregar app iOS
2. Bundle ID: `com.aurora.app`
3. Descargar `GoogleService-Info.plist`
4. Colocar en: `aurora/ios/Runner/GoogleService-Info.plist`
5. Abrir Xcode → arrastrar el archivo a `Runner/Runner` (asegurar "Copy items if needed")
6. En `ios/Runner/Info.plist`, agregar para notificaciones en background:
   ```xml
   <key>UIBackgroundModes</key>
   <array>
     <string>fetch</string>
     <string>remote-notification</string>
   </array>
   ```
7. En Xcode → Signing & Capabilities → agregar **"Push Notifications"**
8. En Xcode → Signing & Capabilities → agregar **"Background Modes"** → activar **"Remote notifications"**

## Backend

1. En Firebase Console → ⚙️ Project Settings → **Service Accounts**
2. Click **"Generate new private key"** → descargar JSON
3. Renombrar a `firebase-service-account.json`
4. Colocar en: `aurora/backend/firebase-service-account.json`
5. Agregar a `.env`:
   ```env
   FIREBASE_SERVICE_ACCOUNT_PATH=firebase-service-account.json
   ```
6. **⚠️ NUNCA commitear este archivo** — agregar a `.gitignore`:
   ```gitignore
   firebase-service-account.json
   ```

## Dependencias Flutter

En `pubspec.yaml` agregar:
```yaml
dependencies:
  firebase_core: ^3.8.1
  firebase_messaging: ^15.2.1
  flutter_local_notifications: ^18.0.1
```

Luego correr:
```bash
flutter pub get
```

## Verificación

1. Correr la app en un dispositivo real (no emulador para push completo)
2. Verificar que el FCM token aparece en la tabla `profiles` de Supabase
3. Enviar un test message desde Firebase Console → Cloud Messaging → "Send test message"
4. Verificar que la notificación aparece en foreground (local notification) y background (system tray)
