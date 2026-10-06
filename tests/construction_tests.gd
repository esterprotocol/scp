class_name ConstructionTests
extends RefCounted

var runner
var game
var worker: Engineer
var jobs: Construction
var grid: GridState

func check(condition: bool, description: String) -> void:
	runner.check(condition, "construction: " + description)

func step(delta: float) -> void:
	worker._process(delta)
	jobs._process(delta)

func begin_work() -> void:
	var ticks := 0
	while not worker.working and ticks < 500:
		step(0.05)
		check(grid.is_walkable(grid.to_cell(worker.position)), "travel stays on walkable floor")
		ticks += 1
	check(worker.working, "worker reaches adjacent work position")

func reset_case() -> void:
	game.reset_scenario()

func run(harness: SceneTree, scene: Node2D) -> void:
	runner = harness
	game = scene
	worker = game.engineer
	jobs = game.construction
	grid = game.grid
	worker.set_process(false)
	jobs.set_process(false)
	reset_case()
	var original_walls := grid.walls.duplicate()
	check(jobs.plan(GameSettings.SPAWN).contains("ocupada"), "cannot plan on engineer")
	check(jobs.plan(Vector2i(10, 5)).contains("parede"), "cannot plan on existing wall")
	check(jobs.plan(Vector2i(24, 0)).contains("Fora"), "cannot plan outside map")
	check(jobs.blueprints.is_empty(), "invalid plans make no blueprint")
	jobs.plan(Vector2i(6, 5))
	check(grid.is_walkable(Vector2i(6, 5)), "blueprint is walkable")
	var path := GridNavigation.find_path(grid, GameSettings.SPAWN, Vector2i(7, 5))
	check(path.size() == 4 and path.has(Vector2i(6, 5)), "route crosses unbuilt blueprint")
	jobs.plan(Vector2i(6, 5))
	check(jobs.blueprints.size() == 1, "repeated planning does not duplicate")
	jobs.authorize()
	jobs.authorize()
	check(jobs.tasks.size() == 1, "repeated authorization makes one task per cell")
	jobs._process(0.0)
	check(jobs.active == Vector2i(6, 5) and worker.construction_busy, "authorized task takes worker")
	check(worker.move_to(Vector2i(7, 5)).contains("recusada"), "manual order refused during construction travel")
	begin_work()
	var difference := worker.cell - jobs.active
	check(absi(difference.x) + absi(difference.y) == 1 and worker.position == grid.center(worker.cell), "works from orthogonal adjacent cell center")
	check(jobs.progress() == 0.0, "travel time does not count as work")
	jobs._process(GameSettings.WALL_BUILD_SECONDS * 0.5)
	check(is_equal_approx(jobs.progress(), 0.5), "configurable work time and progress")
	check(grid.is_walkable(Vector2i(6, 5)), "incomplete construction stays walkable")
	check(game.hud.task_label.text.contains("Construindo") and is_equal_approx(game.hud.progress_bar.value, 50.0), "HUD task and work progress")
	check(worker.move_to(Vector2i(7, 5)).contains("Cancele"), "working refuses manual order with explanation")
	var before := worker.position
	jobs.cancel_active()
	check(jobs.tasks.is_empty() and jobs.blueprints.is_empty() and jobs.active == Construction.NONE, "cancel removes incomplete task and blueprint")
	check(not worker.construction_busy and not worker.working and worker.position == before, "cancel releases worker without teleport")
	check(grid.is_walkable(Vector2i(6, 5)), "cancel does not complete wall")
	check(worker.move_to(Vector2i(7, 6)).contains("a caminho"), "manual order accepted after cancellation")

	reset_case()
	jobs.plan(Vector2i(8, 5))
	jobs.authorize()
	jobs._process(0.0)
	worker._process(0.125)
	before = worker.position
	check(before != grid.center(worker.cell), "cancel travel case is between cell centers")
	jobs.cancel(Vector2i(8, 5))
	check(worker.position == before and worker.route.size() == 1, "travel cancellation retains only current segment without snapping")
	check(not worker.construction_busy and jobs.tasks.is_empty(), "travel cancellation frees worker")
	worker.move_to(Vector2i(7, 6))
	worker._process(20.0)
	check(worker.position == grid.center(Vector2i(7, 6)), "worker can be redirected after travel cancellation")

	reset_case()
	jobs.plan(Vector2i(6, 5))
	jobs.authorize()
	jobs._process(0.0)
	begin_work()
	before = worker.position
	jobs._process(GameSettings.WALL_BUILD_SECONDS - 0.01)
	check(grid.is_walkable(Vector2i(6, 5)), "wall does not exist before full work time")
	jobs._process(0.02)
	check(not grid.is_walkable(Vector2i(6, 5)), "completed wall blocks navigation")
	check(worker.position == before and grid.is_walkable(worker.cell), "completion does not move or enclose worker cell")
	check(jobs.tasks.is_empty() and jobs.blueprints.is_empty() and not worker.construction_busy, "completion clears task and blueprint and releases worker")
	path = GridNavigation.find_path(grid, GameSettings.SPAWN, Vector2i(7, 5))
	check(not path.has(Vector2i(6, 5)) and path.size() > 4, "subsequent pathfinding avoids new wall")

	reset_case()
	jobs.plan(Vector2i(19, 19))
	jobs.plan(Vector2i(6, 5))
	jobs.authorize()
	jobs._process(0.0)
	check(jobs.tasks[Vector2i(19, 19)].status == "Bloqueada", "unreachable task marked blocked")
	check(jobs.blocked_text().contains("inacessível") and game.hud.blocked_label.text.contains("19, 19"), "blocked reason visible with cell")
	check(jobs.active == Vector2i(6, 5), "first blocked job does not starve reachable job")
	begin_work()
	jobs._process(GameSettings.WALL_BUILD_SECONDS)
	check(not grid.is_walkable(Vector2i(6, 5)) and jobs.tasks.size() == 1, "reachable task finishes while blocked job remains")
	jobs._process(0.0)
	check(jobs.active == Construction.NONE and not worker.construction_busy, "blocked task leaves worker free")
	grid.add_wall(Vector2i(19, 19))
	check(jobs.dirty, "grid change schedules reevaluation of blocked jobs")
	jobs._process(0.0)
	check(jobs.tasks[Vector2i(19, 19)].reason.contains("parede"), "blocked reason is reevaluated after grid change")
	jobs.cancel(Vector2i(19, 19))
	check(jobs.tasks.is_empty() and jobs.blueprints.is_empty(), "blocked work can be canceled individually")

	# A blueprint may become occupied between planning and authorization.
	reset_case()
	jobs.plan(Vector2i(6, 5))
	worker.move_to(Vector2i(6, 5))
	worker._process(10.0)
	jobs.authorize()
	jobs._process(0.0)
	check(jobs.active == Construction.NONE and jobs.blocked_text().contains("ocupada"), "revalidate occupation before dispatch")
	check(grid.is_walkable(worker.cell), "does not build on current engineer position")
	worker.move_to(Vector2i(5, 5))
	worker._process(10.0)
	jobs._process(0.0)
	check(jobs.active == Vector2i(6, 5), "occupied blocked work retries after engineer moves")
	begin_work()
	# Simulate a stale task whose target changed independently before completion.
	grid.add_wall(Vector2i(6, 5))
	var wall_count := grid.walls.size()
	jobs._process(GameSettings.WALL_BUILD_SECONDS)
	check(jobs.active == Construction.NONE and jobs.blocked_text().contains("parede"), "revalidate target before completion")
	check(grid.walls.size() == wall_count and jobs.tasks[Vector2i(6, 5)].elapsed == 0.0, "stale task cannot complete or duplicate a wall")

	# Future route cells are not reserved: changing one must invalidate movement.
	reset_case()
	worker.move_to(Vector2i(8, 5))
	worker._process(0.125)
	before = worker.position
	grid.add_wall(Vector2i(6, 5))
	check(worker.position == before and not worker.route.has(Vector2i(6, 5)), "grid change invalidates affected route without teleport")
	worker._process(10.0)
	check(worker.cell == Vector2i(5, 5) and worker.position == grid.center(worker.cell), "invalidated route stops at safe current segment end")
	check(not worker.occupies(Vector2i(6, 5)), "engineer never enters newly blocked cell")
	worker.move_to(Vector2i(8, 5))
	worker._process(10.0)
	check(worker.position == grid.center(Vector2i(8, 5)), "new manual route detours around wall")

	# Work cell changed while travelling: abandon unsafe job and continue others.
	reset_case()
	jobs.plan(Vector2i(8, 5))
	jobs.plan(Vector2i(4, 7))
	jobs.authorize()
	jobs._process(0.0)
	check(jobs.work_cell == Vector2i(7, 5), "nearest reachable work cell chosen")
	worker._process(0.125)
	before = worker.position
	grid.add_wall(Vector2i(7, 5))
	jobs._process(0.0)
	check(worker.position == before and jobs.active == Construction.NONE and not worker.construction_busy, "unsafe work access cancels assignment without teleport")
	check(jobs.blocked_text().contains("Posição de trabalho"), "invalidated work position has reason")
	worker._process(10.0)
	jobs._process(0.0)
	check(jobs.active != Construction.NONE and grid.is_walkable(jobs.work_cell), "scheduler retries with a reachable adjacent position")
	jobs.cancel_all()
	check(jobs.tasks.is_empty() and jobs.blueprints.is_empty() and not worker.construction_busy, "cancel all clears authorized and active jobs")

	# UI events must be consumed rather than leaking into map planning.
	reset_case()
	await runner.process_frame
	var transform: Transform2D = game.get_canvas_transform()
	runner.click(runner.root, game.hud.plan_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	check(game.planning and jobs.blueprints.is_empty(), "mode button does not paint a blueprint")
	runner.click(runner.root, transform * grid.center(Vector2i(7, 5)), MOUSE_BUTTON_LEFT)
	check(jobs.blueprints.has(Vector2i(7, 5)), "planning click marks individual cell")
	runner.click(runner.root, Vector2(40, 40), MOUSE_BUTTON_LEFT)
	check(jobs.blueprints.size() == 1, "panel click does not paint on map")
	runner.click(runner.root, game.hud.authorize_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	runner.click(runner.root, game.hud.authorize_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	check(jobs.tasks.size() == 1, "authorize UI repetition does not duplicate")
	runner.click(runner.root, transform * grid.center(Vector2i(7, 5)), MOUSE_BUTTON_RIGHT)
	check(jobs.blueprints.is_empty() and jobs.tasks.is_empty(), "planning right click cancels individual work")
	runner.click(runner.root, game.hud.select_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	check(not game.planning, "select mode restores manual controls")

	# Existing opening is buildable; no closed-room prerequisite.
	reset_case()
	jobs.plan(Vector2i(10, 12))
	jobs.authorize()
	jobs._process(0.0)
	begin_work()
	jobs._process(GameSettings.WALL_BUILD_SECONDS)
	check(grid.walls.has(Vector2i(10, 12)), "can construct in original wall opening")
	jobs.plan(Vector2i(6, 5))
	jobs.plan(Vector2i(7, 5))
	jobs.authorize()
	jobs._process(0.0)
	game.set_planning(true)
	game.camera.change_zoom(2.0)
	game.hud.restart_button.pressed.emit()
	check(grid.walls == original_walls, "restart exactly restores original fixed walls and opening")
	check(jobs.tasks.is_empty() and jobs.blueprints.is_empty() and jobs.active == Construction.NONE, "restart clears all construction state")
	check(not worker.construction_busy and not worker.working and worker.route.is_empty(), "restart releases worker and clears movement")
	check(worker.position == grid.center(GameSettings.SPAWN) and not worker.selected, "restart restores original engineer")
	check(not game.planning and game.hud.select_button.button_pressed, "restart restores selection mode")
	check(game.camera.position == GameSettings.INITIAL_CAMERA and is_equal_approx(game.camera.zoom.x, 0.875), "restart preserves camera reset with map fitted at 720p")
	check(game.hud.progress_bar.value == 0.0 and game.hud.task_label.text.contains("nenhuma"), "restart clears task and progress display")
