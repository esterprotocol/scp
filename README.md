# Site Director

Jogo 2D de construção e gestão em **Godot 4.6.3 stable**, build oficial **`4.6.3.stable.official.7d41c59c4`**, com GDScript e renderizador **Compatibility**. O protótipo cobre mapa, câmera, seleção, movimentação, construção com saída segura, demolição física, portas operáveis, áreas designadas, objetos instalados e um slot manual de salvar/carregar. Sem assets externos, plugins ou dependências de jogo.

A entrega visual está na branch `feat/character-visuals`, criada da base verificada `feat/escape-selection-shortcut`, commit `c0f71a1`. Sem merge automático na `main`.

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
| Esc | Voltar ao modo Selecionar e limpar a seleção de engenheiro/célula; obras e blueprints continuam |
| Botão esquerdo sobre o engenheiro, no modo Selecionar | Selecionar |
| Botão esquerdo sobre o chão, no modo Selecionar | Desselecionar |
| Botão direito, com engenheiro selecionado, no modo Selecionar | Mover; durante uma obra a ordem é recusada com explicação |
| Botão “Planejar parede” | Ativar planejamento por células individuais |
| Botão esquerdo, no modo Planejar parede | Marcar uma célula como blueprint |
| Botão direito, no modo Planejar parede | Cancelar blueprint/tarefa da célula |
| Botão “Demolir” | Ativar seleção de paredes para demolição |
| Botão esquerdo sobre parede, no modo Demolir | Solicitar uma tarefa de demolição, sem remover a parede |
| Botão direito, no modo Demolir | Cancelar a tarefa da célula, preservando a parede |
| Botão “Porta” e esquerdo sobre uma parede | Solicitar instalação física de porta fechada |
| Botão direito, no modo Porta | Cancelar instalação incompleta; a parede original permanece |
| Esquerdo sobre uma porta no modo Selecionar; botão “Abrir/Fechar porta” | Selecionar e operar a porta; não fecha sobre o engenheiro |
| Botão “Área”, seletor de tipo e esquerdo sobre piso | Pintar célula transitável; arrastar com esquerdo pinta outras células |
| Tipo “Sem área” | Apagar designação da célula pintada |
| Botão “Objeto” e seletor de tipo | Planejar Cama, Mesa de refeitório, Assento ou Distribuidor de refeições |
| Esquerdo/direito, no modo Objeto | Criar blueprint transitável ou cancelar blueprint/obra incompleta |
| Esquerdo sobre objeto no modo Selecionar | Mostrar tipo, área e pontos de interação disponíveis |
| Esquerdo sobre objeto no modo Demolir | Solicitar demolição física; libera a célula só após concluir |
| Botão “Autorizar planejados” | Criar uma tarefa para cada blueprint ainda não autorizado |
| Botão “Cancelar tarefa atual” | Remover a obra atual e liberar o engenheiro |
| Botão “Cancelar todas as obras” | Remover todos os blueprints e trabalhos incompletos |
| WASD ou setas | Deslocar câmera |
| Arrastar com botão central | Deslocar câmera |
| Roda do mouse | Zoom entre 0,65× e 1,8× |
| Botão “Reiniciar cenário” | Restaurar cenário original, grade, obras, modo, engenheiro, câmera e painel |
| Botão “Salvar” | Substituir o slot manual pelo cenário atual |
| Botão “Carregar” | Substituir o cenário atual pelo slot validado |
| Botões “Pausa”, “1×” e “2×” | Pausar ou alterar a velocidade da simulação; Reiniciar volta a 1× |

O engenheiro é dourado, paredes são cinza e a rota/seleção são verdes. Blueprints de parede são contornos cruzados **azuis** antes da autorização, **dourados** após autorização e **vermelhos** quando bloqueados. Blueprints de objeto usam contorno cruzado na cor do tipo; o objeto concluído é uma forma sólida. Todos os blueprints permanecem transitáveis até a conclusão. Demolições são marcadas por círculo e risco **laranja**, ou vermelho quando bloqueadas; o alvo continua no lugar durante o trabalho. Portas e instalações são **roxas** quando fechadas/em obra, com traço horizontal; portas abertas são **ciano**, com traço lateral. Áreas usam cores suaves: Alojamento azul, Refeitório verde, Contenção violeta. Um pequeno contorno verde marca a saída de referência. O painel esquerdo mostra ferramenta ativa, ação, progresso, mensagens e motivos de bloqueio; o painel direito mostra seleção, área, objeto, interação, estado da porta e destino. Use a rolagem do painel para acessar as ações caso o conteúdo exceda a janela. Cliques na interface não dão ordens nem solicitam tarefas no mapa.

## Interface operacional

O HUD usa uma paleta escura institucional com alertas âmbar e bloqueios vermelhos. Os seis botões de ferramenta usam pictogramas de texto no mesmo formato; a ferramenta ativa recebe preenchimento verde. O requisito de área do objeto selecionado aparece sob o seletor. O painel de inspeção à direita mantém dados de célula, objeto, porta e engenheiro visíveis enquanto o painel esquerdo rola. A ajuda e a legenda podem ser expandidas no fim do painel. As formas e cores são originais do projeto, sem assets externos.

Pausa, 1× e 2× controlam `Engine.time_scale`. Reiniciar volta a 1×; o slot manual continua salvando o mundo e a ferramenta, mas não a velocidade da interface. Ao carregar, a velocidade escolhida na sessão continua ativa.

## Regras do protótipo

- Mapa de **24 × 24 células**, com **32 pixels** por célula; coordenadas `(x, y)` começam em `(0, 0)` no canto superior esquerdo.
- Engenheiro começa em `(4, 5)` e anda a **128 px/s**.
- Busca em largura (BFS) encontra uma rota mínima entre células de mesmo custo. Só há passos ortogonais: não atravessa paredes, portas fechadas ou objetos concluídos, e não corta quinas.
- Uma ordem durante o movimento termina o segmento atual antes de seguir a nova rota. Ordens inválidas preservam a rota e o destino anteriores, mostrando o motivo.
- Parede em `x=10`, de `y=3` a `18`, com passagem em `y=12`; paredes adicionais e sala fechada entre `(18, 18)` e `(21, 21)`.
- Dimensões, velocidade, posição inicial e limites da câmera estão centralizados em `scripts/settings.gd`. O cenário fixo é definido em `scripts/grid_state.gd`.

## Planejamento e construção

1. Ative **Planejar parede** e marque células livres com o botão esquerdo. Não é permitido planejar fora do mapa, sobre paredes ou sobre o engenheiro (incluindo as duas pontas do segmento em movimento).
2. Pressione **Autorizar planejados**. Há uma tarefa por célula; repetir a autorização não cria duplicatas. Não é necessário selecionar o engenheiro, formar uma sala ou fechar um perímetro. A abertura original `(10, 12)` é planejável.
3. Quando livre e no centro de uma célula, o engenheiro procura a posição ortogonal adjacente segura mais próxima com caminho. Uma ordem manual já em trânsito termina antes de assumir uma tarefa. A posição mais próxima pode ser descartada para preservar a saída.
4. O engenheiro caminha até essa posição e trabalha por **2 segundos**, configurados em `GameSettings.WALL_BUILD_SECONDS`. O tempo de deslocamento não conta como trabalho. Somente ao completar a duração a parede vira obstáculo.
5. Antes de começar e em cada atualização de trabalho, inclusive na conclusão, são revalidados alvo livre, ocupação e posição adjacente transitável. Obras inacessíveis recebem um motivo e são puladas para permitir outras acessíveis.

Mudanças na grade invalidam rotas afetadas: o engenheiro termina somente o segmento ainda seguro, sem teleportar nem atravessar a nova parede. Tarefas são reavaliadas quando a grade ou a posição/estado do engenheiro muda e após conclusão/cancelamento. Se perder acesso, a obra volta a aguardar acesso, com seu progresso de trabalho reiniciado.

Durante uma tarefa (incluindo deslocamento), ordens manuais de movimento são recusadas. Cancele a tarefa atual ou clique direito na sua célula no modo Planejar/Demolir para liberar o engenheiro. Cancelar trabalho incompleto apaga tarefa e marcação; em trânsito, apenas o trecho corrente termina, e uma nova ordem manual pode redirecionar a partir desse centro.

## Saída segura

`GameSettings.EXIT_CELL` define a saída de referência, inicialmente igual a `SPAWN`, `(4, 5)`. Quando existe caminho até a saída antes da construção, a parede só pode ser construída de uma posição que ainda tenha esse caminho **com o alvo tratado como parede**. A busca testa todos os vizinhos alcançáveis e prefere o mais próximo dentre os seguros, mesmo se for preciso atravessar o blueprint ainda transitável para chegar ao outro lado.

Se os vizinhos alcançáveis não forem seguros, a tarefa fica bloqueada com **“Construção bloquearia a saída do engenheiro”**. A obrigação de preservar a saída é mantida nas tentativas posteriores da mesma tarefa e revalidada durante a obra, inclusive imediatamente antes de concluir. Uma saída que se torna acessível após o início também é protegida. Se o engenheiro já estava isolado antes de qualquer tentativa, não há caminho existente a preservar; obras ainda precisam de acesso adjacente normal.

A simulação passa uma célula bloqueada adicional para a BFS; não adiciona/remove paredes reais nem emite eventos de grade. Demolições acessíveis continuam sendo executadas mesmo se uma construção estiver bloqueada, e mudanças reais da grade reavaliam a fila.

## Demolição física

Ative **Demolir** e clique esquerdo numa parede original ou construída. A solicitação já cria uma tarefa na mesma fila da construção; repetir o pedido não duplica a tarefa, e não é necessário pressionar Autorizar. Apenas um trabalho pode ocupar o engenheiro por vez.

O engenheiro alcança um vizinho ortogonal transitável e trabalha por **1,5 segundo**, configurado em `GameSettings.WALL_DEMOLISH_SECONDS`. Até a conclusão, a parede continua bloqueando a navegação. Ao concluir, a grade remove a parede, emite a alteração e novas rotas/obras passam a poder usar a abertura. Alvo existente e posição adjacente são revalidados antes de trabalhar e concluir; uma tarefa sem acesso mostra o motivo e é pulada.

Clique direito na parede no modo Demolir, use **Cancelar tarefa atual** ou **Cancelar todas as obras** para cancelar antes da conclusão. A parede permanece e o engenheiro fica disponível. Reiniciar restaura exatamente as paredes originais, incluindo as demolidas, remove paredes novas e limpa as duas ações da fila.

## Portas e áreas designadas

No modo **Porta**, clique numa parede existente. O pedido entra na mesma fila de obras: o engenheiro chega a uma célula ortogonal adjacente e instala a porta por **1,5 segundo** (`GameSettings.DOOR_INSTALL_SECONDS`). Até terminar, a parede original continua sólida. Cancelar preserva essa parede. Ao concluir, a célula passa a ser uma porta fechada, que ainda bloqueia passagem. No modo **Selecionar**, clique na porta e use **Abrir porta** ou **Fechar porta** no painel. Abrir libera a passagem; fechar invalida rotas que a cruzariam e não é permitido enquanto o engenheiro ocupa a célula. Mudanças na porta reavaliam tarefas bloqueadas. O modo **Demolir** aceita portas abertas ou fechadas e só remove a porta após trabalho físico, deixando piso transitável. Reiniciar restaura paredes originais e remove todas as portas desta entrega.

No modo **Área**, escolha **Sem área**, **Alojamento**, **Refeitório** ou **Contenção** e clique/arraste o botão esquerdo sobre células transitáveis. Cada célula guarda seu tipo independentemente das paredes, portas, objetos e blueprints; formas livres são aceitas, sem exigência de recinto fechado. O tipo aparece ao selecionar a célula. Áreas não afetam navegação e ainda não tornam salas operacionais. Reiniciar limpa as designações.

## Objetos essenciais

No modo **Objeto**, selecione o tipo e clique numa célula transitável da área correta. **Cama** exige Alojamento; **Mesa de refeitório**, **Assento** e **Distribuidor de refeições** exigem Refeitório. A célula vira blueprint transitável. **Autorizar planejados** cria uma tarefa por célula na fila única do engenheiro. Ele chega a uma posição ortogonal adjacente e trabalha por **2 segundos** (`OBJECT_INSTALL_SECONDS`). Somente a conclusão cria o objeto sólido que bloqueia a navegação. Não é permitido colocar um objeto sobre parede, porta, outro objeto, engenheiro, blueprint ou tarefa incompatível.

Toda instalação conserva ao menos um vizinho transitável como futuro ponto de interação do objeto e, se o engenheiro tinha caminho para a saída, conserva esse caminho após a conclusão. Paredes, outros objetos e o fechamento de portas não podem eliminar o último ponto de interação de um objeto existente. Ao selecionar um objeto concluído, o painel lista seus vizinhos transitáveis. Eles ainda não executam uso ou atendimento nesta entrega.

Se a área mudar após o planejamento, a tarefa é revalidada antes de começar e em cada atualização de trabalho, inclusive na conclusão. Uma incompatibilidade bloqueia a tarefa com motivo legível, sem impedir outras obras. Cancelar durante viagem ou trabalho remove blueprint/tarefa sem criar objeto. **Demolir** um objeto também exige vizinho adjacente e **1,5 segundo** (`OBJECT_DEMOLISH_SECONDS`); a célula só fica livre ao terminar. Reiniciar remove objetos e obras criados pelo jogador.

## Salvar e carregar

Use os botões **Salvar** e **Carregar** no topo do painel esquerdo. O painel mostra sucesso ou o motivo da falha. Existe apenas um slot manual; salvar novamente o substitui. Não há autosave. **Reiniciar não apaga o arquivo**, e carregar posteriormente recupera o cenário salvo.

O arquivo é **`user://site_director.json`**. O caminho absoluto pode ser consultado com `OS.get_user_data_dir()` no Godot. Com `bash tools/godot.sh`, fica em **`.tools/data/godot/app_userdata/Site Director/site_director.json`**, dentro do repositório, em diretório ignorado pelo Git. Com o editor direto no Linux, o padrão é `~/.local/share/godot/app_userdata/Site Director/site_director.json`; outros sistemas usam o diretório de dados de usuário do Godot. O wrapper e o editor direto podem, portanto, usar arquivos diferentes.

O formato atual é JSON com `schema_version: 3` e `godot_version: "4.6.3.stable.official.7d41c59c4"`, versão do projeto também registrada em `GameSettings.GODOT_VERSION`. Arquivos válidos dos esquemas 1 e 2 continuam legíveis e são gravados no esquema 3 ao salvar de novo. Coordenadas são objetos explícitos `{"x": 6, "y": 5}`; paredes e blueprints são arrays desses objetos. Nenhuma chave de texto é interpretada como `Vector2i`.

| Campo | Conteúdo |
| --- | --- |
| `walls` | Todas as paredes atuais, preservando originais demolidas e paredes novas |
| `doors` | Lista de célula e estado `open`; independente das paredes |
| `areas` | Lista de célula e `type` numérico: 1 Alojamento, 2 Refeitório, 3 Contenção |
| `objects` | Lista de célula e tipo numérico dos objetos concluídos, separada de paredes e portas |
| `object_blueprints` | Lista de célula e tipo dos objetos planejados, ainda transitáveis |
| `blueprints` | Planejamento completo; inclui os não autorizados e o vínculo visual dos autorizados |
| `tasks` | Array na ordem da fila; cada tarefa contém `target`, `action`, `object_type`, `status`, `reason`, `elapsed` e `preserve_exit` |
| `active`, `work_cell`, `dirty` | Alvo ativo e posição de trabalho (`null` quando ausentes), estado de reavaliação da fila |
| `engineer` | Célula, posição exata em pixels, destino, rota restante, seleção, ocupado, trabalhando e ação |
| `camera`, `tool`, `area_type`, `object_type`, `selected_cell` | Câmera, ferramenta, tipos escolhidos e célula selecionada |

A captura e a aplicação são síncronas na thread principal, sem avançar a simulação. Carregar primeiro valida o documento inteiro em uma estrutura separada: tipos, versões, coordenadas, duplicações, tempo de trabalho, rota ortogonal transitável, posição no segmento, alvos e vínculos com o engenheiro/posição adjacente, saída segura ativa, câmera e ferramenta. Só então substitui os campos do mundo, sem resetar progresso, reposicionar em centros ou emitir sinais intermediários de grade/engenheiro/tarefas. Os objetos e suas conexões existentes permanecem; a simulação continua normalmente no próximo processamento.

Salvar grava `site_director.json.tmp` no mesmo diretório, faz flush, fecha e relê/valida o temporário antes de renomeá-lo sobre o slot. Uma falha reportada de abertura/gravação/verificação/substituição mantém o slot anterior; o código nunca apaga o slot antigo para contornar uma falha. A substituição no sistema Linux deste ambiente foi executada e verificada. Não há garantia adicional contra falha física de disco/energia.

Arquivos ausentes, JSON corrompido, versões incompatíveis ou estados inconsistentes são recusados sem modificar o mundo. A mensagem do painel muda para explicar o problema. Saves maiores que 2 MiB são recusados. Há leitura compatível dos esquemas 1 e 2, sem suporte a versões futuras, múltiplos slots, restauração de controles de teclado/mouse mantidos pressionados ou histórico de mensagens do painel; a mensagem de carregar é mostrada no lugar do histórico.

## Validação automatizada

```bash
bash tools/validate.sh
git diff --check
```

O script importa o projeto, executa `tests/test_runner.gd` e roda a cena principal por 120 frames em modo headless. Preserva falhas dos comandos, detecta diagnósticos de erro e exige um resultado com verificações realmente executadas. O runner termina com código diferente de zero em falha e tem limite de 30 segundos.

Cobertura anterior preservada: rota livre e mínima, desvio pela passagem, parede, fora do mapa, sala inacessível, quina diagonal bloqueada, destino atual, velocidade e chegada, redirecionamento em movimento, preservação de ordem após rejeição, limites da câmera, atualização do painel, reinício e eventos de clique passando pelo viewport/interface.

Cobertura de construção em `tests/construction_tests.gd`: blueprint transitável; autorização sem duplicação; trabalho adjacente e duração/progresso; rejeição de ordens manuais; cancelamento parado e em trânsito sem teleportar; parede concluída muda navegação; tarefa inacessível não bloqueia acessíveis; ocupação e alvo revalidados; bloqueios reavaliados por mudanças da grade; rota invalidada; nova posição de trabalho após perder acesso; controles de planejamento/autorização/cancelamento pelo viewport; construção da abertura original; reinício integral.

Cobertura adicional em `tests/demolition_tests.gd`: permanência da parede durante trabalho; cancelamento em trânsito e durante demolição; duração/progresso; abertura de rota inacessível; pedido repetido; demolição de paredes originais e construídas; fila exclusiva mista; bloqueio do último acesso; posição alternativa segura com deslocamento pelo blueprint; simulação sem mutação/eventos; revalidação antes de concluir; demolição que restaura saída e retoma obra bloqueada; controles pelo viewport; reinício de paredes removidas/construídas, filas e trabalhador.

Cobertura de persistência em `tests/save_tests.gd`: blueprint não autorizado; movimento entre centros; construção e demolição parciais; fila mista e bloqueio; ordem, progresso e saída preservados; conclusão sem repetição; carga repetida sem duplicação/sinais intermediários; paredes novas/demolidas; ausência/corrupção/versões incompatíveis; coordenadas, vínculos, rota, progresso e câmera inválidos; limite mínimo de zoom float32; falha real ao abrir temporário preservando slot anterior; substituição do slot; reiniciar e recuperar; botões e mensagens. Os testes usam um caminho isolado em `user://` e o removem ao terminar, sem tocar no slot do jogador.

Cobertura de portas/áreas em `tests/door_area_tests.gd`: instalação parcial e conclusão física; cancelamento preservando parede; porta fechada/aberta na navegação e no painel; tarefa bloqueada retomada ao abrir; rota invalidada ao fechar; demolição de porta; áreas arbitrárias sem bloquear caminho e independentes de paredes; seleção e clique no painel; save/load de porta aberta/fechada, áreas e instalação parcial; rejeição de sobreposição inválida; leitura de save legado do esquema 1; reinício das estruturas originais.

Cobertura de objetos em `tests/object_tests.gd`: compatibilidade dos quatro tipos com suas áreas, blueprint transitável, objeto sólido e interação adjacente, instalação/demolição física, cancelamento em trânsito/trabalho, proteção da saída e do último ponto de interação, revalidação após mudança de área, fila com tarefa bloqueada, rotas combinando porta e objeto, save/load parcial/repetido e migração dos esquemas 1 e 2.

Validação atual: **1.096 verificações, 0 falhas** com `bash tools/validate.sh`. A cena foi executada graficamente em Xvfb com Mesa llvmpipe e renderizador Compatibility; a captura `15-escape-help-1280x720.png` mostra a ajuda do novo atalho legível no painel rolado, com o mapa inteiro visível. O roteiro manual abaixo continua pendente, sem alegação de cliques humanos ou teste em monitor físico.

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
14. Reinicie, ative **Demolir** e clique na parede `(18, 19)`. Repita o pedido: deve existir uma tarefa. Durante o deslocamento/trabalho, a parede deve permanecer sólida e o painel deve indicar Demolir e progresso. Cancele: a parede permanece. Solicite novamente e aguarde a conclusão: `(19, 19)` deve ficar alcançável pela nova abertura.
15. Construa `(6, 5)`, depois solicite sua demolição. Confira que ambas as ações usam um trabalhador, e que a parede só desaparece após o tempo de trabalho. Clique no painel em modo Demolir: nenhum pedido deve ser criado no mapa.
16. Para um exemplo de proteção da referência, mova o engenheiro de `(4, 5)` para `(7, 5)` e planeje a célula `(4, 5)`. Autorize: deve aparecer a mensagem exata de saída bloqueada, pois construir sobre a própria saída não permite preservá-la. Uma demolição acessível solicitada em paralelo deve prosseguir.
17. Para a posição alternativa segura, reinicie; construa as paredes `(6, 4)`, `(7, 4)`, `(8, 4)`, `(8, 5)`, `(8, 6)`, `(7, 6)` e `(6, 6)`. Mova o engenheiro para `(7, 5)` e planeje `(6, 5)`, a abertura desse pequeno recinto. O engenheiro deve cruzar a abertura e trabalhar do lado de fora `(5, 5)`, mantendo rota até `(4, 5)` após fechar. Os testes automatizados também verificam esse comportamento num corredor controlado.
18. Reinicie com paredes originais demolidas, paredes novas e tarefas mistas incompletas: o mapa deve voltar exatamente ao original, com a abertura `(10, 12)`, engenheiro na origem, modo Selecionar e progresso zero.
19. Planeje um blueprint sem autorizar, altere câmera/ferramenta e Salve. Reinicie e Carregue: confira blueprint não autorizado, câmera e modo restaurados. Repita Carregar: nada deve duplicar.
20. Dê uma ordem longa e Salve entre centros. Carregue antes de chegar: o engenheiro deve voltar exatamente ao ponto salvo e continuar a rota, sem ser ajustado ao centro.
21. Salve no meio de uma construção e depois de uma demolição. Reinicie e Carregue em cada caso: confira ação, alvo e progresso retomados, e conclusão única após o tempo restante. Inclua uma tarefa bloqueada antes e outra ação depois da ativa na fila.
22. Confira as mensagens de Salvar/Carregar. Para testar erro manualmente, faça uma cópia externa do save e corrompa o JSON ou altere `schema_version`; Carregar deve recusar e preservar o mundo atual. Restaure a cópia ao terminar. Sem arquivo, Carregar deve informar ausência.
23. No modo Porta, clique numa parede. Confira que ela continua sólida durante a instalação, que cancelar preserva a parede e que a conclusão a troca por porta fechada. No modo Selecionar, clique na porta e abra/feche pelo painel; confira alteração de caminho e impossibilidade de fechar sobre o engenheiro.
24. Demola uma porta e confira que só ao terminar ela vira piso. Pinte células transitáveis com os quatro tipos do seletor Área, inclusive formas abertas; confira a cor suave, o tipo no painel, navegação inalterada, save/load e limpeza ao reiniciar.
25. Pinte uma célula como Alojamento e três como Refeitório. No modo Objeto, planeje uma Cama na primeira e Mesa, Assento e Distribuidor nas outras. Confira a recusa de tipos na área errada, blueprint transitável e objeto concluído sólido após deslocamento/trabalho adjacente.
26. Selecione um objeto concluído e confira tipo, área e vizinhos de interação no painel. Demola o objeto e confirme que ele só libera a célula ao terminar. Tente bloquear o último vizinho com parede, objeto ou porta fechada: a ação deve ser recusada.
27. Altere a área de um blueprint/tarefa, verifique motivo de bloqueio e outra obra avançando; restaure a área e confirme a retomada. Salve no meio da instalação e demolição de objeto, carregue duas vezes e confira posição/progresso e ausência de duplicação. Reinicie e confirme remoção dos objetos.
28. Ative cada ferramenta, selecione o engenheiro ou uma célula e pressione Esc. Confira retorno ao modo Selecionar e seleção limpa, mantendo blueprints e tarefas na fila.
29. Em 1280×720, confira o mapa inteiro entre os dois painéis, o destaque da ferramenta ativa, mensagens vermelhas de bloqueio, o painel de objeto com interação e o alcance das ações pela rolagem. Abra a ajuda e role até o fim. Repita em 1920×1080.
30. Durante um deslocamento ou trabalho, pressione Pausa e confirme que a posição/progresso não mudam. Retome em 1× e experimente 2×; Reiniciar deve repor 1×.

## Organização e limite de escopo

`grid_state.gd`: paredes, portas, áreas e objetos independentes; `navigation.gd`: busca de rotas reais/hipotéticas; `engineer.gd`: personagem, movimento e invalidação de rotas; `construction.gd`: coordenação única de construção, demolição e instalação; `save_slot.gd`: captura, JSON, validação, gravação e restauração; `map_view.gd`: desenho; `site_camera.gd`: câmera; `hud.gd`: interface; `ui_theme.gd`: paleta, espaçamentos e estilos; `main.gd`: composição e comandos. A cena fica em `scenes/main.tscn`.

Classe-D, uso automático dos objetos, necessidades, economia, SCPs, combate, autosave e múltiplos trabalhadores não fazem parte desta entrega. Veja `docs/PROGRESS.md` para o estado da validação e a próxima tarefa.
