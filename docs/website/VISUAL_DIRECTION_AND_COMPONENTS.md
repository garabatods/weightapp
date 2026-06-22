# Leafstep Website Visual Direction & Components

## Visual goal

The website should feel:

- Calm
- Premium
- Native iOS-inspired
- Warm
- Private
- Gentle
- Minimal

Think:

> Wellness journal meets clean Apple-style product page.

## Color tokens

Use these as starting values if the repo does not already have design tokens.

```css
:root {
  --bg-warm: #F7F4EE;
  --bg-warm-2: #EFEAE0;
  --bg-mint: #E8F4EA;

  --surface: #FFFFFF;
  --surface-soft: #FBFAF6;

  --text-primary: #1F2A24;
  --text-secondary: #5C6761;
  --text-muted: #8A948E;

  --leaf-green: #2F7D59;
  --leaf-green-dark: #236346;
  --mint: #CFE8D6;

  --blue-info: #4E8BC7;
  --orange-streak: #D8893A;
  --lavender-flex: #B9A7E8;
  --yellow-mostly: #EACB62;
  --gray-missed: #B8B8B8;

  --border-soft: rgba(31, 42, 36, 0.10);
  --shadow-soft: 0 24px 70px rgba(31, 42, 36, 0.10);
  --shadow-card: 0 16px 40px rgba(31, 42, 36, 0.08);
}
```

## Color usage

- Use warm ivory for the page background.
- Use white cards.
- Use green only for primary CTAs and positive states.
- Use neutral/slate for most text and icons.
- Use lavender for Flex Days.
- Use blue for weigh-ins and informational accents.
- Use orange for streaks.
- Use yellow only for `Mostly` status accents.
- Avoid making the whole page green.

## Typography

Use system fonts or Inter.

Suggested CSS:

```css
body {
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.hero-title {
  font-size: clamp(3rem, 7vw, 5.8rem);
  line-height: 0.95;
  letter-spacing: -0.06em;
}

.section-title {
  font-size: clamp(2rem, 4vw, 3.8rem);
  line-height: 1;
  letter-spacing: -0.05em;
}
```

## Components to create

### Header

Props / content:

- Logo mark
- Brand name: Leafstep
- Nav links
- CTA

Visual:

- Soft transparent background
- Rounded CTA
- Minimal nav

### Button

Variants:

- Primary
- Secondary / ghost

Primary:

- Green background
- White text
- Rounded pill
- Soft shadow

Secondary:

- White or transparent background
- Slate text
- Border

### Feature card

Content:

- Icon bubble
- Title
- Body
- Optional small visual

Visual:

- White card
- Rounded corners
- Soft border
- Soft shadow
- Plenty of padding

### Phone mockup

Purpose:

- Static decorative app preview only.

States to show:

1. Today check-in
2. Progress trend
3. History / Flex Day calendar

Important:

- Do not make the phone mockups interactive.
- Do not create actual app logic.
- Do not store data.

### Badge chip

Examples:

- First check-in
- Trend builder
- Flex Day saved

Visual:

- Rounded pill
- Small icon
- Soft background
- Subtle border

### Privacy card

Content:

- Title
- Body
- Four trust points

Visual:

- Larger rounded card
- Mint gradient or soft warm background
- Lock/leaf icon
- Strong but calm layout

### FAQ item

Options:

- Static stacked item
- Accordion

Static is preferred if faster.

## Motion

Optional, subtle only:

- Fade up sections
- Slow floating hero badges
- Gentle phone mockup parallax

Respect:

```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation: none !important;
    transition: none !important;
    scroll-behavior: auto !important;
  }
}
```

## Imagery direction

Use app UI screenshots if available.

If screenshots are not available:

- Create CSS-based static mockups.
- Use realistic UI copy from the app.
- Keep them visibly illustrative.

Do not use:

- Body transformation images
- Fitness model photography
- Scale close-up images
- Medical charts
- Diet food photography
