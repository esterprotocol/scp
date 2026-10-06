# Progresso — entrega 02: construção básica

## Base e revisão

- Base obrigatória verificada antes de editar: branch `feat/site-director-prototype`, commit completo `175a9f45d92286072615ae76d77ed4cbdee2320b`.
- Branch da entrega: `feat/construction-basic`, criada diretamente desse commit. Sem merge automático na `main`.
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

## Verificado no Godot

- Executável existente: `/usr/local/bin/godot` → `/opt/godot/4.6.3/Godot_v4.6.3-stable_linux.x86_64`.
- Versão executada: `4.6.3.stable.official.7d41c59c4`.
- Importação headless do editor concluída, sem erros de scripts.
- Runner: **326 verificações, 0 falhas**, com as **176 verificações anteriores preservadas**. Cobre caminhos livres, desvio, destinos inválidos/inacessíveis, quinas, velocidade, chegada, redirecionamento, câmera, HUD, reinício e cliques sintéticos no viewport.
- Testes adicionais verificam: blueprint transitável; autorização repetida; trabalho adjacente; tempo/progresso; recusa manual; cancelamento durante trabalho e deslocamento; conclusão e navegação atualizada; bloqueios sem paralisar outras tarefas; reavaliação por mudança da grade; revalidação de alvo/ocupação; invalidação de rotas e posição de trabalho; entrada pela interface; fechamento da abertura planejável; reinício integral.
- Cena principal executada por 120 frames em modo headless.
- O erro de inferência de tipo da entrega anterior permanece corrigido. Na entrega atual, importação, suíte ampliada e execução headless passaram com `bash tools/validate.sh`.
- Comando consolidado: `bash tools/validate.sh`; verificação de whitespace: `git diff --check`.

## Limitações conhecidas

- A tentativa gráfica da entrega anterior falhou: `X11 Display is not available`; fallback também falhou com `Can't connect to a Wayland display` e `XDG_RUNTIME_DIR is invalid or not set`. A validação visual desta entrega continua explicitamente pendente; nenhum teste visual humano foi declarado aprovado.
- Headless usa renderização dummy: os testes comprovam lógica, cena e entrada sintética, mas não aparência, fluidez percebida ou desenho pelo driver Compatibility.
- Câmera usa zoom centrado na tela; limites de deslocamento permitem ver margem ao redor do mapa.
- Cenário fixo, uma unidade, sem salvamento. Sem portas, demolição, economia, necessidades, SCPs, combate ou múltiplos trabalhadores/reservas complexas.
- Se perder acesso, a tarefa fica bloqueada e perde o progresso incompleto; tentativas posteriores reiniciam o trabalho. Ordens manuais em trânsito terminam antes de assumir uma tarefa.
- Cancelar obras não remove paredes concluídas. Uma rota invalidada termina só o segmento seguro; novas ordens ou tarefas calculam nova rota.

## Próxima tarefa

Executar o roteiro manual ampliado do README numa sessão gráfica com Godot 4.6.3, registrando revisão visual dos modos, blueprints, construção, bloqueios, cancelamento e reinício, além das funcionalidades anteriores. Novas mecânicas dependem de uma próxima entrega definida pelo usuário.
