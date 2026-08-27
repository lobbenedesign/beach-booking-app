# 🏖️ Beach Booking

**[🇮🇹 Leggi questo in Italiano](README.md)**

**Customer-facing** Flutter app for booking a real beach club: choose an umbrella/spot with a seasonal pricing engine, book a restaurant table, order from the bar/restaurant menu, and browse a marketplace of on-demand extra services (rentals, beach services) — all orderable in real time.

> **Project status:** technical prototype/demo, not a production-ready product. See [Current limitations](#current-limitations) before evaluating it for real-world use.

This repository is the **customer side** of a two-app platform: the operator-facing management software (live map, spot editor, pricing engine, restaurant dashboard) lives in a separate repository, [beach-manager-app](https://github.com/lobbenedesign/beach-manager-app). Both apps share the same data/pricing engine but are built for entirely different audiences and flows — this repository has no administration functionality at all.

---

## Why this project

Between 2020 and the end of 2022 I worked at an IT company building a booking system for beach clubs and the corresponding management software for the operator. I joined the team when the product had already generated around €300,000 in transactions over the previous two years. After thoroughly analyzing the existing system, I identified the limits of the original idea and proposed expanding it toward a broader market within the same industry — work that in my first few months contributed to growing transactions to €3,600,000, and which over the following two years grew past €4,600,000.

This project was born in those very first months of the collaboration: a Flutter prototype meant to show that an emerging technology at the time could be the answer to bringing more modernity to a system that had only ever been a web application, finally giving it a real cross-platform app. That collaboration ended at the end of 2022; since then I've kept developing and expanding the project independently. This repository isolates the end-customer-facing part of the full system.

## Screenshots

<p align="center">
  <img src="docs/screenshots/01-login.png" width="48%" alt="Login" />
  <img src="docs/screenshots/02-customer-home.png" width="48%" alt="Customer home" />
</p>

## What this project demonstrates

### Booking an umbrella

Date selection → package choice → live-availability map, with prices differentiated by package, day of the week, season, and row/zone.

<p align="center">
  <img src="docs/screenshots/03-booking-packages.png" width="48%" alt="Package selection" />
  <img src="docs/screenshots/04-booking-map.png" width="48%" alt="Umbrella selection map" />
</p>

### Bar & restaurant ordering

Menu split by category (starters, pizza, mains, desserts) with photos, descriptions, allergens; the order is sent to the operator in real time.

<p align="center">
  <img src="docs/screenshots/05-menu-order.png" width="70%" alt="Order from the customer app" />
</p>

### Extra services marketplace

Bar orders, timed rentals (single/double kayak, motorboat), beach tennis court, at-your-umbrella services (massages, drinks) — the same seasonal pricing engine as the management app, orderable independently from the app.

<p align="center">
  <img src="docs/screenshots/06-extra-services-customer.png" width="70%" alt="Extra services, customer side" />
</p>

### Restaurant table booking

<p align="center">
  <img src="docs/screenshots/07-restaurant-booking-customer.png" width="70%" alt="Restaurant table booking" />
</p>

## Tech stack

- **Flutter Web** (Dart)
- **Provider** for state management
- **go_router** for routing
- Local persistence via `shared_preferences` (demo, not a real backend)

## Running it

```bash
flutter pub get
flutter run -d chrome
```

### Demo account

| Role | Email | Password |
|---|---|---|
| Customer | `demo@beach.com` | anything |

## Current limitations

This is a technical prototype, not a production-ready product:

- **No backend**: all data lives in memory and in the browser's `localStorage` — there's no real multi-device or multi-user sync
- **Demo authentication**: login accepts any password, this is not a real security system
- **Simulated payments**: the Stripe/PayPal integration is mocked, no real transaction ever happens
- **Test coverage**: good on business logic (pricing engine, bookings, orders), absent on end-to-end/UI tests
- **No administration functionality**: for the live map, spot editor, and operator dashboard, see [beach-manager-app](https://github.com/lobbenedesign/beach-manager-app)

## License

**All rights reserved.** The code is publicly viewable for demonstration/portfolio purposes only; no right to copy, modify, use, or distribute is granted without the author's written permission. See [LICENSE](LICENSE).

Are you a company or recruiter interested in this project, in a commercial license, or in collaborating with / hiring the author? Reach out on [LinkedIn](https://www.linkedin.com/in/giuseppe-lobbene-39566a5b/) or by email: [giuseppelobbene@gmail.com](mailto:giuseppelobbene@gmail.com).
