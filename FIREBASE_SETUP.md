# Firebase Setup (IRIS)

Questa app ora supporta una struttura Firebase con fallback locale automatico.

## 1) Configura progetto Firebase
1. Crea progetto su Firebase Console.
2. Abilita `Authentication` (Email/Password).
3. Abilita `Cloud Firestore` in modalità production.
4. Registra app Android/iOS/Web.

## 2) Genera opzioni FlutterFire
Esegui da root progetto:

```bash
flutterfire configure
```

Questo genera/aggiorna `lib/firebase/firebase_options.dart`.

## 3) Deploy regole e indici
Da root progetto:

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

File usati:
- `firebase/firestore.rules`
- `firebase/firestore.indexes.json`

## 4) Struttura collezioni
- `users/{userId}`
  - id, email, name, surname, role, developerType, managerId, teamLeadId, isActive, createdAt
- `projects/{projectId}`
  - id, name, description, color, ownerUserId, isActive, createdAt, assignedUserIds
- `timesheet_entries/{entryId}`
  - id, userId, projectId, date, hours, notes, createdAt, updatedAt

## 5) Ruoli e permessi previsti
- `admin`: pieno controllo
- `manager`: gestione progetti + visibilità team
- `teamLead`: gestione progetti + visibilità team
- `employee`: solo consuntivazione personale

### Gerarchia team
- Admin assegna:
  - `managerId` sui documenti `teamLead`
  - `teamLeadId` sui documenti `employee`
- Manager vede i TL con `managerId = managerUid` e i developer dei TL seguiti.
- Team Lead vede i developer con `teamLeadId = teamLeadUid`.

### Ownership progetti
- I progetti creati da TL hanno `ownerUserId = tlUid`.
- In app, il TL vede solo progetti con `ownerUserId` uguale al suo uid.

## 6) Fallback locale
Se Firebase non è configurato o fallisce:
- l'app usa SharedPreferences come prima,
- i servizi continuano a funzionare senza blocchi.

## 7) Auth reale
- Login/registrazione usano FirebaseAuth (Email/Password).
- Sessione persistente: l’utente resta loggato dopo chiusura e riapertura app.
- Al primo login viene creato/aggiornato il profilo in `users/{uid}`.
