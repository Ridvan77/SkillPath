# SkillPath

Platforma za pregled, rezervaciju i pohadjanje kurseva i radionica iz razlicitih oblasti, poput stranih jezika, programiranja, grafickog dizajna i drugih vjestina.

## Tehnologije

| Komponenta | Tehnologija |
|------------|------------|
| Backend API | ASP.NET Core 8.0 Web API (C#) |
| Baza podataka | SQL Server (Azure SQL Edge via Docker) |
| Desktop aplikacija | Flutter (Windows/macOS) |
| Mobilna aplikacija | Flutter (Android) |
| Message Broker | RabbitMQ |
| Email Worker | .NET 8.0 Worker Service + MailKit |
| Push notifikacije | Firebase Cloud Messaging (FCM) |
| Placanje | Stripe (sandbox) |
| Autentifikacija | JWT Bearer |
| Recommender sistem | User-based Collaborative Filtering |

## Preduvjeti

Prije pokretanja aplikacije potrebno je instalirati sljedece alate:

1. **Docker Desktop** — [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)
2. **.NET 8.0 SDK** — [https://dotnet.microsoft.com/download/dotnet/8.0](https://dotnet.microsoft.com/download/dotnet/8.0)
3. **Flutter SDK** (najnovija verzija) — [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
4. **Android Studio** (za Android emulator) — [https://developer.android.com/studio](https://developer.android.com/studio)

### Provjera instalacije

```bash
docker --version
dotnet --version
flutter --version
```

## Firebase konfiguracija (FCM)

Aplikacija koristi Firebase Cloud Messaging za push notifikacije. Potrebno je podesiti sljedece:

1. Kreirajte Firebase projekt na [https://console.firebase.google.com](https://console.firebase.google.com)
2. Dodajte Android aplikaciju sa package name: `com.example.skillpath_mobile`
3. Preuzmite `google-services.json` i postavite u `UI/skillpath_mobile/android/app/`
4. U Firebase Console > Project Settings > Service Accounts, generisite privatni kljuc
5. Sacuvajte kao `firebase-service-account.json` u `SkillPath.WebAPI/`
6. Omogucite Cloud Messaging (V1) u Firebase Console > Project Settings > Cloud Messaging

**Napomena:** Bez Firebase konfiguracije aplikacija ce raditi, ali push notifikacije nece biti dostupne.

## Pokretanje aplikacije

### Korak 1: Kloniranje repozitorija

```bash
git clone https://github.com/Ridvan77/SkillPath.git
cd SkillPath
```

### Korak 2: Konfiguracija (.env)

U root folderu projekta se nalazi `.env` datoteka sa konfiguracijskim podacima. Prije pokretanja, provjerite i po potrebi azurirajte sljedece vrijednosti:

```env
# Baza podataka
SQL_SA_PASSWORD=SkillPathPassword2024!

# JWT
JWT_SECRET_KEY=YourSuperSecretKeyThatIsAtLeast32CharactersLongForHS256Algorithm!
JWT_EXPIRY_MINUTES=60

# RabbitMQ
RABBITMQ_USERNAME=guest
RABBITMQ_PASSWORD=guest

# Stripe (Test Keys - zamijenite sa vasim)
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...

# Email (Gmail App Password - zamijenite sa vasim)
EMAIL_FROM_EMAIL=vas@gmail.com
EMAIL_SMTP_HOST=smtp.gmail.com
EMAIL_SMTP_PORT=587
EMAIL_SMTP_USERNAME=vas@gmail.com
EMAIL_SMTP_PASSWORD=vasa_app_lozinka
```

**Napomena za Gmail:** Potrebno je kreirati App Password na [https://myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords). Obicna lozinka nece raditi.

**Napomena za Stripe:** Registrujte se na [https://dashboard.stripe.com/register](https://dashboard.stripe.com/register) i kopirajte test kljuceve iz Dashboard > Developers > API Keys. Takodje azurirajte Stripe kljuceve u `UI/skillpath_mobile/assets/.env`.

### Korak 3: Pokretanje backend servisa (Docker)

```bash
docker-compose up --build
```

Ovo pokrece 4 servisa:

| Servis | Port | Opis |
|--------|------|------|
| **SQL Server** | 1433 | Azure SQL Edge baza podataka (IB210224) |
| **SkillPath API** | 8080 | ASP.NET Core Web API sa Swagger UI |
| **RabbitMQ** | 5672, 15672 | Message broker (AMQP + Management UI) |
| **Email Worker** | - | Pozadinski servis za slanje emailova |

Sacekajte da se svi servisi pokrenu (cca 30-60 sekundi). API automatski:
- Kreira bazu podataka i tabele
- Seed-uje referentne podatke (drzave, gradove, kategorije)
- Kreira test korisnike i primjere podataka (kursevi, rezervacije, recenzije)
- Inicijalizira Firebase Admin SDK (ako je `firebase-service-account.json` prisutan)
- Pokrece pozadinski servis za zakazane notifikacije

### Korak 4: Provjera API-ja

Otvorite Swagger UI u pregledniku: **http://localhost:8080/swagger**

Testirajte login:
1. Pronadjite `POST /api/Auth/login`
2. Unesite: `{ "email": "admin@skillpath.ba", "password": "test" }`
3. Kopirajte `accessToken` iz odgovora
4. Kliknite "Authorize" dugme na vrhu i unesite: `Bearer {token}`

### Korak 5: Pokretanje mobilne aplikacije (Android)

```bash
cd UI/skillpath_mobile
flutter clean
flutter pub get
flutter run -d emulator-5554
```

**Napomena:** Android emulator koristi `10.0.2.2` kao adresu host masine. API base URL je automatski konfigurisan u `api_client.dart`.

Za fizicki Android uredaj, potrebno je zamijeniti API adresu sa IP adresom vaseg racunara:
```bash
flutter run --dart-define=API_BASE_URL=http://VASA_IP:8080
```

### Korak 6: Pokretanje desktop aplikacije

```bash
cd UI/skillpath_desktop
flutter clean
flutter pub get
flutter run -d macos    # za macOS
flutter run -d windows  # za Windows
```

Desktop aplikacija automatski koristi `http://localhost:8080` kao API adresu.

## Korisnicki podaci za pristup

| Kontekst | Email | Lozinka |
|----------|-------|---------|
| Desktop verzija (Admin) | admin@skillpath.ba | test |
| Mobilna verzija (Student) | student@skillpath.ba | test |
| Instructor | instructor@skillpath.ba | test |

Dodatni test studenti: `student3@skillpath.ba` do `student11@skillpath.ba` (lozinka: `test`)

## Struktura projekta

```
SkillPath/
├── SkillPath.sln                 # Visual Studio Solution
├── SkillPath.Model/              # Entiteti, DbContext, Enumi
├── SkillPath.Services/           # Poslovna logika, DTO-ovi, Interfejsi, Izuzeci
├── SkillPath.WebAPI/             # Kontroleri, Middleware, Konfiguracija, Seed
│   └── firebase-service-account.json  # Firebase Admin SDK kljuc (nije u Git-u)
├── SkillPath.Worker/             # RabbitMQ email worker servis
├── UI/
│   ├── skillpath_shared/         # Dijeljeni Flutter paket (modeli, provideri, API klijent)
│   ├── skillpath_mobile/         # Flutter mobilna aplikacija (Student + Instructor)
│   │   └── android/app/google-services.json  # Firebase Android konfig (nije u Git-u)
│   └── skillpath_desktop/        # Flutter desktop aplikacija (Admin panel)
├── Dockerfile                    # Docker konfiguracija za API
├── docker-compose.yml            # Orkestracija svih servisa
├── .env                          # Konfiguracijski podaci (tajne)
├── recommender-dokumentacija.md  # Dokumentacija recommender sistema
└── README.md
```

## Arhitektura

### Mikroservisna arhitektura

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Flutter    │     │   Flutter    │     │   Flutter    │
│   Mobile     │     │   Desktop    │     │   Shared     │
│  (Student/   │     │   (Admin)    │     │  (Modeli,    │
│  Instructor) │     │              │     │  Provideri)  │
└──────┬───────┘     └──────┬───────┘     └─────────────┘
       │                    │
       └────────┬───────────┘
                │ HTTP/REST (JWT)
                ▼
       ┌────────────────┐
       │  SkillPath API │ Port 8080
       │  (ASP.NET Core)│
       └───┬────┬───┬───┘
           │    │   │
     ┌─────▼──┐ │ ┌─▼─────────┐
     │SQL     │ │ │ RabbitMQ   │
     │Server  │ │ │ (Broker)   │
     │Port    │ │ │ Port 5672  │
     │1433    │ │ └──┬─────────┘
     └────────┘ │    │
           ┌────▼──┐ ┌──▼────────┐
           │Firebase│ │  Email    │
           │  FCM   │ │  Worker   │
           │(Push)  │ │ (MailKit) │
           └────────┘ └───────────┘
```

### API servisi

Svi servisi su registrovani kao **Scoped** (osim RabbitMQ publishera koji je Singleton). Kontroleri ne sadrze poslovnu logiku — koriste servisni sloj (Controller → Service → DbContext).

## Baza podataka

**Naziv baze:** `IB210224`

### Glavne tabele (14)

| # | Tabela | Opis |
|---|--------|------|
| 1 | ApplicationUser | Korisnici (ASP.NET Identity) |
| 2 | Course | Kursevi |
| 3 | CourseSchedule | Termini/rasporedi kurseva |
| 4 | Reservation | Rezervacije studenata |
| 5 | Payment | Stripe placanja |
| 6 | Review | Recenzije i ocjene kurseva |
| 7 | ReviewHelpfulVote | Glasovi za korisne recenzije |
| 8 | Notification | Obavijesti korisnicima |
| 9 | UserFavorite | Omiljeni kursevi korisnika |
| 10 | UserCourseView | Pregledi kurseva (za recommender) |
| 11 | ReservationStatusHistory | Audit trag promjena statusa |
| 12 | FcmToken | FCM tokeni uredjaja korisnika |
| 13 | BroadcastNotification | Admin notifikacije (zakazane/poslane) |
| 14 | News | Novosti/obavijesti platforme |

### Referentne tabele (3+)

| Tabela | Opis |
|--------|------|
| Category | Kategorije kurseva (Programiranje, Dizajn, Biznis, Jezici, Muzika, Fitness) |
| City | Gradovi (Mostar, Sarajevo, Tuzla, Zenica, Banja Luka, ...) |
| Country | Drzave (BiH, Hrvatska, Srbija) |
| AspNetRoles | Uloge (Admin, Instructor, Student) |
| AspNetUserRoles | Veza korisnik-uloga |

## API Endpointi

| Controller | Ruta | Opis |
|-----------|------|------|
| AuthController | `/api/Auth` | Registracija, login, profil, promjena lozinke |
| CourseController | `/api/Course` | CRUD kurseva, pretraga, filtriranje, upload slika |
| CourseScheduleController | `/api/course-schedules` | Upravljanje terminima |
| ReservationController | `/api/Reservation` | Kreiranje, potvrda, otkazivanje rezervacija |
| PaymentController | `/api/Payment` | Stripe PaymentIntent kreiranje |
| ReviewController | `/api/Review` | Recenzije, ocjene, korisni glasovi, vidljivost |
| NotificationController | `/api/Notification` | Obavijesti, FCM registracija, zakazivanje, admin pregled |
| FavoriteController | `/api/Favorite` | Omiljeni kursevi |
| RecommenderController | `/api/Recommender` | Personalizirane preporuke |
| CategoryController | `/api/Category` | Kategorije kurseva |
| CityController | `/api/City` | Gradovi |
| CountryController | `/api/Country` | Drzave |
| UserController | `/api/User` | Upravljanje korisnicima i predavacima (admin) |
| ReportController | `/api/Report` | Izvjestaji o predavacima i kategorijama (admin) |
| DashboardController | `/api/Dashboard` | Statistike (admin) |

## Funkcionalnosti

### Mobilna aplikacija (Student)
- Pregled i pretraga kurseva sa filterima (kategorija, cijena, nivo, predavac)
- Detaljan prikaz kursa sa recenzijama i terminima
- Trokoracna rezervacija: licni podaci → Stripe placanje → potvrda
- Pregled rezervacija (Aktivne/Zavrsene/Otkazane) sa otkazivanjem
- Personalizirane preporuke (User-based Collaborative Filtering)
- Recenzije sa zvjezdicama i "korisno" glasovima
- Push notifikacije u realnom vremenu (Firebase Cloud Messaging)
- Obavijesti sa detaljnim prikazom
- Omiljeni kursevi
- Profil sa uredivanjem i promjenom lozinke

### Mobilna aplikacija (Instructor)
- Dashboard sa statistikama (kursevi, studenti, ocjena)
- Pregled i uredivanje vlastitih kurseva
- Raspored sa brojem upisanih studenata
- Pregled recenzija na svoje kurseve
- Push notifikacije u realnom vremenu
- Profil

### Desktop aplikacija (Admin)
- Dashboard sa preglednim statistikama i nedavnim rezervacijama
- Upravljanje kursevima (CRUD, upload slika, rasporedi)
- Upravljanje korisnicima (pregled, uredivanje, soft/hard brisanje)
- Upravljanje predavacima (pregled, statistike kurseva, ocjene)
- Upravljanje rezervacijama (potvrda, otkazivanje, filtriranje)
- Moderacija recenzija (sakrivanje/prikazivanje, brisanje)
- Upravljanje notifikacijama (kreiranje, zakazivanje, FCM push)
- Generisanje izvjestaja sa PDF exportom (predavaci, kategorije)
- Upravljanje kategorijama

### Push notifikacije (Firebase Cloud Messaging)
- Slanje push notifikacija korisnicima i predavacima u realnom vremenu
- Zakazivanje notifikacija za odredjeni datum i vrijeme
- Grupno slanje (svi korisnici, samo studenti, samo predavaci)
- Automatsko registrovanje FCM tokena pri prijavi na mobilnu aplikaciju
- Pozadinski servis za slanje zakazanih notifikacija

### Email obavijesti (via RabbitMQ → Worker → Gmail SMTP)
- Registracija korisnika (dobrodoslica)
- Kreiranje rezervacije (potvrda sa detaljima)
- Potvrda placanja
- Otkazivanje rezervacije (sa informacijom o refundaciji)
- Promjena lozinke (sigurnosna obavijest)
- Admin broadcast obavijesti

### Recommender sistem
- User-based Collaborative Filtering algoritam
- Signali: pregledi kurseva, favoriti, rezervacije, recenzije
- Kosinusna slicnost za pronalazenje slicnih korisnika
- Objasnjive preporuke ("Slicni korisnici sa istim interesima su upisali ovaj kurs")
- Popularity-based fallback za nove korisnike
- Dokumentacija: `recommender-dokumentacija.md`

## Stripe placanje (Sandbox)

Placanje koristi Stripe sandbox okruzenje. Za testiranje koristite:

| Polje | Vrijednost |
|-------|-----------|
| Broj kartice | 4242 4242 4242 4242 |
| Datum isteka | Bilo koji buduci datum |
| CVC | Bilo koja 3 cifre |
| ZIP | Bilo kojih 5 cifara |

## RabbitMQ Management

- **URL:** http://localhost:15672
- **Username:** guest
- **Password:** guest

## Cesti problemi

### Port 5000/7000 zauzet na macOS-u
macOS Control Center koristi portove 5000 i 7000. API koristi port **8080**.

### Docker Desktop ne startuje (macOS Apple Silicon)
Kliknite "Disable Rosetta" ako se pojavi greska sa Rosetta instalacijom.

### Flutter `flutter_secure_storage` greska na macOS-u
Aplikacija koristi `shared_preferences` umjesto `flutter_secure_storage` za kompatibilnost sa macOS sandbox-om.

### Android emulator ne moze pristupiti API-ju
Android emulator koristi `10.0.2.2` umjesto `localhost`. Ovo je automatski konfigurisano u `api_client.dart`.

### Gmail SMTP greska "Authentication Required"
Provjerite da koristite Gmail App Password (16 karaktera, format: `xxxx xxxx xxxx xxxx`), ne obicnu lozinku.

### Push notifikacije ne rade
Provjerite da su `google-services.json` i `firebase-service-account.json` pravilno postavljeni. Firebase Cloud Messaging (V1) mora biti omogucen u Firebase Console.
