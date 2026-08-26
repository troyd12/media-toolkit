# Image Prompt Templates

Fill in `{subject}` / `{brand}` / `{colors}` — rest is tuned wording that consistently produces clean results on `pollo-image-v2`.

## Sharpness — read this before filling a template

Perceived quality is set by three things, in this order: **resolution**, **what the prompt
asks the model to blur**, and **the aspect ratio you generate at**. Prompt wording will not
rescue a 2K render, and no resolution will rescue a prompt that asks for soft focus.

**Words that instruct blur.** These are legitimate photographic language and the model obeys
them literally. Use them only when you want the blur:

> shallow depth of field · f/1.8 · bokeh · soft focus · dreamy · atmospheric haze · soft light

`cinematic` is the subtle one — it tends to pull in grain, haze and a lifted black point along
with the colour grade.

**Words that ask for crispness:**

> sharp focus · deep focus · tack sharp · crisp edges · high detail · fine detail · everything in focus

**Rules of thumb**

- Anything with **text, a logo, or a UI in it** should be crisp everywhere. Never pair those
  with depth-of-field language.
- Anything that will be **cropped into, zoomed, or animated** later should be crisp, because
  the downstream move magnifies whatever softness is already there.
- **Generate at the aspect ratio you will ship.** Generating 1:1 and cropping to 16:9 discards
  44% of the pixels — the same visible loss as dropping a resolution tier.
- A deliberately shallow portrait is *not* a quality problem. Blur that the user asked for
  reads as depth; blur they didn't ask for reads as a soft image.

## logo
**Use when:** user says "logo for X", "make me a logo".
**Default aspect:** 1:1. **Default res:** 4K.
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
> Cinematic professional headshot of **{subject}**, {age/ethnicity/gender optional}, {wardrobe}, soft directional rim light, shallow depth of field f/1.8, 85mm lens, neutral studio background, color-graded, sharp focus on the eyes, high detail, photorealistic.

**Note:** the shallow depth of field here is intentional — it blurs the *background*, which is
what makes a headshot read as professional. `sharp focus on the eyes` keeps the subject itself
crisp. If the user wants the whole frame sharp (corporate directory, a shot to be cropped
into), replace `shallow depth of field f/1.8` with `deep focus f/8, everything sharp`.

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

**Note:** hero banners usually carry headline text over the negative space, and text over a
soft background reads as a soft image. If text is going on top, drop `shallow depth of field`
and `atmospheric` and add `sharp focus throughout, crisp detail`.

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

When user says any trigger phrase (e.g. *"logo for LAB24"*, *"make a headshot of..."*), pick the matching template, fill slots, and call `generate.sh` with appropriate aspect/resolution (defaults noted above). Honor the global 4K resolution policy in `SKILL.md`, and check the filled prompt against the **Sharpness** section before submitting.
