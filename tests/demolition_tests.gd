class_name DemolitionTests
extends ConstructionTests

func check(condition: bool, description: String) -> void:
	runner.check(condition, "demolition/safe exit: " + description)

func corridor(allowed: Array[Vector2i]) -> void:
	# Test fixture only: replace the map before giving any orders.
	grid.walls.clear()
	for x in GameSettings.GRID_SIZE.x:
		for y in GameSettings.GRID_SIZE.y:
			var cell := Vector2i(x, y)
			if not allowed.has(cell):
				grid.walls[cell] = true
	grid.changed.emit()

func run(harness: SceneTree, scene: Node2D) -> void:
	runner = harness
	game = scene
	worker = game.engineer
	jobs = game.construction
	grid = game.grid
	worker.set_process(false)
	jobs.set_process(false)
	reset_case()
	var originals := grid.walls.duplicate()
	check(GameSettings.EXIT_CELL == GameSettings.SPAWN, "reference exit defaults to spawn")
	check(jobs.request_demolition(Vector2i(6, 5)).contains("Não existe"), "cannot demolish floor")
	check(jobs.request_demolition(Vector2i(-1, 0)).contains("Fora"), "cannot demolish outside map")
	check(jobs.tasks.is_empty(), "invalid demolition creates no task")
	var target := Vector2i(18, 19)
	check(GridNavigation.find_path(grid, worker.cell, Vector2i(19, 19)).is_empty(), "sealed-room floor initially inaccessible")
	jobs.request_demolition(target)
	jobs.request_demolition(target)
	jobs.authorize()
	check(jobs.tasks.size() == 1 and jobs.tasks[target].action == Construction.DEMOLISH, "repeated demolition request creates one task")
	check(grid.walls.has(target), "request does not remove wall")
	jobs._process(0.0)
	check(jobs.active == target and worker.construction_busy, "demolition uses exclusive worker coordination")
	check(worker.move_to(GameSettings.SPAWN).contains("recusada"), "demolition travel rejects manual order")
	begin_work()
	var difference := worker.cell - target
	check(absi(difference.x) + absi(difference.y) == 1, "demolition works orthogonally adjacent")
	check(worker.state_text() == "Demolindo parede" and game.hud.task_label.text.contains("Demolir"), "HUD identifies demolition action and target")
	jobs._process(GameSettings.WALL_DEMOLISH_SECONDS * 0.5)
	check(grid.walls.has(target) and is_equal_approx(jobs.progress(), 0.5), "wall remains during configurable demolition work")
	check(GridNavigation.find_path(grid, worker.cell, Vector2i(19, 19)).is_empty(), "incomplete demolition keeps route closed")
	var before := worker.position
	jobs.cancel_active()
	check(grid.walls.has(target) and jobs.tasks.is_empty(), "cancel preserves wall and clears task")
	check(not worker.construction_busy and not worker.working and worker.position == before, "cancel releases worker without teleport")
	check(worker.move_to(Vector2i(17, 20)).contains("a caminho"), "manual order accepted after demolition cancellation")

	reset_case()
	jobs.request_demolition(Vector2i(10, 5))
	jobs._process(0.0)
	worker._process(0.125)
	before = worker.position
	jobs.cancel_active()
	check(worker.position == before and worker.route.size() == 1 and not worker.construction_busy, "demolition cancellation in transit finishes only current segment")
	check(grid.walls.has(Vector2i(10, 5)), "transit cancellation preserves original wall")

	reset_case()
	jobs.request_demolition(target)
	jobs._process(0.0)
	begin_work()
	jobs._process(GameSettings.WALL_DEMOLISH_SECONDS - 0.01)
	check(grid.walls.has(target), "wall stays until full work duration")
	before = worker.position
	jobs._process(0.02)
	check(not grid.walls.has(target) and grid.is_walkable(target), "completion removes original wall")
	check(not GridNavigation.find_path(grid, worker.cell, Vector2i(19, 19)).is_empty(), "completed demolition opens previously inaccessible route")
	check(worker.position == before and jobs.tasks.is_empty() and not worker.construction_busy, "completion releases worker in place")

	reset_case()
	jobs.plan(Vector2i(6, 5))
	jobs.authorize()
	jobs._process(0.0)
	begin_work()
	jobs._process(GameSettings.WALL_BUILD_SECONDS)
	check(grid.walls.has(Vector2i(6, 5)), "new constructed wall exists")
	jobs.request_demolition(Vector2i(6, 5))
	jobs._process(0.0)
	begin_work()
	jobs._process(GameSettings.WALL_DEMOLISH_SECONDS)
	check(not grid.walls.has(Vector2i(6, 5)), "can demolish constructed wall too")

	# The last reference-exit cell cannot itself be sealed from any work side.
	reset_case()
	corridor([GameSettings.SPAWN, Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5)])
	worker.move_to(Vector2i(7, 5))
	worker._process(10.0)
	jobs.plan(GameSettings.EXIT_CELL)
	jobs.authorize()
	var walls_before := grid.walls.duplicate()
	var events := {"count": 0}
	var count_event := func() -> void: events.count += 1
	grid.changed.connect(count_event)
	jobs._process(0.0)
	check(jobs.active == Construction.NONE and jobs.tasks[GameSettings.EXIT_CELL].reason == Construction.UNSAFE_EXIT, "last exit construction blocked with exact reason")
	check(game.hud.blocked_label.text.contains(Construction.UNSAFE_EXIT), "unsafe exit reason displayed")
	check(grid.walls == walls_before and events.count == 0, "hypothetical checks neither mutate grid nor emit change events")
	jobs.request_demolition(Vector2i(7, 4))
	jobs._process(0.0)
	check(jobs.active == Vector2i(7, 4), "unsafe construction does not block reachable demolition")
	begin_work()
	jobs._process(GameSettings.WALL_DEMOLISH_SECONDS)
	check(not grid.walls.has(Vector2i(7, 4)) and jobs.tasks.has(GameSettings.EXIT_CELL), "demolition proceeds while unsafe build remains queued")
	grid.changed.disconnect(count_event)

	# Closing a corridor is allowed from the exit side, even if the closest
	# work position is on the trapped side. Travel must cross the blueprint.
	reset_case()
	corridor([GameSettings.SPAWN, Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5)])
	worker.move_to(Vector2i(7, 5))
	worker._process(10.0)
	jobs.plan(Vector2i(6, 5))
	jobs.authorize()
	walls_before = grid.walls.duplicate()
	grid.changed.connect(count_event)
	events.count = 0
	jobs._process(0.0)
	check(jobs.work_cell == Vector2i(5, 5), "prefers reachable safe side over nearest trapped side")
	check(worker.route.has(Vector2i(6, 5)), "safe work position reached through still-walkable blueprint")
	check(grid.walls == walls_before and events.count == 0, "safe-side selection is purely hypothetical")
	begin_work()
	jobs._process(GameSettings.WALL_BUILD_SECONDS)
	check(grid.walls.has(Vector2i(6, 5)) and worker.cell == Vector2i(5, 5), "safe alternative permits wall completion")
	check(not GridNavigation.find_path(grid, worker.cell, GameSettings.EXIT_CELL).is_empty(), "exit remains reachable after construction")
	check(events.count == 1, "only real wall completion emits change event")
	grid.changed.disconnect(count_event)

	# Simulate a grid change while working to check the final safety guard.
	# Removing the new obstruction by physical demolition restores access and
	# lets the original queued construction resume, using the same worker.
	reset_case()
	corridor([GameSettings.SPAWN, Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4), Vector2i(6, 5), Vector2i(6, 6), Vector2i(6, 7)])
	worker.move_to(Vector2i(6, 7))
	worker._process(10.0)
	jobs.plan(Vector2i(6, 6))
	jobs.authorize()
	jobs._process(0.0)
	begin_work()
	jobs._process(GameSettings.WALL_BUILD_SECONDS * 0.5)
	grid.add_wall(Vector2i(6, 4))
	before = worker.position
	jobs._process(GameSettings.WALL_BUILD_SECONDS)
	check(jobs.active == Construction.NONE and jobs.tasks.has(Vector2i(6, 6)) and jobs.tasks[Vector2i(6, 6)].reason == Construction.UNSAFE_EXIT, "revalidation immediately before completion blocks lost exit")
	check(grid.is_walkable(Vector2i(6, 6)) and worker.position == before, "unsafe completion does not build or teleport")
	jobs.request_demolition(Vector2i(6, 4))
	jobs._process(0.0)
	check(jobs.active == Vector2i(6, 4), "blocked build yields worker to restoring demolition")
	begin_work()
	jobs._process(GameSettings.WALL_DEMOLISH_SECONDS)
	check(not grid.walls.has(Vector2i(6, 4)), "physical demolition restores access")
	jobs._process(0.0)
	check(jobs.active == Vector2i(6, 6), "blocked build reevaluated and resumed after demolition")
	begin_work()
	jobs._process(GameSettings.WALL_BUILD_SECONDS)
	check(grid.walls.has(Vector2i(6, 6)) and not GridNavigation.find_path(grid, worker.cell, GameSettings.EXIT_CELL).is_empty(), "resumed build preserves restored exit")

	# Demolition whose adjacent cells are inaccessible must explain its block.
	reset_case()
	grid.add_wall(Vector2i(20, 20))
	jobs.request_demolition(Vector2i(20, 20))
	jobs._process(0.0)
	check(jobs.blocked_text().contains("Demolir") and jobs.blocked_text().contains("inacessível"), "blocked demolition includes action and reason")
	jobs.cancel_all()
	check(jobs.tasks.is_empty() and grid.walls.has(Vector2i(20, 20)), "cancel all preserves requested walls")

	# UI input and reset of mixed work.
	reset_case()
	await runner.process_frame
	var transform: Transform2D = game.get_canvas_transform()
	runner.click(runner.root, game.hud.demolish_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	check(game.demolishing and not game.planning and jobs.tasks.is_empty(), "demolish mode button does not request work on map")
	runner.click(runner.root, transform * grid.center(Vector2i(10, 5)), MOUSE_BUTTON_LEFT)
	runner.click(runner.root, transform * grid.center(Vector2i(10, 5)), MOUSE_BUTTON_LEFT)
	check(jobs.tasks.size() == 1 and grid.walls.has(Vector2i(10, 5)), "demolish pointer requests one task without removal")
	runner.click(runner.root, Vector2(40, 40), MOUSE_BUTTON_LEFT)
	check(jobs.tasks.size() == 1, "HUD click does not request demolition")
	runner.click(runner.root, transform * grid.center(Vector2i(10, 5)), MOUSE_BUTTON_RIGHT)
	check(jobs.tasks.is_empty() and grid.walls.has(Vector2i(10, 5)), "demolition pointer cancellation preserves wall")
	jobs.request_demolition(Vector2i(10, 5))
	jobs.plan(Vector2i(6, 5))
	jobs.authorize()
	jobs._process(0.0)
	check(jobs.active == Vector2i(10, 5) and jobs.tasks.size() == 2, "mixed queue has a single active demolition")
	begin_work()
	jobs._process(GameSettings.WALL_DEMOLISH_SECONDS)
	jobs._process(0.0)
	begin_work()
	jobs._process(GameSettings.WALL_BUILD_SECONDS)
	jobs.request_demolition(Vector2i(6, 5))
	jobs.plan(Vector2i(8, 6))
	jobs.authorize()
	jobs._process(0.0)
	game.hud.restart_button.pressed.emit()
	check(grid.walls == originals, "reset restores removed original and removes constructed walls exactly")
	check(jobs.tasks.is_empty() and jobs.blueprints.is_empty() and jobs.active == Construction.NONE, "reset clears both action queues")
	check(worker.cell == GameSettings.SPAWN and worker.position == grid.center(worker.cell) and worker.route.is_empty() and not worker.construction_busy and not worker.working, "reset restores sole worker")
	check(not game.demolishing and not game.planning and game.hud.select_button.button_pressed and game.hud.progress_bar.value == 0.0, "reset restores mode and progress")
