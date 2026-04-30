# SkillPath - Dokumentacija sistema preporuka

## Uvod

SkillPath koristi **User-based Collaborative Filtering** pristup za personalizovano predlaganje kurseva korisnicima. Ovaj algoritam analizira obrasce ponasanja korisnika — koje kurseve su pregledali, rezervisali, kako su ih ocijenili i koje kategorije preferiraju — te identifikuje druge korisnike sa slicnim interesovanjima.

## Prikupljanje podataka

Sistem prikuplja sljedece signale koji se stvarno upisuju u bazu podataka:

| Signal | Tabela | Tezina | Opis |
|--------|--------|--------|------|
| Pregled kursa | UserCourseView | +1 (max 3) | Svaki put kada korisnik otvori detalje kursa |
| Dodavanje u favorite | UserFavorite | +2 | Korisnik sacuva kurs na listu favorita |
| Rezervacija | Reservation (Active/Completed) | +5 | Korisnik aktivno pohadja ili je zavrsio kurs |
| Recenzija | Review | +ocjena (1-5) | Korisnik ostavi ocjenu za kurs |

Maksimalna vrijednost interakcije po kursu: 3 + 2 + 5 + 5 = 15

## Algoritam

### Korak 1: Kreiranje vektora interakcija

Za svakog korisnika se kreira vektor koji mapira kurseve na numericki skor:

```
vektor(korisnik) = {
    kurs_A: min(broj_pregleda, 3) * 1 + je_favorit * 2 + ima_rezervaciju * 5 + ocjena,
    kurs_B: ...,
    ...
}
```

### Korak 2: Pronalazenje slicnih korisnika

Za ciljnog korisnika se racuna **kosinusna slicnost** sa svim ostalim korisnicima koji imaju barem 2 interakcije:

```
slicnost(A, B) = (A · B) / (||A|| * ||B||)
```

Biramo top-10 najslicnijih korisnika (susjeda).

### Korak 3: Bodovanje kandidatskih kurseva

Za svaki kurs koji ciljni korisnik NIJE pregledao/rezervisao, racunamo ponderisani skor:

```
skor(korisnik, kurs) = SUM(slicnost(korisnik, susjed_i) * skor_susjeda_i(kurs)) / SUM(|slicnost|)
```

### Korak 4: Generisanje objasnjenja

Za svaki preporuceni kurs generisemo objasnjenje koje pokazuje ZASTO je kurs preporucen:

- "Slicni korisnici sa istim interesima su upisali ovaj kurs"
- "Popularno medju studentima koji dijele vase interesovanje za [kategorija]"

### Korak 5: Fallback za nove korisnike (Cold Start)

Ako korisnik ima manje od 2 interakcije, sistem koristi **popularity-based** pristup:
- Kursevi se rangiraju po broju rezervacija + broju recenzija + prosjecnoj ocjeni
- Filtriraju se po kategorijama koje je korisnik pregledao

## Implementacija

### Backend
- **RecommenderService.cs** — Implementacija algoritma
- **RecommenderController.cs** — API endpointi
- **UserCourseView** tabela — Pracenje pregleda kurseva

### Frontend (Mobile)
- Preporuceni kursevi se prikazuju na pocetnom ekranu u sekciji "Personalizirane Preporuke"
- Svaka preporuka sadrzi objasnjenje ispod naziva kursa
- Pregled kursa automatski poziva `POST /api/Recommender/track-view`

### API Endpointi
- `GET /api/Recommender` — Vraca listu preporucenih kurseva sa skorovima i objasnjenjima
- `POST /api/Recommender/track-view` — Biljezi pregled kursa (poziva se iz mobilne aplikacije)

## Evaluacija

Sistem se kontinuirano poboljsava sa vise korisnickih interakcija. Kvalitet preporuka raste proporcionalno s brojem korisnika i njihovih aktivnosti na platformi.
