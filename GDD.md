# Hotel Sem Saída — GDD

Versão de 04/11/2026 · Roberto Miranda

## Visão geral

Hotel Sem Saída é um jogo de enigmas misterioso em primeira pessoa 3D para PC, no qual você alterna entre duas mulheres da mesma família presas no mesmo hotel, separadas por 100 anos.

| Item | Definição |
| --- | --- |
| Gênero | Puzzle/aventura com minigames, inspirado em It Takes Two e Split Fiction (versão enxuta) |
| Plataforma | PC (Windows), distribuição via itch.io e Steam |
| Engine | Godot 4 (GDScript) |
| Visual | 3D em primeira pessoa; hotel quente e luxuoso em 1923, frio e em ruínas hoje |
| Tom | Misterioso e sombrio |
| Modo | Solo com troca de personagem ou dupla online em dois PCs, cada um com sua tela |
| Dificuldade | Enigmas difíceis, sem sistema de dicas: o jogador resolve sozinho |
| Equipe | Roberto + Claude (Claude Design e Claude Code) |

## História e personagens

O Grand Hotel Aurora é famoso por hóspedes que entraram e nunca saíram. Lia investiga hoje o sumiço da bisavó, Helena, que desapareceu lá em 1923.

| Personagem | Época | Papel |
| --- | --- | --- |
| Helena | 1923 | Hóspede no hotel em pleno funcionamento: luxo, funcionários, hóspedes vivos e coisas estranhas acontecendo. Já tinha um filho quando viajou; some no hotel em 1923 |
| Lia | Hoje | Bisneta de Helena; entra no hotel abandonado e em ruínas atrás de respostas |

- **Mistério central:** hóspedes desaparecidos. Cada andar revela parte de quem sumiu, quando e como.
- **Os desaparecidos (aprovado em 03/11/2026):** uma pessoa por geração, num ciclo de cerca de 25 anos que sugere, sem dizer, que agora é a vez de alguém.

  | Ano | Desaparecido | Quem era | Onde aparece |
  | --- | --- | --- | --- |
  | 1923 | Helena | Hóspede, bisavó de Lia | Fio de todo o jogo |
  | 1923 | Otília | Cozinheira do hotel; escreveu "despensa 3 8" a lápis no cardápio | Cozinha |
  | 1951 | Dr. Caio Ferraz | Médico, hóspede de longa estadia | Biblioteca |
  | 1979 | Marta Siqueira | Fotógrafa que cobria a decadência do hotel | Saguão (bolsa no poço) e Biblioteca |
  | 2003 | Tomás Reis | Explorador de prédios abandonados, com lanterna e mochila; espelho de Lia | Casa das caldeiras |

  Quem sumiu depois de 1923 não existe na época de Helena: ela só deixa vestígios físicos que eles vão encontrar.
- **Comunicação:** as duas não se falam. A única ligação entre elas são as consequências físicas de uma época na outra.
- **Reviravolta (para o final, ainda não produzida):** Lia já está presa no hotel e é a próxima hóspede desaparecida, sem perceber. Por enquanto, os 3 andares apenas plantam pistas sutis disso.

## Mecânica central

Uma tecla troca entre Helena (1923) e Lia (hoje). As duas ocupam o mesmo espaço físico do hotel, e o que Helena faz no passado muda o que Lia encontra no presente.

- **Passado → presente:** plantar uma semente vira uma árvore que quebra uma parede; um cofre trancado em 1923 aparece enferrujado e aberto hoje; um móvel arrastado libera uma passagem nas ruínas.
- **Presente → conhecimento:** Lia acha jornais, registros e destroços que mostram o desfecho das coisas. O jogador usa essas pistas para resolver os enigmas de Helena (as personagens não sabem, mas o jogador sabe).
- **Regra de ouro:** só o passado altera o presente, nunca o contrário. Isso mantém os enigmas lógicos.
- **Ao trocar:** um fade leva aos olhos da outra personagem, na posição e sala em que foi deixada. Cada uma passa pelas portas individualmente; a outra não é transportada junto.
- **Dupla online.** Na recepção, quem cria a sala escolhe Helena ou Lia. O visitante controla a outra personagem. Cada jogador explora a própria época, com posição, câmera, sala e leitura independentes. Os vestígios dos enigmas são compartilhados. O anfitrião pode salvar e retomar o progresso da dupla.

## Estrutura

A primeira versão tem o saguão como hub e 3 andares, cada um com uma mecânica de destaque, todos em primeira pessoa. O final fica em aberto nesta fase de testes.

| Local | Câmera | Mecânica de destaque | Minigame |
| --- | --- | --- | --- |
| Saguão (hub) | Primeira pessoa 3D | Elevador que libera os andares; recepção e livro de hóspedes com nomes dos desaparecidos | Piano de cauda (melodias ao longo do jogo) |
| Cozinha | Primeira pessoa 3D | Causa e consequência física entre as épocas (fogão, elevador de serviço, despensa) | Fechaduras da despensa |
| Biblioteca | Primeira pessoa 3D | Cifras, livros fora do lugar, estantes que se movem | Fechaduras com código |
| Casa das caldeiras | Primeira pessoa 3D | Vapor, pressão e válvulas; em 1923 funciona, hoje está inundada | Mecanismos e engrenagens |

Ordem para jogar: o jogo começa no **Saguão**, depois Cozinha → Biblioteca → Caldeiras, subindo a dificuldade.

**Fim de um andar (atualizado em 04/11/2026):** o último enigma abre a continuação física do caminho. Na Cozinha, Lia desce pelo piso apodrecido à manutenção e segue pelo acesso de serviço da Biblioteca. O retorno ao Saguão é voluntário, pelas portas; o livro de hóspedes pode então revelar a novidade sobre o desaparecido. As personagens nunca são transportadas juntas automaticamente.

## Capítulos e enigmas

Cada andar tem de 3 a 4 enigmas encadeados, e o último combina tudo o que o andar ensinou. As propostas abaixo são rascunhos para você aprovar, trocar ou cortar.

### Saguão (aprovado em 03/11/2026)

**Espaço:** uma única tela vista de cima (640×360), simétrica, com o lustre como marco central. Todas as saídas ficam alcançáveis nas duas épocas.

```
########[ESCADA]####################[EL]#
#  ESC            [===LIVRO===]      [  ]
#  ESC                                  #
#     O          ~~~~LUSTRE~~~~      O   #
D                                       #
D                  ( * )         PIANO  #
#                                PIANO  #
#     O                              O  #
#                                       #
###############[ENTRADA]#################
```

- **Recepção** no centro-norte (x 224–416, y 96–128), com o livro de hóspedes, o quadro de chaves e, atrás do balcão, o cofre da gerência.
- **Elevador principal** na parede norte (x 496–544). **Escada** a noroeste. **Porta de serviço da Cozinha** na parede oeste (y 208–256). **Piano de cauda** a leste (só cenário por enquanto). **Entrada principal** ao sul, trancada nas duas épocas: o jogo nunca mostra Lia entrando por ela. Colunas em (160/480, 176) e (160/480, 304).
- **Hoje:** o lustre caiu no centro (x 256–384, y 192–256) sem bloquear caminho, a escada desabou, o piano está coberto de lona e o livro está mofado.

**Livro de hóspedes:** em 1923, em uso, com os nomes da semana. Hoje, mofado; os desaparecidos têm a coluna "Saída" em branco. A última linha tem a data de hoje e a tinta ainda úmida ("Uma assinatura recente. A letra parece familiar."), com o nome ilegível: pista sutil da reviravolta.

**Enigmas, nesta ordem** (abertura do jogo, 40–75 min; terminam liberando a porta de serviço da Cozinha):

1. **Quadro de chaves** (Lia observa, Helena age)
   - Hoje, o quadro da recepção está podre e vazio; onde a tinta descascou aparecem os nomes dos funcionários sob cada gancho ("Otília", "Sr. Amaral", "Bento"…).
   - Em 1923, os ganchos têm 12 chaves iguais e a pintura cobre os nomes. No livro de 1923, um hóspede reclama: "esperei 20 minutos pelo Bento, o ascensorista".
   - Helena pega a chave do gancho do Bento. Chave errada: ela "não gira" no painel do elevador; Helena devolve no quadro e tenta outra.
2. **Poço do elevador** (Lia age fisicamente)
   - Hoje, a cabine apodrecida tapa o poço no térreo; pela grade, Lia vê a alça de uma bolsa de couro presa sob o piso da cabine.
   - Em 1923, Helena gira a chave do Bento no painel, e a cabine sobe vazia. A chave fica presa no painel (libera a mão).
   - Hoje, a cabine está parada no alto para sempre, e a porta ficou entreaberta. Lia desce ao poço e acha a bolsa de câmera de Marta Siqueira (1979), com uma foto, e a chave de um cadeado.
3. **Cofre da gerência e lustre** (junta tudo; minigame do cadeado de 4 dígitos)
   - Em 1923, há uma frase riscada na porta do cofre: "o dia em que o Aurora se acendeu".
   - Hoje, o lustre caído deixa à vista a coroa de latão, que em 1923 ficava no teto, com a gravação "Aceso pela primeira vez em 14/03/1923". Uma placa na entrada diz "Inaugurado em 06/09/1921": é a pista falsa.
   - Helena abre o cofre com 1403 (tentativas ilimitadas), pega a chave de serviço e destranca a fechadura original da porta de serviço.
   - Hoje, a fechadura está corroída e aberta, mas há um cadeado posto em 1979. Lia o abre com a chave do poço. Com as duas trancas abertas, em qualquer ordem, a porta leva as duas à Cozinha.

**Ao voltar da Cozinha:** o livro de hoje mostra o nome de Otília, com a coluna "Saída" vazia, na mesma letra do lápis do cardápio ("3 8"). O jogador entende que a pista que usou foi deixada por ela tentando sair.

**Trecho jogável em 3D.** No fim das Caldeiras, Tomás menciona a correia de uma máquina fotográfica presa na soleira do elevador principal. Lia pode voltar pela Biblioteca e seguir essa pista. O quadro tem doze ganchos. Em 1923, Helena pode retirar uma chave por vez e devolvê-la ao gancho de origem. Hoje, a tinta descascada revela o nome de cada funcionário. A chave de Bento fica presa na botoeira e a cabine sobe. Pela escada lateral do poço, Lia alcança a bolsa de Marta, examina a cópia da foto da oficina e vê a pequena chave de serviço dentro dela. A mesma escada leva de volta ao Saguão. A retirada dessa chave e o cofre da gerência ficam para a etapa seguinte.

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

### Continuação da Cozinha em 3D — 04/11/2026

O buraco no piso da despensa leva **fisicamente à manutenção sob a cozinha**, sem retorno automático ao Saguão. Lia encontra ali uma chave de 1951, identificada como duplicata da Biblioteca, e usa a escada/corredor de serviço para entrar na próxima fase. Pode voltar à despensa pela escada da manutenção.

A porta pública da Biblioteca fica no Saguão. Em 1923 ela funciona normalmente para Helena; hoje está trancada, e Lia precisa da chave. A chave destranca apenas o presente: não atravessa o tempo e não modifica o passado. A conclusão da Cozinha libera a continuação. A passagem pelo buraco registra `cozinha.concluida`, mas a descoberta sobre Otília pode ser lida no Saguão quando o jogador voltar por vontade própria.

Esta sequência substitui o antigo fade de volta ao Saguão ao terminar a Cozinha.

### Biblioteca (quatro enigmas mantidos em 04/11/2026)

**Espaço 3D:** salão de leitura com estantes altas, teto em caixotões, tapete vinho, mesas com luminárias verdes, nicho seco sob um peitoril e arquivo atrás de uma estante móvel. Hoje há livros ausentes, marcas de sol, umidade, janelas pregadas e luar frio. Uma porta retorna ao Saguão e outra ao corredor de serviço.

1. **Estante fora de ordem:** a ordem certa dos livros em 1923 só aparece pelas manchas de sol que eles deixaram nas prateleiras hoje.
2. **Cifra do bibliotecário:** notas cifradas espalhadas pelas duas épocas; a chave fica num carimbo de devolução.
3. **Livro escondido:** Helena esconde um livro dentro de outro; hoje, Lia o encontra e lê uma página sobre um dos desaparecidos.
4. **Sala secreta:** uma fechadura com código cuja resposta depende das três etapas anteriores.

**Implementação jogável:** quatro livros (Atlas, Botânica, Crônicas e Diários) podem ser trocados aos pares com E em 1923. Hoje, os contornos desbotados revelam a ordem por altura. A ordem abre a gaveta com o bilhete cifrado; o carimbo preservado hoje explica o deslocamento alfabético. A frase identifica o Atlas. Helena o guarda dentro de um registro oco, sob o peitoril seco; assim ele sobrevive e recebe as anotações de Caio Ferraz em 1951. Lia encontra os algarismos correspondentes aos títulos; combinados com a ordem dos livros, abrem o arquivo em 1923. A passagem também fica aberta hoje. O dossiê de Caio no arquivo encerra o capítulo, sem teleportar ninguém.

**Solução de produção (spoilers):** ordem Botânica → Diários → Atlas → Crônicas; cifra de três letras, `DEUD R DWODV` = `ABRA O ATLAS`; fichas Atlas=6, Botânica=7, Crônicas=4, Diários=2; combinação final 7264. Flags sob `biblioteca.*`, posição de cada volume salva individualmente. Tentativas ilimitadas, sem consumo de livro em erro. A porta destrancada permanece acessível após gastar a chave.


### Casa das caldeiras

1. **Pressão:** Helena ajusta válvulas numa sequência certa; o erro explode um cano que, hoje, deixa a sala inundada de outro jeito.
2. **Inundação:** Lia só atravessa onde o nível da água ficou baixo, e isso depende de quais ralos Helena deixou abertos.
3. **Engrenagens:** um mecanismo quebrado hoje precisa de peças que Helena guarda em lugares que vão sobreviver 100 anos.
4. **Fornalha:** o encerramento do andar une as três mecânicas numa única sala.

**Primeira etapa jogável em 3D.** A estante que Helena abre na Biblioteca revela, nas duas épocas, a porta de serviço no arquivo reservado. Cada personagem pode descer às caldeiras e voltar pela mesma porta. Na galeria dos foguistas, o esmalte do coletor encobre as marcas de montagem em 1923. Hoje, Lia vê os talhos sob a tinta descascada. Helena pode girar os três volantes e acompanhar a partida pelo manômetro. Um erro rompe a união de alívio e faz subir a água da bacia no presente. O registro de alimentação permite rearmar e repetir. Em regime, o nível baixa e revela a grade do ralo.

**Drenagem jogável.** A passagem atrás da bacia leva ao coletor de esgotamento. Em 1923 a pressão de serviço libera três ralos. Hoje, Lia pode seguir as tubulações e inspecionar onde descarregam. Com apenas uma descarga livre o nível baixa parcialmente. O ramal rompido devolve água ao canal. Com as duas descargas livres e o ramal rompido isolado, a boia baixa, a grade sobe e Lia pode atravessar pelas rampas até a bancada da oficina. A cunha retém a regulagem, e o caminho de volta permanece livre. A ficha na bancada introduz a próxima etapa, as engrenagens.

**Oficina e inspeção da F-2.** A duplicata de 1951 na manutenção identifica o arquivo de Caio. No dossiê, Marta deixou uma foto da bancada das caldeiras em 1979. Em 2003, Tomás reconheceu os três cortes de lima da foto e descreveu a altura da ferrugem no caderno que deixou junto à mochila. Helena pode transferir o pinhão e a coroa sobressalentes para os ganchos altos. Só as peças preservadas ficam disponíveis para Lia. Ela monta cada peça no eixo correspondente e gira a manivela. Uma haste liga a bancada à caixa de inspeção da segunda caldeira. Quando a portinhola sobe, Lia volta a pé até ela e vê as duas hastes de tiragem.

**A última regulagem.** Cada haste tem quatro furos e apenas um deles está polido. Contando a partir do pivô de cada haste, Lia distingue a terceira posição na admissão e a segunda na chaminé. Em 1923, com a pressão de serviço e os ralos regulados, Helena pode experimentar as posições dos dois volantes. A regulagem certa deixa o ferrolho da caixa de limpeza alinhado. Hoje, Lia puxa a tampa ao lado da inspeção e encontra a lanterna apagada de Tomás com a última folha do caderno. Ler o relato dele encerra a Casa das Caldeiras. Lia permanece diante da caixa e pode refazer o caminho até a Biblioteca.

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
- [x] Como o jogador percebe que está no fim de um andar? (fade ao Saguão e novidade no livro)
- [x] Quantos hóspedes desaparecidos existem e quem são? (um por geração, ver "História e personagens")
- [ ] O elevador principal leva aos andares em 1923? Hoje a cabine fica no alto para sempre; decidir antes da Biblioteca.
- [ ] Qual é o nome definitivo do jogo?
- [ ] Como serão o final e a revelação da reviravolta (depois da fase de testes)?
