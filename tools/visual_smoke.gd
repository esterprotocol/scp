extends SceneTree

# Run with an X display and software OpenGL, never --headless:
# DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1 SITE_DIRECTOR_CAPTURE_WIDTH=1920 SITE_DIRECTOR_CAPTURE_HEIGHT=1080 \
#   bash tools/godot.sh --audio-driver Dummy --resolution 1920x1080 --position 0,0 --script res://tools/visual_smoke.gd

const OUTPUT := "res://docs/screenshots/"

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for index in range(4):
		await process_frame
	await RenderingServer.frame_post_draw

func capture(name: String, width: int, height: int) -> void:
	await settle()
	var output := OUTPUT + "%s-%dx%d.png" % [name, width, height]
	# Capture actual display pixels after OpenGL presents frames on Xvfb.
	var command_output: Array = []
	var error := OS.execute("import", PackedStringArray(["-window", "root", ProjectSettings.globalize_path(output)]), command_output, true)
	var image := Image.new()
	if error != 0 or image.load(ProjectSettings.globalize_path(output)) != OK or image.get_width() != width or image.get_height() != height:
		printerr("Screenshot failed or size mismatch: %s; command: %s" % [output, command_output])
		quit(1)
	else:
		print("Screenshot: %s actual %dx%d" % [output, image.get_width(), image.get_height()])

func shot(name: String, width: int, height: int) -> void:
	await capture(name, width, height)

func run() -> void:
	print("Visual smoke: inspect engine output for the OpenGL Compatibility renderer.")
	var width := int(OS.get_environment("SITE_DIRECTOR_CAPTURE_WIDTH"))
	var height := int(OS.get_environment("SITE_DIRECTOR_CAPTURE_HEIGHT"))
	if width not in [1280, 1920] or height != (720 if width == 1280 else 1080):
		printerr("Set SITE_DIRECTOR_CAPTURE_WIDTH/HEIGHT to 1280/720 or 1920/1080.")
		quit(1)
		return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.classd.set_process(false)
	game.engineer.set_process(false)
	game.construction.set_process(false)
	if OS.get_environment("SITE_DIRECTOR_CAPTURE_REVAMP") == "1":
		await shot("16-revamp-initial", width, height)
		game.set_object_mode()
		game.grid.set_area(Vector2i(6, 5), 1)
		game.grid.set_area(Vector2i(8, 5), 2)
		game.construction.plan_object(Vector2i(6, 5), 1)
		game.construction.plan_object(Vector2i(8, 5), 2)
		game.hud.show_message("Blueprints prontos. Cama exige Alojamento; mesa exige Refeitório.")
		await shot("17-revamp-objects", width, height)
		game.construction.authorize()
		game.construction._process(0.0)
		game.engineer._process(1.0)
		game.construction._process(0.0)
		game.construction._process(0.6)
		var scroll: ScrollContainer = game.hud.get_child(0).get_child(0)
		scroll.ensure_control_visible(game.hud.progress_bar)
		await shot("18-revamp-work", width, height)
		game.reset_scenario()
		game.construction.plan(Vector2i(19, 19))
		game.construction.authorize()
		game.construction._process(0.0)
		scroll.ensure_control_visible(game.hud.blocked_label)
		game.hud.show_message("Obra bloqueada: sem acesso à posição de trabalho.")
		await shot("19-revamp-alert", width, height)
		game.reset_scenario()
		game.grid.set_area(Vector2i(6, 5), 1)
		game.grid.add_object(Vector2i(6, 5), 1)
		game.select_cell(Vector2i(6, 5))
		game.hud.show_message("Cama selecionada. Use as células vizinhas para interação.")
		await shot("20-revamp-inspection", width, height)
		game.hud.help_label.visible = true
		await process_frame
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await shot("21-revamp-help", width, height)
		game.reset_scenario()
		game.classd.set_selected(true)
		game.classd.hunger = 18.0
		game.classd.rest = 12.0
		game.classd._process(0.0)
		game.hud.refresh_population(game.classd)
		game.hud.refresh_selection(game.engineer, game.classd)
		game.hud.show_message("Classe-D 001: necessidades críticas; aguarda acesso a objetos.")
		scroll.scroll_vertical = 0
		await shot("22-revamp-character", width, height)
		game.queue_free()
		await process_frame
		quit(0)
		return
	if OS.get_environment("SITE_DIRECTOR_CAPTURE_ESCAPE") == "1":
		game.grid.set_area(Vector2i(6, 5), 1)
		game.construction.plan_object(Vector2i(6, 5), 1)
		game.construction.authorize()
		game.set_object_mode()
		game.engineer.set_selected(true)
		game.select_cell(Vector2i(6, 5))
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		root.push_input(escape, true)
		if not game.hud.select_button.button_pressed or game.engineer.selected or not game.construction.tasks.has(Vector2i(6, 5)):
			printerr("Escape did not restore selection mode while preserving work.")
			quit(1)
			return
		var escape_scroll: ScrollContainer = game.hud.get_child(0).get_child(0)
		await process_frame
		await process_frame
		escape_scroll.scroll_vertical = int(escape_scroll.get_v_scroll_bar().max_value)
		await shot("15-escape-help", width, height)
		game.queue_free()
		await process_frame
		quit(0)
		return
	if OS.get_environment("SITE_DIRECTOR_CAPTURE_CLASSD") == "1":
		await capture_classd(game, width, height)
		game.queue_free()
		await process_frame
		quit(0)
		return
	if OS.get_environment("SITE_DIRECTOR_CAPTURE_OBJECTS") == "1":
		game.grid.set_area(Vector2i(6, 5), 1)
		game.grid.set_area(Vector2i(6, 6), 1)
		for cell: Vector2i in [Vector2i(8, 5), Vector2i(8, 6), Vector2i(9, 5), Vector2i(9, 6)]:
			game.grid.set_area(cell, 2)
		game.grid.add_object(Vector2i(8, 5), 2)
		game.grid.add_object(Vector2i(8, 6), 3)
		game.construction.plan_object(Vector2i(6, 5), 1)
		game.construction.authorize()
		game.construction.plan_object(Vector2i(9, 5), 4)
		game.object_type = 4
		game.hud.object_type.select(3)
		game.construction._process(0.0)
		game.engineer._process(1.0)
		game.construction._process(0.0)
		game.construction._process(0.8)
		game.hud.show_message("Cama em instalação; distribuidor ainda é blueprint transitável.")
		await shot("10-object-blueprints", width, height)
		game.construction._process(GameSettings.OBJECT_INSTALL_SECONDS - 0.8)
		game.select_cell(Vector2i(6, 5))
		game.hud.show_message("Cama concluída: ocupa a célula; interação pelos vizinhos livres.")
		await shot("11-object-installed", width, height)
		game.construction.request_demolition(Vector2i(6, 5))
		game.construction._process(0.0)
		game.engineer._process(1.0)
		game.construction._process(0.0)
		game.construction._process(0.5)
		game.hud.show_message("Demolição física: a cama permanece até a conclusão.")
		await shot("12-object-demolition", width, height)
		var object_scroll: ScrollContainer = game.hud.get_child(0).get_child(0)
		object_scroll.ensure_control_visible(game.hud.progress_bar)
		object_scroll.scroll_vertical += 90
		await shot("13-object-progress", width, height)
		game.construction._process(GameSettings.OBJECT_DEMOLISH_SECONDS)
		game.grid.set_area(Vector2i(9, 5), 1)
		game.construction.authorize()
		game.construction._process(0.0)
		game.hud.show_message("Distribuidor bloqueado: exige área Refeitório.")
		object_scroll.ensure_control_visible(game.hud.blocked_label)
		object_scroll.scroll_vertical += 110
		await shot("14-object-blocked", width, height)
		game.queue_free()
		await process_frame
		quit(0)
		return
	if OS.get_environment("SITE_DIRECTOR_CAPTURE_DOORS") == "1":
		game.grid.set_area(Vector2i(6, 4), 1)
		game.grid.set_area(Vector2i(7, 4), 1)
		game.grid.set_area(Vector2i(7, 5), 2)
		game.grid.set_area(Vector2i(8, 5), 3)
		game.grid.install_door(Vector2i(10, 5))
		game.grid.install_door(Vector2i(10, 6))
		game.grid.set_door_open(Vector2i(10, 6), true)
		game.construction.request_door(Vector2i(10, 7))
		game.construction._process(0.0)
		game.engineer._process(3.0)
		game.construction._process(0.0)
		game.construction._process(0.5)
		game.select_cell(Vector2i(10, 5))
		game.hud.show_message("Porta fechada selecionada; instalação em andamento.")
		await shot("07-doors-and-areas", width, height)
		game.set_area_mode()
		game.select_cell(Vector2i(7, 4))
		await shot("08-area-selected", width, height)
		var door_scroll: ScrollContainer = game.hud.get_child(0).get_child(0)
		door_scroll.scroll_vertical = int(door_scroll.get_v_scroll_bar().max_value)
		await shot("09-door-panel-scrolled", width, height)
		game.queue_free()
		await process_frame
		quit(0)
		return
	await shot("01-initial", width, height)

	game.reset_scenario()
	game.construction.plan(Vector2i(6, 5))
	game.construction.authorize()
	game.construction.plan(Vector2i(8, 6))
	game.construction._process(0.0)
	game.engineer._process(0.25)
	game.construction._process(0.0)
	game.construction._process(0.8)
	game.hud.show_message("Construção em andamento; blueprint azul ainda não autorizado.")
	await shot("02-building", width, height)

	game.reset_scenario()
	game.construction.request_demolition(Vector2i(10, 5))
	game.construction._process(0.0)
	game.engineer._process(3.0)
	game.construction._process(0.0)
	game.construction._process(0.6)
	game.hud.show_message("Demolição em andamento: parede ainda presente.")
	await shot("03-demolishing", width, height)

	game.reset_scenario()
	game.construction.plan(Vector2i(19, 19))
	game.construction.authorize()
	game.construction._process(0.0)
	game.hud.show_message("Obra bloqueada: sem acesso à sala isolada.")
	await shot("04-blocked", width, height)

	game.reset_scenario()
	game.construction.plan(Vector2i(6, 5))
	game.construction.authorize()
	game.construction.plan(Vector2i(8, 6))
	game.construction._process(0.0)
	game.engineer._process(0.25)
	game.construction._process(0.0)
	game.construction._process(0.8)
	game.set_planning(true)
	var save_path := "user://site_director_visual_smoke.json"
	var saved: String = game.save_slot.save_game(game, save_path)
	if not saved.contains("sucesso"):
		printerr(saved)
		quit(1)
		return
	game.reset_scenario()
	var loaded: String = game.save_slot.load_game(game, save_path)
	if not loaded.contains("sucesso"):
		printerr(loaded)
		quit(1)
		return
	game.hud.show_message(loaded)
	await shot("05-loaded", width, height)
	DirAccess.remove_absolute(save_path)

	game.reset_scenario()
	var scroll: ScrollContainer = game.hud.get_child(0).get_child(0)
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await shot("06-panel-scrolled", width, height)
	print("Panel bottom button positions: save=%s load=%s" % [game.hud.save_button.get_global_rect(), game.hud.load_button.get_global_rect()])
	game.queue_free()
	await process_frame
	quit(0)

func prepare_classd_objects(game: Node2D) -> void:
	for y in range(6, 11):
		for x in range(7, 10):
			game.grid.set_area(Vector2i(x, y), 1 if y <= 7 else 2)
	for entry in [{"cell": Vector2i(8, 7), "type": 1}, {"cell": Vector2i(8, 9), "type": 4}, {"cell": Vector2i(9, 9), "type": 2}, {"cell": Vector2i(9, 10), "type": 3}]:
		game.construction.plan_object(entry.cell, entry.type)
		game.construction.authorize()
		game.construction._process(0.0)
		game.engineer._process(10.0)
		game.construction._process(0.0)
		game.construction._process(GameSettings.OBJECT_INSTALL_SECONDS)
	game.engineer.move_to(GameSettings.SPAWN)
	game.engineer._process(10.0)
	game.classd.set_selected(true)
	game.hud.refresh_selection(game.engineer, game.classd)

func capture_classd(game: Node2D, width: int, height: int) -> void:
	prepare_classd_objects(game)
	game.classd._process(0.0)
	game.hud.show_message("Classe-D 001 ocioso. Cama e refeições instaladas pelo engenheiro.")
	await shot("15-classd-idle", width, height)

	game.reset_scenario()
	game.classd.set_selected(true)
	game.classd.hunger = 18.0
	game.classd.rest = 12.0
	game.classd._process(0.0)
	game.hud.show_message("Necessidades urgentes: faltam cama e distribuidor de refeições acessíveis.")
	await shot("16-classd-alert", width, height)

	game.reset_scenario()
	prepare_classd_objects(game)
	game.classd.rest = 20.0
	game.classd.hunger = 75.0
	game.classd._process(0.3)
	if game.classd.state != ClassD.MOVING or game.classd.reserved_object != Vector2i(8, 7):
		printerr("Visual fixture failed: Classe-D must be moving to installed bed.")
		quit(1)
		return
	game.hud.show_message("Descanso baixo: rota laranja até o ponto livre ao lado da cama.")
	await shot("17-classd-to-bed", width, height)

	while game.classd.state == ClassD.MOVING:
		game.classd._process(0.05)
	game.classd._process(3.0)
	if game.classd.state != ClassD.USING or game.classd.position != game.grid.center(game.classd.destination):
		printerr("Visual fixture failed: Classe-D must be using bed at its interaction point.")
		quit(1)
		return
	game.select_cell(Vector2i(8, 7))
	game.hud.show_message("Cama reservada por classd-001. Recuperação gradual, sem entrar na célula do objeto.")
	await shot("18-classd-using", width, height)

	var scroll: ScrollContainer = game.hud.get_child(0).get_child(0)
	scroll.ensure_control_visible(game.hud.load_button)
	scroll.scroll_vertical += 80
	await shot("19-classd-panel", width, height)
	print("720p controls: object=%s save=%s load=%s" % [game.hud.object_button.get_global_rect(), game.hud.save_button.get_global_rect(), game.hud.load_button.get_global_rect()])
