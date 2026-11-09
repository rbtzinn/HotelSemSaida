# Jogar em dupla

Os dois jogadores usam a mesma versão de **Hotel Sem Saída**. No Windows, extraia o ZIP inteiro (o `.exe` precisa do `HotelSemSaida.pck` e das DLLs da Epic que vêm ao lado dele) e abra `HotelSemSaida.exe`. Se o Windows avisar "O Windows protegeu o computador", clique em **Mais informações > Executar assim mesmo**.

A versão aparece embaixo, na recepção. Quando sair uma nova, clique em **Atualizar** e depois em **Reiniciar o jogo**; não precisa baixar o ZIP de novo. Na dupla, os dois precisam estar na mesma versão.

## Com código de sala (normal)

1. Os dois escrevem o próprio nome no campo **Seu nome** (a outra pessoa vê).
2. Quem vai hospedar escolhe Helena ou Lia e clica em **Criar sala**. Aparece um código de 6 letras e números (ex.: `K7M2QX`); **Copiar** o põe na área de transferência.
3. O amigo digita o código em **Código da sala** e clica em **Entrar**. Maiúsculas, espaços e traços não importam.
4. Na sala, o anfitrião ainda pode trocar de personagem; o amigo fica com a outra e vê a troca na hora.
5. O anfitrião clica em **Novo jogo** ou, se já houver progresso da dupla, **Retomar save**. Ao retomar, vale a personagem escolhida agora; Helena e Lia voltam à sala e à posição salvas.

Ninguém precisa de conta da Epic nem abrir portas no roteador: a conexão passa pelos servidores da Epic quando a ligação direta não dá. Redes de empresa ou faculdade podem bloquear; aí use o plano B.

## Plano B: por endereço (Playit)

Na recepção, clique em **Plano B: entrar por endereço (Playit)**.

1. O anfitrião clica em **Criar sala por endereço (UDP 7777)**.
2. No PC do anfitrião, abra o agente do Playit, vincule-o à sua conta e crie um túnel **UDP** com endereço local `127.0.0.1` e porta local `7777`. Mantenha-o aberto durante a partida. [Playit para Windows](https://playit.gg/download/windows)
3. Envie ao amigo o **endereço público completo** do túnel (com a porta). Ele cola no campo **Endereço:porta** e clica em **Entrar**. Na mesma rede Wi-Fi, vale o IPv4 local do anfitrião com a porta 7777.

## Durante a partida

Cada pessoa anda e lê na sua própria tela; o Tab não troca de personagem no online. As portas podem ser atravessadas separadamente. Quando Helena muda um objeto, Lia vê a consequência no presente. Esc pausa apenas a tela de quem apertou.

Para guardar o progresso, o anfitrião usa **F2** ou **Esc → Salvar a dupla**. O progresso da dupla fica num arquivo separado do solo, no PC do anfitrião.

## Preparar a sala por código (uma vez, no projeto)

O código de sala usa o **Epic Online Services** (grátis) pelo plugin **EOSG** (Epic Online Services Godot, MIT). Sem o plugin ou sem as chaves, a recepção avisa o que falta e o plano B continua funcionando.

### 1. Plugin no Godot (não precisa de administrador)

1. Abra o projeto no Godot, aba **AssetLib**, busque **Epic Online Services Godot** (de 3ddelano, versão 2.3.1 ou mais nova), **Download** e **Install** (instala em `addons/epic-online-services-godot/`).
2. **Projeto > Configurações do Projeto > Plugins**: ligue **Epic Online Services Godot (EOSG)**. Isso adiciona os autoloads do plugin (`EOSGRuntime`, `HPlatform`, `HAuth`, `HLobbies`…).
3. Faça commit e push da pasta `addons/` e do `project.godot`.

### 2. Produto no Epic Developer Portal

1. Entre em [dev.epicgames.com/portal](https://dev.epicgames.com/portal) (crie a organização se pedir) e **Create Product** com o nome *Hotel Sem Saida*.
2. **Product Settings > Clients > Add new client policy**: tipo **Custom policy**, **User is required desligado**, e permita as ações de **Connect** (login), **Lobbies** e **P2P**. Salve.
3. **Add new client** com essa policy (tipo *GameClient*).
4. Em **Product Settings > SDK Download & Credentials** copie: Product ID, Sandbox ID e Deployment ID, Client ID e Client Secret. O produto do Hotel só tem o sandbox *Live*, e funciona com ele.

No produto do Hotel, a policy usada é a pronta **Peer2Peer** (permite o login anônimo, os lobbies e o P2P); uma policy própria só precisa dessas mesmas permissões.

### 3. Chaves no projeto

Copie `epic_credentials.example.cfg` para `epic_credentials.cfg` na raiz do projeto e preencha. A *encryption_key* pode ser qualquer sequência de 64 caracteres hexadecimais. O arquivo fica fora do git (o repositório é público) e entra sozinho no `.exe` exportado.

### 4. Testar e gerar a versão

- **No mesmo PC**: abra duas cópias do jogo (ou rode duas vezes o `.exe`); uma cria a sala e a outra entra com o código. Cada cópia ganha uma identidade anônima própria na Epic, então não precisa de outro PC nem da DevAuthTool. Sem janela: `Godot_console.exe --headless --path . --script res://tools/test_epic_sala.gd -- criar` num terminal e `-- entrar CODIGO` em outro.
- **Com o amigo**: mande o ZIP e teste pela internet de verdade (é o que confere a rede dele).
- **Gerar o `.exe`**: Projeto > Exportar > Windows x64 > Exportar projeto, numa pasta vazia (ex.: `build/`). Saem o `HotelSemSaida.exe`, o `HotelSemSaida.pck` e três DLLs: `libeosg.windows.template_release.x86_64.dll`, `EOSSDK-Win64-Shipping.dll` e `xaudio2_9redist.dll`. Zipe a pasta inteira; sem as DLLs, o jogo abre mas a sala por código diz que falta o plugin. Para publicar uma versão (com o botão Atualizar do jogo), use `tools/publicar_versao.sh` (ver CLAUDE.md, "Atualização pelo jogo").
