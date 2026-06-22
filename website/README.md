# Leafstep Informational Website

This folder contains a static single-page informational website for the downloadable Leafstep mobile app.

## Preview locally

Open `website/index.html` in a browser, or serve the folder:

```sh
python3 -m http.server 8080 --directory website
```

Then visit:

```txt
http://localhost:8080
```

The nutritionist platform prototype is available at:

```txt
http://localhost:8080/nutritionist.html
```

Use the local demo access code:

```txt
leafstep-pro
```

## Replace later

- Replace placeholder download CTAs in `index.html` with real store URLs or store badge assets when available.
- Replace files in `assets/screens/` when final app screenshots are ready.
- Replace `assets/brand/app-icon.png` if a dedicated website logo mark is created.
- Replace the static nutritionist prototype with real professional auth, a backend, short-lived one-time QR token generation, and server-side revocation before launch.

## Public site scope

The public `index.html` site is not a web app. It does not include login, account creation, dashboard behavior, check-ins, goal management, tracking, auth, backend code, or a database.

`nutritionist.html` is a separate frontend-only prototype for the supervised Meal Plan workflow. It stores demo plans, pseudonymous patient slots, and pairing payloads in the browser’s local storage only. It intentionally does not collect patient email, full name, diagnosis, weight history, check-ins, measurements, goals, or app history.
