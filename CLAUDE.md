# Hotel Sem Saída — instruções para as IAs do projeto

Jogo de enigmas **em primeira pessoa, 3D**, para PC (Windows), feito no **Godot 4.7** por Roberto com o Claude Code e o Codex (GPT). Este arquivo é a **única** fonte de verdade sobre o projeto (o `AGENTS.md` do Codex só aponta para cá): leia-o inteiro antes de qualquer tarefa e atualize-o ao terminar uma etapa.

## Estado atual (08/11/2026)

- **Jogo 3D em primeira pessoa** é o jogo de verdade. O 2D (pixel art) continua no repositório como histórico e referência dos enigmas da Cozinha; não é mais desenvolvido. As seções sobre 2D mais abaixo valem só para os arquivos 2D.
- Cena principal: `scenes/ui/entrada.tscn` (recepção: jogar solo, continuar solo, ou dupla online).
- Salas 3D: `saguao_3d` (hub), `cozinha_3d`, `manutencao_3d`, `biblioteca_3d`, `caldeiras_3d`, `quartos_3d`, `salao_3d`, `torre_3d` (pasta `scenes/rooms/`).
- Ordem: Saguão → Cozinha → (buraco) manutenção → Biblioteca → Caldeiras → de volta ao Saguão (elevador e bolsa de Marta). Desaparecidos, um por geração: Otília (1923), Caio Ferraz (1951), Marta Siqueira (1979), Tomás (2003).
- O jogo tem começo, meio e fim: depois das Caldeiras, a S4 (cofre e entrada principal) leva ao final desta versão (ver "Volta ao Saguão e final").
- Falta: uma partida inteira em dupla pela sala por código com outra pessoa (o plugin e as chaves já funcionam, ver "Dupla online"), modelos do Blender nas peças dos enigmas (volantes, engrenagens) e testes de uma partida inteira por pessoas; destino de Helena e quebra do ciclo ficam para depois desta versão.

## O jogo em uma frase

O Grand Hotel Aurora existe em duas épocas, 1923 e hoje. O jogador alterna com uma tecla entre **Helena** (1923, hóspede) e **Lia** (hoje, a bisneta dela). O que Helena faz no passado muda o que Lia encontra no presente.

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
- **Tela de carregamento** (`LoadingScreen`, `scripts/ui/loading_screen.gd`, pedido do Roberto em 09/11/2026): toda troca de cena passa por `RoomManager.open_scene(caminho, on_open)`, nunca por `change_scene_to_file`. Ela mostra o sol da recepção girando, o nome da sala (`LoadingScreen.NAMES`) e a barra do carregamento em segundo plano (`ResourceLoader.load_threaded_request`); na montagem da sala o jogo trava um instante, mas a tela continua dizendo "Carregando". Some dois quadros depois de a sala abrir (shaders). `is_changing()` vale durante o carregamento.
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
- Prefira código simples e legível a padrões complexos. Autoloads só para `PatchLoader` (o primeiro da lista), `Settings`, `EraManager`, `WorldState`, `SaveSystem`, `RoomManager`, `NetSession` e `Audio` (e algo novo só com motivo claro).
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
- O cofre agora tem colisão (antes dava para atravessá-lo atrás do balcão).
- **Cofre com duas fechaduras (08/11/2026)**: além do `1403`, a chave do gerente (da Torre) na fechadura de baixo, em qualquer ordem. Girada, a chave fica nela (`saguao.cofre.chave`); o 1403 sem a chave deixa o disco travado no número (`saguao.cofre.segredo`). Com as duas, liga `saguao.cofre.aberto`. Hoje, `CofreHoje` mostra as duas fechaduras, a chave presa se Helena a girou, e o cofre aberto e vazio (`PortaCofreHoje`) se ela o abriu. O cofre fica na parede norte entre o balcão e o elevador (`LobbyRoom3D.SAFE`, x 14,1), com dobradiça à direita: aberta (90° em 1923, 112° hoje), a porta não bate no balcão e tem colisão própria, desligada quando fechada. O relógio de carrilhão foi para trás do balcão (x 12,2); hoje está tombado de lado ao longo da parede. Em 1923 ele marca 11h40 (modelo `relogio_carrilhao_1923`, a hora da torre antes de Helena mexer); hoje, 3h07. Uma luz baixa ilumina o cofre em 1923. Teste `tools/test_saguao_final_3d.gd` (preserva o save real).

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
- Teste `tools/test_salao_3d.gd`. Protocolo da dupla subiu para 5 (hoje 7); o save da dupla aceita qualquer versão anterior.

## Piano do Saguão (08/11/2026; design no `GDD.md`, "Piano do Saguão")

- `lobby_piano_3d.gd` (instalado por `LobbyRoutes3D`): em 1923, `TocarPiano` abre `PianoUI` (`scripts/ui/piano_ui.gd`: 8 teclas brancas, dó de latão na 1ª, mouse ou 1 a 8; as últimas notas formando a melodia emitem `solved`; errar não faz nada). A valsa `3 · 1 · 5 · 6` liga `saguao.piano.valsa` e abre o painel da parede leste atrás do piano (folha com colisão própria, que gira junto). Hoje: `LonaPiano` mostra a plaquinha de latão; o painel aberto vale para as duas.
- Com o painel aberto, "Subir a escada em caracol" leva à Torre (`DaEscada`); de lá volta a `DaTorre`, na frente do painel. O vão é só a entrada visual (a parede atrás é sólida; a passagem é pela interação).
- Teste `tools/test_piano_saguao_3d.gd`.

## Telhado e torre do relógio (08/11/2026; design no `GDD.md`, "Andares de cima")

- Cena `scenes/rooms/torre_3d.tscn`: `TowerRoom3D` (casinha da escada, terraço da frente com a caixa d'água, vão do telhado com parapeitos, terraço e torre com mecanismo, mostradores e caixa do pêndulo) e `TowerLevel3D`.
- Passarelas: em 1923 as duas firmes; hoje dependem de `torre.registro.fechado` (oeste firme / leste caída; sem o registro, as duas podres). Podre ou caída: tábuas quebradas sólidas nas duas pontas, sem piso no meio. Cada estado é um nó com as próprias colisões (`_set_solid`).
- Relógio: `torre.ponteiros` (0..719 minutos, 0 = 12h00). Sem a flag, 1923 marca 11h40 e hoje 3h07. `ClockUI` (`scripts/ui/clock_ui.gd`) gira os minutos e as horas juntos; confirmar em 3h07 liga `torre.pendulo.aberto` (fica aberta). Na caixa, Helena pega `chave_gerente` (`torre.chave.gerente`); hoje Lia lê os nomes riscados (`torre.concluida`).
- `EraEnvironment.outdoor` (ligado na Torre): fundo e névoa de noite azulada nas duas épocas; sem isso a névoa marrom dos salões tingia o céu de 1923.
- Teste `tools/test_torre_3d.gd`. Protocolo da dupla: 7.

## Visual: sem cintilação e com qualidade gráfica (08/11/2026)

- Pedido do Roberto: deixar o jogo leve e bem mais bonito, sem texturas piscando. Etapas: 1) cintilação e qualidade; 2) texturas CC0 (Poly Haven / ambientCG); 3) modelos feitos por script no Blender (`tools/blender/`).
- 1923 não tem mais o estilo PS1 (`retro` desligado em `HotelMaterials`): a diferença entre épocas fica na luz, nas cores e no estado do hotel.
- `CoplanarFix` (`scripts/world3d/coplanar_fix.gd`): faces de materiais diferentes no mesmo plano (z-fighting) são separadas ao montar a sala; a menor fica 2 mm por cima. `HotelBuilder3D` corrige as próprias peças antes de juntar as malhas e guarda `surface_boxes`; `ChapterRoom3D._fix_surfaces` corrige as peças do nível contra elas. Ao escrever peças novas, não precisa compensar à mão. Teste `tools/test_coplanar.gd`.
- Texturas CC0 do Poly Haven em `art/textures/` (créditos em `art/textures/CREDITOS.md`): `HotelMaterials.DETAIL` liga cada papel a uma textura (modo 0: a textura vira a cor, tingida para a média dela bater com a cor do papel na época; modo 1: só o brilho dela modula o padrão procedural, no mármore xadrez, metais e lonas). O shader projeta pelo plano da face, com normal map e rugosidade. As importadas vêm sem mipmaps, então `HotelMaterials._texture` gera os mipmaps ao carregar (não edite os `.import`). Papel de parede, tapete, quadros e peças lisas continuam procedurais.
- Modelos do Blender em `art/models/` (piano de cauda, lustre, cadeira de café, mesa redonda), gerados por `tools/blender/make_props.py` (roda com `blender --background --python` ou com o pacote `bpy` do pip; Roberto não precisa abrir o Blender). O script junta as peças por material e dá a cada objeto o nome de um papel de `HotelMaterials`; `HotelBuilder3D._model(path, posição, rotação, escala)` troca pelo material da época e as peças entram na junção de malhas da sala. A colisão continua sendo `_solid`. Saguão, Salão e Quartos: piano de cauda, lustres, cadeira de café, mesa redonda, sofá, poltrona, relógio de carrilhão, cama, guarda-roupa, escrivaninha e baú. Biblioteca: estantes (três tamanhos, com versão `_hoje` de livros faltando e tombados), mesa de leitura, cadeira, luminária de banco e lustre. Caldeiras: caldeira rebitada e luminária industrial. Cozinha: fogão a lenha, geladeira de gelo, portas da bancada e estante da despensa. Torre: mecanismo do relógio (engrenagens dentadas, escape; o mostrador de acerto continua da sala). Manutenção: bancada com morsa, armários de ferramentas e aquecedor de água. Portas: folhas almofadadas `porta_<largura>x<altura>` (cm), dupla e vaivém, também nas folhas que giram do 207 e do 214. `python tools/blender/make_props.py -- <nomes>` gera só alguns. Níveis usam `ChapterRoom3D.model` (mesmo `HotelBuilder3D.load_model`). Atenção: no script, `cylinder(axis="x"/"z")` cresce para -x/-z a partir da base. `_model` aceita `roles` (troca de papéis, ex.: madeira velha e panos com pó hoje) e `parent` (um grupo, como a poltrona tombada).
- Qualidade gráfica nas Configurações (`Settings.data.quality`: 0 Baixa, 1 Média, 2 Alta): escala 3D 60/77/100% (FSR com nitidez 0,6; a nitidez 1,0 fazia os padrões cintilarem), MSAA 2x só na Alta, sombras 1024/2048/4096, SSAO e névoa volumétrica só a partir da Média (na Baixa, névoa comum). `EraEnvironment` remonta os ambientes quando a qualidade muda.

## Passe de luz, textura e detalhe (09/11/2026)

- Pedido do Roberto depois de uma revisão visual com capturas de todas as salas (ele deixou as decisões de objetos e layout com o Claude, sem mexer em enigmas).
- **Lanterna da Lia** (`FirstPersonMotor._add_flashlight`): três luzes na câmera. `Lanterna` (miolo com sombra, pouca energia e `spot_attenuation` 0,5: de perto a parede não estoura em branco, que era o que deixava só um disco de borda dura), `LanternaHalo` (cone largo e fraco) e `LanternaResto` (omni de 4,5 m para o que está ao lado dela).
- **Luz de 1923**: `HotelBuilder3D._wall_lamp(at, yaw, energia, alcance)` desenha a arandela (hoje sobra a ferragem, sem luz) e `_door_light(at, yaw)` põe uma luz baixa na frente de uma porta. Usadas no corredor dos Quartos (`LAMPS_NORTH`/`LAMPS_SOUTH`), no vestíbulo do Salão, acima das estantes laterais da Biblioteca, na casinha da Torre e nas portas do Saguão, da Biblioteca e da Cozinha. Lâmpadas (`bulb`) emitem 2,6 em vez de 4 e o brilho de 1923 baixou; a luz dos pendentes da Cozinha fica abaixo da cúpula.
- **Rachaduras** (shader): só reboco, azulejo e mármore racham por inteiro, o papel de parede de leve; madeira, metal e pano não. O traço é fino, entortado pelo ruído da poeira, e ao longe engrossa e clareia em vez de cintilar (`CRACK_*`). Madeira velha ganha veios gastos.
- **Um papel de parede por andar**: `wallpaper` (losango vinho: Saguão, Biblioteca, Torre), `wallpaper_rooms` (flor, verde: Quartos) e `wallpaper_ballroom` (leque, azul-noite: Salão). O desenho vem de `wallpaper_motif` no shader, escolhido em `HotelMaterials.WALLPAPER_MOTIF`.
- **Letreiros**: `art/fonts/sign_font.tres` usa a Federo (OFL, `art/fonts/CREDITOS.md`) com a fonte do sistema de reserva. Ela não é MSDF, então `ChapterRoom3D.label` desenha com o dobro de pontos. `HotelBuilder3D._plaque(...)` (mesmos argumentos de `_label`) põe a placa de laca com filete de latão atrás das letras.
- **Céu** (`shaders/sky_env_night.gdshader`, ligado por `EraEnvironment.outdoor`): lua, halo e estrelas; a lua fica na direção do facho de luar da Torre. A névoa não cobre o céu. `TowerRoom3D._build_sky` cerca o telhado de prédios com janelas acesas.
- **Objetos novos** (o que fica à altura do corpo é sólido): Cozinha, quadro de campainhas `CHAMADAS` na parede da escada e prateleira de temperos na parede sul; corredor de serviço (`MaintenanceRoom3D._build_corridor_dressing`), pilastras e vigas (`CORRIDOR_RIBS`), barra pintada, estação de válvulas, baldes de areia e caixotes, sempre encostados nas paredes; Saguão, palmeiras com nervura e folíolos (`_frond`).
- **Segunda leva (10/11/2026)**: Cozinha com móveis de trabalho que quebram o corredor sem mexer nos enigmas (`_build_work_furniture`: cepo de açougue `BUTCHER_BLOCK` com grade de panelas no teto, aparador, guarda-louça e barril com sacas; todos sólidos) e pendentes de cúpula escura com a luz 0,9 m abaixo. Salão: ribalta na beira do palco (`FOOTLIGHTS`, com vãos na escadinha e no monte de areia: a calha é sólida e sem os vãos ninguém subia ao palco), arandelas `_wall_lamp` nas laterais e mais energia nos lustres. O papel `night` (fundo das janelas) virou `shaders/spatial_env_night_window.gdshader`, com degradê e estrelas. Os veios do mármore se apagam com a idade (`AGED_VEINS`).
- **Terceira leva (10/11/2026)**: rasgos do papel de parede com borda picotada, tira clara de papel descolado e ripas onde o reboco caiu (`TEAR_*`, `LATH_*` no shader; antes eram manchas cinzas lisas). Quartos 207 e 214: cortinas, quadro (`GuestFloorRoom3D._picture`), arandela, e no 214 uma janela e passadeira. Torre por dentro: papel nas quatro paredes com lambri, arandelas e `_build_tower_fittings` (prateleira de almotolias, caixote, escada de mão e pesos de reserva; sólidos e sem letreiros, para não parecerem pista).
- Para conferir o visual sem placa de vídeo (nuvem/CI): `xvfb-run` com o Godot e `mesa-vulkan-drivers` (lavapipe) roda o Forward+ por software, ~1 min por sala em 1280×720.

## Áudio (08/11/2026)

- Autoload `Audio` (`scripts/core/audio.gd`), justificado porque os ambientes continuam tocando entre as salas. Camadas em loop: `jazz` e `burburinho` (1923), `vento` e `goteiras` (hoje), `tique` (Torre, nas duas). `Audio.ROOMS` dá o volume de cada camada por cena (nome do `.tscn`); ao trocar de sala, os volumes mudam com fade. A troca de época toca `troca_epoca` e distorce o bus `Ambiente` por meio segundo (pedido do GDD).
- Efeitos: `Audio.play("nome")` / `play_one_of("passo", 6)` tocam `art/audio/efeitos/<nome>.ogg` no bus `Efeitos`. `Interactable3D.sound` (vazio = `_default_sound()` da classe: clique em ações, página em leituras, porta em `Door3D`, chave/pegar em `ItemPickup3D`, nada em mensagens); `_on_interact` pode trocar `pending_sound` (porta trancada, destrancar). Também tocam: passos da personagem ativa (`FirstPersonMotor._footsteps`, a cada 0,7 m), dígitos e acerto do cadeado, teclas do piano, ponteiros e corda do relógio, batidas na porta do final.
- Sons CC0 do OpenGameArt (créditos em `art/audio/CREDITOS.md`), preparados por `tools/prepare_audio.py` (ffmpeg + numpy: cortes, filtros, loops sem emenda). O piano é sintetizado no mesmo script (não havia notas soltas CC0).
- **Volume da música (09/11/2026)**: o jazz de 1923 toca no bus `Musica`, que manda para o `Ambiente` (e pega a distorção da troca de época). Configurações > Áudio > "Música (jazz de 1923)" (`Settings.data.music`, aplicado por `Settings.apply_music()`; o `Audio` cria o bus e o aplica ao começar).
- Fechar o jogo passa por `Audio.quit()` (menu "Sair" e o X da janela): cala os sons e só sai depois de dois quadros, senão o Godot acusa recursos presos. O volume e o mudo continuam nas Configurações (bus Master).
- Teste `tools/test_audio.gd`: todo som citado no código existe, toda sala tem perfil e as camadas seguem a época.

## Abertura cinematográfica (13/11/2026)

- Roberto aprovou uma abertura de 22 s para partidas novas. Sai da câmera da Helena no Saguão de 1923, sobe até a janela e corta para um voo 3D sobre a fachada e a Torre. O mesmo enquadramento passa para hoje, o jazz e o burburinho dão lugar ao vento, e aparece “O que Helena muda em 1923, Lia encontra hoje.” A câmera desce e devolve a visão à personagem da partida.
- `scripts/ui/opening.gd` roda no Saguão a partir de Jogar solo ou Novo jogo na dupla. Cada tela pode pular com Esc/Start ou pelo botão, e retoma na própria personagem. A sequência muda só a apresentação local e não grava flags ou troca a época da partida. Continuar e Retomar save abrem diretamente no jogo.
- `scripts/world3d/opening_exterior_3d.gd` usa `HotelBuilder3D` para montar a fachada nas duas épocas. O sistema antigo de cutscenes de capítulo continua no histórico de 07–08/11/2026. Testes: `tools/test_opening.gd` e `tools/test_dupla_online.gd`.

## Dupla online (05/11/2026)

- `NetSession` (autoload, `scripts/online/net_session.gd`): ENet UDP 7777; o anfitrião escolhe a época e o visitante fica com a outra. Cada máquina simula só a própria personagem; portas, leitura e pausa são locais. Roteiro do Playit em `JOGAR-ONLINE.md`.
- Só as flags mudam pela rede, e só as que `scripts/online/coop_progress.gd` permite para cada época (passado: mecanismos; presente: leituras e progresso). **Toda flag nova de enigma precisa entrar lá**; `tools/test_coop_flags.gd` falha se alguma ficar de fora, e em modo debug o jogo avisa (`push_warning`).
- Save da dupla separado do solo (`user://dupla.save`, só o anfitrião salva). Online, o Tab e o save solo ficam desligados; `EraLinked3D` reage a flags na hora.
- **Sala por código (08/11/2026, pedido do Roberto)**: `NetSession.host_room(era)` / `join_room(código)` abrem a sala pelo Epic Online Services (`scripts/online/epic_online.gd`: login anônimo por Device ID, lobby de 2 vagas com id `HOTEL<código>`, `EOSGMultiplayerPeer` por baixo do multiplayer do Godot). Código de 6 caracteres sem O/0 e I/1. O plugin EOSG (`addons/epic-online-services-godot/`, AssetLib) e `epic_credentials.cfg` (fora do git; modelo `epic_credentials.example.cfg`) são opcionais: sem eles, `EpicOnline.missing()` diz o que falta. Nada no código do jogo cita as classes do plugin pelo nome (o projeto precisa abrir sem ele). Os autoloads do plugin (`EOSGRuntime`, `HPlatform`, `HAuth`, `HLobbies`…) são a exceção aceita à regra dos autoloads. Passo a passo do portal em `JOGAR-ONLINE.md`.
- **Epic de verdade (09/11/2026)**: produto só com o sandbox Live e a client policy pronta *Peer2Peer*; login, lobby e conexão P2P funcionam. Dois cuidados: `product_version` não pode ir vazio (o Godot registra `application/config/version` com `""`; vazio, `EOS_Initialize` dá `InvalidParameters`) e o id do socket do `EOSGMultiplayerPeer` só aceita letras e números (`hotelsemsaida`). O `HAuth` do plugin apaga e recria o Device ID a cada login, então cada processo ganha um Product User ID novo: duas cópias no mesmo PC (mesmo APPDATA) entram na mesma sala. Teste manual `tools/test_epic_sala.gd -- criar` num processo e `-- entrar CODIGO` em outro (precisa de internet; sem argumentos, `SKIP`). Quando o anfitrião desfaz a sala antes de o visitante sair, o plugin escreve `Failed to leave lobby: result_code=NotFound`: inofensivo.
- Recepção (`scripts/ui/entrada.gd`): botão Configurações ao lado de Jogar solo; a capa da esquerda passa para a de hoje (azulada, moldura partida, raios caídos, letras faltando) quando a personagem escolhida é Lia, e volta com Helena. recepção: nome do jogador (`Settings.data.player_name`, trocado no `_check_in`/`_welcome`), código grande com Copiar, o anfitrião troca de personagem até começar (`choose_era`, RPC `_assign`) e escolhe Novo jogo ou Retomar save (ao retomar, vale a escolha atual). O endereço:porta (ENet/Playit) virou o "Plano B". Protocolo 8.
- Teste: `tools/run_dupla_online.sh` roda 4 modos (nova, retomar, codigo, retomar codigo); no modo `codigo` a Epic é trocada por `tools/fake_rooms.gd` (ENet local) via `NetSession.rooms`. A Epic de verdade só se testa com o plugin e as chaves.

## Versão para Windows (08/11/2026)

- `export_presets.cfg` tem o preset "Windows x64" (`.pck` separado do `.exe`, para os remendos; ficam de fora `tools/`, prévias e fontes de arte). Precisa dos modelos de exportação do Godot 4.7.2 (Editor > Gerenciar modelos de exportação > Baixar; ~1 GB uma vez só).
- Gerar: no Godot, Projeto > Exportar > Windows x64 > Exportar projeto; ou sem janela: `Godot --headless --path . --export-release "Windows x64" build/HotelSemSaida.exe`. Saem o `.exe` (~110 MB, o motor), o `HotelSemSaida.pck` (~30 MB, o jogo) e as DLLs da Epic (`libeosg.windows.template_release.x86_64.dll`, `EOSSDK-Win64-Shipping.dll`, `xaudio2_9redist.dll`): o ZIP precisa da pasta inteira. O `epic_credentials.cfg` entra no pacote pelo `include_filter`. Com o editor aberto, o export acusa que não copiou a DLL de *debug* do plugin (arquivo preso pelo editor); não atrapalha o release.
- Ícone (09/11/2026): imagem feita no ChatGPT (`art/incoming/icone/icone_chatgpt.webp`, fachada do hotel dividida entre 1923 e hoje com a fechadura acesa). `python tools/make_icon.py` tira os cantos pretos e gera `art/icon/icone.png` (janela, `config/icon`) e `art/icon/icone.ico` (16 a 256 px; `config/windows_native_icon` e `application/icon` do export, com `modify_resources` ligado). O export também grava nome e versão no `.exe` (`application/file_version` e `product_version`, fixos em 1.0.1.0): **não suba**. O `.exe` sai idêntico (mesmo sha256) entre exports com o mesmo Godot, ícone e versão gravada, e por isso quem atualiza uma versão completa não baixa o `.exe` de novo.

## Atualização pelo jogo (09/11/2026)

- Pedido do Roberto: ninguém baixa ZIP nem `.exe` de novo a cada versão. O ZIP (`.exe` + `.pck` + DLLs) é baixado uma vez; depois, a recepção mostra a versão e, se houver uma nova, **Atualizar** baixa só um remendo (`.pck` com o que mudou) e **Reiniciar o jogo** a instala.
- `GameVersion` (`scripts/core/game_version.gd`): `VERSION` sobe a cada versão publicada. A "base" é `application/config/version` no `project.godot` (a versão do ZIP; só muda numa versão completa). Na dupla, o anfitrião recusa quem tem outra `VERSION` e os dois veem as duas versões.
- `PatchLoader` (primeiro autoload, `scripts/core/patch_loader.gd`): no `_init`, só no jogo exportado (feature `template`), instala `user://atualizacao/remendo-novo.pck` por cima de `remendo.pck` e o carrega com `ProjectSettings.load_resource_pack`. Por ser o primeiro, os outros autoloads e as cenas já saem do remendo (conferido no 4.7.2, inclusive `class_name` novo). Remendo de outra base (ZIP novo instalado) é apagado. Mudanças nele só valem num ZIP novo.
- `Updater` (`scripts/core/updater.gd`, filho da recepção): lê `versao.json` do último Release do GitHub (`version`, `base`, `patch {url, size, sha256}`, `zip`, `zip_size`, `zip_sha256`, `files`, `page`), baixa para `.part`, confere tamanho e sha256 e só então grava `remendo-novo.*`. No editor não procura (só com `-- --procurar-atualizacao`).
- **Versão completa pelo jogo (09/11/2026, pedido do Roberto: ninguém baixa ZIP de novo)**: base diferente, o `Updater` compara a lista `files` (nome, tamanho, sha256, url de cada arquivo solto no Release) com a pasta do jogo e baixa só o que mudou (em geral só o `.pck`) para `user://atualizacao/jogo-novo/`; sem a lista, baixa e extrai o ZIP. Ao reiniciar, roda `user://atualizacao/instalar.ps1` (PowerShell, UTF-8 com BOM por causa dos acentos), que espera o jogo fechar, copia por cima da pasta do `.exe` e o abre. Sem Windows ou sem escrita na pasta do jogo, o botão abre a página do Release. Quem tem a 1.0.0 só tem o botão antigo (página).
- Publicar: `tools/publicar_versao.sh completa` (ZIP para quem instala e cada arquivo solto para quem atualiza; `VERSION` = base) ou `tools/publicar_versao.sh remendo` (`VERSION` maior que a base; põe os arquivos soltos na completa base se faltarem, como na 1.0.1). Precisa de commit e push feitos e do `gh` logado; cria o Release `v<VERSION>` com os arquivos e o `versao.json`. O remendo é sempre em relação ao ZIP base (`--export-patch --patches`), então quem pula versões baixa um só. **Mudou `project.godot` (autoload, Input Map, configurações), `addons/` ou a versão do Godot? Versão completa** (o remendo não carrega isso; o script recusa). Os builds ficam em `build/` (fora do git).
- **Remendo que quebra o jogo (09/11/2026)**: a primeira 1.0.2 saiu com um script pela metade, porque o export lê a pasta do projeto e ela foi editada durante a publicação (o Release foi apagado antes de alguém instalar). Desde então o `publicar_versao.sh` para sem enviar nada se o export acusar script com erro ou se a pasta mudar durante o export: **não edite o projeto enquanto o Roberto publica**. E, a partir da 1.1.0, o `PatchLoader` cria `remendo.abrindo` ao abrir com um remendo e a recepção o apaga (`PatchLoader.confirm`); se ele ainda existir na abertura seguinte, o remendo é descartado e o jogo volta à versão instalada.
- Teste `tools/test_atualizacao.gd` (versões, decisão, download por um servidor HTTP local, sha256 errado, instalação e descarte do remendo, versão completa só com os arquivos que mudaram, o `instalar.ps1` de verdade e a volta pelo ZIP).

## Versão de navegador (protótipo solo, 10/11/2026)

- Pedido do Roberto: jogar com uma pessoa que só tem iPhone. Primeiro passo: protótipo **solo** no navegador para medir o desempenho no celular; a dupla no navegador fica para depois (precisa de rede nova por WebSocket/WebRTC e um servidor de pareamento: o plugin da Epic é DLL de Windows e o navegador não abre UDP).
- `tools/exportar_web.sh [godot]` gera `build/web/` (index.html, .wasm ~40 MB, .pck ~30 MB) **sem tocar no `project.godot`**: copia o projeto para `build/web_src/`, tira `addons/` e os autoloads da Epic, força o renderizador Compatibility, sobe o limite de luzes por objeto (as salas são malhas juntadas: com o padrão de 8 luzes faltava luz) e exporta com `tools/web/export_presets.cfg` (sem threads, não precisa de cabeçalhos especiais no servidor). Precisa dos modelos de exportação da Web. A pasta tem de ser servida por HTTP(S).
- `GamePlatform` (`scripts/core/game_platform.gd`; o nome `Platform` bate com uma classe do plugin da Epic): `is_web()`, `is_touch()` (tela de toque, ou `-- --toque` para testar no PC), `is_compatibility()`, `is_lite()`.
- `TouchControls` (`scripts/ui/touch_controls.gd`, criado pelo HUD em primeira pessoa quando há tela de toque): metade esquerda é o analógico de andar, metade direita arrasta o olhar, botões Usar, Pular, Época e Pausa; com uma tela em close aberta viram quatro setas, Usar e X. Tudo sai como ações do Input Map (`InputEventAction`), então cadeado, relógio e bilhetes funcionam sem mudar. Com toque, `Room3D` não prende o mouse e os avisos mostram "Usar" (`Settings.TOUCH_LABELS`).
- No navegador: a recepção esconde a dupla e a atualização, a pausa não tem "Sair do jogo", a qualidade padrão é Baixa, a escala do 3D mira uma altura fixa (`Settings.COMPAT_3D_HEIGHT`) e os materiais usam o caminho `lite` do shader (envelhecimento com dois ruídos, sem normal map de detalhe).
- Publicação web retirada a pedido do Roberto (10/11/2026): o link da landing e os arquivos de `site/jogar/` foram removidos. O protótipo técnico e `tools/exportar_web.sh` foram preservados; a opção `--site` do exportador pode recriar essa pasta. Os saves do navegador ficam no próprio aparelho.
- Conferido no Chromium sem placa de vídeo (Playwright, toque emulado): abre, anda, olha, troca de época e pausa. **Não medido em celular de verdade**; no iPhone o Safari é o risco.
- Limites conhecidos: barras pretas nas laterais em telas mais largas que 16:9 (o HUD usa posições fixas em 640×360), a fonte da interface cai na padrão do Godot (não há fontes do sistema no navegador) e o piano precisa de toque nas teclas.

## Site (09/11/2026)

- Landing page estática em `site/` (`index.html`, `styles.css`, `site.js`, imagens em `site/img/`), publicada pelo Roberto na Vercel com Root Directory `site` e sem build. É apresentação e download para Windows; não contém jogo no navegador.
- Visual premium aprovado pelo Roberto (10/11/2026): identidade art déco vinho/dourado, fachada em portal arqueado, imagens comparáveis das épocas, Helena e Lia, livro de hóspedes, dupla online e instalação em FAQ. Fontes Poiret One, Cormorant Garamond e Manrope auto-hospedadas em `site/fonts/`, com licenças OFL. Menu móvel e FAQ nativos; conteúdo visível sem JavaScript, foco por teclado e movimento reduzido.
- O botão de download pega o `.zip` do Release mais novo que tem um (API do GitHub, no navegador); sem resposta, leva à página do último Release. Remendos não mudam o link.
- Validação do site (10/11/2026): desktop, tablet e celular (1440, 768, 390 e 320 px), menu/FAQ, comparadores por teclado, recursos e âncoras locais; resolver de download testado com versão completa, remendo, falha de rede e timeout.
- Para ver localmente: `.claude/launch.json` (servidor `site`, porta 4173).

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
