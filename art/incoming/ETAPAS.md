# Pacote de arte — etapas de geração

Gerado em 03/11/2026 com a ferramenta integrada de geração de imagens, a partir de [PROMPTS.md](../prompts/PROMPTS.md) e das referências do projeto.

As **15 imagens estão salvas nesta pasta**, com os nomes pedidos e resolução **1536 × 1024**. São fontes para recorte e integração; as animações ainda não foram montadas nem reproduzidas no Godot.

## Etapa 1 — Cenários do Saguão: gerados

- [M1 — Saguão em 1923](saguao_1923.png)
- [M2 — Saguão no presente](saguao_present.png)

O tapete redondo e o piano de cauda do passado foram corrigidos após a primeira geração. O presente mantém a arquitetura envelhecida, a escada destruída, o lustre caído e o piano coberto.

## Etapa 2 — Objetos: gerados

- [O1 — Objetos de 1923](objetos_1923.png)
- [O2 — Objetos do presente](objetos_hoje.png)

Cada folha tem oito células ocupadas, com os objetos e seus estados. Os tamanhos gerados variam em relação às medidas do prompt; precisam ser normalizados no recorte para caber nos espaços reservados do cenário.

## Etapa 3 — Lia: gerada

- [L1 — Caminhar de lado](lia_lado_andar.png)
- [L2 — Caminhar de frente](lia_frente_andar.png)
- [L3 — Caminhar de costas](lia_costas_andar.png)
- [L4 — Parada e interações](lia_parada.png)

As duas poses frontais de L4 foram corrigidas para olhar de frente. As quatro folhas usam a referência atual da Lia; os quadros existentes de descida pelos cabos não foram substituídos.

## Etapa 4 — Helena: gerada

- [H1 — Caminhar de lado](helena_lado_andar.png)
- [H2 — Caminhar de frente](helena_frente_andar.png)
- [H3 — Caminhar de costas](helena_costas_andar.png)
- [H4 — Parada e interações](helena_parada.png)
- [H5 — Caminhar com gelo](helena_gelo_andar.png)
- [H6 — Caminhar com fermento](helena_fermento_andar.png)
- [H7 — Colocar gelo e usar fermento](helena_usar.png)

## Conferência dos arquivos

- Os quinze PNGs abrem e têm 1536 × 1024 pixels.
- As cópias salvas correspondem às fontes geradas, conferidas por SHA-256.
- As treze folhas têm oito células com conteúdo, sem silhuetas encostando nas bordas das células na inspeção por máscara de magenta.
- As folhas usam **fundo magenta**, alternativa prevista no pacote: as tentativas de transparência dos objetos produziram halos. O fundo ainda deve ser removido no recorte.

Essa conferência verifica os arquivos e o espaço de recorte. Não comprova continuidade de animação, escala corporal uniforme ou encaixe com as colisões do jogo.

## Etapa seguinte — Recorte e integração: pendente

1. Remover o fundo magenta e separar as células, preservando as fontes desta pasta.
2. Alinhar pés e tronco sem redimensionar cada quadro de forma independente; verificar continuidade dos ciclos em reprodução.
3. Conferir a grade de pixels da Helena e normalizar os objetos às medidas do jogo.
4. Conferir cenários contra a geometria e as colisões, especialmente a área do lustre caído.
5. Montar as animações, integrar os recursos e validar no Godot.

Os prompts efetivamente enviados, referências, correções, fontes, hashes e verificações estão em [generation-manifest.json](generation-manifest.json).
