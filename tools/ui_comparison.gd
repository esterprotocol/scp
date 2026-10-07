extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(_game: Node, name: String) -> void:
	for frame in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.get_width() == 1280 and image.get_height() == 720)
	var phase := OS.get_environment("SITE_DIRECTOR_UI_PHASE")
	var path := "res://docs/screenshots/ui-%s-%s.png" % [phase, name]
	assert(image.save_png(path) == OK)
	print("Capture: ", path)

func click(game: Node, world: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = game.get_canvas_transform() * world
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.engineer.set_process(false)
	game.classd.set_process(false)
	game.construction.set_process(false)
	Input.warp_mouse(Vector2(900, 450))
	await capture(game, "normal")
	click(game, game.engineer.position)
	await capture(game, "npc")
	game.reset_scenario()
	game.set_planning(true)
	click(game, game.grid.center(Vector2i(6, 5)))
	game.hud.authorize_button.pressed.emit()
	game.construction._process(0.0)
	game.engineer._process(1.0)
	game.construction._process(0.0)
	game.construction._process(0.6)
	var scroll: ScrollContainer = game.hud.get_child(0).get_child(0)
	scroll.ensure_control_visible(game.hud.progress_bar)
	await capture(game, "construction")
	game.reset_scenario()
	game.set_object_mode()
	Input.warp_mouse(game.get_canvas_transform() * game.grid.center(Vector2i(7, 5)))
	click(game, game.grid.center(Vector2i(7, 5)))
	await capture(game, "blocked")
	if OS.get_environment("SITE_DIRECTOR_UI_PHASE") == "after":
		await interactions(game)
	game.queue_free()
	await process_frame
	quit()

func press_control(game: Node, control: Control) -> void:
	var scroll: ScrollContainer = game.hud.get_child(0).get_child(0)
	if scroll.is_ancestor_of(control):
		scroll.ensure_control_visible(control)
	for frame in range(4):
		await process_frame
	click(game, game.get_canvas_transform().affine_inverse() * control.get_global_rect().get_center())
	await process_frame

func escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event, true)

func interactions(game: Node) -> void:
	game.reset_scenario()
	await process_frame
	click(game, game.engineer.position)
	assert(game.engineer.selected and game.engineer.route.is_empty())
	await press_control(game, game.hud.move_button)
	assert(game.choosing_destination)
	click(game, game.grid.center(Vector2i(7, 5)))
	assert(game.engineer.destination == Vector2i(7, 5))
	escape()
	assert(not game.choosing_destination and not game.engineer.selected and not game.engineer.route.is_empty())
	game.reset_scenario()
	await press_control(game, game.hud.plan_button)
	click(game, game.grid.center(Vector2i(6, 5)))
	assert(game.construction.blueprints.has(Vector2i(6, 5)))
	await press_control(game, game.hud.authorize_button)
	assert(game.construction.tasks.has(Vector2i(6, 5)))
	await press_control(game, game.hud.cancel_all_button)
	assert(game.construction.tasks.is_empty())
	await press_control(game, game.hud.object_button)
	await process_frame
	assert(game.hud.object_type.visible and not game.hud.area_type.visible)
	click(game, game.grid.center(Vector2i(7, 5)))
	assert(game.hud.message_label.text.contains("exige área"))
	game.hud.object_button.grab_focus()
	escape()
	assert(game.hud.select_button.button_pressed)
	game.reset_scenario()
	click(game, game.classd.position)
	assert(game.classd.selected and game.hud.move_button.disabled)
	escape()
	assert(not game.classd.selected)
	game.grid.set_area(Vector2i(6, 5), 1)
	game.grid.add_object(Vector2i(6, 5), 1)
	click(game, game.grid.center(Vector2i(6, 5)))
	await process_frame
	assert(game.hud.inspect_demolish_button.visible)
	await press_control(game, game.hud.inspect_demolish_button)
	assert(game.construction.tasks.has(Vector2i(6, 5)))
	await process_frame
	await press_control(game, game.hud.inspect_cancel_button)
	assert(game.construction.tasks.is_empty() and game.grid.objects.has(Vector2i(6, 5)))
	game.grid.install_door(Vector2i(10, 5))
	click(game, game.grid.center(Vector2i(10, 5)))
	await press_control(game, game.hud.toggle_door_button)
	assert(game.grid.doors[Vector2i(10, 5)])
	await press_control(game, game.hud.pause_button)
	assert(Engine.time_scale == 0.0)
	await press_control(game, game.hud.normal_button)
	assert(Engine.time_scale == 1.0)
	var path := "user://ui-interaction-check.json"
	assert(game.save_slot.save_game(game, path).contains("sucesso"))
	assert(game.save_slot.load_game(game, path).contains("sucesso"))
	DirAccess.remove_absolute(path)
	print("GRAPHICAL INTERACTIONS: selection, move, Escape/focus, tools, authorization, cancellation, blocked action, autonomous NPC, object, door, pause and isolated save/load passed")
