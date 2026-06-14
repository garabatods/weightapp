# Leafstep Website Design QA

final result: passed

## Reference

- Source: `/var/folders/q0/0d1_gkgj3cb7k8h7z_glkjzr0000gn/T/codex-clipboard-2f3d3117-c9bc-48c3-b671-ea22fa3eaf31.png`
- Target: `http://127.0.0.1:8080/`

## Checks

- Reworked the landing page toward the reference composition: serif hero, centered nav, overlapping app screen previews, trust chips, compact contrast band, workflow row, feature band, lower privacy/principle/FAQ grid, and final CTA.
- Added no-people wellness visuals: a warm journal still life and a subtle botanical paper texture.
- Added generated no-people raster icons for all placeholder card and mini-badge icon slots.
- Restored the hero as an app-focused static mobile UI mockup cluster.
- Added generated raster icons for the three hero trust chips.
- Removed the avatar video section so no video fallback text can appear.
- Replaced the fake testimonial with a Flex Days product principle card.
- Replaced pre-release and future-availability CTA copy with a platform-neutral download placeholder.
- Added presentational motion: scroll reveals, hover lift, hero media/badge float, and desktop pointer-depth effects.
- Verified `ffmpeg` and `ffprobe` are installed.
- Verified desktop render in the in-app browser.
- Verified mobile render at `390 x 844`.
- Confirmed no horizontal overflow on desktop or mobile.
- Confirmed no broken images.
- Confirmed no console errors.
- Confirmed generated card icons load on desktop and mobile.
- Confirmed placeholder glyphs/numbers were removed from the card icon slots.
- Confirmed trust-chip placeholders were replaced with generated icons.
- Confirmed no video fallback copy is present in the page.
- Confirmed mobile trust/problem sections were refined after live review: trust icons render at 56px, problem-band icons render at 64px, and no horizontal overflow is present at 390px.
- Confirmed public website copy was revised to remove platform-exclusive wording from user-facing page copy.
- Confirmed no pre-release, future-availability, platform-exclusive, or fake testimonial copy remains in user-facing website files.
- Confirmed reduced-motion support exists in JS and CSS: JS exits before enabling motion, and CSS disables animation/transition under `prefers-reduced-motion`.
- Confirmed no forms, auth, backend, dashboard, check-in, or web tracking behavior was added.

## Notes

- The hero uses static app screenshots from `website/assets/screens/`; the supplied lifestyle image remains available but is no longer the primary hero visual.
- Wellness assets were generated with the built-in ImageGen workflow and copied into `website/assets/wellness/`.
- Card icons were generated with the built-in ImageGen workflow and copied into `website/assets/icons/`.
- Trust-chip icons were generated with the built-in ImageGen workflow and copied into `website/assets/icons/`.
- Store badge assets were not present, so the site uses a clean `Download the app` CTA button placeholder.
