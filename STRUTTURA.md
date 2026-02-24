# 🗂️ Struttura Completa del Progetto

```
consuntivazione_iris/
│
├── 📄 README.md                          # Documentazione principale
├── 📄 GUIDA_UTENTE.md                    # Guida per utenti finali
├── 📄 COMANDI.md                         # Comandi e istruzioni sviluppo
├── 📄 pubspec.yaml                       # Dipendenze Flutter
├── 📄 analysis_options.yaml              # Configurazione linter
│
├── 📁 lib/                               # Codice sorgente principale
│   ├── 📄 main.dart                      # Entry point applicazione
│   │
│   ├── 📁 models/                        # Modelli dati
│   │   ├── user_model.dart               # Modello utente (User, UserRole, DeveloperType)
│   │   ├── user_model.g.dart             # Codice generato JSON
│   │   ├── project_model.dart            # Modello progetto
│   │   ├── project_model.g.dart          # Codice generato JSON
│   │   ├── timesheet_entry.dart          # Modello consuntivazione
│   │   └── timesheet_entry.g.dart        # Codice generato JSON
│   │
│   ├── 📁 services/                      # Logica di business
│   │   ├── auth_service.dart             # Autenticazione e gestione sessione
│   │   ├── data_service.dart             # CRUD dati (utenti, progetti, timesheet)
│   │   └── notification_service.dart     # Gestione notifiche push
│   │
│   ├── 📁 screens/                       # Schermate UI
│   │   ├── login_screen.dart             # Schermata login
│   │   ├── register_screen.dart          # Schermata registrazione
│   │   ├── home_screen.dart              # Container principale con navigation
│   │   ├── admin_dashboard_screen.dart   # Dashboard amministratore
│   │   ├── manage_users_screen.dart      # Gestione utenti (admin)
│   │   ├── manage_projects_screen.dart   # Gestione progetti (admin)
│   │   ├── timesheet_screen.dart         # Consuntivazione ore
│   │   ├── calendar_screen.dart          # Calendario recap mensile
│   │   └── profile_screen.dart           # Profilo utente
│   │
│   ├── 📁 widgets/                       # Widget riutilizzabili
│   │   ├── gradient_button.dart          # Bottone con gradiente
│   │   ├── project_card.dart             # Card progetto
│   │   └── stat_card.dart                # Card statistica
│   │
│   └── 📁 theme/                         # Tema e stili
│       └── app_theme.dart                # Colori, font, stili globali
│
├── 📁 android/                           # Configurazione Android
│   ├── app/
│   │   ├── build.gradle.kts              # Build config (minSdk: 21)
│   │   └── src/main/
│   │       └── AndroidManifest.xml       # Permessi notifiche
│   ├── build.gradle.kts
│   └── gradle/
│
├── 📁 ios/                               # Configurazione iOS
│   ├── Runner/
│   │   └── Info.plist                    # Permessi e configurazioni
│   └── Runner.xcodeproj/
│
├── 📁 web/                               # Configurazione Web
│   ├── index.html                        # HTML principale con splash
│   ├── manifest.json                     # PWA manifest
│   └── icons/                            # Icone PWA
│
├── 📁 linux/                             # Configurazione Linux
├── 📁 macos/                             # Configurazione macOS
├── 📁 windows/                           # Configurazione Windows
│
└── 📁 assets/                            # Risorse statiche
    ├── images/                           # Immagini
    └── icons/                            # Icone custom
```

---

## 📋 Dettaglio File Principali

### 🎯 Core Files

#### `lib/main.dart`
- Inizializzazione app
- Setup providers (AuthService, DataService)
- Configurazione theme
- Splash screen con animazione
- Routing iniziale (Login vs Home)

#### `lib/models/`
**user_model.dart**
- Enum: UserRole (admin, employee)
- Enum: DeveloperType (android, ios, fullStack, backend, frontend, designer, qa)
- Class: User con tutti i campi necessari
- Serializzazione JSON

**project_model.dart**
- Class: Project (nome, descrizione, colore, stato)
- Lista utenti assegnati
- Serializzazione JSON

**timesheet_entry.dart**
- Class: TimesheetEntry
- Validazione ore (0.5 - 8.0, incrementi 0.5)
- Timestamp creazione/modifica
- Serializzazione JSON

---

### 🔧 Services

#### `auth_service.dart`
**Funzionalità:**
- Login con email/password
- Registrazione nuovi utenti
- Gestione sessione corrente
- Logout
- Creazione admin di default
- Persistenza con SharedPreferences

**Metodi principali:**
```dart
Future<void> initialize()
Future<bool> login(String email, String password)
Future<bool> register({...})
Future<void> logout()
User? get currentUser
bool get isAdmin
```

#### `data_service.dart`
**Funzionalità:**
- CRUD completo per Users
- CRUD completo per Projects
- CRUD completo per TimesheetEntries
- Validazione ore giornaliere (max 8h)
- Query per data/utente
- Calcolo statistiche
- Persistenza con SharedPreferences

**Metodi principali:**
```dart
Future<void> initialize()
Future<bool> addTimesheetEntry(TimesheetEntry)
double getDailyHours(String userId, DateTime date)
List<TimesheetEntry> getEntriesForUser(...)
Project? getProjectById(String id)
```

#### `notification_service.dart`
**Funzionalità:**
- Setup notifiche locali
- Scheduling giornaliero alle 18:00
- Esclusione weekend e festività italiane
- Gestione timezone (Europe/Rome)

**Festività gestite:**
- Capodanno, Epifania, 25 Aprile, 1° Maggio
- 2 Giugno, Ferragosto, Ognissanti
- Immacolata, Natale, Santo Stefano

---

### 🎨 Screens

#### Admin Screens
1. **admin_dashboard_screen.dart**
   - Statistiche globali (utenti, progetti, ore)
   - Azioni rapide (gestione utenti/progetti)
   - Lista progetti recenti

2. **manage_users_screen.dart**
   - Lista dipendenti
   - Aggiungi nuovo utente
   - Elimina utente
   - Card con avatar e info

3. **manage_projects_screen.dart**
   - Lista progetti
   - Crea/Modifica progetto
   - Selettore colore visuale
   - Elimina progetto

#### User Screens
4. **timesheet_screen.dart**
   - Selettore data con frecce
   - Progress bar ore giornaliere
   - Lista consuntivazioni del giorno
   - Dialog aggiungi/modifica con validazione
   - Popup errore se superi 8h

5. **calendar_screen.dart**
   - Stats mensili (ore, giorni, media)
   - Calendario interattivo (table_calendar)
   - Indicatori ore per giorno (colorati)
   - Breakdown ore per progetto
   - Dettaglio giorno selezionato

6. **profile_screen.dart**
   - Info utente (nome, email, tipo)
   - Attiva notifiche
   - Info app
   - Logout

#### Auth Screens
7. **login_screen.dart**
   - Form email/password
   - Validazione campi
   - Link registrazione
   - Hint credenziali demo

8. **register_screen.dart**
   - Form completo (nome, cognome, email, tipo, password)
   - Dropdown tipo developer
   - Validazione password match
   - Conferma registrazione

---

### 🎨 Theme & Widgets

#### `theme/app_theme.dart`
**Colori:**
- Primary: #6C63FF (viola)
- Secondary: #4ECDC4 (turchese)
- Accent: #FF6B6B (rosso)
- Success: #2ECC71 (verde)
- Warning: #F39C12 (arancione)
- Error: #E74C3C (rosso scuro)

**Components:**
- AppBar trasparente
- Card con bordi arrotondati (16px)
- Input fields con riempimento
- Bottoni arrotondati
- Text styles (heading1, heading2, heading3, body, caption)

#### `widgets/`
- **gradient_button.dart**: Bottone con gradiente e loading state
- **project_card.dart**: Card progetto con colore laterale
- **stat_card.dart**: Card statistica con icona e numero grande

---

## 🔄 Flusso Dati

### Autenticazione
```
Login Screen
    ↓
AuthService.login()
    ↓
SharedPreferences (salva user)
    ↓
Home Screen (con NavigationBar)
```

### Consuntivazione
```
TimeSheet Screen
    ↓
Dialog Aggiungi Ore
    ↓
DataService.addTimesheetEntry()
    ↓
Validazione (max 8h/giorno)
    ↓
Se OK: Salva in SharedPreferences
Se KO: Mostra popup errore
    ↓
Aggiorna UI (Provider.notifyListeners)
```

### Gestione Admin
```
Admin Dashboard
    ↓
Manage Users/Projects
    ↓
DataService.add/update/delete()
    ↓
SharedPreferences
    ↓
Aggiorna UI
```

---

## 💾 Persistenza Dati

### SharedPreferences Keys
- `current_user`: Utente loggato (JSON)
- `users`: Lista tutti gli utenti (JSON array)
- `projects`: Lista progetti (JSON array)
- `timesheet_entries`: Lista consuntivazioni (JSON array)

### Formato Dati
Tutti gli oggetti sono serializzati in JSON usando `json_serializable`.

---

## 🎯 Validazioni Implementate

### Consuntivazione
✅ Ore in multipli di 0.5  
✅ Min 0.5h per entry  
✅ Max 8h per progetto singolo  
✅ Max 8h totali al giorno  
✅ Progetto obbligatorio  
✅ Data valida  

### Utenti
✅ Email formato valido  
✅ Nome e cognome obbligatori  
✅ Password min 6 caratteri  
✅ Tipo developer obbligatorio  
✅ Email univoca  

### Progetti
✅ Nome obbligatorio  
✅ Descrizione obbligatoria  
✅ Colore selezionato  

---

## 🚀 Funzionalità Avanzate

### State Management
- Provider per reattività
- ChangeNotifier per services
- context.watch per UI updates
- context.read per azioni

### Navigation
- MaterialPageRoute per transizioni
- pushReplacement per login/logout
- Navigator.pop per dialog e back

### UI/UX
- Splash screen animato
- Loading states
- Error handling
- Success feedback
- Confirm dialogs
- Progress indicators
- Color-coded stats

---

**Versione**: 1.0.0  
**File totali**: ~40 file  
**Linee di codice**: ~3000+ LOC  
**Piattaforme**: Android, iOS, Web, Windows, Linux, macOS
