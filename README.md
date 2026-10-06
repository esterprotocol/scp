# Site Director

Jogo 2D de construção e gestão em **Godot 4.6.3 stable**, build oficial **`4.6.3.stable.official.7d41c59c4`**, com GDScript e renderizador **Compatibility**. O protótipo cobre mapa, câmera, seleção, movimentação e planejamento/construção de paredes por um engenheiro. Sem assets externos, plugins ou dependências de jogo.

A entrega de construção está na branch `feat/construction-basic`, criada da base `feat/site-director-prototype`, commit `175a9f4`. A `main` ainda não continha o protótipo na criação desta entrega.

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
| Botão “Selecionar” | Ativar controles de seleção e movimento |
| Botão esquerdo sobre o engenheiro, no modo Selecionar | Selecionar |
| Botão esquerdo sobre o chão, no modo Selecionar | Desselecionar |
| Botão direito, com engenheiro selecionado, no modo Selecionar | Mover; durante uma obra a ordem é recusada com explicação |
| Botão “Planejar parede” | Ativar planejamento por células individuais |
| Botão esquerdo, no modo Planejar parede | Marcar uma célula como blueprint |
| Botão direito, no modo Planejar parede | Cancelar blueprint/tarefa da célula |
| Botão “Autorizar planejados” | Criar uma tarefa para cada blueprint ainda não autorizado |
| Botão “Cancelar tarefa atual” | Remover a obra atual e liberar o engenheiro |
| Botão “Cancelar todas as obras” | Remover todos os blueprints e trabalhos incompletos |
| WASD ou setas | Deslocar câmera |
| Arrastar com botão central | Deslocar câmera |
| Roda do mouse | Zoom entre 0,65× e 1,8× |
| Botão “Reiniciar cenário” | Restaurar cenário original, grade, obras, modo, engenheiro, câmera e painel |

O engenheiro é dourado, paredes são cinza e a rota/seleção são verdes. Blueprints são contornos cruzados: **azul** antes da autorização, **dourado** após autorização e **vermelho** quando bloqueados. Todos permanecem transitáveis até a conclusão. O painel mostra seleção, estado, destino, tarefa, progresso, contagem de obras e motivos de bloqueio por célula. Use a rolagem do painel para acessar as ações caso o conteúdo exceda a janela. Cliques na interface não dão ordens nem planejam paredes no mapa.

## Regras do protótipo

- Mapa de **24 × 24 células**, com **32 pixels** por célula; coordenadas `(x, y)` começam em `(0, 0)` no canto superior esquerdo.
- Engenheiro começa em `(4, 5)` e anda a **128 px/s**.
- Busca em largura (BFS) encontra uma rota mínima entre células de mesmo custo. Só há passos ortogonais: não atravessa paredes nem corta quinas.
- Uma ordem durante o movimento termina o segmento atual antes de seguir a nova rota. Ordens inválidas preservam a rota e o destino anteriores, mostrando o motivo.
- Parede em `x=10`, de `y=3` a `18`, com passagem em `y=12`; paredes adicionais e sala fechada entre `(18, 18)` e `(21, 21)`.
- Dimensões, velocidade, posição inicial e limites da câmera estão centralizados em `scripts/settings.gd`. O cenário fixo é definido em `scripts/grid_state.gd`.

## Planejamento e construção

1. Ative **Planejar parede** e marque células livres com o botão esquerdo. Não é permitido planejar fora do mapa, sobre paredes ou sobre o engenheiro (incluindo as duas pontas do segmento em movimento).
2. Pressione **Autorizar planejados**. Há uma tarefa por célula; repetir a autorização não cria duplicatas. Não é necessário selecionar o engenheiro, formar uma sala ou fechar um perímetro. A abertura original `(10, 12)` é planejável.
3. Quando livre e no centro de uma célula, o engenheiro procura a posição ortogonal adjacente mais próxima com caminho. Uma ordem manual já em trânsito termina antes de assumir uma tarefa.
4. O engenheiro caminha até essa posição e trabalha por **2 segundos**, configurados em `GameSettings.WALL_BUILD_SECONDS`. O tempo de deslocamento não conta como trabalho. Somente ao completar a duração a parede vira obstáculo.
5. Antes de começar e em cada atualização de trabalho, inclusive na conclusão, são revalidados alvo livre, ocupação e posição adjacente transitável. Obras inacessíveis recebem um motivo e são puladas para permitir outras acessíveis.

Mudanças na grade invalidam rotas afetadas: o engenheiro termina somente o segmento ainda seguro, sem teleportar nem atravessar a nova parede. Tarefas são reavaliadas quando a grade ou a posição/estado do engenheiro muda e após conclusão/cancelamento. Se perder acesso, a obra volta a aguardar acesso, com seu progresso de trabalho reiniciado.

Durante uma tarefa (incluindo deslocamento), ordens manuais de movimento são recusadas. Cancele a tarefa atual ou clique direito na sua célula no modo Planejar para liberar o engenheiro. Cancelar trabalho incompleto apaga tarefa e blueprint; em trânsito, apenas o trecho corrente termina, e uma nova ordem manual pode redirecionar a partir desse centro. Paredes já concluídas permanecem até o reinício; não há demolição.

## Validação automatizada

```bash
bash tools/validate.sh
git diff --check
```

O script importa o projeto, executa `tests/test_runner.gd` e roda a cena principal por 120 frames em modo headless. Preserva falhas dos comandos, detecta diagnósticos de erro e exige um resultado com verificações realmente executadas. O runner termina com código diferente de zero em falha e tem limite de 30 segundos.

Cobertura anterior preservada: rota livre e mínima, desvio pela passagem, parede, fora do mapa, sala inacessível, quina diagonal bloqueada, destino atual, velocidade e chegada, redirecionamento em movimento, preservação de ordem após rejeição, limites da câmera, atualização do painel, reinício e eventos de clique passando pelo viewport/interface.

Cobertura de construção em `tests/construction_tests.gd`: blueprint transitável; autorização sem duplicação; trabalho adjacente e duração/progresso; rejeição de ordens manuais; cancelamento parado e em trânsito sem teleportar; parede concluída muda navegação; tarefa inacessível não bloqueia acessíveis; ocupação e alvo revalidados; bloqueios reavaliados por mudanças da grade; rota invalidada; nova posição de trabalho após perder acesso; controles de planejamento/autorização/cancelamento pelo viewport; construção da abertura original; reinício integral.

Validação nesta entrega: **326 verificações, zero falhas**, incluindo as 176 anteriores; importação e execução headless concluídas com `bash tools/validate.sh`. A execução gráfica da entrega anterior foi tentada, mas o ambiente não oferecia X11/Wayland: `X11 Display is not available` e `Can't connect to a Wayland display`. Headless não valida pixels, aparência ou interação humana; a validação visual desta entrega continua explicitamente pendente em uma sessão gráfica.

## Teste manual visual (pendente)

1. Execute o projeto com F5. Confira o mapa inteiro, painel legível e engenheiro dourado. Clique direito sem selecionar: deve pedir seleção.
2. Selecione o engenheiro e clique direito em `(7, 5)`: deve seguir em linha reta e parar no centro. Confira estado e destino no painel.
3. Envie para `(9, 8)` e depois `(11, 8)`: deve contornar a parede pela passagem em `(10, 12)`, sem cortar quinas.
4. Clique direito em `(10, 5)` (parede), fora do mapa e em `(19, 19)` (chão isolado): confira mensagens distintas e legíveis.
5. Dê outra ordem durante o movimento; confira que termina o segmento em curso antes de mudar de direção. Tente uma ordem inválida em movimento: a rota anterior deve continuar.
6. Mova a câmera com teclas e botão central; teste os dois extremos de zoom e selecione/mova novamente após deslocar e ampliar.
7. Clique no painel: a seleção deve permanecer. Reinicie durante o movimento: engenheiro, painel e câmera devem voltar ao estado inicial.
8. Ative **Planejar parede** e marque `(6, 5)`: confira o contorno azul. No modo Selecionar, mova pelo blueprint; ele não deve impedir passagem. Reinicie e planeje novamente.
9. Autorize duas vezes: confira uma única tarefa para `(6, 5)`. O engenheiro deve ir a uma célula adjacente e trabalhar por 2 segundos; confira progresso. Antes de concluir, a célula deve ser transitável; ao concluir, deve virar parede cinza.
10. Selecione o engenheiro durante a obra e tente mover: confira a recusa. Cancele a tarefa atual durante o trabalho e repita durante o deslocamento. Tarefa e blueprint devem desaparecer, sem salto de posição, e ordens manuais devem voltar a funcionar.
11. Planeje primeiro `(19, 19)` (sala inacessível) e depois `(6, 5)`. Autorize: a primeira deve mostrar motivo de bloqueio; a segunda deve ser executada. No modo Planejar, cancele individualmente a obra bloqueada com o botão direito.
12. Planeje a abertura `(10, 12)` e autorize: deve ser construída sem exigir uma sala fechada. Planeje outras paredes, conclua uma, deixe outra em andamento e reinicie: todas as paredes novas, blueprints e tarefas devem sumir, restaurando também a abertura original.
13. Clique nos botões e no painel com o modo Planejar ativo: nenhum blueprint deve aparecer no mapa por causa desses cliques. Confira legibilidade das razões e acesso a todos os botões pela rolagem do painel.

## Organização e limite de escopo

`grid_state.gd`: estado e alterações da grade; `navigation.gd`: busca de rotas; `engineer.gd`: personagem, movimento e invalidação de rotas; `construction.gd`: blueprints, tarefas, escolha de posição, bloqueios e trabalho; `map_view.gd`: desenho; `site_camera.gd`: câmera; `hud.gd`: interface; `main.gd`: composição e comandos. A cena fica em `scenes/main.tscn`.

Portas, demolição, economia, necessidades, SCPs, combate, save/load e múltiplos trabalhadores não fazem parte desta entrega. Veja `docs/PROGRESS.md` para o estado da validação e a próxima tarefa.
