# Tagar — UI Design System

> **Tagar** (तगर) is a flowering plant native to India that blooms in summer — pure white petals with dark green foliage. This design system is rooted in nature: calm, warm, and grounded.

---

## 1. Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| Petal White | `#F7F5F0` | Backgrounds |
| Bark Cream | `#EDE8DC` | Surfaces (cards, sheets) |
| Leaf Green | `#5A8A3C` | Primary buttons, active states |
| Forest Green | `#2E5220` | Headers, bold text |
| Earth Brown | `#7D5A3C` | Accents, icons |
| Sandy Brown | `#C4A882` | Borders, dividers |
| River Blue | `#4A7FA5` | Info states, links |
| Sky Blue | `#B8D4E8` | Highlights, selections |

---

## 2. Typography

| Role | Font | Weight | Use |
|------|------|--------|-----|
| Logo / Brand | Cormorant Garamond | SemiBold 600 | Splash screen, app bar brand name |
| UI Headers | DM Serif Display | Regular 400 | Screen titles, section headings |
| Body Text | Noto Sans | Regular 400 / Medium 500 | Chat messages, labels, descriptions |
| Body Text (Bengali/Hindi) | Noto Sans | Regular 400 | All Indian languages — single font covers all |

**Fallback stack:** `Noto Sans`, `Noto Sans Bengali`, `Noto Sans Devanagari`, `sans-serif`

---

## 3. Spacing & Sizing (4px grid)

| Token | Pixels |
|-------|--------|
| `xxs` | 4 |
| `xs` | 8 |
| `sm` | 12 |
| `md` | 16 |
| `lg` | 24 |
| `xl` | 32 |
| `xxl` | 48 |
| `xxxl` | 64 |

- **Border radius:** 12px (cards), 20px (sheets), 24px (bottom nav), 50% (avatars)
- **Bottom nav height:** 64px
- **App bar height:** 56px

---

## 4. Visual Language

- **Shapes:** Soft, rounded corners everywhere. Nothing sharp or aggressive.
- **Depth:** Minimal shadows — only `Elevation 1` (2px) for surfaces that need lift.
- **Icons:** Outlined style, Earth Brown by default, Leaf Green when active.
- **Images:** Muted, desaturated photography. No neon or high-contrast imagery.
- **Motion:** Gentle easing curves — `Curves.easeInOutCubic` as default. No bouncy or exaggerated animations.

---

## 5. Component Tokens (Light Theme)

| Component | Background | Text | Border |
|-----------|-----------|------|--------|
| Scaffold | Petal White `#F7F5F0` | — | — |
| Card | Bark Cream `#EDE8DC` | Forest Green `#2E5220` | Sandy Brown `#C4A882` |
| Bottom Nav | Bark Cream `#EDE8DC` | Earth Brown `#7D5A3C` | — |
| Bottom Nav (active) | — | Leaf Green `#5A8A3C` | — |
| Primary Button | Leaf Green `#5A8A3C` | Petal White `#F7F5F0` | — |
| Text Field | Petal White `#F7F5F0` | Forest Green `#2E5220` | Sandy Brown `#C4A882` |
| Link / Info | River Blue `#4A7FA5` | — | — |
| Selection / Highlight | Sky Blue `#B8D4E8` | — | — |
| Error State | — | `#C13B3B` | — |

---

## 6. Dark Mode (Future)

When dark mode is added:
- Invert backgrounds: dark earth tones (`#1A1815` as base)
- Petal White → warm dark gray
- Keep Leaf Green as primary (it glows nicely on dark)
- Reduce contrast on borders

---

## 7. Implementation Notes

- Define all colors in `core/theme/app_colors.dart` as `Color` constants.
- Define text styles in `core/theme/app_text_styles.dart` as `TextStyle` constants using the three font families above.
- Build `AppTheme` in `core/theme/app_theme.dart` as `ThemeData` using `ThemeData.from` with the color scheme.
- Use a `ThemeMode` provider in `core/providers/theme_provider.dart` for light/dark toggling (phase 2).
- All text must use `Noto Sans` for body copy — the font covers Bengali, Hindi, and English with consistent metrics.
