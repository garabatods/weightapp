# Leafstep Website Codex Pack

Use this pack to brief Codex on building a simple informational website for the Leafstep iOS app.

## Important clarification

This website is **not** a web version of the app.

It should be a public marketing / informational landing page only.

Do **not** build:

- Login
- User accounts
- Web dashboard
- Web check-in flow
- Web progress tracking
- Web goals management
- Cloud sync
- Backend
- Database
- Auth
- AI coach
- Calorie tracker
- Food tracker
- Wearable sync
- Social features

The website should only explain the iOS app and drive users toward:

- Joining a beta
- Downloading the iOS app, if available
- Learning what the app does

## Recommended files to give Codex

Start with:

1. `LEAFSTEP_INFORMATIONAL_WEBSITE_BRIEF.md`
2. `CODEX_PROMPT_IMPLEMENT_INFORMATIONAL_SITE.md`
3. `WEBSITE_COPY.md`
4. `LANDING_PAGE_STRUCTURE.md`
5. `VISUAL_DIRECTION_AND_COMPONENTS.md`
6. `ACCEPTANCE_CRITERIA.md`
7. `ASSETS_NEEDED.md`

## Suggested Codex workflow

1. Add these markdown files to the repo, preferably in:

```txt
/docs/website/
```

2. Ask Codex to read:

```txt
/docs/website/LEAFSTEP_INFORMATIONAL_WEBSITE_BRIEF.md
/docs/website/CODEX_PROMPT_IMPLEMENT_INFORMATIONAL_SITE.md
```

3. If the repo is only the native iOS app, ask Codex to create a separate static website folder:

```txt
/website/
```

4. The website can be built as a static page using the existing project setup if one exists. If there is no web stack, use a lightweight static implementation.

## Recommended output

A polished single-page informational website:

- Mobile-first
- Responsive
- Premium and relaxing
- App-focused
- No functional app behavior
- No backend
- No auth
- No form unless intentionally added later
