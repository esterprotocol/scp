# Progresso — entrega 08: atalho Esc

## Base e mudança

- Base confirmada: `feat/essential-objects`, commit `34f038cb11b6238ef6a3408ab96313f018c92d41`; `AGENTS.md` lido. Branch: `feat/escape-selection-shortcut`, sem merge na `main`.
- Esc volta ao modo Selecionar a partir de Planejar, Demolir, Porta, Área ou Objeto e limpa a seleção do engenheiro e da célula. Blueprints, fila e trabalho em andamento continuam intactos. A ajuda no painel e o README descrevem o atalho.

## Verificado e pendente

- `bash tools/validate.sh`: **1.096 verificações, 0 falhas**; importação e execução headless da cena concluídas. O teste novo envia `InputEventKey` pelo viewport nos cinco modos, também com botão da interface focado, e verifica seleção limpa e obra preservada.
- Cena executada graficamente em Xvfb/Mesa llvmpipe, OpenGL Compatibility, 1280×720. A captura `15-escape-help-1280x720.png` foi feita após frames renderizados e inspecionada: instrução de Esc legível no painel rolado, mapa inteiro visível e sem sobreposição.
- Interação humana com teclado e monitor físico ainda pendente; o atalho foi acionado por evento sintético nos testes e na captura.

## Histórico — entrega 07: objetos essenciais

## Base e implementação

- Base confirmada antes de editar: `feat/doors-and-zones`, commit `8a717dca69c6a2968fc9af88f4bc29f0034bff69`; `AGENTS.md` lido. Branch desta entrega: `feat/essential-objects`, sem merge na `main`.
- Godot `4.6.3.stable.official.7d41c59c4` e Compatibility mantidos. `GridState` separa paredes, portas, áreas e objetos. Cama exige Alojamento; Mesa de refeitório, Assento e Distribuidor exigem Refeitório. Blueprints de objeto não bloqueiam; objetos concluídos bloqueiam.
- Ferramenta Objeto com seletor de tipo, planejamento individual e autorização pela fila do engenheiro. Instalação física adjacente leva 2 segundos, demolição física 1,5 segundo; a mudança da grade ocorre só na conclusão. Cancelar em trânsito ou trabalho descarta blueprint/tarefa sem criar objeto.
- Área é revalidada antes de iniciar e concluir. Tarefas bloqueadas mostram o tipo e motivo e não impedem outras. Instalação preserva a saída do engenheiro, conserva ao menos um vizinho transitável para interação e impede que paredes, objetos ou porta fechada removam o último ponto de interação de um objeto existente.
- Save JSON evoluído para esquema 3, com objetos, blueprints de objeto, tipos e tarefas parciais na fila ordenada. Saves válidos dos esquemas 1 e 2 continuam legíveis. Reiniciar limpa objetos e obras; carregar valida estruturas e vínculos antes de substituir o cenário, sem duplicar tarefas.

## Verificado e limites

- `bash tools/validate.sh`: **1.089 verificações, 0 falhas**; importação do projeto e execução headless da cena principal concluídas. Cenários anteriores preservados; novos testes cobrem compatibilidade dos quatro tipos, navegação antes/depois da obra, interação, instalação/demolição, cancelamento, saída, revalidação de área, porta com objeto, save/load parcial e repetido, migração e reinício.
- Execução gráfica real em Xvfb/Mesa llvmpipe, OpenGL Compatibility, 1280×720: cinco capturas novas `10`–`14` em `docs/screenshots/` depois de frames renderizados. Inspeção por visão confirmou blueprint cruzado distinto de forma sólida, cores de área, objeto e rota legíveis, progresso e razão de bloqueio acessíveis com rolagem, e painel sem cobrir o mapa.
- Testes manuais de cliques, arraste, continuidade da animação e monitor/driver físico ainda pendentes; estados gráficos preparados por métodos do jogo. A rotina de Classe-D, uso automático de objetos, necessidades, economia e SCPs permanecem fora do escopo. Áreas e objetos não tornam a sala operacional automaticamente.

## Histórico — entrega 06: portas e áreas designadas

## Base e implementação

- Base confirmada antes das alterações: `feat/visual-smoke-check`, commit `ec3a2b2418b37811b39ccfdb5856ae1896377227`; `AGENTS.md` lido. Branch desta entrega: `feat/doors-and-zones`, sem merge na `main`.
- Godot `4.6.3.stable.official.7d41c59c4` e Compatibility mantidos. A grade agora guarda paredes, portas e áreas em estruturas separadas. Portas fechadas bloqueiam a BFS; abertas permitem passagem. Abrir/fechar emite alteração da grade e reavalia rotas e tarefas.
- Modo Porta solicita instalação física em parede existente pela fila única; tempo configurável `DOOR_INSTALL_SECONDS = 1.5`. Cancelar preserva a parede; concluir cria porta fechada. Demolição física aceita portas e deixa piso livre ao concluir. Painel e mapa mostram porta aberta/fechada, instalação, alvo e progresso.
- Modo Área pinta células transitáveis, inclusive por arraste, com Sem área, Alojamento, Refeitório ou Contenção. Dados independentes da estrutura construída; desenho com cores suaves. Painel mostra o tipo da célula selecionada. Reiniciar restaura as paredes originais e limpa portas/áreas.
- Save JSON passa a esquema 2, com listas explícitas de portas e áreas, ferramenta/tipo e célula selecionada; valida tudo antes de aplicar. Saves válidos do esquema 1 continuam legíveis. Restauração mantém instalação parcial, progresso e estado aberto/fechado, sem eventos intermediários.

## Verificado e pendente

- `bash tools/validate.sh`: **963 verificações, 0 falhas**; importação do projeto e execução headless da cena principal concluídas. Os cenários anteriores permanecem na suíte; os novos verificam instalação/cancelamento/conclusão de porta, rota aberta/fechada, retomada de obra bloqueada ao abrir, invalidação de rota ao fechar, demolição, áreas e persistência, leitura do esquema 1 e reinício.
- Execução gráfica real em Xvfb/Mesa llvmpipe, OpenGL Compatibility, 1280×720: três capturas adicionais `07`–`09` em `docs/screenshots/`, após aguardar frames. Inspeção com ferramenta de visão confirmou porta aberta/fechada distinta, área suave, trabalho e progresso legíveis, painel rolável e botões acessíveis. A primeira captura mostrou o painel avançando sobre o mapa por causa do texto de controles; após quebra de linha, a recaptura confirmou a largura anterior e mapa desobstruído.
- Teste manual de cliques, arraste, animação contínua e monitor/driver físico segue pendente. Os estados gráficos foram preparados por métodos reais do jogo; nenhuma interação humana foi testada.
- Sem Classe-D, necessidades, economia, SCPs ou objetos que tornem áreas operacionais. Áreas não exigem perímetro fechado nesta entrega.

## Histórico — entrega 05: verificação gráfica

## Base e ambiente

- Base confirmada antes de editar: `feat/save-load-basic` no commit `532f8315ab9421f89e3964be048098974f366e49`; `AGENTS.md` lido. Trabalho na branch `feat/visual-smoke-check`, sem merge na `main`.
- Godot `4.6.3.stable.official.7d41c59c4`, renderizador Compatibility. A execução gráfica usou Xvfb e OpenGL Mesa `llvmpipe` 4.5; o log confirmou `Compatibility - Using Device: Mesa - llvmpipe`.
- O repositório inicial não tinha Xvfb. A primeira tentativa de instalação pelo espelho configurado (`snapshot.debian.org`) recebeu HTTP 403; uma correção direcionada baixou o pacote Debian assinado pelo espelho `deb.debian.org` e o extraiu sob `.tools/visual/`. A sessão gráfica funcionou. Não foi usado renderizador dummy/headless como prova visual.

## Execução e inspeção

- `tools/visual_smoke.gd` prepara estados pela cena e pelos sistemas reais de planejamento, autorização, demolição e save/load. A captura aguarda frames de renderização e lê a janela X11 com `import`, sem interação humana. O save temporário visual usa `user://site_director_visual_smoke.json` e é removido depois.
- Foram produzidas 12 capturas em `docs/screenshots/`: cenário inicial, construção com blueprint pendente, demolição em andamento, obra bloqueada, cenário carregado e painel rolado até os botões inferiores, cada uma em 1280×720 e 1920×1080. As dimensões PNG foram checadas pelo script.
- As imagens foram inspecionadas com ferramenta de visão. Mapa e engenheiro aparecem em ambas as resoluções; botões e texto são legíveis, o painel rola até Salvar/Carregar, progresso e mensagens não se sobrepõem. Azul, dourado, laranja e vermelho distinguem os quatro estados pedidos; o motivo de bloqueio fica visível.
- Defeitos demonstrados e corrigidos: a mensagem neutra `Nenhum bloqueio.` era vermelha; agora é cinza. A resolução base anterior, 1152×864, cortava a parte inferior do mapa numa tela de 720 px; a resolução base agora é 1280×720 e o zoom inicial considera a altura da janela, mantendo o mapa inteiro visível com margem. A captura final em 1920×1080 usa `--resolution 1920x1080` desde a inicialização para aplicar corretamente a escala do Godot.
- Para reproduzir, inicie Xvfb nos displays com telas 1280×720 e 1920×1080, instale `import` (ImageMagick), e execute `DISPLAY=:100 LIBGL_ALWAYS_SOFTWARE=1 SITE_DIRECTOR_CAPTURE_WIDTH=1280 SITE_DIRECTOR_CAPTURE_HEIGHT=720 bash tools/godot.sh --audio-driver Dummy --resolution 1280x720 --position 0,0 --script res://tools/visual_smoke.gd`; para a outra resolução, use display `:99`, largura 1920, altura 1080 e `--resolution 1920x1080`.

## Verificações e limites desta entrega

- Testes de lógica: `bash tools/validate.sh` após as correções de código: **823 verificações, 0 falhas**, importação do editor e cena principal por 120 frames concluídas. As expectativas de zoom e clique no botão de reinício foram atualizadas para a janela de 720p e o painel rolável; todos os cenários antigos permanecem na suíte. O runner é headless e não conta como validação visual.
- Execução gráfica: cena real desenhada via OpenGL Compatibility em Xvfb/llvmpipe, dois tamanhos, com capturas após renderização. Inspeção de imagens: feita nos seis estados de 1280×720 e nos cenários inicial, bloqueado e painel rolado de 1920×1080; as demais capturas de 1920×1080 foram geradas e estão disponíveis para revisão.
- Testes manuais ainda pendentes: cliques reais do usuário, atalhos de teclado, arraste, rolagem com mouse, tempos de animação percebidos e uso em monitor/driver físico. Os estados gráficos foram preparados programaticamente; nenhuma interação humana foi declarada testada.

## Histórico — entrega 04: slot manual de salvar/carregar

## Base e revisão

- Base obrigatória verificada antes de editar: branch `feat/demolition-safe-access`, commit completo `228d13fac77b41a74366643e30dc851a95ed605e`; `AGENTS.md` lido antes das alterações.
- Branch da entrega: `feat/save-load-basic`, criada diretamente desse commit. Sem merge automático na `main`.
- Godot 4.6.3, Compatibility, dimensões, velocidade e funcionalidades da entrega anterior preservados.

## Implementado

- Projeto Godot na raiz, cena principal executável e renderizador Compatibility.
- Grade 24 × 24, células 32 px; visual desenhado com formas e cores.
- Câmera com WASD/setas, arraste central, limites de deslocamento e zoom limitado.
- Engenheiro selecionável; comandos com botão direito; rota desenhada e movimento a 128 px/s.
- Paredes fixas, passagem e sala inacessível; BFS ortogonal sem corte de quinas.
- Redirecionamento seguro entre centros de células; ordens inválidas mantêm a rota anterior.
- Painel de seleção, estado, destino, mensagens de erro e reinício funcional.
- Wrapper com versão fixa e diretórios graváveis; runner automatizado sem framework externo.
- Modos Selecionar e Planejar parede com botões; marcação individual, autorização e cancelamento por célula, da tarefa atual ou de todas as obras incompletas.
- Blueprint desenhado com contorno cruzado; azul planejado, dourado autorizado, vermelho bloqueado. Não bloqueia a grade.
- Uma tarefa por célula, sem duplicação na autorização. Um único engenheiro assume tarefas quando livre.
- Escolha da célula ortogonal adjacente acessível mais próxima; deslocamento seguido de 2 segundos de trabalho configuráveis em `WALL_BUILD_SECONDS`.
- Parede passa a bloquear somente após trabalho completo. Ocupação, alvo livre e acesso são revalidados antes do trabalho e da conclusão.
- Obras bloqueadas têm motivo legível por célula e não impedem outras acessíveis. Reavaliação após mudanças na grade e no estado/posição do engenheiro.
- Alteração da grade invalida rotas afetadas, com parada no segmento seguro sem teleportar. Cancelamento libera o engenheiro e remove tarefa/blueprint.
- Ordens manuais recusadas durante deslocamento/trabalho em obra; aceitas novamente após cancelamento.
- Interface com tarefa atual, progresso e lista de bloqueios, em painel rolável. Cliques na interface não planejam células no mapa.
- Reinício limpa integralmente paredes novas, blueprints, tarefas, progresso e modo, além dos estados originais do engenheiro/câmera/painel.
- Modo Demolir; pedido por célula cria tarefa sem remover parede, sem duplicações. Marcação laranja distinta de blueprint.
- Fila única de construção/demolição; um único trabalhador e uma única tarefa ativa. Ação, alvo, progresso e motivos de bloqueio aparecem no painel.
- Demolição exige vizinho ortogonal acessível e 1,5 segundo de trabalho configurável; somente ao concluir remove a parede e atualiza navegação. Aceita paredes originais e construídas.
- Cancelar demolição preserva a parede e libera o trabalhador, também em trânsito sem teleportar. Reinício restaura paredes originais demolidas e limpa ambas as ações.
- Saída de referência `EXIT_CELL = SPAWN`. Seleção de posição de construção considera a parede hipotética concluída e prefere vizinho seguro quando houver saída antes da tarefa.
- Mensagem exata para bloqueio de segurança: “Construção bloquearia a saída do engenheiro”. A obrigação permanece entre tentativas e é revalidada antes de concluir.
- Simulação de navegação somente por leitura, com célula adicional bloqueada; não modifica grade nem emite eventos. Construções bloqueadas não impedem demolições que restabeleçam acesso.
- Um único slot manual com botões Salvar/Carregar e mensagens. Arquivo `user://site_director.json`; o wrapper o mantém em `.tools/data/godot/app_userdata/Site Director/`, ignorado pelo Git. Reiniciar não apaga o save.
- JSON esquema 1 e versão exata do Godot em metadados. Coordenadas explícitas `{x, y}`, paredes/blueprints em arrays e fila em array ordenado, sem chaves `Vector2i` implícitas.
- Preserva grade completa, planejamento não autorizado, tarefas/ação/progresso/ordem/bloqueios, vínculos ativos e obrigação de saída, posição exata/rota/estado do trabalhador, câmera e ferramenta.
- Validação integral em estado separado antes de tocar no mundo; recusa ausência, corrupção, incompatibilidade e inconsistências de navegação/trabalho. Carga substitui os campos sem somar estado, emitir sinais intermediários, teleportar ou reiniciar progresso.
- Captura/aplicação síncronas na thread principal. Gravação por temporário, flush, releitura/validação e substituição por rename no mesmo diretório, sem remover o slot anterior em falha.

## Verificado no Godot

- Executável existente: `/usr/local/bin/godot` → `/opt/godot/4.6.3/Godot_v4.6.3-stable_linux.x86_64`.
- Versão executada: `4.6.3.stable.official.7d41c59c4`.
- Importação headless do editor concluída, sem erros de scripts.
- Runner: **823 verificações, 0 falhas**, com todos os cenários das entregas anteriores preservados. Cobre caminhos livres, desvio, destinos inválidos/inacessíveis, quinas, velocidade, chegada, redirecionamento, câmera, HUD, reinício e cliques sintéticos no viewport.
- Testes adicionais verificam: blueprint transitável; autorização repetida; trabalho adjacente; tempo/progresso; recusa manual; cancelamento durante trabalho e deslocamento; conclusão e navegação atualizada; bloqueios sem paralisar outras tarefas; reavaliação por mudança da grade; revalidação de alvo/ocupação; invalidação de rotas e posição de trabalho; entrada pela interface; fechamento da abertura planejável; reinício integral.
- Demolição/saída segura: parede preservada durante trabalho/cancelamento; pedido repetido; abrir rota antes inacessível; paredes originais e construídas; bloqueio do último acesso; escolha de outra posição segura e passagem pelo blueprint; simulação sem alteração/eventos; revalidação antes da conclusão; demolição restaurando saída e permitindo retomar construção; fila mista, interface e reinício integral.
- A primeira execução ampliada detectou um mapa de teste com passagem alternativa não intencional; a fixture foi corrigida para efetivamente cortar a saída antes da conclusão. A fixture de demolição inacessível também foi ajustada para uma parede interna isolada. As verificações foram mantidas e a suíte completa reexecutada.
- Foi necessário permitir cruzar o blueprint durante o deslocamento até o lado seguro; ocupação continua validada antes de iniciar/concluir trabalho. A suíte cobre esse percurso.
- Persistência executada em arquivos isolados de teste: planejamento não autorizado; movimento entre células; construção/demolição parciais; fila mista bloqueada e ordenada; repetição de carga sem duplicação; conclusão única após retomada; grade nova/demolida; reiniciar e carregar; mensagens dos botões; ausência/corrupção/versões e estados inconsistentes recusados sem alterar o cenário.
- Falha real de abertura do temporário (diretório no lugar do arquivo) preservou bytes do slot válido e cenário. A substituição de um slot existente também foi executada com sucesso.
- Testes confirmam que a restauração não emite sinais de grade/engenheiro. O limite mínimo do zoom exigiu tolerância à representação float32 na validação; a posição e o zoom salvos continuam sendo restaurados sem arredondamento.
- Cena principal executada por 120 frames em modo headless.
- O erro de inferência de tipo da entrega anterior permanece corrigido. Na entrega atual, importação, suíte ampliada e execução headless passaram com `bash tools/validate.sh`.
- Comando consolidado: `bash tools/validate.sh`; verificação de whitespace: `git diff --check`.

## Limitações conhecidas

- A tentativa gráfica da entrega anterior falhou: `X11 Display is not available`; fallback também falhou com `Can't connect to a Wayland display` e `XDG_RUNTIME_DIR is invalid or not set`. A validação visual desta entrega continua explicitamente pendente; nenhum teste visual humano foi declarado aprovado.
- Headless usa renderização dummy: os testes comprovam lógica, cena e entrada sintética, mas não aparência, fluidez percebida ou desenho pelo driver Compatibility.
- Câmera usa zoom centrado na tela; limites de deslocamento permitem ver margem ao redor do mapa.
- Cenário fixo, uma unidade. Sem portas, economia, necessidades, SCPs, combate ou múltiplos trabalhadores/reservas complexas. Persistência é manual, um slot, sem autosave.
- Se perder acesso, a tarefa fica bloqueada e perde o progresso incompleto; tentativas posteriores reiniciam o trabalho. Ordens manuais em trânsito terminam antes de assumir uma tarefa.
- Cancelar tarefas não remove paredes existentes. Uma rota invalidada termina só o segmento seguro; novas ordens ou tarefas calculam nova rota.
- A garantia de saída preserva conectividade existente até a referência; não cria uma saída para o engenheiro que já estava isolado antes da tarefa. Demolição pode restabelecer essa conexão.
- Saves aceitam apenas esquema 1 e o Godot exato do projeto, com limite de 2 MiB; sem migração de versões. Dados de teclado/mouse pressionados e histórico de mensagens não são persistidos.
- Substituição segura verificada no Linux deste ambiente; não foi testada em outros sistemas/arquivos de rede e não fornece garantia adicional contra falha física de disco/energia.

## Próxima tarefa

Executar o roteiro manual ampliado do README numa sessão gráfica com Godot 4.6.3, incluindo Salvar/Carregar durante movimento, construção e demolição, mensagens de erro, repetição de carga e recuperação após reinício. Validação visual permanece explicitamente pendente. Novas mecânicas dependem de uma próxima entrega definida pelo usuário.
