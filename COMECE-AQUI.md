# Hotel Sem Saída — como começar o protótipo (Godot)

Este guia leva você do zero até a primeira etapa rodando no Godot com o Claude Code. Nada aqui precisa de acesso de administrador.

## 1. Baixar o Godot

1. Abra <https://godotengine.org/download/windows/>.
2. Baixe a versão **Godot Engine** padrão (não a ".NET"), 64 bits. Vem um `.zip`.
3. Crie a pasta `C:\Users\roberto.gabriel\Ferramentas\Godot` e extraia o `.zip` lá dentro.
4. Dentro dela ficam dois executáveis: `Godot_v4.x-stable_win64.exe` (abre o editor) e `..._console.exe` (o mesmo, com janela de terminal). Não precisa instalar nada.
5. Opcional: clique com o botão direito no `.exe` sem "console" e escolha **Enviar para → Área de trabalho (criar atalho)**.

## 2. Criar a pasta do projeto

Não precisa criar o projeto no Godot: o Claude Code cria o `project.godot` na Etapa 1. Basta dizer a ele em qual pasta trabalhar, por exemplo:

```
C:\Users\roberto.gabriel\Documents\Projetos\HotelSemSaida
```

O `CLAUDE.md` fica na raiz dessa pasta.

## 3. Abrir o projeto no Godot (depois da Etapa 1)

1. Abra o Godot. Na tela **Gerenciador de Projetos**, clique em **Importar**.
2. Escolha o arquivo `project.godot` dentro de `HotelSemSaida` e clique em **Importar e editar**.
3. Para rodar o jogo, aperte **F5** (cena principal) ou **F6** (cena aberta).

Deixe o Godot aberto enquanto o Claude Code trabalha. Quando ele alterar scripts, o Godot recarrega sozinho; se pedir para recarregar arquivos, aceite.

## 4. Prompts de cada etapa

Use um prompt por vez. Só passe para a próxima etapa quando a atual estiver funcionando.

**Etapa 1 — Base do projeto**
```
Leia o CLAUDE.md. Faça a Etapa 1 (Base do projeto): project.godot com resolução, escala inteira e Input Map da tabela, estrutura de pastas e a cena sala_teste com parede, piso e as raízes World1923 e WorldToday. No final, me diga exatamente o que fazer no Godot para testar.
```

**Etapa 2 — Troca de época**
```
Etapa 2 do CLAUDE.md: EraManager, EraVisibility, fade de transição e HUD mínimo com a personagem ativa e o ano. Me diga como testar.
```

**Etapa 3 — Duas personagens**
```
Etapa 3 do CLAUDE.md: PlayerMotor lateral, CharacterInput e SoloInputRouter. Helena aparece só em 1923, Lia só hoje, e cada uma fica parada quando a outra está ativa. Me diga como testar.
```

**Etapa 4 — Causa e consequência**
```
Etapa 4 do CLAUDE.md: WorldState, Interactable, EraLinkedObject e o enigma de teste do armário. Me diga como testar e qual é a sequência para resolver.
```

**Etapa 5 — Câmera de cima**
```
Etapa 5 do CLAUDE.md: modo TOP_DOWN no PlayerMotor e a cena sala_teste_de_cima. Me diga como testar.
```

**Etapa 6 — Salvar e carregar**
```
Etapa 6 do CLAUDE.md: salvar e carregar o WorldState e a posição das duas personagens em JSON. Me diga como testar.
```

## 5. Se der erro

Copie o texto do erro da aba **Saída** ou **Depurador** (parte de baixo do editor) e cole no Claude Code, dizendo em qual etapa você estava.
