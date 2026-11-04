# Jogar em dupla

Os dois jogadores usam a mesma versão de **Hotel Sem Saída**. No Windows, extraia o ZIP e abra `HotelSemSaida.exe`. No projeto Godot, aperte **F5** para abrir a recepção.

1. Quem vai hospedar escolhe Helena ou Lia e clica em **Criar sala**. O outro jogador fica com a personagem da outra época.
2. No PC do anfitrião, abra o agente do Playit, vincule-o à sua conta e crie um túnel **UDP** de uma porta. Use `127.0.0.1` como endereço local e `7777` como porta local. Mantenha o agente aberto durante a partida. [Playit para Windows](https://playit.gg/download/windows)
3. Copie o **endereço público completo** do túnel, incluindo a porta pública que o Playit atribuiu. Envie-o ao amigo. No lobby, ele cola esse endereço no campo **Endereço:porta** e clica em **Entrar**. Só o anfitrião precisa rodar o Playit. [Como funciona o Playit](https://playit.gg/)
4. Quando aparecer **Dupla completa**, o anfitrião clica em **Começar no Saguão**. Na mesma rede Wi-Fi, o visitante também pode entrar usando o IPv4 local do anfitrião e a porta 7777.

Cada pessoa anda e lê na sua própria tela. As portas podem ser atravessadas separadamente. Quando Helena muda um objeto, Lia vê a consequência no presente. Esc pausa apenas a tela de quem apertou.

Para guardar o progresso, o anfitrião usa **F2** ou **Esc → Salvar a dupla**. Na próxima sessão, os dois entram no lobby e o anfitrião escolhe **Retomar save da dupla**. Cada personagem volta à sala e à posição salvas. A dupla tem um arquivo de progresso separado do solo.
