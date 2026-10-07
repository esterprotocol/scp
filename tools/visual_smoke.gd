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
	game.engineer.set_process(false)
	game.construction.set_process(false)
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
