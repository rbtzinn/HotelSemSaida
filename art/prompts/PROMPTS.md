# Pacote de prompts para o ChatGPT — Saguão e animações

São 15 imagens: 2 cenários do Saguão, 2 folhas de objetos, 4 folhas da Lia e 7 da Helena. Cada uma tem os anexos, o prompt (em inglês, que o gerador segue melhor) e o nome do arquivo para salvar.

## Como pedir

1. **Uma imagem por mensagem.** Anexe os arquivos listados e cole o prompt inteiro, do bloco de código.
2. **Uma conversa por personagem** (Lia, depois Helena). A partir da segunda folha da mesma personagem, anexe também a primeira folha que ficou boa e acrescente no fim do prompt: `Same character, same size and line style as the attached sheet.`
3. **Salve em `art/incoming/`** com o nome indicado, em PNG. Fundo transparente; se o ChatGPT não der transparência, peça de novo com `flat pure #FF00FF magenta background instead of transparency`.
4. **Confira antes de salvar:**
   - Personagens: 8 quadros na grade 4×2, todos do mesmo tamanho, pés na mesma linha e nada cortado. Se um quadro sair torto, peça de novo só aquela folha.
   - Cenários: o enquadramento e as posições batem com o guia.
5. **Não precisa ficar perfeito no pixel.** Eu recorto, alinho os pés e o tronco, aplico a mesma escala a todos os quadros (a tremedeira de antes vinha de cada quadro ter um tamanho) e reduzo para o tamanho do jogo.

Os anexos ficam em `art/prompts/guides/`. Os guias do Saguão saem do próprio jogo (`tools/capture_lobby_guides.gd` e `tools/make_art_guides.py`). Os quadros de descida pelos cabos da Lia continuam os atuais: por isso a referência dela é o desenho de hoje.

---

## Cenários do Saguão

O guia é o Saguão do jogo numa tela de 1536×1024. O jogo ocupa a faixa y 80–944; acima e abaixo é só margem de parede, que eu corto. Os retângulos **cinza lisos** são vagas de objetos que mudam durante o jogo (elevador, quadro de chaves, cofre, porta da Cozinha): eles vêm separados, nas folhas de objetos.

### M1 — `saguao_1923.png`

Anexos: `guides/saguao_layout_1923.png` (geometria) e `art/environment/kitchen_1923.png` (estilo).

```
Use the FIRST attached image as EXACT GAMEPLAY GEOMETRY and PLACEMENT reference, an edit target for architectural restyling. Use the SECOND attached image only as STYLE reference (same game, same pixel-art language). Output 1536x1024 landscape.

View: classic 16-bit RPG interior seen from above at a 3/4 angle. The floor is seen from above; the back (north) wall is a vertical band seen frontally across the top; west and east walls are thin edges along the sides; the south wall is a thin strip at the bottom. Furniture shows its top and its front face. No vanishing point, no fisheye, no tilted camera.

Keep every element exactly where the reference has it (image pixels):
- North wall band: y 0..234 across the whole width. Walkable floor: x 38..1498, y 234..906. West/east wall edges: x 0..38 and x 1498..1536. South wall: y 906..1024.
- Grand staircase going up out of the top of the image, northwest: x 115..346, y 118..349.
- Reception counter: x 538..998, y 310..387, with an open guest register book on its top at the center (768, 349).
- Four marble columns, footprints at (384, 502), (1152, 502), (384, 810), (1152, 810), about 40 px wide and 96 px tall.
- Round rug under where the chandelier hangs: x 614..922, y 541..694. Do NOT paint the chandelier itself (it is on the ceiling, outside the view).
- Black grand piano, lid closed: x 1200..1410, y 632..752.
- Main entrance: revolving brass door in the south wall, x 691..845, y 906..944.
- The four FLAT GRAY rectangles are reserved slots. Paint them as plain wall surface matching the surrounding wall (the three on the north wall) and as a plain dark recessed doorway with a thin frame (the one on the west edge, x 0..38, y 579..694). No elevator door, no key rack, no safe, no door leaf there: those objects are separate sprites.

1923: the lobby of a working grand art-deco hotel at night. Authentic restrained 16-bit PIXEL ART: deliberate square pixels, dark 1-pixel outlines, limited flat shading, no blur, no smooth gradients. Palette: burgundy #3B1A1F walls, aged brass #C9973B trims, deep green #1F3A2E marble/carpet, dark wood, warm cream accents, warm lamp light #F2D49B pooling from wall sconces. Calm walls with shallow inset panels and wainscot, no busy wallpaper patterns. Patterned floor kept quiet so characters read clearly on it.

No characters, no text, no labels, no UI, no glowing game objects, no extra doors, rooms or stairs. Clear readable silhouettes, generous calm floor space.
```

### M2 — `saguao_present.png`

Anexos: `guides/saguao_layout_present.png` (geometria), `art/environment/kitchen_present.png` (estilo) e, de preferência, o `saguao_1923.png` que já ficou bom (para a mesma arquitetura).

```
Use the FIRST attached image as EXACT GAMEPLAY GEOMETRY and PLACEMENT reference, an edit target for architectural restyling. Use the SECOND attached image only as STYLE reference. If a THIRD image is attached, it is the same lobby in 1923: keep exactly the same architecture, aged 100 years. Output 1536x1024 landscape.

View: classic RPG interior seen from above at a 3/4 angle. Floor seen from above; north wall a vertical band across the top; west/east walls thin edges; south wall a thin strip at the bottom. Furniture shows top and front face. No vanishing point, no fisheye.

Keep every element exactly where the reference has it (image pixels):
- North wall band: y 0..234. Walkable floor: x 38..1498, y 234..906. West/east wall edges: x 0..38 and x 1498..1536. South wall: y 906..1024.
- Collapsed staircase northwest, x 115..346, y 118..349: broken steps and rubble, impossible to climb.
- Reception counter x 538..998, y 310..387, dusty and cracked, with a moldy open guest register at (768, 349).
- Four columns at the same footprints (384, 502), (1152, 502), (384, 810), (1152, 810), stained and chipped.
- The great chandelier has FALLEN onto the middle of the floor: a wrecked heap of bent brass arms, broken crystal drops and its big brass ceiling crown, x 614..922, y 541..694. The crown is on the lower front side of the heap and plainly visible, with an engraved band on it but NO legible letters or numbers.
- Grand piano covered by a dusty tarp: x 1200..1410, y 632..752.
- Main entrance in the south wall, x 691..845, y 906..944: boarded up with planks and a chain.
- The four FLAT GRAY rectangles are reserved slots: paint the three on the north wall as plain damaged wall matching the surroundings, and the one on the west edge (x 0..38, y 579..694) as a plain dark recessed doorway with a thin frame. No elevator door, key rack, safe or door leaf there: those are separate sprites.

Today: the same lobby after 100 years abandoned. REALISTIC HAND-DRAWN 2D adventure-game background, not pixel art, not 3D. Dark blue-gray #1C2630, weathered wood, rust, restrained moss #3E4A2F, cold diffuse light from cracks, dust in the air. Walls physically real: faded striped wallpaper in large calm fields, torn patches showing plaster, damp stains, fine cracks. Moody but readable, not black, floor kept clear enough for characters to read on it.

No characters, no text, no labels, no UI, no glowing objects, no extra doors, rooms or stairs.
```

---

## Objetos que mudam em jogo

Uma grade 4×2 de células 384×512, fundo transparente, **um objeto por célula, centralizado, encostado na linha de baixo da célula**. Os tamanhos estão em pixels da imagem e todos usam a mesma escala (4 px por pixel do jogo); respeite a proporção. Não precisa anexar grade, mas pode anexar `guides/grade_helena.png` para mostrar as células.

### O1 — `objetos_1923.png`

Anexos: `art/environment/kitchen_1923.png` (estilo).

```
A sprite sheet of 8 separate game objects on a fully TRANSPARENT background, arranged in a 4x2 grid of equal 384x512 cells (image 1536x1024). One object per cell, horizontally centered, its bottom edge resting on y=480 of its cell. Every object uses the same scale: 4 image pixels per game pixel. Authentic restrained 16-bit PIXEL ART matching the attached style reference: square pixels, dark 1-pixel outlines, flat shading, no blur. Palette: burgundy #3B1A1F, aged brass #C9973B, deep green #1F3A2E, dark wood, cream. Seen from the front, as mounted on a wall in a 3/4 top-down RPG interior. No text, no letters, no numbers, no shadows outside the objects.

Cells, left to right, top row then bottom row:
1. Art-deco passenger elevator, closed brass scissor gate, the lit cabin visible behind the gate. 208x200 px.
2. The same elevator with the gate closed but NO cabin: dark empty shaft behind the gate, two hanging cables. 208x200 px.
3. Small key board of dark wood with 12 identical brass room keys hanging on 12 hooks (two rows of six), every hook filled. 192x152 px.
4. The same key board with exactly the same layout, but with all 12 hooks EMPTY. 192x152 px.
5. Small black steel manager's safe set into the wall, door closed, brass dial in the middle. 176x168 px.
6. The same safe with its door swung open, dark empty interior. 176x168 px.
7. Elevator call panel: small brass plate with a keyhole and an arrow lamp. 64x96 px.
8. Narrow service door seen edge-on in a side wall, closed, dark wood with brass handle. 64x192 px.
```

### O2 — `objetos_hoje.png`

Anexos: `art/environment/kitchen_present.png` (estilo) e o `objetos_1923.png` (para manter as mesmas formas).

```
A sprite sheet of 8 separate game objects on a fully TRANSPARENT background, arranged in a 4x2 grid of equal 384x512 cells (image 1536x1024). One object per cell, horizontally centered, its bottom edge resting on y=480 of its cell. Every object uses the same scale as the second attached image; keep the same shapes, 100 years older. REALISTIC HAND-DRAWN 2D painting matching the first attached style reference, not pixel art. Dark blue-gray, rust, rotten wood, dust, cold light. Seen from the front, as mounted on a wall in a 3/4 top-down interior. No text, no letters, no numbers, no shadows outside the objects.

Cells, left to right, top row then bottom row:
1. The art-deco elevator 100 years later: rusted bent gate, and the rotten cabin floor sitting low in the doorway, blocking the shaft; a leather strap is caught under the cabin floor. 208x200 px.
2. The same elevator with the doors forced half open and NO cabin: dark open shaft going down, frayed cables. 208x200 px.
3. The key board 100 years later: rotten, all 12 hooks empty, paint peeled under each hook revealing a small blank pale name plate (12 plates, two rows of six, NO writing on them). 192x152 px.
4. The guest-register book lying open, moldy pages, close view seen from above. 192x152 px.
5. The manager's safe 100 years later, rusted, door closed. 176x168 px.
6. The same safe rusted with the door hanging open, empty. 176x168 px.
7. The narrow service door seen edge-on in a side wall, swollen dark wood, with a heavy 1970s padlock and hasp. 64x192 px.
8. The same service door without the padlock, the old lock corroded, door ajar. 64x192 px.
```

---

## Lia (hoje) — desenho realista

Grade: `guides/grade_lia.png`, 4×2 células de 384×512. **Linha vermelha = pés** (y 480). **Linha azul = topo da cabeça** (y 48). **Tracejado = centro do tronco** (x 192). Altura total de 432 px em todos os quadros.

Referência da personagem: `guides/ref_lia.png`. Anexe a grade e a referência em todas as folhas.

### L1 — `lia_lado_andar.png`

```
Animation sprite sheet of the SAME young woman as the attached character reference (same face, ponytail, denim jacket, olive backpack, dark jeans, gray sneakers, flashlight in her right hand). REALISTIC HAND-DRAWN 2D style exactly like the reference, not pixel art, not 3D. Fully TRANSPARENT background.

Use the attached grid as the EXACT layout: 1536x1024, 4 columns x 2 rows of 384x512 cells, one pose per cell, left to right then top to bottom. The guide lines are for placement only: do NOT draw them. In every cell: the supporting foot rests exactly on the red line (y=480), the top of the head is at the blue line (y=48, only a few pixels of natural up/down bob allowed), the torso stays centered on the dashed vertical line. The figure is EXACTLY the same size in all 8 cells: no zoom, no scale change, no shift.

Side view, walking to the RIGHT, a calm investigative walk, 8-frame loop:
1. contact: right leg forward, heel touching, left leg back on its toe; left arm forward.
2. down: weight on the right leg, knee bent, body at its lowest.
3. passing: left leg swings past the straight right leg, body upright.
4. up: right leg pushes off on its toe, body at its highest.
5. contact: left leg forward, heel touching, right leg back; right arm forward.
6. down: weight on the left leg, body lowest.
7. passing: right leg swings past the straight left leg.
8. up: left leg pushes off, body highest; frame 8 leads smoothly back into frame 1.
Arms swing opposite to legs; the flashlight hand swings gently. Consistent lighting from the upper left.
```

### L2 — `lia_frente_andar.png`

```
Animation sprite sheet of the SAME young woman as the attached character reference (same face, ponytail, denim jacket, olive backpack straps, dark jeans, gray sneakers, flashlight in her right hand). REALISTIC HAND-DRAWN 2D style exactly like the reference, not pixel art, not 3D. Fully TRANSPARENT background.

Use the attached grid as the EXACT layout: 1536x1024, 4x2 cells of 384x512, one pose per cell, left to right then top to bottom. Do NOT draw the guide lines. Feet on the red line (y=480), top of head at the blue line (y=48) with only a slight natural bob, body centered on the dashed line, EXACTLY the same size in all cells.

FRONT view: she walks TOWARD the camera, seen from slightly above (camera about 30 degrees high, as in a 3/4 top-down RPG), 8-frame loop:
1. right foot forward and down, left foot back. 2. weight on right, lowest. 3. left foot passing. 4. rising on right toe.
5. left foot forward and down, right foot back. 6. weight on left, lowest. 7. right foot passing. 8. rising on left toe, leading back into 1.
Arms swing opposite to legs, close to the body. Keep the face and outfit identical in every frame.
```

### L3 — `lia_costas_andar.png`

```
Animation sprite sheet of the SAME young woman as the attached character reference (same ponytail, denim jacket, olive backpack, dark jeans, gray sneakers, flashlight in her right hand). REALISTIC HAND-DRAWN 2D style exactly like the reference, not pixel art, not 3D. Fully TRANSPARENT background.

Use the attached grid as the EXACT layout: 1536x1024, 4x2 cells of 384x512, one pose per cell, left to right then top to bottom. Do NOT draw the guide lines. Feet on the red line (y=480), top of head at the blue line (y=48) with only a slight natural bob, body centered on the dashed line, EXACTLY the same size in all cells.

BACK view: she walks AWAY from the camera, seen from slightly above (camera about 30 degrees high), backpack clearly visible, 8-frame loop:
1. right foot forward (away), left foot back toward camera. 2. weight on right, lowest. 3. left foot passing. 4. rising on right toe.
5. left foot forward, right foot back. 6. weight on left, lowest. 7. right foot passing. 8. rising on left toe, leading back into 1.
Arms swing opposite to legs; ponytail sways slightly.
```

### L4 — `lia_parada.png`

```
Sprite sheet of the SAME young woman as the attached character reference, same outfit and flashlight. REALISTIC HAND-DRAWN 2D style exactly like the reference. Fully TRANSPARENT background.

Use the attached grid as the EXACT layout: 1536x1024, 4x2 cells of 384x512, one pose per cell, left to right then top to bottom. Do NOT draw the guide lines. Feet on the red line (y=480), top of head at the blue line (y=48), body centered on the dashed line, EXACTLY the same size in all cells. The two poses of each pair must be nearly identical: only the chest rises a little (breathing); head, feet and outline stay in place.
1. side view facing right, standing still, relaxed, breathing in.
2. same as 1, breathing out (almost no change).
3. front view toward the camera (camera 30 degrees high), standing still, breathing in.
4. same as 3, breathing out.
5. back view away from the camera, standing still, breathing in.
6. same as 5, breathing out.
7. side view facing right, reaching forward with the free left hand at chest height to touch or pick something.
8. front view, crouching slightly and reaching down toward the floor in front of her.
```

---

## Helena (1923) — pixel art 16 bits

Grade: `guides/grade_helena.png`, 4×2 células de 384×512. **Linha vermelha = pés** (y 480). **Linha azul = topo da cabeça** (y 96). Altura de 384 px (48 pixels do jogo, cada um um bloco de 8×8).

Referência: `guides/ref_helena_8x.png` (o sprite atual, ampliado 8×). Anexe a grade e a referência em todas as folhas. Nas de objeto, anexe também `guides/ref_gelo_8x.png` ou `guides/ref_fermento_8x.png`.

Bloco comum de estilo, que já está dentro de cada prompt abaixo:

```
Authentic 16-bit PIXEL ART on a strict grid: every game pixel is an exact 8x8 block of one flat color, so the character is 24 game pixels wide at most and 48 tall (192x384 image pixels). Dark 1-game-pixel outline, limited palette (burgundy #6B1E2A dress, aged brass #C9973B details, warm skin, dark brown bob hair under a burgundy cloche hat with a brass band as in the reference), flat shading, no anti-aliasing, no blur, no gradients.
```

### H1 — `helena_lado_andar.png`

```
Animation sprite sheet of the SAME 1920s woman as the attached reference (Helena: burgundy dress, burgundy cloche hat, dark brown bob). Authentic 16-bit PIXEL ART on a strict grid: every game pixel is an exact 8x8 block of one flat color, so the character is at most 24 game pixels wide and 48 tall (192x384 image pixels). Dark 1-game-pixel outline, limited palette (burgundy #6B1E2A dress, aged brass #C9973B details, warm skin, dark brown bob hair), flat shading, no anti-aliasing, no blur, no gradients. Fully TRANSPARENT background.

Use the attached grid as the EXACT layout: 1536x1024, 4x2 cells of 384x512, one pose per cell, left to right then top to bottom. Do NOT draw the guide lines. Feet on the red line (y=480), top of the hat at the blue line (y=96) with at most one game pixel (8 px) of bob, body centered on the dashed line, EXACTLY the same size in all cells.

Side view walking to the RIGHT, elegant 1920s walk, 8-frame loop:
1. contact: right leg forward, left back. 2. down: weight on right, lowest. 3. passing: left leg passes. 4. up: rising on right toe.
5. contact: left leg forward, right back. 6. down. 7. passing. 8. up, leading back into 1.
Arms swing opposite to legs; dress hem sways slightly.
```

### H2 — `helena_frente_andar.png`

```
Animation sprite sheet of the SAME 1920s woman as the attached reference (Helena: burgundy dress, burgundy cloche hat, dark brown bob). Authentic 16-bit PIXEL ART on a strict grid: every game pixel is an exact 8x8 block of one flat color, character at most 24x48 game pixels (192x384 image pixels). Dark 1-game-pixel outline, limited palette, flat shading, no anti-aliasing, no blur. Fully TRANSPARENT background.

Use the attached grid as the EXACT layout: 1536x1024, 4x2 cells of 384x512, one pose per cell, left to right then top to bottom. Do NOT draw the guide lines. Feet on the red line (y=480), top of the hat at the blue line (y=96), at most 8 px of bob, centered on the dashed line, EXACTLY the same size in all cells.

FRONT view: walking TOWARD the camera, seen from slightly above (3/4 top-down RPG, camera about 30 degrees high), 8-frame loop:
1. right foot forward. 2. weight on right, lowest. 3. left foot passing. 4. rising.
5. left foot forward. 6. weight on left, lowest. 7. right foot passing. 8. rising, leading back into 1.
```

### H3 — `helena_costas_andar.png`

```
Animation sprite sheet of the SAME 1920s woman as the attached reference (Helena: burgundy dress, burgundy cloche hat, dark brown bob). Authentic 16-bit PIXEL ART on a strict grid: every game pixel is an exact 8x8 block of one flat color, character at most 24x48 game pixels (192x384 image pixels). Dark 1-game-pixel outline, limited palette, flat shading, no anti-aliasing, no blur. Fully TRANSPARENT background.

Use the attached grid as the EXACT layout: 1536x1024, 4x2 cells of 384x512, one pose per cell, left to right then top to bottom. Do NOT draw the guide lines. Feet on the red line (y=480), top of the hat at the blue line (y=96), at most 8 px of bob, centered on the dashed line, EXACTLY the same size in all cells.

BACK view: walking AWAY from the camera, seen from slightly above (camera about 30 degrees high), 8-frame loop:
1. right foot forward (away). 2. weight on right, lowest. 3. left foot passing. 4. rising.
5. left foot forward. 6. weight on left, lowest. 7. right foot passing. 8. rising, leading back into 1.
```

### H4 — `helena_parada.png`

```
Sprite sheet of the SAME 1920s woman as the attached reference (Helena). Authentic 16-bit PIXEL ART on a strict grid: every game pixel is an exact 8x8 block of one flat color, character at most 24x48 game pixels (192x384 image pixels). Dark 1-game-pixel outline, limited palette, flat shading, no anti-aliasing, no blur. Fully TRANSPARENT background.

Use the attached grid as the EXACT layout: 1536x1024, 4x2 cells of 384x512, one pose per cell, left to right then top to bottom. Do NOT draw the guide lines. Feet on the red line (y=480), top of the hat at the blue line (y=96), centered on the dashed line, EXACTLY the same size in all cells. In each pair, the second pose differs from the first by ONE game pixel at most (breathing); outline, head and feet stay in place.
1. side view facing right, standing still. 2. same, breathing (one pixel of chest change).
3. front view (camera 30 degrees high), standing still. 4. same, breathing.
5. back view, standing still. 6. same, breathing.
7. side view facing right, reaching forward with one hand at chest height (to take a key from a hook or turn a key in a panel).
8. front view, reaching down toward the floor in front of her.
```

### H5 — `helena_gelo_andar.png`

Anexos extras: `guides/ref_gelo_8x.png`.

```
Animation sprite sheet of the SAME 1920s woman as the first attached reference (Helena) carrying the block of ice from the second attached reference with both hands in front of her waist. Authentic 16-bit PIXEL ART on a strict grid: every game pixel is an exact 8x8 block of one flat color; the woman is at most 24x48 game pixels (192x384 image pixels), the ice block keeps exactly the reference size (12x10 game pixels). Dark 1-game-pixel outline, limited palette, flat shading, no anti-aliasing. Fully TRANSPARENT background.

Use the attached grid as the EXACT layout: 1536x1024, 4x2 cells of 384x512, one pose per cell. Do NOT draw the guide lines. Feet on the red line (y=480), top of the hat at the blue line (y=96), at most 8 px of bob, body centered on the dashed line, EXACTLY the same size in all cells.

Side view walking to the RIGHT carrying the ice, slightly careful steps, 8-frame loop:
1. contact, right leg forward. 2. down. 3. passing. 4. up. 5. contact, left leg forward. 6. down. 7. passing. 8. up, leading back into 1.
The ice stays held in front of her waist in every frame, moving only with the body bob.
```

### H6 — `helena_fermento_andar.png`

Anexos extras: `guides/ref_fermento_8x.png`.

```
Animation sprite sheet of the SAME 1920s woman as the first attached reference (Helena) carrying the small yeast jar from the second attached reference in her right hand, held in front of her at waist height. Authentic 16-bit PIXEL ART on a strict grid: every game pixel is an exact 8x8 block of one flat color; the woman is at most 24x48 game pixels (192x384 image pixels), the jar keeps exactly the reference size (10x12 game pixels). Dark 1-game-pixel outline, limited palette, flat shading, no anti-aliasing. Fully TRANSPARENT background.

Use the attached grid as the EXACT layout: 1536x1024, 4x2 cells of 384x512, one pose per cell. Do NOT draw the guide lines. Feet on the red line (y=480), top of the hat at the blue line (y=96), at most 8 px of bob, body centered on the dashed line, EXACTLY the same size in all cells.

Side view walking to the RIGHT, 8-frame loop:
1. contact, right leg forward. 2. down. 3. passing. 4. up. 5. contact, left leg forward. 6. down. 7. passing. 8. up, leading back into 1.
```

### H7 — `helena_usar.png`

Anexos extras: `guides/ref_gelo_8x.png` e `guides/ref_fermento_8x.png`.

```
Sprite sheet of the SAME 1920s woman as the first attached reference (Helena) using two objects from the other attached references. Authentic 16-bit PIXEL ART on a strict grid: every game pixel is an exact 8x8 block of one flat color; the woman is at most 24x48 game pixels (192x384 image pixels); the ice block (12x10 game pixels) and the yeast jar (10x12 game pixels) keep their reference sizes. Dark 1-game-pixel outline, limited palette, flat shading, no anti-aliasing. Fully TRANSPARENT background.

Use the attached grid as the EXACT layout: 1536x1024, 4x2 cells of 384x512, one pose per cell. Do NOT draw the guide lines. Feet on the red line (y=480), body centered on the dashed line, the same size in all cells. Side view, facing RIGHT.
Top row, putting the ice block on the floor:
1. standing, holding the ice at the waist. 2. bending the knees, ice lowering. 3. crouched, the ice touching the floor about 15 game pixels (120 image px) in front of her feet. 4. standing up again, hands empty, the ice left on the floor exactly where it touched in frame 3.
Bottom row, pouring the yeast into a bowl of dough at counter height in front of her (do not draw the bowl):
5. holding the jar at the waist. 6. lifting the jar forward to chest height. 7. tilting the jar, pouring. 8. lowering the empty hand, jar gone (it stays in the bowl).
```

---

## Depois de gerar

Me avise quando as imagens estiverem em `art/incoming/`. Aí eu:

- recorto as folhas e alinho pés e tronco;
- aplico **uma única escala** por personagem (Lia: 432 px → 48 do jogo; Helena: blocos de 8×8 → 1 pixel);
- monto as animações de lado, frente e costas;
- instalo os cenários e os objetos no Saguão;
- rodo os testes e gero capturas para você conferir.

Se alguma folha sair muito fora da grade, eu digo qual pedir de novo.
