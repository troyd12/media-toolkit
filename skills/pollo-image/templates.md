# Image Prompt Templates

Fill in `{subject}` / `{brand}` / `{colors}` — rest is tuned wording that consistently produces clean results on `pollo-image-v2`.

## logo
**Use when:** user says "logo for X", "make me a logo".
**Default aspect:** 1:1. **Default res:** 2K.
**Template:**
> Minimalist modern tech logo for **{brand}**. Clean bold geometric sans-serif wordmark, {colors or "electric cyan to deep blue gradient"} on pure white background. {optional: small icon accent to the left — hexagonal node-network / circuit motif}. Centered, symmetric, sharp vector-style edges, flat design, high contrast, professional branding. No extra text or taglines.

## wordmark
**Use when:** plain text logo, no icon.
**Template:**
> Clean modern sans-serif wordmark reading exactly "**{text}**" in bold geometric type. {colors or "deep navy"} on pure white background. Perfect letter-spacing, centered, flat design, razor-sharp vector edges, timeless professional branding.

## monogram
**Use when:** initials-based mark, usually square/badge.
**Default aspect:** 1:1.
**Template:**
> Geometric monogram mark for "**{initials}**" enclosed in a rounded square / circle badge, {colors or "cyan-to-blue gradient"} with subtle circuit-line accents. Pure white background, centered, symmetric, flat vector style, sharp edges.

## icon
**Use when:** single glyph / app icon, no text.
**Template:**
> Minimal flat vector app icon depicting **{concept}**, {colors or "cyan and deep blue"}, enclosed in a rounded square, centered, symmetric, sharp geometric edges, no text, iOS-style depth with subtle shadow.

## headshot
**Use when:** portrait, professional/cinematic.
**Default aspect:** 2:3 or 3:4.
**Template:**
> Cinematic professional headshot of **{subject}**, {age/ethnicity/gender optional}, {wardrobe}, soft directional rim light, shallow depth of field f/1.8, 85mm lens, neutral studio background, color-graded, high detail, photorealistic.

## product-shot
**Use when:** catalog/e-commerce photo.
**Default aspect:** 1:1 or 4:3.
**Template:**
> Clean studio product photograph of **{product}**, centered, soft even lighting, seamless white background, subtle contact shadow, commercial photography quality, high detail, 4K commercial advertising style.

## hero-banner
**Use when:** website/landing hero image.
**Default aspect:** 16:9.
**Template:**
> Cinematic wide hero banner image: **{scene}**. Cinematic lighting, atmospheric, shallow depth of field, rich color grade, negative space on {left/right/center} for text overlay, 16:9, photorealistic.

## illustration
**Use when:** friendly flat illustration for web/app.
**Template:**
> Flat vector illustration of **{subject}**, pastel palette, clean geometric shapes, soft curves, minimal details, centered composition, modern editorial style, pure white or light-tinted background.

## concept-art
**Use when:** imaginative / sci-fi / fantasy scene.
**Default aspect:** 16:9.
**Template:**
> Cinematic concept art of **{scene}**, dramatic lighting, rich atmosphere, detailed environment, film still aesthetic, color-graded, 16:9, in the style of {optional: Blade Runner / Studio Ghibli / Moebius}.

## social-tile
**Use when:** square social-media graphic with space for text.
**Default aspect:** 1:1.
**Template:**
> Clean social media graphic tile: **{theme}**, bold simple composition, generous negative space for text overlay, {colors}, flat design or minimal photo, eye-catching at small sizes, 1:1.

---

## Usage in Claude

When user says any trigger phrase (e.g. *"logo for LAB24"*, *"make a headshot of..."*), pick the matching template, fill slots, and call `generate.sh` with appropriate aspect/resolution (defaults noted above). Honor the global 2K resolution policy.
