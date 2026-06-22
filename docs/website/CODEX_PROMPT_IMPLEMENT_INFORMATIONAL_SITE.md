# Codex Prompt — Implement Leafstep Informational Website

Use this prompt in Codex after adding the website brief files to the repo.

---

## Prompt

Read the website docs in `/docs/website/` and implement a polished single-page informational landing page for the Leafstep iOS app.

This is **not** a web version of the app. It is only a public marketing / informational website.

Do not build login, account creation, database, auth, dashboard, user tracking, weight entry, check-in flow, goal management, or any real app functionality on the web.

The page should explain the iOS app and encourage users to join the beta or download the app.

## Implementation instructions

1. Inspect the repo first.
2. If a web app/site already exists, use the existing framework and conventions.
3. If no web stack exists, create a separate `/website/` folder with a lightweight static landing page.
4. Keep the implementation simple, maintainable, and responsive.
5. Prefer semantic HTML, accessible buttons/links, and clean CSS.
6. Do not add backend dependencies.
7. Do not add auth dependencies.
8. Do not add analytics unless the repo already has a clear analytics setup and the product owner requested it.
9. Use static app mockups if real screenshots are unavailable.
10. Make it feel premium, calm, iOS-native, and soft.

## Required sections

Build these sections:

1. Header / nav
2. Hero
3. Problem / contrast
4. How it works
5. Feature grid
6. Privacy / local-only
7. Gentle reminders
8. FAQ
9. Final CTA
10. Footer

## Header

Use:

- Brand: `Leafstep`
- Nav links: `Features`, `Privacy`, `FAQ`
- CTA: `Join the beta`

If App Store URL exists later, make the CTA `Download on the App Store`.

## Hero copy

Eyebrow:

> Private iOS habit tracker

Headline:

> A calmer way to stay consistent with your weight-loss habits.

Subheadline:

> Leafstep helps you track the days that matter, build a rhythm, and watch your weight trend follow — without calorie counting, food databases, or pressure.

Primary CTA:

> Join the beta

Secondary CTA:

> See how it works

Trust row:

> Private by design · No calorie tracking · Local-only on iPhone

## Visual requirements

Use a warm premium wellness look:

- Warm ivory background
- Soft mint glow
- Neutral white cards
- Green as primary CTA only
- Slate/neutral body text
- Blue for weigh-in accents
- Orange for streak accents
- Lavender for Flex Day accents

Use iPhone-style mockups showing static representations of:

- Today check-in
- Progress trend
- History calendar or Flex Day state

These mockups are decorative/static and should not behave like an app.

## Responsive behavior

Desktop:

- Hero can use two-column layout.
- Feature cards can use a 3-column grid.
- Phone mockups can overlap.

Tablet:

- Hero can stack or use reduced columns.
- Feature grid can use 2 columns.

Mobile:

- Single column.
- CTA visible early.
- Phone mockups stacked or simplified.
- Nav can be simplified.

## Accessibility

- Use semantic landmarks: header, main, section, footer.
- Use meaningful headings.
- Ensure color contrast is readable.
- Buttons/links must have accessible labels.
- Decorative visuals should be hidden from screen readers if needed.
- Respect `prefers-reduced-motion`.

## Do not include

- Login
- Sign up flow that creates accounts
- Real forms unless requested
- Dashboard
- In-browser check-in
- In-browser charts that imply real user data
- Pricing table
- Social proof unless content is provided
- Medical claims
- Weight-loss guarantees

## Deliverables

After implementation:

1. Summarize what changed.
2. List files created/modified.
3. Explain how to run or preview the page.
4. Call out any placeholder assets or links that need replacement.
5. Confirm that no web app functionality, auth, backend, or database was added.
