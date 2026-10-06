# Site Director

- Projeto na raiz; Godot **4.6.3.stable.official.7d41c59c4**, GDScript, Compatibility.
- Use o checkout existente e uma branch de trabalho. Não crie worktrees sem pedido explícito; não faça merge automático na main.
- Mantenha grade, navegação, personagem e interface separados. Centralize parâmetros em `scripts/settings.gd`; preserve passos ortogonais e redirecionamento sem cortar quinas.
- Evite assets externos, plugins e frameworks. Não amplie o escopo sem pedido.
- Comandos usados, na raiz: `bash tools/godot.sh --headless --version`, `bash tools/validate.sh`, `git diff --check`.
- Para diagnóstico, foram usados `bash tools/godot.sh --headless --editor --import`, `bash tools/godot.sh --headless --script res://tests/test_runner.gd` e `bash tools/godot.sh --headless --quit-after 120`.
- A verificação gráfica usa Xvfb, Mesa llvmpipe e `bash tools/godot.sh --audio-driver Dummy --resolution 1280x720 --position 0,0 --script res://tools/visual_smoke.gd` com `DISPLAY`, `LIBGL_ALWAYS_SOFTWARE=1` e `SITE_DIRECTOR_CAPTURE_WIDTH/HEIGHT`; use `SITE_DIRECTOR_CAPTURE_OBJECTS=1` para gerar apenas as capturas de objetos. Veja `docs/PROGRESS.md`. Não confunda headless com validação visual.
- Atualize README e `docs/PROGRESS.md` com resultados reais. Não versione `.godot/` nem `.tools/`; versione os arquivos `.gd.uid` gerados pelo Godot.
