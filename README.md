# Site Director

Primeira entrega de um jogo 2D de construção e gestão em **Godot 4.6.3 stable**, build oficial **`4.6.3.stable.official.7d41c59c4`**, com GDScript e renderizador **Compatibility**. Este protótipo cobre mapa, câmera, seleção e movimentação de um engenheiro. Sem assets externos, plugins ou dependências de jogo.

## Executar

Abra `project.godot` na versão indicada do Godot e pressione **F6** na cena `scenes/main.tscn` ou **F5** para executar o projeto.

No ambiente na nuvem, o executável já existe em `/usr/local/bin/godot`, apontando para `/opt/godot/4.6.3/Godot_v4.6.3-stable_linux.x86_64`. Em outra máquina, instale o editor padrão (sem .NET) da [release oficial 4.6.3](https://github.com/godotengine/godot-builds/releases/tag/4.6.3-stable). Confira o arquivo baixado contra `SHA512-SUMS.txt` da mesma release. Não é necessário instalar pacotes de GDScript.

Com Bash, a partir da raiz do repositório:

```bash
bash tools/godot.sh --headless --version
bash tools/godot.sh --headless --editor --import
bash tools/godot.sh --editor
# Ou executar diretamente, numa sessão gráfica:
bash tools/godot.sh
```

`tools/godot.sh` verifica a versão exata e prepara diretórios XDG graváveis em `.tools/` (ignorados pelo Git), evitando erros de cache de fontes e dados no sandbox. Use `GODOT_BIN=/caminho/para/godot bash tools/godot.sh ...` se o executável não estiver no PATH. O wrapper não baixa binários nem altera o sistema. Em Windows, abra o projeto diretamente com o editor oficial indicado.

## Controles

| Entrada | Ação |
| --- | --- |
| Botão esquerdo sobre o engenheiro | Selecionar |
| Botão esquerdo sobre o chão | Desselecionar |
| Botão direito, com engenheiro selecionado | Mover para a célula apontada |
| WASD ou setas | Deslocar câmera |
| Arrastar com botão central | Deslocar câmera |
| Roda do mouse | Zoom entre 0,65× e 1,8× |
| Botão “Reiniciar cenário” | Restaurar posição, seleção, destino, câmera e mensagem |

O engenheiro é dourado, paredes são cinza e a rota/seleção são verdes. O painel mostra selecionado, estado, destino e mensagens. Cliques no painel não dão ordens ao mundo.

## Regras do protótipo

- Mapa de **24 × 24 células**, com **32 pixels** por célula; coordenadas `(x, y)` começam em `(0, 0)` no canto superior esquerdo.
- Engenheiro começa em `(4, 5)` e anda a **128 px/s**.
- Busca em largura (BFS) encontra uma rota mínima entre células de mesmo custo. Só há passos ortogonais: não atravessa paredes nem corta quinas.
- Uma ordem durante o movimento termina o segmento atual antes de seguir a nova rota. Ordens inválidas preservam a rota e o destino anteriores, mostrando o motivo.
- Parede em `x=10`, de `y=3` a `18`, com passagem em `y=12`; paredes adicionais e sala fechada entre `(18, 18)` e `(21, 21)`.
- Dimensões, velocidade, posição inicial e limites da câmera estão centralizados em `scripts/settings.gd`. O cenário fixo é definido em `scripts/grid_state.gd`.

## Validação automatizada

```bash
bash tools/validate.sh
git diff --check
```

O script importa o projeto, executa `tests/test_runner.gd` e roda a cena principal por 120 frames em modo headless. Preserva falhas dos comandos, detecta diagnósticos de erro e exige um resultado com verificações realmente executadas. O runner termina com código diferente de zero em falha e tem limite de 30 segundos.

Cobertura: rota livre e mínima, desvio pela passagem, parede, fora do mapa, sala inacessível, quina diagonal bloqueada, destino atual, velocidade e chegada, redirecionamento em movimento, preservação de ordem após rejeição, limites da câmera, atualização do painel, reinício e eventos de clique passando pelo viewport/interface.

Validação nesta entrega: **176 verificações, zero falhas**, importação e execução headless concluídas. A execução gráfica foi tentada, mas o ambiente não oferece X11/Wayland: `X11 Display is not available` e `Can't connect to a Wayland display`. Headless não valida pixels, aparência ou interação humana; o teste visual abaixo continua pendente em uma sessão gráfica.

## Teste manual visual (pendente)

1. Execute o projeto com F5. Confira o mapa inteiro, painel legível e engenheiro dourado. Clique direito sem selecionar: deve pedir seleção.
2. Selecione o engenheiro e clique direito em `(7, 5)`: deve seguir em linha reta e parar no centro. Confira estado e destino no painel.
3. Envie para `(9, 8)` e depois `(11, 8)`: deve contornar a parede pela passagem em `(10, 12)`, sem cortar quinas.
4. Clique direito em `(10, 5)` (parede), fora do mapa e em `(19, 19)` (chão isolado): confira mensagens distintas e legíveis.
5. Dê outra ordem durante o movimento; confira que termina o segmento em curso antes de mudar de direção. Tente uma ordem inválida em movimento: a rota anterior deve continuar.
6. Mova a câmera com teclas e botão central; teste os dois extremos de zoom e selecione/mova novamente após deslocar e ampliar.
7. Clique no painel: a seleção deve permanecer. Reinicie durante o movimento: engenheiro, painel e câmera devem voltar ao estado inicial.

## Organização e limite de escopo

`grid_state.gd`: estado da grade; `navigation.gd`: busca de rotas; `engineer.gd`: personagem e movimento; `map_view.gd`: desenho; `site_camera.gd`: câmera; `hud.gd`: interface; `main.gd`: composição e comandos. A cena fica em `scenes/main.tscn`.

Construção, economia, necessidades, SCPs, combate, persistência e múltiplos personagens não fazem parte desta entrega. Veja `docs/PROGRESS.md` para o estado da validação e a próxima tarefa.
