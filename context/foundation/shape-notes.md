---
project: timelines
context_type: greenfield
product_type: mobile
target_scale:
  users: small
  qps: low
  data_volume: small
created: 2026-09-18
updated: 2026-09-18
timeline_budget:
  mvp_weeks: 7
  hard_deadline: 2026-11-04
  after_hours_only: true
checkpoint:
  current_phase: 8
  phases_completed: [1, 2, 3, 4, 5, 6, 7]
  gray_areas_resolved: []
  frs_drafted: 6
  quality_check_status: accepted
---

# Shape Notes

## Vision & Problem Statement

Użytkownik nie docenia zmian zachodzących w życiu, ponieważ doświadcza głównie chwili obecnej. Rozproszone zdjęcia i opisy utrudniają mu dostrzeżenie postępu oraz efektów regularnej pracy.

Aplikacja ma umożliwić prowadzenie dziennika podzielonego na kategorie osi czasu, aby użytkownik mógł wrócić do wcześniejszych wpisów i zobaczyć zmiany zachodzące wraz z upływem czasu.

Reguła porównywania dwóch dni i oceniania zdrowego rozwoju rośliny pozostaje taka sama przy większej liczbie użytkowników.

## User & Persona

Główną personą jest autor aplikacji jako codzienny użytkownik, który dokumentuje wybraną aktywność. Sięga po aplikację podczas codziennego działania, aby zapisywać kolejne etapy i później zauważyć postęp, którego nie dostrzega na bieżąco.

### Początkowo rozważane grupy

- osoby ćwiczące,
- amatorzy prac ogrodowych,
- rodzice.

## Access Control

Dostęp do aplikacji wymaga logowania przez konto Google/Gmail. Każdy zalogowany użytkownik ma taki sam zakres uprawnień i może zarządzać wyłącznie własnymi osiami czasu oraz wpisami. MVP nie obsługuje innych metod logowania, ról ani współdzielenia.

## Success Criteria

### Primary

- Użytkownik może otworzyć aplikację, wybrać oś czasu, zobaczyć jej mockupowe wpisy oraz przycisk dodania nowego wpisu.

### Secondary

- Użytkownik może dodać wpis ze zdjęciem.

### Guardrails

- Użytkownik może poruszać się po aplikacji dzięki prostej nawigacji.
- Wpisy pozostają czytelne.

## User Stories

### US-01: Użytkownik ogląda swoje osie czasu

- **Given** użytkownik nie jest zalogowany
- **When** użytkownik poprawnie zaloguje się swoim kontem Google
- **Then** użytkownik widzi swoje osie czasu

## Functional Requirements

- FR-001: Użytkownik może zalogować się za pomocą swojego konta Google. Priority: must-have
  > Socrates: Counter-argument considered: "Zależność od zewnętrznego dostawcy może sprawić, że awaria lub zmiana usługi Google uniemożliwi dostęp do aplikacji." Resolution: użytkownik wybrał ten kontrargument do dalszego uwzględnienia.
- FR-002: Zalogowany użytkownik może zobaczyć listę osi czasu. Priority: must-have
  > Socrates: Counter-argument considered: "Brak kontrargumentu — wymaganie pozostaje bez zmian." Resolution: wymaganie pozostaje bez zmian, ponieważ lista osi czasu jest potrzebna dla wielu kategorii.
- FR-003: Zalogowany użytkownik może wejść w wybraną oś czasu. Priority: must-have
  > Socrates: Counter-argument considered: "Wybór osi to zbędny krok, jeśli użytkownik powinien od razu trafiać do jednej domyślnej osi czasu." Resolution: użytkownik wybrał ten kontrargument do dalszego uwzględnienia.
- FR-004: Użytkownik może zobaczyć wpisy należące do wybranej osi czasu. Priority: must-have
  > Socrates: Counter-argument considered: "Brak kontrargumentu — wymaganie pozostaje bez zmian." Resolution: widok wpisów pozostaje podstawową wartością osi czasu.
- FR-005: Użytkownik może odróżnić wpisy dotyczące kolejnych dni. Priority: must-have
  > Socrates: Counter-argument considered: "Dni nie są najważniejszą osią porównania; użytkownik może bardziej potrzebować porównania tygodni, miesięcy lub etapów." Resolution: użytkownik wybrał ten kontrargument do dalszego uwzględnienia.
- FR-006: Użytkownik może zobaczyć zdjęcia zapisane w pamięci telefonu i opisy wpisów. Priority: must-have
  > Socrates: Counter-argument considered: "Zdjęcia lokalne mogą zniknąć po zmianie urządzenia, usunięciu pliku lub utracie dostępu do pamięci." Resolution: użytkownik wybrał ten kontrargument do dalszego uwzględnienia.

## Business Logic

Aplikacja pozwala porównać dwa stany osi czasu poprzez przesłanie zdjęć do AI.

Użytkownik wybiera dwa dni, na przykład dzień z początku i dzień po dwóch miesiącach dokumentowania rośliny. Wynikiem porównania jest informacja, czy roślina rozwija się zdrowo. Użytkownik korzysta z tej funkcji po czasie, aby otrzymać podsumowanie zmian.

## Non-Functional Requirements

- Aplikacja działa na telefonach z systemem Android wyposażonych w aparat.

## Forward: tech-stack

- Użytkownik rozważa lokalne przechowywanie zdjęć.
- Użytkownik rozważa użycie własnego klucza do AI do analizy.

## Non-Goals

- MVP nie obejmuje rozbudowanej analizy AI; zakres AI pozostaje ograniczony do wybranego porównania rośliny.
- MVP nie umożliwia współdzielenia osi czasu; osie czasu są prywatne dla użytkownika.
- MVP nie obejmuje scenariusza rodzicielskiego.
- MVP nie zapewnia synchronizacji ani kopii zdjęć w chmurze; zdjęcia pozostają przechowywane lokalnie.

## Timeline acknowledgment

Acknowledged on 2026-09-18: 7-week MVP requires sustained dedication; user accepted.

## Open Questions

1. **Which activity should be the first concrete use case beyond the general timeline flow?** — Owner: user. The discussion mentions exercise, gardening and parenting; gardening is used in the business rule, while the primary persona remains the author of the application.
2. **Which mobile technology, image-storage approach and AI-key handling should be selected?** — Owner: user, during the next technical step. Current considerations are recorded under `## Forward: tech-stack`.
3. **What are the expectations for delivering and using the Android application?** — Owner: user, during the next technical step.

## Quality cross-check

- Access Control: present.
- Business Logic: present as a one-sentence rule.
- Project artifacts: present.
- Timeline-cost acknowledgment: present; the user accepted a 7-week MVP timeline.
- Non-Goals: present.
- Preserved behavior: not applicable; this is a greenfield project.
