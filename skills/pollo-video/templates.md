# Video Prompt Templates

Fill in `{subject}` / `{action}` / `{scene}`. Rest is tuned wording for Seedance / Kling / Veo.

**Model tips:** Seedance 2.0 is best for realism/cinematic. Kling v2-6 is strong at character motion. Veo 3.1 is best for physics/complex scenes. Default model: `seedance-2-0`.

## cinematic-clip
**Use when:** single cinematic shot, film-like.
**Default:** 5s, 16:9, 480p, seedance-2-0.
**Template:**
> Cinematic {wide | medium | close-up} shot: **{subject}** **{action}** in **{location}**. {time of day: golden hour / blue hour / overcast}. Shallow depth of field, 35mm anamorphic lens, slow {push-in / dolly / crane} camera move, rich color grade, atmospheric lighting, film-still aesthetic, photorealistic.

## product-demo
**Use when:** rotating / reveal shot of a product.
**Default:** 5s, 1:1 or 16:9, 720p, seedance-pro-1-5.
**Template:**
> Clean studio product video of **{product}**, smooth 360° rotation on a reflective surface, soft diffused studio lighting, seamless {white / gradient} backdrop, subtle contact shadow, commercial photography quality, 4K ad aesthetic.

## portrait-loop
**Use when:** talking-head portrait, subtle motion, loopable.
**Default:** 5s, 9:16 (vertical) or 2:3, 480p, seedance-pro-1-5.
**Template:**
> Medium portrait of **{subject}**, {wardrobe}, subtle natural motion — gentle breathing, slight head turn, blink. Soft rim lighting, shallow f/1.8, neutral background, color-graded, photorealistic, seamlessly loopable.

## b-roll
**Use when:** atmospheric background footage.
**Default:** 5s, 16:9, 480p.
**Template:**
> Atmospheric b-roll footage: **{scene}**. {weather/mood}. Slow smooth camera drift, no people or minimal background figures, cinematic color grade, negative space for graphics overlay, 16:9, photorealistic.

## motion-graphic
**Use when:** abstract/animated logo reveal or kinetic type.
**Default:** 5s, 16:9, 480p.
**Template:**
> Abstract motion graphic animation: **{element}** with smooth geometric transitions, {colors}, clean minimalist composition, soft particle effects, centered, symmetric, kinetic energy, designed for a brand intro / logo reveal.

## explainer-shot
**Use when:** diagram / data viz / explainer style.
**Default:** 5s, 16:9, 720p if available.
**Template:**
> Clean explainer-video shot: **{concept}** visualized as animated {isometric / flat / schematic} graphics, bright readable palette, clear hierarchy, smooth motion, neutral background, suitable for educational narration overlay.

## aerial
**Use when:** drone / aerial / overhead view.
**Default:** 5s, 16:9, 480p.
**Template:**
> Aerial drone footage of **{location}**, smooth forward flight / slow orbit at medium altitude, {time of day}, cinematic grade, natural lighting, wide landscape view, 16:9, photorealistic.

## action
**Use when:** dynamic movement / sports / vehicles.
**Default:** 5s, 16:9, 480p, kling-v2-6 or veo3-1 for better physics.
**Template:**
> Dynamic action shot: **{subject}** **{fast action}** in **{environment}**, motion blur on fast elements, low shutter speed, {weather}, cinematic color grade, handheld / tracking camera, photorealistic, 16:9.

---

## Usage in Claude

When user says a trigger phrase (e.g. *"5 second product demo of..."*, *"cinematic clip of..."*), pick the matching template, fill slots, surface cost (credits) briefly, then call `generate.sh`. Honor allowed duration/resolution combos per model — if user's request violates them, pick the closest valid combo and note the substitution.
