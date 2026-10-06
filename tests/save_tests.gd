class_name SaveTests
extends ConstructionTests

class IsolatedSlot extends SaveSlot:
	var test_path: String
	func save_game(scene: Node2D, _path: String = PATH) -> String:
		return super.save_game(scene, test_path)
	func load_game(scene: Node2D, _path: String = PATH) -> String:
		return super.load_game(scene, test_path)

var slot := SaveSlot.new()
var path: String

func check(condition: bool, description: String) -> void:
	runner.check(condition, "save/load: " + description)

func write_json(data: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "", false, true))
	file.close()

func save_and_restore() -> Dictionary:
	var snapshot := slot.capture(game)
	check(slot.save_game(game, path).contains("sucesso"), "write complete snapshot to disk")
	game.reset_scenario()
	check(slot.load_game(game, path).contains("sucesso"), "read validated snapshot from disk")
	check(slot.capture(game) == snapshot, "restore complete state exactly, including queue order and progress")
	return snapshot

func reject(data: Variant, description: String) -> void:
	var before := slot.capture(game)
	write_json(data)
	check(not slot.load_game(game, path).contains("sucesso") and slot.capture(game) == before, description)

func run(harness: SceneTree, scene: Node2D) -> void:
	runner = harness
	game = scene
	worker = game.engineer
	jobs = game.construction
	grid = game.grid
	worker.set_process(false)
	jobs.set_process(false)
	var directory := "user://save_tests_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(directory)
	path = directory + "/slot.json"
	reset_case()
	var before := slot.capture(game)
	check(slot.load_game(game, path).contains("ausente") and slot.capture(game) == before, "missing file preserves world")
	jobs.plan(Vector2i(8, 6))
	game.camera.position = Vector2(320, 400)
	game.camera.change_zoom(1.3)
	game.set_planning(true)
	save_and_restore()
	check(jobs.blueprints.has(Vector2i(8, 6)) and jobs.tasks.is_empty(), "unapproved blueprint remains unapproved")
	check(FileAccess.file_exists(path), "restart does not delete save")
	game.camera.change_zoom(0.00001)
	save_and_restore()
	check(is_equal_approx(game.camera.zoom.x, GameSettings.ZOOM_MIN), "minimum float32 zoom survives save/load")

	reset_case()
	worker.set_selected(true)
	worker.move_to(Vector2i(8, 5))
	worker._process(0.137)
	check(worker.position != grid.center(worker.cell), "movement save is between centers")
	var snapshot := save_and_restore()
	check(worker.position == Vector2(snapshot.engineer.position.x, snapshot.engineer.position.y), "load does not snap moving worker")
	worker._process(10.0)
	check(worker.cell == Vector2i(8, 5) and worker.route.is_empty(), "remaining manual movement completes after load")

	# Mixed queue: first task blocked, second active, demolition later in FIFO.
	reset_case()
	jobs.plan(Vector2i(19, 19))
	jobs.plan(Vector2i(6, 5))
	jobs.authorize()
	jobs.request_demolition(Vector2i(10, 5))
	jobs._process(0.0)
	worker._process(0.125)
	snapshot = save_and_restore()
	check(jobs.active == Vector2i(6, 5) and jobs.tasks[Vector2i(19, 19)].status == "Bloqueada", "mixed blocked queue and active travel preserved")
	check(jobs.tasks.keys() == [Vector2i(19, 19), Vector2i(6, 5), Vector2i(10, 5)], "mixed queue order is explicit")
	begin_work()
	jobs._process(0.7)
	snapshot = save_and_restore()
	check(worker.working and is_equal_approx(jobs.tasks[jobs.active].elapsed, 0.7), "partial construction resumes without restarting work")
	var events := {"count": 0}
	var count_event := func() -> void: events.count += 1
	grid.changed.connect(count_event)
	var worker_events := {"count": 0}
	var count_worker := func() -> void: worker_events.count += 1
	worker.changed.connect(count_worker)
	check(slot.load_game(game, path).contains("sucesso") and slot.capture(game) == snapshot, "repeated load replaces rather than adds tasks")
	check(events.count == 0 and worker_events.count == 0, "restoration emits no intermediate simulation signals")
	jobs._process(GameSettings.WALL_BUILD_SECONDS - 0.7)
	check(grid.walls.has(Vector2i(6, 5)) and events.count == 1 and jobs.tasks.size() == 2, "loaded construction completes exactly once")
	jobs._process(0.0)
	check(jobs.active == Vector2i(10, 5), "blocked build does not prevent queued demolition after load")
	begin_work()
	jobs._process(0.4)
	game.set_demolishing()
	snapshot = save_and_restore()
	check(grid.walls.has(Vector2i(10, 5)) and worker.working and worker.work_action == Construction.DEMOLISH and is_equal_approx(jobs.tasks[jobs.active].elapsed, 0.4), "partial demolition resumes with wall intact")
	check(grid.walls.has(Vector2i(6, 5)) and game.demolishing, "new walls and demolition tool preserved")
	events.count = 0
	jobs._process(GameSettings.WALL_DEMOLISH_SECONDS - 0.4)
	check(not grid.walls.has(Vector2i(10, 5)) and events.count == 1 and jobs.tasks.size() == 1, "loaded demolition completes once and only once")
	jobs._process(10.0)
	check(events.count == 1, "later ticks do not repeat completed operation")
	grid.changed.disconnect(count_event)
	worker.changed.disconnect(count_worker)

	# Restore saved demolished walls too, not only original/new solid cells.
	snapshot = save_and_restore()
	check(not grid.walls.has(Vector2i(10, 5)) and grid.walls.has(Vector2i(6, 5)), "restore full current grid rather than merge original map")
	var valid_bytes := FileAccess.get_file_as_string(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken json")
	file.close()
	before = slot.capture(game)
	check(slot.load_game(game, path).contains("corrompido") and slot.capture(game) == before, "corrupt JSON preserves full world")
	var invalid := snapshot.duplicate(true)
	invalid.schema_version = 999
	reject(invalid, "incompatible schema preserves world")
	invalid = snapshot.duplicate(true)
	invalid.godot_version = "4.0"
	reject(invalid, "incompatible Godot metadata rejected")
	invalid = snapshot.duplicate(true)
	invalid.engineer.position = {"x": 144.1, "y": 176.2}
	reject(invalid, "invalid segment position rejected before modifying world")
	invalid = snapshot.duplicate(true)
	invalid.tasks.append(invalid.tasks[0].duplicate(true))
	reject(invalid, "duplicate task in JSON rejected")
	invalid = snapshot.duplicate(true)
	invalid.walls.append({"x": 24, "y": 0})
	reject(invalid, "outside coordinate rejected")
	invalid = snapshot.duplicate(true)
	invalid.walls.append(invalid.walls[0].duplicate())
	reject(invalid, "duplicate wall rejected")
	invalid = snapshot.duplicate(true)
	invalid.engineer.route = [{"x": 10, "y": 4}]
	invalid.engineer.destination = {"x": 10, "y": 4}
	reject(invalid, "route through wall or nonadjacent jump rejected")
	invalid = snapshot.duplicate(true)
	invalid.active = {"x": 7, "y": 7}
	reject(invalid, "broken active-task link rejected")
	invalid = snapshot.duplicate(true)
	invalid.camera.zoom = 100
	reject(invalid, "invalid camera rejected")
	invalid = snapshot.duplicate(true)
	invalid.engineer.position.x = 1e100
	reject(invalid, "huge coordinates rejected before Vector2 conversion")
	invalid = snapshot.duplicate(true)
	invalid.tasks[0].elapsed = -1
	reject(invalid, "invalid work progress rejected")
	# Reinstate the last valid test slot, then force a real temporary-open
	# failure by putting a directory at the temporary filename.
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(valid_bytes)
	file.close()
	DirAccess.make_dir_absolute(path + ".tmp")
	before = slot.capture(game)
	check(slot.save_game(game, path).contains("temporário") and FileAccess.get_file_as_string(path) == valid_bytes and slot.capture(game) == before, "failed write leaves last valid slot and world intact")
	DirAccess.remove_absolute(path + ".tmp")
	# A second successful save must safely replace an existing slot.
	jobs.plan(Vector2i(9, 9))
	check(slot.save_game(game, path).contains("sucesso"), "safe replacement of existing slot succeeds")
	game.reset_scenario()
	check(slot.load_game(game, path).contains("sucesso") and jobs.blueprints.has(Vector2i(9, 9)), "restart then load restores most recent saved state")

	# Wire the actual buttons to an isolated path, never a player's real slot.
	var original_slot: SaveSlot = game.save_slot
	var isolated := IsolatedSlot.new()
	isolated.test_path = path
	game.save_slot = isolated
	game.hud.save_button.pressed.emit()
	check(game.hud.message_label.text.contains("salvo com sucesso"), "save button reports success")
	game.reset_scenario()
	game.hud.load_button.pressed.emit()
	check(game.hud.message_label.text.contains("carregado com sucesso") and jobs.blueprints.has(Vector2i(9, 9)), "load button restores snapshot and reports success")
	game.save_slot = original_slot
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	reset_case()
