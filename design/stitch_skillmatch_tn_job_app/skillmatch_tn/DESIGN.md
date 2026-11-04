---
name: SkillMatch TN
colors:
  surface: '#f6f9ff'
  surface-dim: '#d0dbe7'
  surface-bright: '#f6f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#ebf5ff'
  surface-container: '#e4effb'
  surface-container-high: '#dee9f5'
  surface-container-highest: '#d8e4f0'
  on-surface: '#121d25'
  on-surface-variant: '#44474d'
  inverse-surface: '#27323b'
  inverse-on-surface: '#e7f2fe'
  outline: '#74777d'
  outline-variant: '#c4c6cd'
  surface-tint: '#4d6078'
  primary: '#000e1f'
  on-primary: '#ffffff'
  primary-container: '#10243a'
  on-primary-container: '#798ca6'
  inverse-primary: '#b5c8e5'
  secondary: '#006b59'
  on-secondary: '#ffffff'
  secondary-container: '#96f4db'
  on-secondary-container: '#00725f'
  tertiary: '#170b00'
  on-tertiary: '#ffffff'
  tertiary-container: '#341f00'
  on-tertiary-container: '#bc7e17'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d2e4ff'
  primary-fixed-dim: '#b5c8e5'
  on-primary-fixed: '#071c32'
  on-primary-fixed-variant: '#354860'
  secondary-fixed: '#96f4db'
  secondary-fixed-dim: '#7ad7c0'
  on-secondary-fixed: '#00201a'
  on-secondary-fixed-variant: '#005143'
  tertiary-fixed: '#ffddb5'
  tertiary-fixed-dim: '#ffb956'
  on-tertiary-fixed: '#2a1800'
  on-tertiary-fixed-variant: '#643f00'
  background: '#f6f9ff'
  on-background: '#121d25'
  surface-variant: '#d8e4f0'
typography:
  headline-xl:
    fontFamily: Merriweather
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
  headline-lg:
    fontFamily: Merriweather
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Merriweather
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  headline-sm:
    fontFamily: Merriweather
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1.25rem
  space-xl: 1.75rem
---

## Brand & Style

This design system establishes an editorial yet pragmatic visual environment tailored to junior developers, engineering graduates, and students navigating the Tunisian technology ecosystem. It rejects generic tech hyper-minimalism in favor of an authoritative, structured, and warm institution-grade design style.

### Target Audience & Core Tone
- **Audience:** Tunisian software engineering students, tech bootcamp graduates, and career transitioners seeking internships, first roles, and skill verification.
- **Tone:** Methodical, reliable, quietly prestigious, and dignified. It communicates career elevation without the intimidation of legacy corporate recruiting tools.
- **Visual Aesthetic:** Grounded Mediterranean-Nordic hybrid minimalism. It pairs deep maritime navy with rich parchment surfaces, anchored by botanical emerald and sunlit amber accents.

## Colors

The palette relies on structural weight, thermal warmth, and immediate semantic clarity. High-contrast pairings ensure readability in varying mobile lighting conditions.

### Core Roles
- **Canvas Base (`#F7F5EF`):** An organic, low-strain warm cream replacing sterile digital whites. All surfaces build upon this warm paper layer.
- **Primary Navy (`#10243A`):** The structural anchor. Used for primary branding, top navigation bars, key headlines, and deep-contrast headers.
- **Action & Verification Emerald (`#0F7F6B`):** The engine of progression. Drives call-to-actions, high-affinity match percentages, application submissions, and confirmed qualifications.
- **Catalyst Amber (`#E8A33D`):** An energetic highlight for application deadlines, bookmark states, urgent internship notices, and attention badges.
- **Neutral Carbon (`#5B6670`):** Secondary metadata, auxiliary labels, timestamps, and descriptive company subheaders.

### Semantic Skill Tokens
- **Skill Acquired:** Surface `#DFF3EE`, text `#0A5C4D`, border `transparent`. Indicates verified match between candidate syllabus and job specification.
- **Skill Missing:** Surface `#FDE7E5`, text `#8A1C14`, border `1px solid #F0B2AF`. Highlights curriculum gaps that require action or leveling-up.
- **Dividers & Structural Borders:** Border color `#E0DDD2` maintains tactile containment across neutral cream fields without harshness.

## Typography

Typography balances academic prestige with ergonomic software legibility. 

- **Display & Section Titles:** `Merriweather` provides editorial weight, evoking respected technical publications and university degree certificates. Used for screen titles, key job role headers, and modal headings.
- **Interface & Operational Text:** `Plus Jakarta Sans` provides open letterforms, tall x-heights, and crisp rendering on compact mobile viewports (390×844). Used across job descriptions, metadata rows, match scores, and form inputs.
- **Rhythm & Hierarchy:** All text treatments require standard line-heights exceeding 1.25x for display serif fonts and 1.4x for body text to preserve scanning speed under bright daylight.

## Layout & Spacing

The layout is optimized specifically for portrait mobile screens (390×844 viewport standard).

### Structural Rules
- **Grid:** 4-column fluid mobile grid with `16px` (`1rem`) gutters and `20px` (`1.25rem`) lateral margins to keep interactive content clear of bezel edges.
- **Vertical Cadence:** Multiples of `4px` and `8px`. Section gaps use `space-xl` (28px), while nested component rows use `space-md` (12px) and `space-sm` (8px).
- **Safe Area Insets:** Top headers allocate dynamic headroom for status bar items (47px base on iOS). Bottom tab bars explicitly pad the iOS home indicator bar (34px) while ensuring full touch-target reachability.

## Elevation & Depth

This system avoids floating or heavily blurred layered glass. Visual separation is achieved through tactile structural outlines and physical paper planes.

### Architectural Levels
- **Level 0 (Base Canvas):** Solid `#F7F5EF`. The foundational canvas.
- **Level 1 (Card & Module Surfaces):** Solid `#FFFFFF` surfaces rimmed with a strict `#E0DDD2` border (1px). Ambient shadow is ultra-soft: `0px 2px 8px rgba(16, 36, 58, 0.04)`.
- **Level 2 (Active Sheets & Sticky Bars):** Solid `#FFFFFF` or `#10243A` with a delicate top/bottom boundary border and directional shadow: `0px -4px 16px rgba(16, 36, 58, 0.08)`.
- **Level 3 (Modals & Bottom Drawers):** `#FFFFFF` paired with an ambient backdrop overlay (`rgba(16, 36, 58, 0.45)`).

## Shapes

The geometric silhouette conveys modern professionalism with friendly, approachable contours:

- **Cards & Primary Modules:** `20px` corner radius. This gives job cards, profile score cards, and application trackers an intentional, premium hand-held feel.
- **Interactive Controls (Buttons & Inputs):** `14px` corner radius. Balances the softer card corners with disciplined structure.
- **Metadata Chips & Tags:** `8px` to `12px` corner radius depending on scale. Never fully circular pills, reinforcing an organized tabular feeling.
- **Avatars & Score Indicators:** Circular (`9999px`) for individual recruiter photos and overall compatibility percentage donuts.

## Components

### Buttons
- **Primary CTA:** Height `52px`, background `#0F7F6B`, text `#FFFFFF`, radius `14px`, font `label-lg`. Full width or minimum `160px`. Focus and active state deepens to `#0A5C4D`.
- **Secondary / Ghost:** Height `52px`, background `transparent`, text `#10243A`, border `1.5px solid #10243A`, radius `14px`.
- **Tertiary Utility:** Height `40px`, padding `0 16px`, background `#F7F5EF`, text `#5B6670`, radius `10px`.

### Skill Badges & Chips
- **Acquired Skill Chip:** Background `#DFF3EE`, text `#0A5C4D`, border `none`, padding `6px 12px`, radius `8px`, typography `label-md`. Prefixed with a subtle checkmark icon.
- **Missing Skill Chip:** Background `#FDE7E5`, text `#8A1C14`, border `1px solid #F0B2AF`, padding `5px 11px`, radius `8px`, typography `label-md`. Prefixed with a warning or plus icon.
- **Neutral Filter Chip:** Background `#FFFFFF`, text `#5B6670`, border `1px solid #E0DDD2`, radius `10px`, min height `36px`.

### Job & Match Cards
- **Container:** Background `#FFFFFF`, border `1px solid #E0DDD2`, radius `20px`, padding `20px`.
- **Card Structure:** 
  1. Top row: Company avatar (44×44px, radius 10px), job title in `headline-sm`, company and location in `body-sm` (`#5B6670`).
  2. Middle row: Match percentage indicator (e.g., "85% Match" pill using `#DFF3EE` background and `#0A5C4D` text).
  3. Skill row: Flex wrap layout of acquired vs. missing chips with `6px` gap.
  4. Footer row: Publication timestamp and salary/stipend bracket in `TND` (Tunisian Dinar).

### Input Fields & Search Bars
- **Container:** Height `52px`, background `#FFFFFF`, border `1px solid #E0DDD2`, radius `14px`, horizontal padding `16px`.
- **Active / Focused:** Border `1.5px solid #0F7F6B`, subtle glow `0px 0px 0px 3px rgba(15, 127, 107, 0.15)`.
- **Labels:** `label-md` seated above the field in `#10243A`.

### Selection Controls (Checkboxes & Radios)
- **Checkboxes:** Size `22×22px`, radius `6px`, border `1.5px solid #5B6670`. Checked state: background `#0F7F6B`, border `#0F7F6B`, white checkmark.
- **Radios:** Size `22×22px`, circle, border `1.5px solid #5B6670`. Selected state: `#0F7F6B` outline with centered `10px` solid dot.

### Bottom Navigation Bar
- **Dimensions & Placement:** Fixed at screen bottom, height `64px` plus bottom safe area inset. Background `#FFFFFF`, top border `1px solid #E0DDD2`.
- **Structure:** Exactly 3 balanced tabs:
  1. **Offres:** Briefcase icon + "Offres"
  2. **Compétences:** Checklist/Sparkle icon + "Compétences"
  3. **Profil:** User icon + "Profil"
- **State Styling:** Active tab displays `#0F7F6B` icon and label (`label-sm`). Inactive tabs use `#5B6670`. Minimum touch box per tab: `64×48px`.