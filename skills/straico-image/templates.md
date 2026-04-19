# Straico Image Templates

Same vocabulary as `pollo-image/templates.md`. Use the same template names (`logo`, `wordmark`, `monogram`, `icon`, `headshot`, `product-shot`, `hero-banner`, `illustration`, `concept-art`, `social-tile`).

See `~/.claude/skills/pollo-image/templates.md` for full template definitions. All templates work identically here — just swap the invocation:
- Pollo: `polloimg "filled prompt" 1:1 2K`
- Straico: `straicoimg "filled prompt" square 1 flux/1.1`

## Template → Straico defaults map

| Template | Straico size | Good models |
|---|---|---|
| logo | `square` | `fal-ai/recraft/v3/text-to-image` (best vector), `flux/1.1`, `fal-ai/ideogram/v3` |
| wordmark | `square` | `fal-ai/ideogram/v3` (best text), `fal-ai/recraft/v3/text-to-image` |
| monogram | `square` | `fal-ai/recraft/v3/text-to-image`, `flux/1.1` |
| icon | `square` | `fal-ai/recraft/v3/text-to-image` |
| headshot | `portrait` | `flux/1.1`, `openai/gpt-image-1`, `fal-ai/imagen4/preview` |
| product-shot | `square` | `flux/1.1`, `fal-ai/imagen4/preview` |
| hero-banner | `landscape` | `flux/1.1`, `fal-ai/imagen4/preview`, `openai/gpt-image-1` |
| illustration | `square` or `landscape` | `flux/1.1`, `openai/dall-e-3` |
| concept-art | `landscape` | `flux/1.1`, `fal-ai/imagen4/preview` |
| social-tile | `square` | `flux/1.1`, `fal-ai/ideogram/v3` |

## Why Straico for images?

- **Cheaper per image** than Pollo's API platform tier (~90–250 coins vs ~18 Pollo credits at higher USD price).
- **Ideogram V3** for text-in-image (logos with readable lettering).
- **Recraft V3** for clean vector-style logos.
- **GPT Image 1 / Imagen 4** for photoreal premium quality.

Use Pollo when you specifically need pollo-image-v2's aesthetic or 4K output.
