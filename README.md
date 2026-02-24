# 🕐 IRIS Consuntivazione

Una moderna WebApp Flutter per la gestione della consuntivazione aziendale. L'applicazione è installabile su dispositivi Android e iOS, ma soprattutto utilizzabile direttamente da web browser.

## ✨ Caratteristiche Principali

### 📊 Dashboard Team (Admin / Manager / TL)
- **Gestione Utenti**: Aggiungi, modifica e disattiva dipendenti
- **Gestione Progetti**: Crea e gestisci progetti con colori personalizzati (Admin, Manager, Team Lead)
- **Tipi Developer**: Android, iOS, Full Stack, Backend, Frontend, Designer, QA
- **Statistiche in tempo reale**: Ore totali, giorni lavorati, progetti attivi

### ⏱️ Consuntivazione Ore
- **Validazione automatica**: 
  - Ore in incrementi di 0.5h (min 0.5h, max 8h per progetto)
  - Max 8h lavorative al giorno totali
  - Popup di errore se si supera la soglia
- **Interface intuitiva**: Selezione rapida delle ore con UI gradevole
- **Note opzionali**: Aggiungi dettagli per ogni consuntivazione
- **Modifica ed eliminazione**: Gestione completa delle entry

### 📅 Calendario Recap Mensile
- **Vista calendario interattiva**: Visualizza tutte le tue consuntivazioni
- **Statistiche mensili**: Ore totali, giorni lavorati, media giornaliera
- **Breakdown per progetto**: Grafico a barre con percentuali
- **Dettaglio giornaliero**: Clicca su un giorno per vedere il dettaglio

### 🔔 Notifiche Push
- **Reminder automatici**: Notifiche giornaliere alle 18:00
- **Smart scheduling**: Esclude sabati, domeniche e festività italiane
- **Gestibili**: Attiva/disattiva dalle impostazioni

### 🎨 UI/UX Design
- **Grafica moderna**: Design pulito con gradienti e animazioni
- **Responsive**: Si adatta a tutti i dispositivi
- **Tema personalizzato**: Colori coerenti e accattivanti
- **Iconografia**: Icons significative per ogni sezione

## 🚀 Installazione e Avvio

### Prerequisiti
- Flutter SDK (>=3.9.2)
- Dart SDK
- Android Studio / Xcode (per sviluppo mobile)
- Chrome (per web)

### Installazione Dipendenze

```bash
# Naviga nella directory del progetto
cd consuntivazione_iris

# Installa le dipendenze
flutter pub get

# Per web (Chrome)
flutter run -d chrome

# Per Android
flutter run -d android

# Per iOS
flutter run -d ios
```

### Build per Produzione

```bash
# Build Web
flutter build web

# Build Android APK
flutter build apk --release

# Build Android App Bundle
flutter build appbundle --release

# Build iOS
flutter build ios --release
```

## 👤 Credenziali Demo

Per testare l'applicazione usa:

**Admin:**
- Email: `admin@iris.com`
- Password: `admin@iris.com`

## 📱 Funzionalità per Ruolo

### Admin
- ✅ Dashboard amministrativa completa
- ✅ Gestione utenti (CRUD)
- ✅ Gestione progetti (CRUD)
- ✅ Visualizzazione statistiche globali
- ✅ Consuntivazione personale
- ✅ Calendario personale

### Manager / Team Lead
- ✅ Dashboard team
- ✅ Gestione progetti (CRUD)
- ✅ Monitoraggio consuntivi del team
- ✅ Consuntivazione personale
- ✅ Calendario personale

### Employee
- ✅ Consuntivazione ore
- ✅ Calendario personale
- ✅ Visualizzazione progetti assegnati
- ✅ Profilo personale

## 🏗️ Struttura del Progetto

```
lib/
├── main.dart                 # Entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── project_model.dart
│   └── timesheet_entry.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── data_service.dart
│   └── notification_service.dart
├── screens/                  # UI Screens
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── admin_dashboard_screen.dart
│   ├── timesheet_screen.dart
│   ├── calendar_screen.dart
│   ├── manage_users_screen.dart
│   ├── manage_projects_screen.dart
│   └── profile_screen.dart
├── widgets/                  # Reusable widgets
│   ├── gradient_button.dart
│   ├── project_card.dart
│   └── stat_card.dart
└── theme/                    # App theme
    └── app_theme.dart
```

## 🛠️ Tecnologie Utilizzate

### Framework & Linguaggio
- **Flutter 3.9+**: Framework UI cross-platform
- **Dart**: Linguaggio di programmazione

### State Management
- **Provider**: Gestione dello stato reattivo

### Storage
- **SharedPreferences**: Persistenza dati locale
- **Firebase (struttura pronta)**: Cloud Firestore + regole/indici (con fallback locale)

### UI Components
- **Material Design 3**: Design system moderno
- **Table Calendar**: Widget calendario personalizzabile
- **FL Chart**: Grafici e visualizzazioni

### Notifiche
- **Flutter Local Notifications**: Notifiche push locali
- **Timezone**: Gestione fusi orari per scheduling

### Internazionalizzazione
- **Intl**: Formattazione date in italiano

## 🎯 Regole di Business

### Consuntivazione
1. **Incrementi**: Le ore devono essere in multipli di 0.5h
2. **Minimo**: 0.5h per progetto
3. **Massimo per progetto**: 8h
4. **Massimo giornaliero**: 8h totali
5. **Validazione**: Controllo automatico prima del salvataggio

### Notifiche
- Inviate alle **18:00** ogni giorno lavorativo
- Esclusi: sabato, domenica, festività italiane
- Calendario festività: Capodanno, Epifania, 25 Aprile, 1° Maggio, 2 Giugno, Ferragosto, Ognissanti, Immacolata, Natale, Santo Stefano

## 🔐 Sicurezza

⚠️ **Nota**: Questa è una versione demo/prototipo:
- L'autenticazione è semplificata (password = email)
- I dati sono salvati localmente (SharedPreferences)
- Non c'è crittografia dei dati
- **Per produzione**: Implementare backend, database reale, OAuth, JWT, HTTPS

## 📝 TODO per Produzione

- [ ] Backend API (Node.js/Django/Laravel)
- [ ] Database (PostgreSQL/MySQL/MongoDB)
- [ ] Autenticazione sicura (JWT, OAuth2)
- [ ] Cloud storage
- [x] Struttura Firebase base (collections, sync service, rules, indexes)
- [ ] Setup FirebaseAuth completo (login reale)
- [ ] Export dati (PDF, Excel)
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Offline mode con sync
- [ ] Analytics e reporting avanzati

## 🤝 Contributi

Questo è un progetto dimostrativo. Per domande o suggerimenti, contatta il team di sviluppo.

## 📄 Licenza

Proprietario - IRIS © 2025

---

**Versione**: 1.0.0  
**Ultima modifica**: Dicembre 2025  
**Sviluppato con** ❤️ **in Flutter**

## 🔥 Setup Firebase
Guida rapida disponibile in [FIREBASE_SETUP.md](FIREBASE_SETUP.md).
