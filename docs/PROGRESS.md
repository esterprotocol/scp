# Progresso — entrega 01

## Implementado

- Projeto Godot na raiz, cena principal executável e renderizador Compatibility.
- Grade 24 × 24, células 32 px; visual desenhado com formas e cores.
- Câmera com WASD/setas, arraste central, limites de deslocamento e zoom limitado.
- Engenheiro selecionável; comandos com botão direito; rota desenhada e movimento a 128 px/s.
- Paredes fixas, passagem e sala inacessível; BFS ortogonal sem corte de quinas.
- Redirecionamento seguro entre centros de células; ordens inválidas mantêm a rota anterior.
- Painel de seleção, estado, destino, mensagens de erro e reinício funcional.
- Wrapper com versão fixa e diretórios graváveis; runner automatizado sem framework externo.

## Verificado no Godot

- Executável existente: `/usr/local/bin/godot` → `/opt/godot/4.6.3/Godot_v4.6.3-stable_linux.x86_64`.
- Versão executada: `4.6.3.stable.official.7d41c59c4`.
- Importação headless do editor concluída, sem erros de scripts.
- Runner: **176 verificações, 0 falhas**. Cobre caminhos livres, desvio, destinos inválidos/inacessíveis, quinas, velocidade, chegada, redirecionamento, câmera, HUD, reinício e cliques sintéticos no viewport.
- Cena principal executada por 120 frames em modo headless.
- Os testes adicionais de entrada revelaram um erro de inferência de tipo na conversão de coordenadas; corrigido com tipo `Vector2` explícito e suíte reexecutada.
- Comando consolidado: `bash tools/validate.sh`; verificação de whitespace: `git diff --check`.

## Limitações conhecidas

- Tentativa gráfica real falhou: `X11 Display is not available`; fallback também falhou com `Can't connect to a Wayland display` e `XDG_RUNTIME_DIR is invalid or not set`. Não há sessão gráfica disponível neste ambiente. Nenhum teste visual humano foi declarado aprovado.
- Headless usa renderização dummy: os testes comprovam lógica, cena e entrada sintética, mas não aparência, fluidez percebida ou desenho pelo driver Compatibility.
- Câmera usa zoom centrado na tela; limites de deslocamento permitem ver margem ao redor do mapa.
- Cenário fixo, uma unidade, sem salvamento; construção, economia, necessidades, SCPs e combate ficam fora do escopo.

## Próxima tarefa

Executar o roteiro manual do README numa sessão gráfica com Godot 4.6.3 e registrar a revisão visual de câmera, painel, seleção e movimento. Novas mecânicas dependem de uma próxima entrega definida pelo usuário.
