---
name: The Architectural Gallery
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#43474d'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#74777e'
  outline-variant: '#c3c6ce'
  surface-tint: '#49607c'
  primary: '#00152a'
  on-primary: '#ffffff'
  primary-container: '#102a43'
  on-primary-container: '#7a92b0'
  inverse-primary: '#b0c9e8'
  secondary: '#565f6b'
  on-secondary: '#ffffff'
  secondary-container: '#d8e0ef'
  on-secondary-container: '#5b636f'
  tertiary: '#201100'
  on-tertiary: '#ffffff'
  tertiary-container: '#3b2400'
  on-tertiary-container: '#ad8a5a'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d1e4ff'
  primary-fixed-dim: '#b0c9e8'
  on-primary-fixed: '#011d35'
  on-primary-fixed-variant: '#314863'
  secondary-fixed: '#dae3f1'
  secondary-fixed-dim: '#bec7d5'
  on-secondary-fixed: '#141c26'
  on-secondary-fixed-variant: '#3f4753'
  tertiary-fixed: '#ffddb4'
  tertiary-fixed-dim: '#e8c08c'
  on-tertiary-fixed: '#291800'
  on-tertiary-fixed-variant: '#5d4119'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
typography:
  display-lg:
    fontFamily: Manrope
    fontSize: 57px
    fontWeight: '700'
    lineHeight: 64px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
---

# Design System Document

## 1. Overview & Creative North Star: "The Architectural Gallery"
This design system is built upon the philosophy of **"The Architectural Gallery."** Rather than viewing a digital interface as a collection of boxes on a screen, we treat it as a curated physical space. The aesthetic is defined by expansive white space (the "gallery walls"), deep navy accents (the "architectural focal points"), and a reliance on tonal depth rather than structural lines.

To move beyond "standard" minimalism, we utilize intentional asymmetry and a rigid "No-Line" rule. The goal is to create an experience that feels inhaled—light, airy, and premium—where high-quality photography is treated as fine art and the UI provides the invisible, sophisticated framework to support it.

---

## 2. Colors & Tonal Depth
The color palette avoids the harshness of pure black and white. It relies on a sophisticated range of grays and deep navies to guide the eye.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to define sections. Boundaries must be established through:
1.  **Background Shifts:** Transitioning from `surface` (#F8F9FA) to `surface-container-low` (#F3F4F5).
2.  **Negative Space:** Using the Spacing Scale (Factor 2) to create "voids" that act as natural separators.

### Surface Hierarchy & Nesting
Treat the UI as physical layers of fine paper. Use the following hierarchy to "lift" or "sink" elements:
*   **Base Layer:** `surface` (#F8F9FA) - The canvas.
*   **Submerged Content:** `surface-container-low` (#F3F4F5) - Used for secondary backgrounds or inset areas.
*   **Elevated Objects:** `surface-container-lowest` (#FFFFFF) - Used for primary cards or floating elements to create a subtle, natural highlight against the light gray base.

### The "Glass & Gradient" Rule
To inject "soul" into the minimalist aesthetic:
*   **Glassmorphism:** For floating navigation or overlays, use `surface_container_lowest` at 80% opacity with a `24px` backdrop-blur.
*   **Signature Textures:** Main CTAs should not be flat. Use a subtle linear gradient from `primary` (#102A43) to a slightly adjusted tonal variant at a 135-degree angle to provide a sense of luxury and depth.

---

### 3. Typography: Editorial Authority
The system utilizes a dual-sans serif approach to balance high-fashion editorial vibes with functional legibility.

*   **Display & Headlines (Manrope):** These are your "statement" pieces. Use `display-lg` and `headline-lg` with tight letter-spacing (-0.02em) to create an authoritative, "bold-minimalist" look. Don't be afraid to let a headline overlap a photograph slightly to break the grid.
*   **Body & Labels (Inter):** Reserved for high-utility information. Inter provides the technical precision needed for readability against light backgrounds.
*   **Hierarchy Note:** Always prioritize a massive scale contrast. A `display-lg` headline should feel significantly more "important" than `body-md` text to create a rhythmic, editorial flow.

---

## 4. Elevation & Depth: The Layering Principle
We do not use structural lines; we use **Tonal Layering** and **Ambient Light**.

*   **Ambient Shadows:** Shadows must be felt, not seen. Use `on-surface` (#191C1D) at 4-6% opacity with a blur radius of at least `32px` and a `12px` Y-offset. This mimics a soft, overhead gallery light.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility, use `outline-variant` (#C3C6CE) at **15% opacity**. It should be a suggestion of a line, not a boundary.
*   **Roundedness Scale:** Following the pill-shaped philosophy (Roundedness 3), all primary containers (Cards, Inputs, Buttons) must use the `DEFAULT` (16px / 1rem) or `lg` (32px / 2rem) radius. This softness counteracts the "coldness" of the minimalist palette.

---

## 5. Components

### Buttons
*   **Primary:** Gradient (Primary to Primary-Container), white text, pill-shaped (16px+ radius). High-impact.
*   **Secondary:** `surface-container-highest` background with `primary` text. No border.
*   **Tertiary:** Ghost style. `primary` text with an underline that only appears on hover.

### Cards & Lists
*   **The Rule:** No dividers. Use `1.5rem` (24px) of vertical padding between items, strictly adhering to the Spacing Factor 2 scale, or alternate background tones between `surface` and `surface-container-low`. 
*   **Photography:** Cards should be image-dominant. Typography should sit on a `surface-container-lowest` "shelf" at the bottom of the card or float over the image using a Glassmorphism treatment.

### Input Fields
*   **Style:** `surface-container-low` background, no border, `DEFAULT` (16px) radius.
*   **Focus State:** Shift background to `surface-container-lowest` and apply a `2px` "Ghost Border" using `primary` at 20% opacity.

### Featured Gallery Module (Special Component)
*   An asymmetrical layout component where two images of different aspect ratios (e.g., 4:5 and 1:1) overlap slightly. Use `headline-sm` typography to caption them, placed in "unexpected" corners to drive the editorial feel.

---

## 6. Do’s and Don’ts

### Do:
*   **Do** use extreme white space. If a section feels "finished," add 16px (2 units) more padding to honor the spacing scale.
*   **Do** use `primary` (#102A43) sparingly. It is an accent color, not a layout color.
*   **Do** ensure all photography has a consistent color grade that complements the #F8F9FA background.

### Don’t:
*   **Don't** use 1px solid black or gray borders. This immediately destroys the premium "Architectural Gallery" feel.
*   **Don't** use "Drop Shadows" that are dark or tight. Shadows should be wide, soft, and atmospheric.
*   **Don't** crowd the layout. If you have more than 5 elements in a single visual cluster, break them into a "nested" surface hierarchy using the Factor 2 spacing rules.