extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func validate_route(grid: GridState, path: Array[Vector2i], start: Vector2i, goal: Vector2i) -> void:
	check(not path.is_empty(), "route exists: %s -> %s" % [start, goal])
	if path.is_empty():
		return
	check(path[0] == start and path[-1] == goal, "route endpoints")
	for index in path.size():
		check(grid.is_walkable(path[index]), "route avoids walls and map boundaries")
		if index > 0:
			var step := path[index] - path[index - 1]
			check(absi(step.x) + absi(step.y) == 1, "only orthogonal adjacent steps; no corner cutting")

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func() -> void:
		printerr("FAIL: test runner timed out before completion")
		quit(2))
	call_deferred("run")

func click(viewport: Viewport, point: Vector2, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = button
	event.pressed = true
	viewport.push_input(event, true)
	var release := event.duplicate() as InputEventMouseButton
	release.pressed = false
	viewport.push_input(release, true)

func run() -> void:
	var grid := GridState.new()
	check(GameSettings.GRID_SIZE == Vector2i(24, 24) and GameSettings.CELL_SIZE == 32, "map dimensions")
	check(grid.to_cell(Vector2(-0.1, 0)) == Vector2i(-1, 0), "negative coordinates stay outside")
	check(grid.to_cell(Vector2(768, 0)) == Vector2i(24, 0), "right boundary stays outside")
	var free := GridNavigation.find_path(grid, Vector2i(4, 5), Vector2i(7, 5))
	validate_route(grid, free, Vector2i(4, 5), Vector2i(7, 5))
	check(free.size() == 4, "shortest free route")
	var detour := GridNavigation.find_path(grid, Vector2i(9, 8), Vector2i(11, 8))
	validate_route(grid, detour, Vector2i(9, 8), Vector2i(11, 8))
	check(detour.size() == 11 and detour.has(Vector2i(10, 12)), "detour uses wall opening")
	check(GridNavigation.find_path(grid, GameSettings.SPAWN, Vector2i(19, 19)).is_empty(), "sealed floor is unreachable")
	check(GridNavigation.find_path(grid, GameSettings.SPAWN, Vector2i(10, 5)).is_empty(), "wall rejected")
	check(GridNavigation.find_path(grid, GameSettings.SPAWN, Vector2i(24, 0)).is_empty(), "outside rejected")
	check(GridNavigation.find_path(grid, GameSettings.SPAWN, GameSettings.SPAWN).size() == 1, "same cell route")
	var corner := GridState.new()
	corner.walls = {Vector2i(0, 1): true, Vector2i(1, 0): true}
	check(GridNavigation.find_path(corner, Vector2i.ZERO, Vector2i.ONE).is_empty(), "cannot escape a diagonal corner")

	var scene := load("res://scenes/main.tscn") as PackedScene
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	var engineer: Engineer = game.engineer
	engineer.set_process(false)
	check(engineer.position == grid.center(GameSettings.SPAWN), "engineer spawns centered")
	check(not engineer.selected, "starts unselected")
	engineer.set_selected(true)
	check(game.hud.selection_label.text.contains("Engenheiro 01"), "HUD selection signal")
	check(engineer.move_to(Vector2i(7, 5)).contains("a caminho"), "valid order accepted")
	engineer._process(0.125)
	check(engineer.position == grid.center(GameSettings.SPAWN) + Vector2(16, 0), "configured speed")
	engineer.move_to(Vector2i(4, 7))
	check(engineer.route[0] == Vector2i(5, 5), "retarget finishes current segment")
	var preserved_route := engineer.route.duplicate()
	check(engineer.move_to(Vector2i(19, 19)).contains("inacessível"), "unreachable message")
	check(engineer.move_to(Vector2i(10, 5)).contains("parede"), "wall message")
	check(engineer.move_to(Vector2i(-1, 5)).contains("fora do mapa"), "outside message")
	check(engineer.route == preserved_route and engineer.destination == Vector2i(4, 7), "invalid orders preserve current route")
	var frames := 0
	while not engineer.route.is_empty() and frames < 1000:
		var previous_position := engineer.position
		engineer._process(1.0 / 60.0)
		var displacement := engineer.position - previous_position
		# A frame may consume the end of one edge and the start of another;
		# the implementation walks each segment independently.
		check(grid.is_walkable(grid.to_cell(engineer.position)), "movement stays on floor")
		check(displacement.length() <= GameSettings.ENGINEER_SPEED / 60.0 + 0.001, "movement respects speed")
		frames += 1
	check(frames < 1000 and engineer.position == grid.center(Vector2i(4, 7)), "movement arrives exactly")
	check(game.hud.state_label.text == "Estado: Parado", "HUD arrival state")
	engineer.move_to(Vector2i(13, 5))
	engineer._process(100.0)
	check(engineer.position == grid.center(Vector2i(13, 5)) and engineer.route.is_empty(), "movement completes obstacle detour even with large delta")
	engineer.move_to(Vector2i(13, 5))
	check(engineer.route.is_empty(), "same-cell order stays idle")
	game.camera.change_zoom(100.0)
	check(is_equal_approx(game.camera.zoom.x, GameSettings.ZOOM_MAX), "maximum zoom")
	game.camera.change_zoom(0.0001)
	check(is_equal_approx(game.camera.zoom.x, GameSettings.ZOOM_MIN), "minimum zoom")
	game.camera.position = Vector2(-10000, 10000)
	game.camera.clamp_position()
	check(game.camera.position == Vector2(-128, 896), "camera pan bounds")
	engineer.move_to(Vector2i(4, 5))
	game.hud.restart_button.pressed.emit()
	check(engineer.cell == GameSettings.SPAWN and engineer.route.is_empty() and not engineer.selected, "restart button resets engineer")
	check(engineer.position == grid.center(GameSettings.SPAWN), "restart resets position")
	check(game.camera.position == GameSettings.INITIAL_CAMERA and is_equal_approx(game.camera.zoom.x, GameSettings.INITIAL_ZOOM), "restart resets camera")
	check(game.hud.destination_label.text == "Destino: (4, 5)", "restart resets HUD")
	# Route synthetic pointer events through the real viewport, including GUI
	# consumption and the camera's world/screen transform.
	await process_frame
	var transform: Transform2D = game.get_canvas_transform()
	click(root, transform * grid.center(Vector2i(7, 5)), MOUSE_BUTTON_RIGHT)
	check(engineer.route.is_empty() and game.hud.message_label.text.contains("Selecione"), "right click requires selection")
	click(root, transform * engineer.position, MOUSE_BUTTON_LEFT)
	check(engineer.selected, "left click selects engineer through viewport")
	click(root, transform * grid.center(Vector2i(7, 5)), MOUSE_BUTTON_RIGHT)
	check(engineer.destination == Vector2i(7, 5) and not engineer.route.is_empty(), "right click issues order through viewport")
	click(root, transform * grid.center(Vector2i(10, 5)), MOUSE_BUTTON_RIGHT)
	check(game.hud.message_label.text.contains("parede"), "invalid click displays readable HUD message")
	click(root, Vector2(40, 40), MOUSE_BUTTON_LEFT)
	check(engineer.selected, "HUD consumes clicks without deselecting")
	click(root, game.hud.restart_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	check(not engineer.selected and engineer.route.is_empty(), "pointer click activates restart button")
	click(root, transform * engineer.position, MOUSE_BUTTON_LEFT)
	click(root, transform * grid.center(Vector2i(6, 6)), MOUSE_BUTTON_LEFT)
	check(not engineer.selected, "clicking floor deselects")
	await ConstructionTests.new().run(self, game)
	await DemolitionTests.new().run(self, game)
	game.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
