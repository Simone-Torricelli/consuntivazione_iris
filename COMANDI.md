# 🚀 Comandi Rapidi - IRIS Consuntivazione

## 📱 Esecuzione in Sviluppo

### Web (Chrome)
```bash
flutter run -d chrome
```

### Android
```bash
# Emulatore Android
flutter run -d android

# Dispositivo fisico via USB
flutter run
```

### iOS (solo su macOS)
```bash
# Simulatore iOS
flutter run -d ios

# Dispositivo fisico
flutter run
```

---

## 🏗️ Build per Produzione

### Web
```bash
# Build ottimizzata
flutter build web --release

# I file compilati saranno in: build/web/

# Per hostare localmente:
cd build/web
python3 -m http.server 8000
# Apri http://localhost:8000
```

### Android APK
```bash
# APK universale
flutter build apk --release

# APK split per architettura (più leggeri)
flutter build apk --split-per-abi

# File generato: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (per Play Store)
```bash
flutter build appbundle --release

# File generato: build/app/outputs/bundle/release/app-release.aab
```

### iOS (solo su macOS)
```bash
flutter build ios --release

# Apri Xcode per archiviare e distribuire
open ios/Runner.xcworkspace
```

---

## 🔧 Comandi Utili

### Installare dipendenze
```bash
flutter pub get
```

### Pulire build cache
```bash
flutter clean
flutter pub get
```

### Analisi statica del codice
```bash
flutter analyze
```

### Formattare il codice
```bash
flutter format .
```

### Eseguire test
```bash
flutter test
```

### Controllare versione Flutter
```bash
flutter --version
```

### Aggiornare Flutter
```bash
flutter upgrade
```

### Vedere dispositivi disponibili
```bash
flutter devices
```

---

## 🐛 Troubleshooting

### Problema: "No devices found"
```bash
# Per web, assicurati che Chrome sia installato
flutter config --enable-web

# Per Android, avvia un emulatore o collega un dispositivo
```

### Problema: Build fallisce
```bash
# Pulisci e ricompila
flutter clean
flutter pub get
flutter run
```

### Problema: Dipendenze non si installano
```bash
# Forza aggiornamento
flutter pub upgrade --major-versions
```

### Problema: Hot reload non funziona
```bash
# Riavvia l'app con hot restart
# Premi 'R' nel terminale dove gira flutter run
```

---

## 📦 Deploy Web

### Firebase Hosting
```bash
# Installa Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Inizializza progetto
firebase init hosting

# Build
flutter build web --release

# Deploy
firebase deploy --only hosting
```

### Netlify
```bash
# Build
flutter build web --release

# Arrastra la cartella build/web su https://app.netlify.com/drop
```

### GitHub Pages
```bash
# Build con base-href
flutter build web --release --base-href "/nome-repo/"

# Copia contenuto di build/web nella branch gh-pages
```

---

## 🎯 Suggerimenti Prestazioni

### Build Ottimizzata Web
```bash
flutter build web --release --web-renderer canvaskit
# o
flutter build web --release --web-renderer html
```

### Ridurre dimensione APK
```bash
# Usa ProGuard/R8 (già abilitato in release)
flutter build apk --release --shrink

# Split per ABI
flutter build apk --release --split-per-abi
```

---

## 📊 Analisi Performance

### Profiling
```bash
# Profile mode per analisi performance
flutter run --profile

# Apri DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### Controllare dimensione app
```bash
# Android
flutter build apk --release --analyze-size

# iOS
flutter build ios --release --analyze-size
```

---

## 🔑 Variabili d'Ambiente

Per configurazioni diverse (dev, staging, prod), puoi usare:

```bash
# Sviluppo
flutter run --dart-define=ENV=dev

# Produzione
flutter run --dart-define=ENV=prod
```

---

## 📝 Note Importanti

1. **Prima build**: La prima build può richiedere diversi minuti
2. **Hot reload**: Usa 'r' per hot reload, 'R' per hot restart
3. **Web**: Testa su più browser (Chrome, Firefox, Safari)
4. **Mobile**: Testa su dispositivi reali, non solo emulatori
5. **iOS**: Richiede account Apple Developer per dispositivi fisici

---

## 🆘 Link Utili

- [Flutter Docs](https://docs.flutter.dev/)
- [Dart Docs](https://dart.dev/guides)
- [Provider Docs](https://pub.dev/packages/provider)
- [Flutter Community](https://flutter.dev/community)

---

**Versione**: 1.0.0  
**Ultimo aggiornamento**: Dicembre 2025
