# Hotel Sem Saída — instruções para o Claude Code

Jogo de enigmas em pixel art 2D para PC (Windows), feito no **Godot 4** por Roberto com o Claude Code. Este arquivo é a fonte de verdade sobre o projeto: leia-o inteiro antes de qualquer tarefa.

## O jogo em uma frase

O Grand Hotel Aurora existe em duas épocas, 1923 e hoje. O jogador alterna com uma tecla entre **Helena** (1923, hóspede) e **Lia** (hoje, a neta dela). O que Helena faz no passado muda o que Lia encontra no presente.

## Regras de design que o código precisa respeitar

1. **Só o passado altera o presente.** Nunca o contrário. Lia descobre informações; Helena muda o mundo.
2. **As duas personagens não se comunicam.** A única ligação é a consequência física.
3. **Mesmo espaço, mesma câmera.** As duas épocas ocupam a mesma geometria da sala. Ao trocar, a câmera fica parada e só o cenário muda.
4. **Cada personagem fica onde foi deixada.** Trocar de época não move ninguém.
5. **Sem sistema de dicas.** Enigmas difíceis, resolvidos só com observação.
6. **Preparado para co-op.** No futuro, cada personagem será um jogador (tela dividida). Por isso, o input de cada personagem é independente desde o início.

## Stack e configuração

- **Godot 4** (última versão 4.x estável), edição **padrão** (não a .NET). Roda sem instalação e sem acesso de administrador.
- Linguagem: **GDScript** com tipagem estática (`var speed: float = 80.0`, `func get_move() -> Vector2:`).
- Nomes de código (classes, funções, variáveis, sinais, nós) em inglês, seguindo o estilo do Godot: `snake_case` para funções e variáveis, `PascalCase` para `class_name` e nós. Comentários e textos de interface em português.
- Resolução de referência: **640×360**. Em `project.godot`: stretch mode `viewport`, aspect `keep`, scale mode `integer` (escala inteira para 1280×720, 1920×1080 e 4K). Filtro de textura padrão: `Nearest`.
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
- **`RoomManager`** (autoload): troca de sala com fade. **Helena e Lia sempre mudam de sala juntas** e aparecem num ponto de entrada (`Marker2D` da sala de destino). O `SaveSystem` também carrega salas por ele.
- **`Door`**: `Interactable` que leva à sala `target_scene`, no ponto de entrada `target_spawn`. Usa-se com E.
- **Menu de pausa** (`scripts/ui/pause_menu.gd`, dentro de `hud.tscn`): Esc/Start pausa o jogo, com Continuar, Salvar, Carregar e Sair.
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
- Prefira código simples e legível a padrões complexos. Autoloads só para `EraManager`, `WorldState`, `SaveSystem` e `RoomManager` (e algo novo só com motivo claro).
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

Próximo: **Capítulo 1 — Cozinha**, a partir do GDD do Roberto.

## Referência

O design completo (história, capítulos, enigmas, minigames) está no GDD do Roberto. Se precisar de algo que não está aqui, pergunte.
