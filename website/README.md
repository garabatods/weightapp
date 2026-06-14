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

## Replace later

- Replace placeholder download CTAs in `index.html` with real store URLs or store badge assets when available.
- Replace files in `assets/screens/` when final app screenshots are ready.
- Replace `assets/brand/app-icon.png` if a dedicated website logo mark is created.

## Scope

This is not a web app. It does not include login, account creation, dashboard behavior, check-ins, goal management, tracking, auth, backend code, or a database.
