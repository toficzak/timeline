---
project: timelines
version: 1
status: draft
created: 2026-09-21
updated: 2026-10-07
prd_version: 1
main_goal: speed
top_blocker: decisions
milestone_id: first-usable-timeline
milestone_seq: 1
milestone_status: open
---

# Roadmap: timelines

> Derived from `context/foundation/prd.md` + auto-researched and user-confirmed codebase baseline.
> Edit-in-place; archive when superseded.
> Slices below are listed in dependency order. The "At a glance" table is the index.

## Milestone

**M-01: Pierwsza użyteczna oś czasu** — Status: open

- **Intent:** Dostarczyć działający, prywatny przepływ od logowania przez Google do oglądania osi czasu i jej wpisów na Androidzie. Kamień milowy ma potwierdzić podstawową wartość produktu bez rozszerzania zakresu o funkcje poza główną ścieżką.
- **Source materials:** `context/foundation/prd.md` (v1)
- **Done when:** every F-NN and S-NN below is `done`.
- **Scope anchors:** FR-001–FR-006, US-01

## Vision recap

Użytkownik chce zauważać zmiany zachodzące w życiu, ale rozproszone zdjęcia i opisy utrudniają dostrzeżenie postępu. Aplikacja porządkuje je w kategorie osi czasu, do których można wrócić i porównać kolejne etapy.

## North star

**S-02: Użytkownik otwiera swoją oś i widzi czytelne wpisy oraz przycisk dodania** — to najmniejszy kompletny przepływ, który udowadnia podstawową hipotezę produktu, dlatego umieszczamy go tak wcześnie, jak pozwalają zależności.

## At a glance

| ID   | Change ID                    | Outcome (user can …)                                      | Prerequisites | PRD refs                         | Status   |
| ---- | ---------------------------- | --------------------------------------------------------- | ------------- | -------------------------------- | -------- |
| F-01 | google-access-foundation     | (foundation) użytkownik może rozpocząć prywatną sesję Google | —             | FR-001, Access Control           | done         |
| F-02 | local-timeline-data-contract | (foundation) aplikacja ma minimalny lokalny kontrakt osi i zdjęć | —             | FR-004, FR-006, NFR              | done         |
| F-03 | android-delivery-path        | (foundation) przepływ można zweryfikować jako aplikację Android | —             | FR-003, NFR, Success Criteria: Guardrails | blocked  |
| S-01 | signed-in-timeline-list      | zalogowany użytkownik może zobaczyć listę własnych osi czasu | F-01          | US-01, FR-001, FR-002             | in-progress |
| S-02 | open-readable-timeline       | użytkownik może wejść w oś, rozróżnić dni i zobaczyć wpisy oraz przycisk dodania | F-02, S-01    | FR-003, FR-004, FR-005             | in-progress |
| S-03 | local-entry-media-view       | użytkownik może zobaczyć lokalne zdjęcia i opisy wpisów | F-02, S-02    | FR-006                         | blocked  |
| S-04 | timeline-crud                | użytkownik może tworzyć, zmieniać nazwę i usuwać własne lokalne osie czasu | S-01, F-02 | MVP notes: CRUD osi czasu | in-progress |
| S-05 | create-timeline-entry        | użytkownik może dodać wpis z opcjonalnym zdjęciem i opisem do wybranej osi | F-02, S-02, S-03 | FR-006, MVP notes: entry creation | in-progress |

## Streams

Navigation aid — canonical ordering still lives in the dependency graph below.

| Stream | Theme                    | Chain                         | Note |
| ------ | ------------------------ | ----------------------------- | ---- |
| A      | Dostęp i lista osi       | `F-01` → `S-01`                | Najkrótsza ścieżka do szybkiej weryfikacji logowania i własności danych. |
| B      | Czytelny dziennik        | `F-02` → `S-02` → `S-03` → `S-05` | Dołącza do Stream A przy `S-02`; tworzenie wpisu domyka podstawowy zapis dziennika. |
| C      | Dostarczenie Androida    | `F-03`                        | Niezależna ścieżka weryfikacji wymagana przez środowisko docelowe. |

## Baseline

What's already in place in the codebase as of `2026-09-21` (auto-researched + user-confirmed).

- **Frontend:** partial — Flutter/Dart is selected; `lib/main.dart:1-16` is only a minimal Material scaffold.
- **Backend / API:** absent — no server, routes or request handlers.
- **Data:** absent — no driver, schema, migration or seeded data in `pubspec.yaml:9-16`.
- **Auth:** per `tech-stack.md` — Google authentication is selected, but not implemented in the scaffold.
- **Deploy / infra:** per `tech-stack.md` — Android/Google Play target and GitHub Actions are selected.
- **Observability:** absent — no application logging, error tracking or metrics in the scaffold.

## Foundations

### F-01: Minimalny dostęp Google

- **Outcome:** (foundation) aplikacja potrafi rozpocząć i zakończyć prywatną sesję użytkownika przez Google.
- **Change ID:** google-access-foundation
- **PRD refs:** FR-001, Access Control
- **Unlocks:** S-01; verification path for private-user access
- **Prerequisites:** —
- **Parallel with:** F-02, F-03
- **Blockers:** —
- **Unknowns:** —
- **Risk:** To pierwszy warunek całej ścieżki; odłożenie integracji dostawcy mogłoby ukryć problem dostępu do końca prac.
- **Status:** done

### F-02: Minimalny lokalny kontrakt osi i zdjęć

- **Outcome:** (foundation) aplikacja ma minimalny, lokalny sposób przechowywania osi, wpisów, opisów i odwołań do zdjęć potrzebny przez pierwszy przepływ.
- **Change ID:** local-timeline-data-contract
- **PRD refs:** FR-004, FR-006, Non-Goals (lokalne zdjęcia)
- **Unlocks:** S-02, S-03; verification path for readable local entries
- **Prerequisites:** —
- **Parallel with:** F-01, F-03
- **Blockers:** —
- **Unknowns:**
  - Jakie podejście do lokalnego przechowywania zdjęć i danych zostaje wybrane? — Owner: user. Block: yes.
- **Risk:** Zła decyzja o lokalnym przechowywaniu może wymusić przebudowę wpisów i zdjęć po rozpoczęciu widoku osi.
- **Status:** done

### F-03: Ścieżka dostarczenia Androida

- **Outcome:** (foundation) aplikacja ma minimalną ścieżkę budowania i ręcznej weryfikacji na docelowym Androidzie.
- **Change ID:** android-delivery-path
- **PRD refs:** FR-003, Non-Functional Requirements, Success Criteria: Guardrails
- **Unlocks:** S-02; named Android verification path
- **Prerequisites:** —
- **Parallel with:** F-01, F-02, S-01
- **Blockers:** —
- **Unknowns:**
  - Jakie są oczekiwania dotyczące dostarczenia i używania aplikacji Android? — Owner: user. Block: yes.
- **Risk:** Bez potwierdzonej ścieżki Androida działający przepływ może pozostać nieweryfikowalny w docelowym środowisku.
- **Status:** blocked

## Slices

### S-01: Lista własnych osi po logowaniu

- **Outcome:** użytkownik może zalogować się przez Google i zobaczyć listę własnych osi czasu.
- **Change ID:** signed-in-timeline-list
- **PRD refs:** US-01, FR-001, FR-002
- **Prerequisites:** F-01
- **Parallel with:** F-02, F-03
- **Blockers:** —
- **Unknowns:**
  - Czy lista osi ma używać wyłącznie danych lokalnych w pierwszym przepływie, czy wymagać synchronizacji? — Owner: user. Block: no.
- **Risk:** Ten wycinek sprawdza dostęp i granicę prywatności przed wejściem w bardziej szczegółowy widok.
- **Status:** in-progress

### S-02: Czytelny widok osi czasu

- **Outcome:** użytkownik może wejść w wybraną oś, rozróżnić wpisy z kolejnych dni, zobaczyć ich listę i przycisk dodania nowego wpisu.
- **Change ID:** open-readable-timeline
- **PRD refs:** FR-003, FR-004, FR-005, Success Criteria: Primary
- **Prerequisites:** F-02, F-03, S-01
- **Parallel with:** F-03
- **Blockers:** —
- **Unknowns:**
  - Która aktywność ma być pierwszym konkretnym scenariuszem poza ogólnym przepływem osi czasu? — Owner: user. Block: no.
  - Czy oczekiwania dostarczenia Androida pozwalają na obecny zakres lokalny? — Owner: user. Block: yes.
- **Risk:** To gwiazda przewodnia kamienia milowego; jej odłożenie opóźnia najważniejszą informację, czy podstawowy dziennik jest użyteczny.
- **Status:** in-progress

### S-03: Lokalne zdjęcia i opisy wpisów

- **Outcome:** użytkownik może zobaczyć zdjęcia zapisane w pamięci telefonu oraz opisy przypisane do wpisów.
- **Change ID:** local-entry-media-view
- **PRD refs:** FR-006, Success Criteria: Secondary
- **Prerequisites:** F-02, S-02
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:**
  - Czy lokalne zdjęcia pozostają wystarczające dla oczekiwanego użycia po zmianie lub utracie urządzenia? — Owner: user. Block: no.
  - Jak należy zabezpieczyć klucz potrzebny do późniejszej analizy AI? — Owner: user. Block: no.
- **Risk:** Ten wycinek domyka wartość dokumentowania, ale powinien pozostać za widokiem osi, aby nie budować obsługi mediów bez działającej nawigacji.
- **Status:** blocked

### S-04: CRUD osi czasu

- **Outcome:** użytkownik może utworzyć, zmienić nazwę i usunąć lokalną oś czasu.
- **Change ID:** timeline-crud
- **PRD refs:** MVP notes: CRUD osi czasu, FR-002
- **Prerequisites:** F-02, S-01
- **Parallel with:** S-02, S-03
- **Blockers:** —
- **Unknowns:** —
- **Risk:** usunięcie osi kaskadowo usuwa jej wpisy, dlatego akcja wymaga potwierdzenia.
- **Status:** in-progress

### S-05: Tworzenie wpisu osi czasu

- **Outcome:** użytkownik może dodać do wybranej osi wpis z bieżącą datą i czasem, opcjonalnym zdjęciem oraz opcjonalnym opisem.
- **Change ID:** create-timeline-entry
- **PRD refs:** FR-006, MVP notes: dodawanie wpisu ze zdjęciem, Success Criteria: Secondary
- **Prerequisites:** F-02, S-02, S-03
- **Parallel with:** S-04
- **Blockers:** —
- **Unknowns:** —
- **Risk:** realna galeria wymaga weryfikacji na Androidzie, a wybór aparatu pozostaje celowo mockiem do czasu osobnej implementacji.
- **Status:** in-progress

## Backlog Handoff

| Roadmap ID | Change ID                    | Suggested issue title                         | Ready for `/10x-plan` | Notes |
| ---------- | ---------------------------- | --------------------------------------------- | --------------------- | ----- |
| F-01       | google-access-foundation     | Ustanowić dostęp przez Google                  | yes                   | Uruchom ten fundament jako pierwszy. |
| F-02       | local-timeline-data-contract | Ustalić minimalny lokalny kontrakt danych      | no                    | Czeka na decyzję o lokalnym przechowywaniu. |
| F-03       | android-delivery-path        | Ustalić ścieżkę dostarczenia Androida          | no                    | Czeka na oczekiwania dotyczące dostarczenia. |
| S-01       | signed-in-timeline-list      | Pokazać użytkownikowi jego osie po logowaniu   | no                    | Zaczyna się po F-01. |
| S-02       | open-readable-timeline       | Otworzyć czytelną oś czasu                     | no                    | Gwiazda przewodnia; czeka na F-02 i S-01. |
| S-03       | local-entry-media-view       | Pokazać lokalne zdjęcia i opisy wpisów         | no                    | Następuje po widoku osi. |
| S-05       | create-timeline-entry        | Dodać nowy wpis do osi czasu                   | no                    | Plan zapisany w `context/changes/create-timeline-entry/`; zależy od widoku wpisów. |

## Open Roadmap Questions

1. **Which activity should be the first concrete use case beyond the general timeline flow?** — Owner: user. Block: S-02 only if a concrete scenario is required before implementation.
2. **Which mobile technology, image-storage approach and AI-key handling should be selected?** — Owner: user. Block: F-02, S-02 and S-03 for the image-storage part; AI handling remains outside these slices.
3. **What are the expectations for delivering and using the Android application?** — Owner: user. Block: F-03 and S-02.

## Parked

- **Porównywanie dwóch zdjęć przez AI** — odłożone do czasu doprecyzowania wymagań funkcjonalnych, klucza AI i bezpiecznego przepływu danych; obecny PRD opisuje regułę biznesową, ale nie nadaje temu osobnego wymagania koniecznego.
- **Synchronizacja i kopia zdjęć w chmurze** — poza zakresem PRD; zdjęcia pozostają lokalne w MVP.
- **Współdzielenie osi czasu, role i inne metody logowania** — poza zakresem PRD.
- **Scenariusz rodzicielski oraz rekomendacje ćwiczeń** — poza zakresem PRD.
- **Backend i obserwowalność** — nie są wymagane przez obecny lokalny zakres MVP; nie budujemy ich jako poziomych fundamentów.

## Milestone History

(Empty on first generation.)

## Done

- **F-02: (foundation) aplikacja ma minimalny, lokalny sposób przechowywania osi, wpisów, opisów i odwołań do zdjęć potrzebny przez pierwszy przepływ.** — Archived 2026-09-26 → `context/archive/2026-09-25-local-timeline-data-contract/`. Lesson: —.
- **F-01: (foundation) aplikacja potrafi rozpocząć i zakończyć prywatną sesję użytkownika przez Google.** — Archived 2026-09-25 → `context/archive/2026-09-23-google-access-foundation/`. Lesson: —.
