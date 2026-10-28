# Hotel Sem Saída — GDD

Versão de 27/10/2026 · Roberto Miranda

## Visão geral

Hotel Sem Saída é um jogo de enigmas misterioso em pixel art 2D para PC, no qual você alterna entre duas mulheres da mesma família presas no mesmo hotel, separadas por 100 anos.

| Item | Definição |
| --- | --- |
| Gênero | Puzzle/aventura com minigames, inspirado em It Takes Two e Split Fiction (versão enxuta) |
| Plataforma | PC (Windows), distribuição via itch.io e Steam |
| Engine | Godot 4 (GDScript) |
| Visual | Pixel art 2D, câmera que muda por capítulo |
| Tom | Misterioso e sombrio |
| Modo | Solo, alternando 2 personagens; arquitetura pronta para co-op no futuro (cada personagem = 1 jogador) |
| Dificuldade | Enigmas difíceis, sem sistema de dicas: o jogador resolve sozinho |
| Equipe | Roberto + Claude (Claude Design e Claude Code) |

## História e personagens

O Grand Hotel Aurora é famoso por hóspedes que entraram e nunca saíram. Lia investiga hoje o sumiço da avó, Helena, que esteve hospedada lá em 1923.

| Personagem | Época | Papel |
| --- | --- | --- |
| Helena | 1923 | Hóspede no hotel em pleno funcionamento: luxo, funcionários, hóspedes vivos e coisas estranhas acontecendo |
| Lia | Hoje | Neta de Helena; entra no hotel abandonado e em ruínas atrás de respostas |

- **Mistério central:** hóspedes desaparecidos. Cada andar revela parte de quem sumiu, quando e como.
- **Comunicação:** as duas não se falam. A única ligação entre elas são as consequências físicas de uma época na outra.
- **Reviravolta (para o final, ainda não produzida):** Lia já está presa no hotel e é a próxima hóspede desaparecida, sem perceber. Por enquanto, os 3 andares apenas plantam pistas sutis disso.

## Mecânica central

Uma tecla troca entre Helena (1923) e Lia (hoje). As duas ocupam o mesmo espaço físico do hotel, e o que Helena faz no passado muda o que Lia encontra no presente.

- **Passado → presente:** plantar uma semente vira uma árvore que quebra uma parede; um cofre trancado em 1923 aparece enferrujado e aberto hoje; um móvel arrastado libera uma passagem nas ruínas.
- **Presente → conhecimento:** Lia acha jornais, registros e destroços que mostram o desfecho das coisas. O jogador usa essas pistas para resolver os enigmas de Helena (as personagens não sabem, mas o jogador sabe).
- **Regra de ouro:** só o passado altera o presente, nunca o contrário. Isso mantém os enigmas lógicos.
- **Ao trocar:** a câmera fica na mesma posição e o cenário "envelhece" ou "rejuvenesce" com uma transição curta. Cada personagem fica parada onde foi deixada.
- **Preparado para co-op:** cada personagem tem seu próprio controlador de input desde o início, para virar 2 jogadores (tela dividida) sem reescrever o jogo.

## Estrutura

A primeira versão tem o saguão como hub e 3 andares, cada um com uma câmera e uma mecânica de destaque. O final fica em aberto nesta fase de testes.

| Local | Câmera | Mecânica de destaque | Minigame |
| --- | --- | --- | --- |
| Saguão (hub) | Vista de cima | Elevador que libera os andares; recepção e livro de hóspedes com nomes dos desaparecidos | Piano de cauda (melodias ao longo do jogo) |
| Cozinha | Plataforma lateral | Causa e consequência física entre as épocas (fogão, elevador de serviço, despensa) | Fechaduras da despensa |
| Biblioteca | Vista de cima | Cifras, livros fora do lugar, estantes que se movem | Fechaduras com código |
| Casa das caldeiras | Plataforma lateral | Vapor, pressão e válvulas; em 1923 funciona, hoje está inundada | Mecanismos e engrenagens |

Ordem sugerida para jogar: Cozinha → Biblioteca → Caldeiras, subindo a dificuldade.

## Capítulos e enigmas

Cada andar tem de 3 a 4 enigmas encadeados, e o último combina tudo o que o andar ensinou. As propostas abaixo são rascunhos para você aprovar, trocar ou cortar.

### Cozinha (aprovado em 27/10/2026)

**Espaço:** uma única tela lateral, em corte (como uma casa de bonecas): a **Cozinha** em cima e a **Despensa** embaixo. Não há troca de sala dentro do andar, então cada personagem fica onde foi deixada.

- Em 1923, uma escada atrás da porta da despensa liga os dois andares.
- Hoje, a escada desabou, e Lia não tem como descer até achar outro caminho.
- O elevador de serviço fica na parede da direita e atravessa os dois andares.

**Enigmas, nesta ordem:**

1. **Despensa trancada** (ensina que as pistas vêm das duas épocas)
   - A combinação de 4 dígitos está num cardápio rasgado. Helena acha a metade de 1923, com os 2 primeiros dígitos, e Lia acha a outra metade, desbotada, com os 2 últimos.
   - Helena abre o cadeado da despensa no minigame e passa a descer a escada em 1923.
2. **Massa que cresce** (ensina que o tempo transforma objetos)
   - Helena pega o fermento na despensa e deixa a massa de pão no forno, que fica perto do elevador.
   - Hoje, o forno está lacrado com a massa petrificada e serve de degrau. Por ele, Lia alcança uma prateleira quebrada e a portinhola do elevador, no alto da parede.
3. **Elevador de serviço** (ensina que o passado pode abrir um caminho no presente)
   - Helena trava o elevador de serviço art déco no andar de cima.
   - Hoje, a cabine não tapa mais o poço. Lia entra pela portinhola e desce pelos cabos até a despensa.
4. **Fogo e gelo** (final, junta os três)
   - Na despensa, hoje, Lia nota um ponto do piso por onde passa uma corrente de ar. É a pista do presente.
   - Helena pega um bloco de gelo na geladeira de 1923 e o deixa derretendo exatamente nesse ponto.
   - Hoje, a infiltração apodreceu o piso ali e abre a passagem: fim do andar.

**Objeto na mão:** Helena segura um objeto por vez (o fermento ou o gelo). É uma mão, e não um inventário completo.

### Biblioteca

1. **Estante fora de ordem:** a ordem certa dos livros em 1923 só aparece pelas manchas de sol que eles deixaram nas prateleiras hoje.
2. **Cifra do bibliotecário:** notas cifradas espalhadas pelas duas épocas; a chave fica num carimbo de devolução.
3. **Livro escondido:** Helena esconde um livro dentro de outro; hoje, Lia o encontra e lê uma página sobre um dos desaparecidos.
4. **Sala secreta:** uma fechadura com código cuja resposta depende das três etapas anteriores.

### Casa das caldeiras

1. **Pressão:** Helena ajusta válvulas numa sequência certa; o erro explode um cano que, hoje, deixa a sala inundada de outro jeito.
2. **Inundação:** Lia só atravessa onde o nível da água ficou baixo, e isso depende de quais ralos Helena deixou abertos.
3. **Engrenagens:** um mecanismo quebrado hoje precisa de peças que Helena guarda em lugares que vão sobreviver 100 anos.
4. **Fornalha:** o encerramento do andar une as três mecânicas numa única sala.

## Minigames

Os dois tipos escolhidos são mecanismos e fechaduras, e piano e ritmo. Cada minigame abre em uma tela própria, em close, e sempre faz parte de um enigma, nunca é só enfeite.

- **Mecanismos e fechaduras:** cofres com disco, cadeados de código, encaixe de engrenagens e calibragem de manômetros. A resposta está sempre no cenário de uma das épocas.
- **Piano e ritmo (câmera de cima das teclas):** tocar uma melodia que abre uma passagem. A melodia é descoberta no jogo (uma partitura rasgada, uma caixinha de música, um gramofone de 1923). O piano fica no saguão: cada andar revela uma melodia que, tocada ali, abre algo novo no hotel.

## Arte, áudio e controles

As duas épocas têm paletas opostas, para que o jogador saiba onde está só de olhar.

- **1923:** dourado, vinho e verde-escuro; luz quente de lustres; personagens vivos ao fundo.
- **Hoje:** cinza, azul frio e verde-musgo; poeira, mofo e lanterna; vazio e silêncio.
- **Áudio:** em 1923, um jazz abafado e burburinho; hoje, ruído de vento e goteiras. A troca de época corta o som com um efeito de distorção.
- **Resolução base:** 640×360 (escala inteira para 1280×720, 1920×1080 e 4K).
- **Sprites:** packs prontos do itch.io, adaptados às paletas das duas épocas. Personagens com 24×48 px.
- **Controles (teclado e controle):** mover, interagir, trocar de personagem e pausar. Nada além disso: a dificuldade fica na lógica, não nos reflexos.
- **Referências visuais:** a direção de arte (paletas, mood board e mockups) está no canvas "Hotel Sem Saída — Direção de Arte", no Claude.

## Plano de produção

O primeiro marco é provar que a troca de época é divertida numa única sala, antes de investir em arte e conteúdo.

1. **Protótipo da troca:** uma sala cinza no Godot, com Helena e Lia, a tecla de troca e um enigma simples de causa e consequência (Claude Code).
2. **Sistema de estado do mundo:** registrar o que Helena mudou e aplicar isso ao presente de forma genérica, para reaproveitar em todos os enigmas.
3. **Direção de arte:** telas de referência, paletas, menu, HUD e mockups dos capítulos (Claude Design).
4. **Cozinha completa:** o primeiro andar jogável, de ponta a ponta, com arte provisória.
5. **Saguão (hub) e elevador:** ligação entre os andares, save e progresso.
6. **Biblioteca e Casa das caldeiras.**
7. **Polimento e testes:** arte final, som, testes com amigos e versão no itch.io.

Cada etapa gera uma versão jogável, que você testa antes de seguirmos para a próxima.

## Questões em aberto

- [ ] Quais packs do itch.io usar (licença comercial para a Steam)?
- [ ] Quais enigmas propostos ficam, saem ou mudam?
- [ ] Quais melodias o piano do saguão vai ter e o que cada uma abre?
- [ ] Como o jogador percebe que está no fim de um andar?
- [ ] Quantos hóspedes desaparecidos existem e quem são?
- [ ] Qual é o nome definitivo do jogo?
- [ ] Como serão o final e a revelação da reviravolta (depois da fase de testes)?
