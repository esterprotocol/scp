# Progresso — entrega 04: slot manual de salvar/carregar

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
