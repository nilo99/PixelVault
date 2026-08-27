# PixelVault — Gengar Design System

Generated via the `ui-ux-pro-max` skill (color/style/typography domain searches) and implemented as Flutter tokens in `lib/core/theme/`. Dark mode only.

## Palette (`gengar_colors.dart`)

| Token | Hex | Use |
|---|---|---|
| background | `#120B1E` | App scaffold background — deep violet-black, not pure black |
| surface | `#1C1330` | Cards, glass panels (base fill before opacity) |
| surfaceVariant | `#241B3D` | Chips unselected, track backgrounds, elevated surfaces |
| primary | `#7C3AED` | Buttons, active nav item, selected chip, focus ring |
| primaryContainer | `#4C1D95` | Pressed/filled states, primary-tinted backgrounds |
| secondary | `#A78BFA` | Secondary accents, lilac glow highlights |
| accent | `#D946EF` | Mischievous "ghost" highlight — badges, special CTAs, magenta glow |
| error | `#F87171` | Failed downloads, destructive actions |
| success | `#34D399` | Completed downloads |
| warning | `#FBBF24` | Paused/retry states |
| onBackground | `#EDE9FE` | Primary text/icons on dark |
| onBackgroundMuted | `#9C93B8` | Secondary/caption text |
| onPrimary | `#FFFFFF` | Text/icons on filled primary surfaces |
| borderSubtle | `#EDE9FE` @ 8% | Dividers |
| glassBorder | `#FFFFFF` @ 10% | Glass panel borders |
| glowSoft / glowStrong / glowAccent | primary/accent @ 33–50% | Box-shadow glow specs |

## Typography (`gengar_typography.dart`)

- **Display/headings**: Outfit (geometric, rounded — friendly-ghost character), weight 600 for titles.
- **Body/labels**: Inter — chosen for legibility at small sizes (rom list rows, chip labels).
- **Numeric accent**: JetBrains Mono, used standalone (not in TextTheme) for file sizes, download speed, byte counts — `GengarTypography.monoAccent(...)`.

Loaded via `google_fonts` (no bundled font assets needed).

## Tokens (`gengar_tokens.dart`)

- **Radius scale**: sm 8 · md 14 · lg 20 · xl 28 · pill 999
- **Glass blur**: low 12 · mid 18 · high 24 (sigma for `ImageFilter.blur`)
- **Glass opacity**: low 0.45 · mid 0.55 · high 0.68
- **Motion**: fast 150ms / base 200ms / slow 300ms; `easeOutCubic` on enter, `easeInCubic` on exit, `easeOutBack` reserved for one emphasis moment per view (e.g. FAB press) — per UX guidance, animate 1–2 key elements max, continuous animation reserved for loading indicators only.

## Components

| Component | Spec |
|---|---|
| **Bottom nav bar** | `GengarGlassPanel` (blur high), floating with margin from edges, pill/rounded-xl container. Active tab: primary-colored icon+label with soft glow behind icon. Inactive: `onBackgroundMuted`. |
| **Console grid card** (Platform Select) | `GengarGlassPanel` radius lg, console art centered, manufacturer caption below in `bodySmall`/muted. Press feedback: `AnimatedScale` to 0.97 over `durationFast`, no hover states (touch-first). |
| **Rom list tile** | Leading console-color dot/icon, title `titleSmall` (Inter/Outfit mix per theme), tag chips row below, trailing file size in `monoAccent`, trailing download icon button (44×44 min touch target). |
| **Tag filter chip** | Stadium shape, unselected = glass outline (`surfaceVariant` @ low opacity + glassBorder), selected = `primary` fill + soft glow. |
| **Buttons** | Primary = `GengarPrimaryButton` (filled violet + glow shadow, radius md). Secondary = `OutlinedButton` (glass border, no fill). Icon buttons = circular, 44×44 minimum, glass background. |
| **Progress — linear** | Rounded track (`surfaceVariant`), fill `primary`, indeterminate shimmer only while active (loading-state rule). |
| **Progress — ring** | `GengarProgressRing`: circular indicator with glow halo + centered `monoAccent` percentage label. |
| **Search bar** | Pill `InputDecorationTheme`, glass fill, focus state = 1.5px primary border (no layout shift). |
| **Dialogs / bottom sheets** | Glass high-opacity panel, radius lg (dialogs) / xl top corners (sheets). |
| **Snackbar/toast** | Glass `surfaceVariant`, radius md, floating behavior; error/success variants tint via left-edge accent bar (implement per-instance, not themed globally). |

## Accessibility notes

- `onBackground` (#EDE9FE) on `background` (#120B1E) ≈ 13:1 contrast — passes AAA for body text.
- `onBackgroundMuted` (#9C93B8) on `background` ≈ 6.2:1 — passes AA for secondary text.
- All interactive targets sized ≥44×44 per touch-target guideline.
- Motion kept to ease-out/ease-in only; no infinite decorative animation (loaders excepted); `easeOutBack` used sparingly, not on lists.
