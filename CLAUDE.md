# Hotel Sem Saída — instruções para as IAs do projeto

Jogo de enigmas **em primeira pessoa, 3D**, para PC (Windows), feito no **Godot 4.7** por Roberto com o Claude Code e o Codex (GPT). Este arquivo é a **única** fonte de verdade sobre o projeto (o `AGENTS.md` do Codex só aponta para cá): leia-o inteiro antes de qualquer tarefa e atualize-o ao terminar uma etapa.

## Estado atual (08/11/2026)

- **Jogo 3D em primeira pessoa** é o jogo de verdade. O 2D (pixel art) continua no repositório como histórico e referência dos enigmas da Cozinha; não é mais desenvolvido. As seções sobre 2D mais abaixo valem só para os arquivos 2D.
- Cena principal: `scenes/ui/entrada.tscn` (recepção: jogar solo, continuar solo, ou dupla online).
- Salas 3D: `saguao_3d` (hub), `cozinha_3d`, `manutencao_3d`, `biblioteca_3d`, `caldeiras_3d`, `quartos_3d`, `salao_3d` (pasta `scenes/rooms/`).
- Ordem: Saguão → Cozinha → (buraco) manutenção → Biblioteca → Caldeiras → de volta ao Saguão (elevador e bolsa de Marta). Desaparecidos, um por geração: Otília (1923), Caio Ferraz (1951), Marta Siqueira (1979), Tomás (2003).
- O jogo tem começo, meio e fim: depois das Caldeiras, a S4 (cofre e entrada principal) leva ao final desta versão (ver "Volta ao Saguão e final").
- Falta: torre do relógio, cofre com duas fechaduras (ver "Andares de cima" no GDD), áudio, opção de qualidade gráfica; destino de Helena e quebra do ciclo ficam para depois desta versão.

## O jogo em uma frase

O Grand Hotel Aurora existe em duas épocas, 1923 e hoje. O jogador alterna com uma tecla entre **Helena** (1923, hóspede) e **Lia** (hoje, a neta dela). O que Helena faz no passado muda o que Lia encontra no presente.

## Regras de design que o código precisa respeitar

1. **Só o passado altera o presente.** Nunca o contrário. Lia descobre informações; Helena muda o mundo.
2. **As duas personagens não se comunicam.** A única ligação é a consequência física.
3. **Mesma geometria, uma câmera por personagem.** As duas épocas ocupam a mesma planta da sala. O Tab leva aos olhos da outra personagem, onde ela estiver.
4. **Cada personagem fica onde foi deixada.** Trocar de época não move ninguém, e só a personagem ativa passa por uma porta (a outra fica na sala dela).
5. **Sem sistema de dicas.** Enigmas difíceis, resolvidos só com observação.
6. **Co-op.** O input de cada personagem é independente. Já existe a dupla online (dois PCs, cada um com uma época); ver "Dupla online".
7. **O que se vê é o que colide.** Nada que pareça sólido pode ser atravessado, e por onde se passa não pode haver nada (pedido do Roberto).

## Stack e configuração

- **Godot 4** (última versão 4.x estável), edição **padrão** (não a .NET). Roda sem instalação e sem acesso de administrador.
- Linguagem: **GDScript** com tipagem estática (`var speed: float = 80.0`, `func get_move() -> Vector2:`).
- Nomes de código (classes, funções, variáveis, sinais, nós) em inglês, seguindo o estilo do Godot: `snake_case` para funções e variáveis, `PascalCase` para `class_name` e nós. Comentários e textos de interface em português.
- 3D: Forward+ (cai para Compatibility), 3D a 60% com FSR, SSAO e névoa em qualidade baixa (ver "Protótipo 3D"). HUD e telas em close usam a resolução de referência abaixo.
- Estilo de código: tipagem estática, espaço depois de vírgula, linhas até ~120 colunas (dicionários de propriedades longos, uma chave por linha), constantes nomeadas para flags e caminhos.
- (2D, histórico) Resolução de referência: **640×360**. Em `project.godot`: stretch mode `canvas_items` (texto e arte do presente em resolução da janela; ver "Atualização visual"). Filtro de textura padrão: `Nearest`.
- Unidade = pixel. Grade de **16 px**. Personagens têm **24×48 px**.
- Uma `Camera2D` fixa por sala.
- Luzes 2D: `PointLight2D` e `CanvasModulate`.

## Estrutura de pastas

```
res://
  project.godot
  CLAUDE.md
  scenes/
    rooms/           Salas (sala_teste.tscn, cozinha.tscn, saguao.tscn…)
    player/          Cena das personagens
    ui/              HUD, fade
  scripts/
    core/            Autoloads e utilidades
    era/             era.gd, era_manager.gd, era_visibility.gd
    world/           world_state.gd, era_linked_object.gd
    player/          player_motor.gd, character_input.gd, solo_input_router.gd
    interaction/     interactable.gd, prompts
    puzzles/         Lógica de cada enigma, uma pasta por andar
    ui/              hud.gd
  art/placeholders/  (vazio por enquanto; placeholders são feitos com ColorRect)
```

## Arquitetura

- **`Era`** (`scripts/era/era.gd`, `class_name Era`): `enum Id { PAST_1923, PRESENT }`.
- **`EraManager`** (autoload): guarda a época ativa, troca com a ação `switch_era` e emite o sinal `era_changed(new_era)`. Faz uma transição curta (fade de ~0,25 s com um `ColorRect` em `CanvasLayer` e `Tween`) sem mover a câmera.
- **`EraVisibility`**: nó colocado em cada raiz de cenário (`World1923`, `WorldToday`). Ao mudar a época, liga ou desliga `visible`, colisões (`process_mode` ou camadas de colisão) e luzes dos filhos. Não use `queue_free` nem tire do grupo os nós das personagens.
- **`WorldState`** (autoload): dicionário de flags (`String → bool/int`), por exemplo `"cozinha.elevador.travado"`. É a memória do que Helena mudou. Exporta e importa as flags (`to_dict` / `load_dict`) para o `SaveSystem`.
- **`SaveSystem`** (autoload): salva e carrega em `user://save.json` as flags, a época ativa, a sala atual e a posição das duas personagens. Ao carregar, define flags e época e **recarrega a sala do zero**, para que todo objeto leia as flags no `_ready`. Por isso, objetos que dependem de flags devem aplicá-las no `_ready`.
- **`Room`**: script da raiz de cada sala. Declara `camera_mode` e o repassa às personagens.
- **`RoomManager`** (autoload): troca de sala com fade. No 2D, **Helena e Lia mudam de sala juntas** e aparecem num ponto de entrada (`Marker2D` da sala de destino). No 3D, só a ativa passa (ver "Protótipo 3D"). O `SaveSystem` também carrega salas por ele.
- **`Door`**: `Interactable` que leva à sala `target_scene`, no ponto de entrada `target_spawn`. Usa-se com E.
- **Menu de pausa** (`scripts/ui/pause_menu.gd`, dentro de `hud.tscn`): Esc/Start pausa o jogo, com Continuar, Salvar, Carregar e Sair.
- **`Interactable`** aceita `required_flag` (só funciona com a flag ligada) e `done_flag` (para de funcionar quando a flag liga). Subclasses prontas: `Door`, `Passage`, `MessageInteractable`, `NoteInteractable` (abre a tela de leitura `NoteUI`), `CodeLockInteractable` (abre o minigame `CodeLockUI`) e `ItemPickup`.
- **Objeto na mão**: cada personagem segura um objeto por vez, guardado no `WorldState` em `"helena.mao"` / `"lia.mao"` (entra no save). O catálogo fica em `scripts/core/items.gd`. Use `PlayerMotor.get_held_item()` / `set_held_item()`.
- **`EraLinkedObject`** com `update_immediately`: reage na hora à flag (para objetos de 1923, como o cadeado que some ao abrir).
- **Telas em close** (`NoteUI`, `CodeLockUI`, menu de pausa): pausam o jogo e, ao fechar, só despausam depois que E/Enter/Espaço forem soltos (`UIUtil.unpause_after_release`), para a mesma tecla não virar interação ou pulo.
- **Toda sala precisa ter**: `Room` na raiz, `Camera2D`, `World1923` e `WorldToday` (cada um com `EraVisibility`), Helena e Lia (`personagem.tscn`, cada uma com `EraVisibility`), `SoloInputRouter`, `HUD` e um `Marker2D` para cada porta que chega nela. Use `sala_teste.tscn` como modelo.
- **`EraLinkedObject`**: nó do presente que lê flags do `WorldState` e aplica o estado correspondente quando a época vira `PRESENT` (ex.: se `cozinha.elevador.travado`, o poço aparece aberto com os cabos).
- **`Interactable`**: `Area2D` base para objetos com interação (ação `interact`), com um texto de prompt curto e restrição de época (só 1923, só hoje ou ambas).
- **Personagens**: `PlayerMotor` (`CharacterBody2D`, movimento lateral ou de cima, conforme a sala) pede comandos a um `CharacterInput` (classe base com `get_move() -> Vector2`, `is_jump_just_pressed() -> bool`, `is_interact_just_pressed() -> bool`). No modo solo, um `SoloInputRouter` entrega o input só para a personagem da época ativa; a outra recebe input vazio e fica parada. No co-op futuro, cada personagem terá um `CharacterInput` ligado ao próprio dispositivo.
- **Câmera por sala**: cada sala declara seu modo (`SIDE_SCROLLER` ou `TOP_DOWN`); o `PlayerMotor` se adapta (com gravidade ou sem).

## Placeholders (fase de protótipo)

Nada de arte final ainda. Use **blocos coloridos**: `ColorRect` (cenário) ou `Polygon2D` (personagens e objetos). Cores:

| Uso | 1923 | Hoje |
| --- | --- | --- |
| Parede | `#3B1A1F` | `#1C2630` |
| Detalhe/realce | `#C9973B` | `#3A4A58` |
| Piso | `#1F3A2E` | `#3E4A2F` |
| Objeto interativo | `#6B1E2A` | `#6E8596` |
| Personagem | Helena `#6B1E2A` | Lia `#6E8596` |
| Luz | `#F2D49B` | `#E8E2D0` (lanterna) |

## Arte (pixel art)

- As folhas originais ficam em `art/source/` (fundo magenta `#FF00FF`, escala 4x: cada pixel do jogo = 4×4). Foram geradas por IA a partir de prompts com o tamanho exato de cada objeto.
- `tools/slice_sprites.gd` recorta as folhas em `art/sprites/<nome>.png` no tamanho do jogo. Rodar: `Godot_console.exe --headless --path . -s res://tools/slice_sprites.gd` (com `-- --list` só lista as caixas). Os nomes de cada folha ficam na constante `NAMES`, na ordem em que os sprites aparecem.
- Personagens: tira de 5 quadros de 24×48 (`helena.png`, `lia.png`), usada em `PlayerMotor.sprite_sheet`; sem ela, a personagem é um bloco colorido.
- `PlaceholderRoom` aceita `wall_texture`, `detail_texture`, `floor_texture` (repetidas) e `wall_tint` (escurece a parede para os objetos se destacarem).
- Objetos são `TextureRect` com as mesmas coordenadas dos blocos antigos. Salas ainda sem arte continuam com blocos coloridos.

## Controles

Ações do Input Map (em `project.godot`):

| Ação | Teclado | Controle |
| --- | --- | --- |
| `move_left` / `move_right` / `move_up` / `move_down` | A/D (lateral), WASD (de cima) | Analógico esquerdo |
| `jump` (só lateral) | Espaço | A / X |
| `interact` | E | B / Bola |
| `switch_era` | Tab | Y / Triângulo |
| `pause` (abre o menu de pausa) | Esc | Start |
| `quick_save` / `quick_load` (atalhos) | F2 / F3 | — |

## Como trabalhar neste projeto

- Pode escrever e editar diretamente arquivos `.gd`, `.tscn`, `.tres` e `project.godot` (são texto). **Nunca** edite a pasta `.godot/`, arquivos `.import` nem `.uid`; o Godot gera esses sozinho.
- Salas feitas de blocos placeholder: prefira um script de montagem (`@tool` ou `_ready`) que cria os blocos por código, em vez de `.tscn` gigantes escritos à mão.
- Depois de mudar código, **valide você mesmo** rodando o Godot sem janela e confira se há erros na saída:
  `"<caminho do Godot>" --headless --path . --quit`
  O executável fica em `C:\Users\roberto.gabriel\Ferramentas\Godot\` (confirme o nome exato do `.exe` na pasta).
- Trabalhe em **etapas pequenas**. Ao fim de cada etapa, diga exatamente o que Roberto deve fazer no Godot para testar (qual cena abrir, F5/F6, quais teclas usar) e o que ele deve ver.
- Se Roberto encontrar erro na aba **Saída** ou **Depurador** do Godot, ele vai colar o texto aqui.
- Não adicione plugins nem addons sem perguntar antes.
- Salve `.tscn`, `.tres` e `.gd` com quebras de linha **LF**. Com CRLF, o `\r` vira linha em branco extra nos textos de várias linhas das cenas (bilhetes, cardápio).
- Prefira código simples e legível a padrões complexos. Autoloads só para `Settings`, `EraManager`, `WorldState`, `SaveSystem` e `RoomManager` (e algo novo só com motivo claro).
- Antes de decisões de design que não estejam neste arquivo, **pergunte ao Roberto** em vez de decidir sozinho.

## Etapas do protótipo

1. **Base do projeto**: `project.godot` (resolução, escala inteira, filtro `Nearest`, Input Map), pastas e a cena `scenes/rooms/sala_teste.tscn`: sala lateral simples (parede, piso e duas raízes: `World1923` e `WorldToday`), definida como cena principal.
2. **Troca de época**: `EraManager`, `EraVisibility`, fade de transição, HUD mínimo (ícone da personagem ativa + ano).
3. **Duas personagens**: `PlayerMotor` lateral, `CharacterInput`, `SoloInputRouter`; cada uma fica parada quando inativa.
4. **Causa e consequência**: `WorldState`, `Interactable`, `EraLinkedObject` e um enigma de teste: Helena empurra um armário em 1923; hoje, a parede atrás dele está com a marca, e uma passagem aparece.
5. **Câmera de cima**: segundo modo do `PlayerMotor` e uma sala de teste vista de cima (`sala_teste_de_cima.tscn`).
6. **Salvar e carregar** o `WorldState` e a posição das personagens.

Concluída a etapa 6, o protótipo da mecânica central está pronto para o primeiro capítulo (Cozinha).

Infraestrutura feita depois do protótipo:

7. **Troca de sala**: `RoomManager`, `Door` e pontos de entrada; portas ligando `sala_teste` e `sala_teste_de_cima`.
8. **Menu de pausa** no Esc/Start.

## Capítulo 1 — Cozinha (design no `GDD.md`)

Cena `scenes/rooms/cozinha.tscn`: uma tela lateral em corte, com a Cozinha em cima (piso em y=200) e a Despensa embaixo (piso em y=344). `Passage` leva uma só personagem a outro ponto da mesma sala (escada, cabos).

- **C1. Layout**: os dois andares nas duas épocas, a escada de 1923 (Descer/Subir), o forno, o poço do elevador e a prateleira quebrada de hoje (alta demais sem degrau).
- **C2. Despensa trancada**: objeto na mão de Helena, cardápio rasgado nas duas épocas e minigame do cadeado de 4 dígitos.
- **C3. Massa que cresce**: fermento e forno; hoje, o forno petrificado vira degrau até a prateleira.
- **C4. Elevador de serviço**: Helena trava o elevador no alto; hoje, Lia entra pela portinhola e desce pelos cabos.
- **C5. Fogo e gelo**: corrente de ar no piso hoje, gelo de 1923 no ponto certo, piso apodrecido e fim do andar.
  - A geladeira dá gelo sem limite. Helena deixa o bloco 15 px à frente dos pés, onde as mãos o soltam no último quadro da animação (`IceDropZone.REACH`, `PlayerMotor.get_facing()`); só a até 12 px do ponto da fresta (x=376) o piso apodrece. Hoje, uma mancha de água marca onde ficou o último bloco.
  - O fim do andar ainda é provisório (tela "Fim da Cozinha" + flag `cozinha.concluida`): o GDD não define como o jogador percebe o fim de um andar nem para onde vai.

## Saguão (hub) — design no `GDD.md`

Cena `scenes/rooms/saguao.tscn` (cena principal do projeto: o jogo começa aqui), vista de cima, uma tela. `LobbyRoom` (`scripts/puzzles/saguao/lobby_room.gd`, estende `PlaceholderRoom`) monta a mesma geometria nas duas épocas; `present = true` liga a versão em ruínas (lustre caído e sólido no centro, escada em escombros, entrada com tábuas).

- **S1. Sala**: layout simétrico, porta de serviço na parede oeste levando à Cozinha (`Pontos/DoSaguao` em `cozinha.tscn`); entrada sul trancada nas duas épocas. Por enquanto a porta da Cozinha está sempre aberta; a S4 a liga a `saguao.porta_servico.livre`. Teste: `tools/test_saguao.gd` (`-- --capture` sem `--headless` salva capturas na pasta TEMP).
- **Arte nova pedida ao ChatGPT** (03/11/2026): `art/prompts/PROMPTS.md` lista 15 imagens (cenários e objetos do Saguão, folhas de andar de frente, costas e lado da Lia e da Helena). Os guias vêm de `tools/capture_lobby_guides.gd` + `tools/make_art_guides.py`; as imagens chegam em `art/incoming/` (pastas com `.gdignore`, fora da importação do Godot).
- Próximas: **S2** quadro de chaves e elevador, **S3** poço, **S4** cofre, porta com duas trancas e fim da Cozinha voltando ao Saguão.

## Protótipo 3D em primeira pessoa (branch `prototipo-3d`, 04/11/2026)

Pedido do Roberto: manter mecânica e enigmas, mas jogar em primeira pessoa com cenário 3D. Decisões: o Tab leva aos olhos da outra personagem (cada uma continua onde foi deixada; a regra 3 vira "mesma geometria, uma câmera por personagem"); 1923 em low-poly retrô e hoje mais realista; tudo num branch, com o 2D intacto no `main`.

- `FirstPersonMotor` (`scripts/player3d/`): `CharacterBody3D` com câmera nos olhos, mesmo `CharacterInput` do 2D (`get_look()` novo: mouse via `ActionCharacterInput.pending_mouse`, analógico direito pelas ações `look_*`). A câmera da época ativa vira a atual. Mira por `RayCast3D` (alcance 2,4 m) em `Interactable3D` (camada 4); o HUD mostra mira e aviso (`set_first_person`, `show_prompt`).
- `Interactable3D`, `MessageInteractable3D`, `NoteInteractable3D` (`scripts/interaction3d/`): mesmas regras de época e flags do `Interactable` 2D.
- `Room3D` prende o mouse e o solta na pausa. `LobbyRoom3D` monta o Saguão em blocos a partir da planta 2D (32 px = 1 m). Cena `scenes/rooms/saguao_3d.tscn` (principal no branch). Teste `tools/test_saguao_3d.gd`.
- **Visual detalhado (04/11/2026, pedido "bem bonito", e o jogo passa a ser 3D em primeira pessoa):**
  - `HotelBuilder3D` (`scripts/world3d/`): base das salas 3D. `_part`/`_block`/`_cylinder`/`_torus`/`_sphere`/`_extrude` desenham sem colisão; `_solid` cria a colisão invisível pela planta 2D. Ao terminar, `_merge_static_meshes` junta as peças por material (centenas de caixas viram ~40 malhas). `_cast_shadows = false` em peças que têm luz por dentro (lustre).
  - `HotelMaterials`: catálogo por papel ("wallpaper", "floor", "brass", "velvet"...) e época, todos com o shader `shaders/spatial_env_hotel_surface.gdshader` (padrões procedurais em coordenadas do mundo; `age` envelhece 100 anos; `retro` dá o PS1 de 1923: texels grandes, cores reduzidas, vértices presos a uma grade). O shader escreve `POSITION` sempre: sem isso o presente sumia.
  - `EraEnvironment` (no `WorldEnvironment`): 1923 quente com brilho e névoa leve; hoje frio com névoa volumétrica para o luar e a lanterna.
  - Renderizador Forward+ (cai para Compatibility sem Vulkan), 3D a 60% da janela com FSR, SSAO e névoa volumétrica em qualidade baixa: ~35 FPS em 1080p numa Intel UHD 630. Uma opção de qualidade nas Configurações fica para depois.
  - `tools/capture_saguao_3d.gd` tira 5 vistas por época (TEMP). Prévias em `art/previews/saguao3d-*.png`.
- **Cozinha 3D (04/11/2026)**: `scenes/rooms/cozinha_3d.tscn`, mesmos enigmas e flags da Cozinha 2D. `KitchenRoom3D` (`scripts/puzzles/cozinha/`) monta o cenário fixo: Cozinha em cima (piso y = 4,5), Despensa embaixo (y = 0), escada de 1923 com rampa invisível (hoje desabada), poço do elevador atrás da parede leste. O que muda com os enigmas são `KitchenProp3D` (`kind`: porta, massa, forno desabado/petrificado, cabine, cabos, fermento, gelo, fresta, buraco, papéis) dentro de `EraLinked3D`.
  - Novos: `ItemPickup3D`, `ItemUse3D`, `CodeLock3D`, `Passage3D` (percurso por `Marker3D`, sem física; save volta ao ponto de partida), `Door3D`, `ChapterEnd3D`, `ServiceElevator3D`, `IceDrop3D` (zona de proximidade; o gelo cai 0,6 m à frente dos pés, flags `cozinha.gelo.x`/`.z` em metros, tolerância 0,4 m da fresta em (11,75; 3,2), entre os dois pilares) e `IceStain3D`.
  - `Interactable3D.min_feet_height`: a portinhola só funciona com a Lia em cima da prateleira (forno petrificado → prateleira, pulo de 0,76 m). Objeto na mão aparece no canto da tela (`FirstPersonMotor.set_held_item`).
  - Regra pedida pelo Roberto: **o que se vê é o que colide.** Nada que pareça sólido pode ser atravessado, e por onde se passa não pode haver nada. A portinhola tem altura de uma pessoa; a grade sanfonada (sólida) a fecha em 1923 e, hoje, até o elevador ficar travado, quando aparece arrancada no chão. Os percursos pelos cabos não cruzam peças. Tampo do forno petrificado e monte do forno desabado têm a altura exata da colisão.
  - `HotelBuilder3D._is_generated` para em outro `HotelBuilder3D`: sem isso a sala fundia as peças móveis (porta, alavancas, cabine) na malha fixa, e elas não se mexiam nem sumiam.
  - `Room3D` não roda mais com o jogo pausado (as personagens herdavam isso e andavam com bilhete ou cadeado abertos); o mouse é conferido pelo sinal `process_frame`.
  - Porta de serviço do Saguão 3D leva a `DoSaguao`; o buraco do piso e a porta da Cozinha voltam a `Pontos/DaCozinha`. Com `cozinha.concluida`, o livro de hoje mostra o nome de Otília.
  - Teste `tools/test_cozinha_3d.gd` (percurso completo; `-- --capture` sem `--headless` salva 4 vistas). Prévias em `art/previews/cozinha3d-*.png`.
- **Só a ativa passa pela porta (decisão do Roberto, 04/11/2026)**: em 3D, `Door3D` e `ChapterEnd3D` usam `RoomManager.change_room_alone`; a outra fica onde foi deixada, na sala dela (`RoomManager._away`: sala, posição e direção do olhar). O Tab, com a outra em outra sala, abre a sala dela (`switch_to_away`, chamado pelo `EraManager`). O save guarda quem está fora em `"away"`. Cada cena continua com os dois nós de personagem; o da que está fora fica parado (época inativa) até ela voltar. Teste `tools/test_rooms_alone_3d.gd` (preserva o save real).
- Falta: opção de qualidade gráfica.

## Capítulos 3D feitos depois da Cozinha (04–05/11/2026; design no `GDD.md`)

Salas montadas por código com `ChapterRoom3D` (`scripts/world3d/chapter_room_3d.gd`: `make_world`, `area`, `box`, `label`, `marker`, `key_visual`). O cenário fixo de cada sala é um `HotelBuilder3D`; interações, peças móveis e marcadores são criados pelo script de nível.

- **Planta do hotel (05/11/2026, pedido do Roberto)**: Cozinha na ala oeste (porta na parede oeste do Saguão) e Biblioteca na ala nordeste (porta na parede norte, entre o elevador e o canto leste; o poço do elevador aparece como alvenaria no canto sul da Biblioteca). A manutenção fica sob a despensa; dela, um corredor de serviço sai pela parede sul, vira e passa ~21 m sob o Saguão até a escada da Biblioteca (`MaintenanceRoom3D.CORRIDOR_*`). Voltar pelo corredor leva a `DaBiblioteca`, no fim dele.
- **Saguão** (`lobby_routes_3d.gd`, `lobby_lift_puzzle_3d.gd`): porta pública da Biblioteca (em 1923 livre; hoje `KeyDoor3D`, exige a chave de 1951). Quadro de 12 ganchos: Helena tira uma chave por vez (`saguao.quadro.gancho`), a do Bento (nome achado por Lia sob a tinta; "Bento, o ascensorista" no livro de 1923) sobe a cabine (`saguao.elevador.no_alto`); hoje Lia desce pela escada do poço até a bolsa de Marta.
- **Manutenção** (`scripts/puzzles/cozinha/maintenance_*`): o buraco da despensa (`ChapterEnd3D` com `descent`) leva Lia para lá. Chave de 1951 na bancada; relógio de ponto com a ficha de Otília (entradas sem saída).
- **Biblioteca** (`scripts/puzzles/biblioteca/`): 1. volumes trocados aos pares (ordem pelas silhuetas de sol de hoje); 2. cifra de César (carimbo mostra só "A → D") identifica o atlas; **qualquer** livro da mesa pode ser levado e guardado no registro oco (`biblioteca.registro`, 0..4) e retirado de novo; só o atlas recebe as anotações de Caio; 3. Lia lê os algarismos; 4. fechadura `7264` abre o arquivo e a porta das Caldeiras. Solução no `GDD.md`.
- **Caldeiras** (`scripts/puzzles/caldeiras/`): partida com três volantes na ordem dos talhos que Lia vê hoje. A ordem só é conferida no terceiro volante (`caldeiras.pressao.abertos` bitmask, `caldeiras.pressao.erro`); erro rompe a união e alaga o presente; o registro de alimentação rearma. Depois: drenagem (ramais), engrenagens F-2 (Helena guarda as peças no alto, Lia monta), tiragem e caixa de limpeza com o caderno de Tomás.

## Volta ao Saguão e final (06/11/2026; design aprovado no `GDD.md`)

- `GuestBook3D` (`scripts/puzzles/saguao/guest_book_3d.gd`): o livro de hoje acumula um nome por capítulo (Otília, Caio, Marta, Tomás; Helena depois de assinar) e a assinatura úmida fica legível aos poucos. Em 1923, com a trava da entrada solta, Helena assina (`saguao.livro.helena`). Com `jogo.final`, ler o livro hoje liga `jogo.encerrado` ao fechar a leitura.
- `MartaBag3D`: examinar a bolsa no poço também solta a chave miúda (`chave_portaria`, etiqueta PORTARIA; `saguao.chave.marta`) se a mão estiver livre.
- `lobby_exit_puzzle_3d.gd` (instalado por `LobbyRoutes3D`): cofre de 1923 atrás do balcão (`1403`, `saguao.cofre.aberto`, chave `chave_entrada`, `saguao.chave.entrada`); a data está na coroa do lustre caído hoje e a placa de 1921 é a pista falsa. Entrada: Helena solta a trava da porta giratória (`saguao.entrada.trava_1923`), que mesmo assim não gira; Lia abre o cadeado de 1979 (`saguao.entrada.cadeado`). Com as duas, Lia "sai" num clarão e volta ao Saguão de costas para a porta (`jogo.final`); a corrente aparece de novo. Com o Tab (ou na dupla, na hora), Helena ouve três batidas.
- `EndScreen` (`scripts/ui/end_screen.gd`): qualquer `Room3D` a abre quando `jogo.encerrado` liga; espera as telas em close fecharem, salva (solo ou dupla) e volta à recepção.
- O cofre agora tem colisão (antes dava para atravessá-lo atrás do balcão). Teste `tools/test_saguao_final_3d.gd` (preserva o save real).

## Quartos — 2º andar (08/11/2026; design aprovado no `GDD.md`, "Andares de cima")

- Cena `scenes/rooms/quartos_3d.tscn`: `GuestFloorRoom3D` (cenário fixo: corredor, escada principal a oeste, rouparia, 214, 207, poço do elevador a leste no mesmo x do Saguão) e `GuestFloorLevel3D` (enigmas). Helena chega pela escada de 1923 (Saguão: `SubirEscada`, marker `DaEscada`); Lia pela escada do poço (Saguão: `SubirAndar`, exige `saguao.bolsa.marta`; marker `DoPoco`). Voltam a `DoAndar2Escada` / `DoAndar2Poco` no Saguão.
- Q1 cunha do carrinho calça a alavanca (`quartos.pavimento.calcado`): hoje a grade do pavimento abre. Q2 correntinha da bandeira do 207 (`quartos.bandeira.aberta`) + cabide da rouparia hoje abrem o 207 (`quartos.207.aberto`). Q3 diário: `quartos.diario.local` 0 escrivaninha, 1 gaveta, 2 guarda-roupa, 3 fundo falso da mala, 4 na mão de Helena; só na mala Lia o lê hoje (`quartos.diario.lido`). Q4 chave mestra da rouparia escondida atrás do espelho (`quartos.chave_mestra.*`) abre o 214 hoje; o caderno de Caio liga `quartos.concluido` e muda conforme `salao.partitura.guardada`.
- Bolsa de Marta: examinar só lê (o verso aponta o 214); a chave miúda é o `ChaveMiuda` à parte, para Lia não subir com a mão ocupada.
- Teste `tools/test_quartos_3d.gd`. Protocolo da dupla subiu para 4.

## Salão de baile — 3º andar (08/11/2026; design no `GDD.md`, "Andares de cima")

- Cena `scenes/rooms/salao_3d.tscn`: `BallroomRoom3D` (cenário fixo: vestíbulo com a escada principal e o poço nos mesmos x dos Quartos; salão alto com mesas, lustres e palco de 1,2 m; escadinha de 1923 com rampa invisível, que hoje desabou) e `BallroomLevel3D` (enigmas).
- Cabine do elevador principal: `saguao.elevador.andar` (1 = 2º, 2 = 3º, 3 = casa de máquinas, padrão sem a flag). Helena a chama nas botoeiras do 2º (`GuestFloorLevel3D`) e do 3º andar; só funciona com `saguao.elevador.no_alto` (chave de Bento). `ElevatorCab3D` (`scripts/world3d/`) desenha a cabine parada no andar, nas duas épocas, sem colisão. Hoje, nos Quartos, `SubirPoco` só leva Lia ao Salão com a cabine no 2º (sai pelo alçapão do teto). Descer pelo poço sempre dá.
- Helena sobe pela escada de 1923 dos Quartos (`SubirEscada`, lance leste do vão; `DescerEscada` ficou no lance oeste). Markers do Salão: `DaEscada`, `DoPoco`; voltam a `DaEscada` / `DoPoco` dos Quartos.
- Contrapeso: em 1923 a malagueta solta o saco (`salao.contrapeso.solto`); hoje ele é o `MonteDeAreia` (0,6 m) encostado no palco, o degrau para Lia subir pulando.
- Partitura (`partitura` na mão): estante ⇄ mão ⇄ banqueta (`salao.partitura.guardada`, ida e volta). Em 1923 a leitura mostra a pauta desenhada por `ScoreSheet` (`scripts/ui/score_sheet.gd`, imagem gerada por código); hoje, com a partitura guardada, a banqueta mostra os números de Caio (3 · 1 · 5 · 6 a partir da tecla de latão = dó) e liga `salao.partitura.lida` e `salao.concluido`.
- Teste `tools/test_salao_3d.gd`. Protocolo da dupla subiu para 5 (hoje 6); o save da dupla aceita qualquer versão anterior.

## Piano do Saguão (08/11/2026; design no `GDD.md`, "Piano do Saguão")

- `lobby_piano_3d.gd` (instalado por `LobbyRoutes3D`): em 1923, `TocarPiano` abre `PianoUI` (`scripts/ui/piano_ui.gd`: 8 teclas brancas, dó de latão na 1ª, mouse ou 1 a 8; as últimas notas formando a melodia emitem `solved`; errar não faz nada). A valsa `3 · 1 · 5 · 6` liga `saguao.piano.valsa` e abre o painel da parede leste atrás do piano (folha com colisão própria, que gira junto). Hoje: `LonaPiano` mostra a plaquinha de latão; o painel aberto vale para as duas.
- A escada em caracol atrás do painel ainda só dá uma mensagem: a Torre vem na próxima etapa. O vão escuro ainda não tem passagem (a parede continua sólida atrás dele) e precisa virar porta para a Torre.
- Teste `tools/test_piano_saguao_3d.gd`. Protocolo da dupla: 6.

## Sem cutscenes (08/11/2026)

- Pedido do Roberto: **não há cutscenes no jogo, e não faça novas.** O sistema (`Cutscene`, `StoryCutscenes`, `StoryTrigger`, `tools/test_cutscenes.gd`) foi apagado; está no histórico do git (commits de 07–08/11/2026). Saves antigos podem ter flags `cena.*`: não fazem nada.

## Dupla online (05/11/2026)

- `NetSession` (autoload, `scripts/online/net_session.gd`): ENet UDP 7777; o anfitrião escolhe a época e o visitante fica com a outra. Cada máquina simula só a própria personagem; portas, leitura e pausa são locais. Roteiro do Playit em `JOGAR-ONLINE.md`.
- Só as flags mudam pela rede, e só as que `scripts/online/coop_progress.gd` permite para cada época (passado: mecanismos; presente: leituras e progresso). **Toda flag nova de enigma precisa entrar lá**; `tools/test_coop_flags.gd` falha se alguma ficar de fora, e em modo debug o jogo avisa (`push_warning`).
- Save da dupla separado do solo (`user://dupla.save`, só o anfitrião salva). Online, o Tab e o save solo ficam desligados; `EraLinked3D` reage a flags na hora.

## Testes

`tools/test_*.gd`, cada um com `Godot_console.exe --headless --path . --fixed-fps 60 --script res://tools/<teste>.gd`. A dupla online roda em dois processos: `tools/run_dupla_online.sh` (Git Bash). Rodados sozinhos, os testes que precisam de argumentos imprimem `SKIP`.

## Referência

O design completo (história, capítulos, enigmas, minigames) está em **`GDD.md`**, na raiz do projeto. Leia-o antes de trabalhar em qualquer capítulo ou enigma. Em conflito, este CLAUDE.md vale para o código e o GDD vale para o design. Se precisar de algo que não está em nenhum dos dois, pergunte.


## Atualização visual e configurações — 28/10/2026

- Por pedido do Roberto, o passado preserva pixel art e o presente inicia uma direção desenhada mais realista, mantendo o hotel abandonado e tecnologia deteriorada. Não transformar o hotel atual em um hotel funcionando.
- A resolução lógica e as colisões continuam 640x360 e 24x48. O stretch agora é canvas_items: textos e arte de alta resolução são renderizados na resolução da janela, enquanto o passado conserva filtro Nearest.
- Settings é um novo autoload justificado pela persistência entre salas. Preferências ficam em user://settings.cfg, separadas do save: vídeo, volume/mudo, teclas/botões do mouse e zona morta. Mudanças de modo/tamanho de vídeo exigem confirmação em 15 segundos.
- Esc > Configurações abre a tela dividida entre passado e presente. Os prompts exibem o botão de interação realmente configurado.
- As duas paredes discretas de art/source/paredes.png estão integradas em art/sprites/parede_1923.png e parede_hoje.png.
- Arte desenhada do presente em art/future/: fontes ImageGen e recortes. Lia usa drawn_animations (SpriteFrames idle/walk, 1/16 quadros; o idle de 4 quadros tremia, e os quadros foram alinhados pelo tronco com `tools/stabilize_lia_frames.py`, originais em `art/future/raw/`), com pés alinhados e tamanho físico preservado. É uma primeira passagem visual; não declarar a animação finalizada com acabamento cinematográfico.
- Tests: Godot --headless --path . --fixed-fps 60 --script res://tools/test_settings.gd (não grava preferências reais), tools/test_visuals.gd e tools/test_stairway.gd. Com -- --capture nos testes visuais, capturas vão à pasta TEMP.


### Lia — descida pelos cabos (28/10/2026)
- art/future/cables/: 4 quadros de entrada, 12 de descida e 4 de saída, recortes individuais256x384 e folhas separadas em sheets/ com células512x512 e margens amplas. layout.json registra caixas, linha de pegada, pés e hashes. Fontes ImageGen originais preservadas no diretório generated_images do chat.
- CablePassage e PlayerMotor controlam aproximação/entrada/descida/saída, sem teleporte. Pausa e época inativa interrompem a ação; save usa o patamar de origem. Os quadros de cabo mantêm a mesma referência de pés352 e escala48/288.
- tools/test_lia_cables.gd testa o percurso; -- --capture salva capturas em TEMP. A subida pelos cabos mantém o comportamento anterior; este trabalho produz a descida pedida.

### Cenários consolidados —28/10/2026
- Pedido aprovado: dois PNGs completos por época, móveis fixos pintados juntos, papel menor e rasgos claros no presente. art/environment/kitchen_1923.png (640x360,128cores,Nearest) e kitchen_present.png (1920x1080,Linear), ambos enquadrados na geometria lógica640x360. Fontes, guias e prompts.json preservados na mesma pasta.
- RoomArtwork instala os PNGs sob os objetos mutáveis, oculta somente os desenhos antigos dos móveis fixos e os CanvasItems gerados; os corpos/colisões continuam na cena. Porta/cadeado, painéis, cabine, massa/forno do presente, fermento/gelo, fresta/buraco e personagens continuam separados. Stairwell.baked_background evita cobrir a escada pintada com o vão antigo, mantendo a porta aberta dinâmica.
- Cardápio do passado12x16 e papel do presente10x12, silhuetas rasgadas novas. O papel presente foi elevado visualmente para a parede acima da bancada sem alterar a área de leitura. Texto/pistas permanecem na NoteUI. Futuro mantém papel de parede rasgado, manchas e fissuras visíveis independentemente dos estados dos enigmas.
- tools/test_room_artwork.gd valida os dois PNGs, dimensões lógicas, ausência de móveis duplicados, tamanhos dos papéis e estados da porta/forno/elevador. Regressões test_stairway e test_lia_cables passaram. Capturas art/previews/kitchen-complete-*.png.

### Correção de bloqueio ao lado do forno —28/10/2026
- Reproduzido: Lia no intervalo x541..563,y200 ficava presa entre forno e parede, pois a prateleira limitava o pulo a~8px. A prateleira do presente agora é plataforma de colisão só por cima (one_way_block_indices=[2] no PlaceholderRoom). O forno continua sólido; altura e força do pulo não mudaram.
- tools/test_oven_escape.gd confirmou fuga pulando à esquerda a partir de3posições, impossibilidade de alcançar a prateleira diretamente do chão e rota forno→prateleira→portinhola. Regressões escada e cabos passaram. Se um save tiver Lia nesse intervalo, ela consegue escapar depois de carregar a cena corrigida.

### Objetos carregados e interface compacta —28/10/2026
- Helena usa item_animations em art/held/helena_items.tres: fermento/gelo, cada um com4idle+8walk+4use. Quadros48x56 (pés52,cabeça24), alinhamento/escala corporal constantes, folhas espaçadas256px/célula, fontes/manifesto/prompts preservados. O objeto é parte da pose, sem ColorRect flutuante; fallback usa a textura real de Items.texture(). tools/prepare_held_items.py reproduz os recortes.
- PlayerMotor.play_item_use recebe callback; o uso trava movimento/interações por0.5s e executa a consequência ao concluir. Era inativa/pausa congelam o relógio. ItemUseInteractable e IceDropZone só esvaziam a mão e alteram flags no callback; save durante uso ainda guarda o objeto original, sem perder/duplicar. Ao terminar, restaura tira original/offset/escala do sprite.
- Interface compacta: avisos de interação9, HUD/mensagens10, botões11, configurações11(cabeçalho16), bilhetes12, cadeado14/20. Fonte padrão10 para seletores/menus adicionais; renderização canvas_items mantém texto nítido. tools/test_held_items.gd verifica estados/mão/uso/pausa/época e UI; configurações, fuga do forno e cabos também passaram. Previews art/previews/helena-carry-ice.png e helena-use-yeast.png.

## Agentes do Claude Code Game Studios — 03/11/2026

Seleção vinda de [Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios) (MIT, licença em `.claude/CCGS-LICENSE`). Só agentes e referência; os hooks, skills e o fluxo de "estúdio" do template **não** foram instalados.

- `.claude/agents/`: `godot-specialist`, `godot-gdscript-specialist`, `godot-shader-specialist`, `game-designer`, `level-designer`, `narrative-director`, `writer`, `qa-tester`, `ux-designer`.
- `docs/engine-reference/godot/`: referência do Godot 4.5–4.7 (mudanças, APIs obsoletas, boas práticas, módulos). Consulte antes de usar API que possa ter mudado depois do 4.3.
- `.claude/rules/scene-files.md` e `shader-code.md`: regras carregadas ao editar `.tscn`/`.tres`/`.gdshader`.

Os agentes foram escritos para a estrutura do template. Neste projeto vale:

- Não existe `project.yaml`: a engine é Godot 4.7.2 com GDScript (este arquivo). Não existe `production/` nem `design/gdd/`: o design está em `GDD.md`, e este CLAUDE.md vale para código.
- Ignore `production/session-state/active.md`, `/bug-report`, `production/qa/` e outros caminhos do template. Bugs e planos de teste voltam como texto na resposta; testes automatizados ficam em `tools/test_*.gd`.
- As regras deste arquivo (design, estrutura, LF, validação headless, perguntar ao Roberto antes de decisões de design) têm prioridade sobre as instruções dos agentes.
