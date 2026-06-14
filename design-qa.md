# Leafstep Website Design QA

final result: passed

## Reference

- Source: `/var/folders/q0/0d1_gkgj3cb7k8h7z_glkjzr0000gn/T/codex-clipboard-2f3d3117-c9bc-48c3-b671-ea22fa3eaf31.png`
- Target: `http://127.0.0.1:8080/`

## Checks

- Reworked the landing page toward the reference composition: serif hero, centered nav, overlapping phone previews, trust chips, compact contrast band, workflow row, feature band, lower privacy/testimonial/FAQ grid, and final CTA.
- Added no-people wellness visuals: a warm journal still life and a subtle botanical paper texture.
- Added generated no-people raster icons for all placeholder card and mini-badge icon slots.
- Replaced the hero phone cluster with the supplied warm lifestyle phone image.
- Added generated raster icons for the three hero trust chips.
- Added a click-to-play avatar video section using the supplied MP4 with controls.
- Added presentational motion: scroll reveals, hover lift, hero media/badge float, and desktop pointer-depth effects.
- Verified `ffmpeg` and `ffprobe` are installed.
- Verified avatar video metadata with `ffprobe`: 28.12 seconds, H.264 video, 832 x 1088, 25 fps, AAC audio.
- Verified desktop render in the in-app browser.
- Verified mobile render at `390 x 844`.
- Confirmed no horizontal overflow on desktop or mobile.
- Confirmed no broken images.
- Confirmed no console errors.
- Confirmed generated card icons load on desktop and mobile.
- Confirmed placeholder glyphs/numbers were removed from the card icon slots.
- Confirmed trust-chip placeholders were replaced with generated icons.
- Confirmed avatar video loads with native controls and no autoplay audio.
- Confirmed mobile trust/problem sections were refined after live review: trust icons render at 56px, problem-band icons render at 64px, and no horizontal overflow is present at 390px.
- Confirmed public website copy was revised to remove platform-exclusive wording from user-facing page copy.
- Confirmed reduced-motion support exists in JS and CSS: JS exits before enabling motion, and CSS disables animation/transition under `prefers-reduced-motion`.
- Confirmed no forms, auth, backend, dashboard, check-in, or web tracking behavior was added.

## Notes

- The hero now uses the supplied lifestyle image instead of app screenshots. The app screenshots remain available in `website/assets/screens/`.
- Wellness assets were generated with the built-in ImageGen workflow and copied into `website/assets/wellness/`.
- Card icons were generated with the built-in ImageGen workflow and copied into `website/assets/icons/`.
- Trust-chip icons were generated with the built-in ImageGen workflow and copied into `website/assets/icons/`.
- The `Join the beta` CTAs still use a replaceable `mailto:` placeholder.
