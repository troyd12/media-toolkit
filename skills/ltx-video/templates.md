# LTX Prompt Templates

LTX wants **one flowing paragraph, in chronological order, under 200 words** — not a tag list.
Every template below is written that way on purpose. Fill the `{slots}` and keep the shape.

The ordering inside each paragraph follows Lightricks' recommended structure: main action first,
then movement detail, then appearance, then environment, then camera, then light and colour,
then any change or event.

---

## establishing-shot
**Use when:** opening a scene, setting a place, landscape or cityscape.

> A {slow push-in / slow drift left} across {location} as {primary motion in the scene, e.g. mist rolls between the buildings}. {Secondary detail: what moves next, and how}. The {key objects} are {precise appearance — material, colour, condition}. In the background, {environment detail}. The camera {holds static / dollies forward slowly / cranes up} at {eye level / low angle}, maintaining {deep focus, everything sharp / a shallow depth of field}. {Lighting: direction, quality, colour temperature}, with {colour palette}. {Optional closing event: as the shot settles, a flock of birds crosses the frame}.

---

## character-action
**Use when:** a person doing something specific. LTX rewards precise, literal gesture description.

> A {shot size, e.g. medium close-up} of {character: age, build, hair, wardrobe — concrete details only} who {main action in one sentence}. {Their} {hands / eyes / posture} {specific secondary movement}. {Facial expression and what it conveys}. Behind {them}, {background description}. The camera {static / slowly pushes in / tracks alongside} at {height}, holding {focus description}. {Lighting} illuminates {what}, casting {shadow quality}. {Change or event: after a brief pause, they turn toward the window}.

---

## dialogue-shot *(LTX-2 audio endpoints only)*
**Use when:** you need a speaking character with synchronized audio.

> A {shot size} of {character description} positioned {where in frame}, looking {where}. {Facial expression}. {They} speak with a {voice description: deep male voice, bright female voice} and a {tone} tone, saying, "{exact line of dialogue}". {Non-speech audio event described in place, e.g. a short audible breath is heard}. {They} continue, "{second line}". The camera remains {static / slowly pushes in}, maintaining {focus description}, with {background} behind {them}. {Lighting and colour}.

**Notes:** put spoken lines in quotes inside the paragraph — that is how the model knows they're
dialogue. Describe audible non-speech events in place, in the order they happen. This only works
on an audio-capable endpoint; on a video-only one the dialogue becomes lip movement with silence.

---

## product-reveal
**Use when:** commercial product shot with motion.

> {Product} rests on {surface} as the camera {slowly orbits right / pushes in}. {First motion: light sweeps across its surface, revealing the texture of the {material}}. The {product} is {precise appearance: colour, finish, proportions, any text or marking}. The background is {description}, softly out of focus. The camera moves {speed and path}, holding the product in sharp focus throughout. {Lighting: key direction, fill, any rim}, producing {highlight and shadow behaviour}. {Closing beat: the light settles and the product comes to rest centered in frame}.

---

## b-roll-texture
**Use when:** atmospheric filler, no subject, meant to sit under a voiceover.

> {Subject matter, e.g. steam rising from a coffee cup} in {setting}. {The motion, described precisely and slowly}. {Material and colour detail of what's in frame}. The camera holds {static / drifts almost imperceptibly}, at {distance and angle}, with {focus description}. {Lighting and colour grade}. The motion continues evenly throughout the shot without any sudden change.

**Note:** the last clause matters. Without it LTX often invents an event partway through, which
makes a clip unusable as a loop or a bed.

---

## logo-motion
**Use when:** animating a mark or wordmark. Consider `image-to-motion` first — it is free and
deterministic, and generative video will redraw your logo rather than preserve it.

> A {logo description: exact shape, colour, proportions} centered on a {background} background. {The motion: the mark holds steady as light sweeps across it from the left}. The edges are {crisp and sharp / softly beveled}, the colour {exact colours}. The camera remains completely static at eye level with the mark filling {proportion} of the frame, in sharp focus throughout. {Lighting}. No text other than the mark itself, and the mark's shape does not change at any point.

**Warning:** generative models redraw logos — letterforms drift and shapes distort. If the mark
must stay exact, use `image-to-motion` on a rendered still instead.

---

## Usage in Claude

1. Match the request to a template, fill the slots, and keep it one paragraph under 200 words.
2. Check it reads chronologically — if a later sentence describes something that happens first,
   reorder it.
3. Strip any tag-style residue (`4k, masterpiece, best quality`). LTX doesn't use it and it
   displaces real description.
4. Call `generate.sh` with the prompt, and pass resolution/duration through `--args` using the
   names from the endpoint's fal API tab.
5. Match resolution and duration when comparing LTX against another model — otherwise you're
   measuring the tier, not the model.
