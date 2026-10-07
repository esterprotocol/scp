class_name ClassDTests
extends RefCounted

var runner
var game
var person: ClassD
var grid: GridState
var slot := SaveSlot.new()
const BED := Vector2i(8, 7)
const MEAL := Vector2i(8, 9)
const SAVE_PATH := "user://classd_test_slot.json"

func check(condition: bool, description: String) -> void:
	runner.check(condition, "Classe-D: " + description)

func reset_case() -> void:
	game.reset_scenario()
	person.set_process(false)
	game.engineer.set_process(false)
	game.construction.set_process(false)

func install(target: Vector2i, kind: int) -> void:
	check(grid.set_area(target, grid.object_area(kind)), "designate compatible area")
	check(grid.add_object(target, kind), "install solid object with interaction points")

func arrive() -> void:
	var ticks := 0
	while person.state == ClassD.MOVING and ticks < 500:
		var before := person.position
		var hunger := person.hunger
		var rest := person.rest
		person._process(0.05)
		check(grid.is_walkable(grid.to_cell(person.position)), "travel stays on floor")
		check(person.position.distance_to(before) <= GameSettings.CLASSD_SPEED * 0.05 + 0.001, "travel respects speed without teleporting")
		check(person.hunger <= hunger and person.rest <= rest, "travel never recovers needs")
		ticks += 1
	check(person.state == ClassD.USING, "arrives before starting use")
	check(person.cell == person.destination and person.position == grid.center(person.destination), "use starts at exact interaction center")
	check(grid.interaction_cells(person.reserved_object).has(person.cell) and person.cell != person.reserved_object, "uses orthogonal point outside object cell")

func restore_exact() -> Dictionary:
	var snapshot := slot.capture(game)
	check(slot.save_game(game, SAVE_PATH).contains("sucesso"), "write schema 4 snapshot")
	game.reset_scenario()
	check(slot.load_game(game, SAVE_PATH).contains("sucesso"), "restore validated snapshot")
	check(slot.capture(game) == snapshot, "restore exact needs, position, route, state and progress")
	return snapshot

func reject(raw: Dictionary, description: String) -> void:
	var before := slot.capture(game)
	check(slot.decode(raw).has("error") and slot.capture(game) == before, description)

func run(harness: SceneTree, scene: Node2D) -> void:
	runner = harness
	game = scene
	person = game.classd
	grid = game.grid
	reset_case()
	check(person.cell != game.engineer.cell and grid.is_walkable(person.cell), "unique person starts on separate free cell")
	person._process(10.0)
	check(is_equal_approx(person.hunger, 100.0 - 10.0 * GameSettings.CLASSD_HUNGER_DECAY) and is_equal_approx(person.rest, 100.0 - 10.0 * GameSettings.CLASSD_REST_DECAY), "both needs decay in configurable simulated time")
	check(person.state == ClassD.IDLE and person.route.is_empty() and person.position == grid.center(person.cell), "no urgency stays idle on free cell")

	reset_case()
	install(BED, 1)
	install(MEAL, 4)
	person.rest = 20.0
	person.hunger = 30.0
	person._process(0.0)
	check(person.need == "Descanso" and person.reserved_object == BED, "lower rest chooses accessible bed before food")
	check(grid.reservations.get(BED) == ClassD.ID and not grid.reserve_object(BED, "classd-002"), "identifier reservation excludes another person")
	check(game.construction.plan(person.cell).contains("Classe-D"), "engineering protects person cell")
	person._process(0.137)
	check(person.position != grid.center(person.cell), "save fixture is between cell centers")
	var snapshot := restore_exact()
	check(person.position == Vector2(snapshot.classd.position.x, snapshot.classd.position.y), "load never snaps moving person")
	grid.reservations[MEAL] = "stale-owner"
	check(slot.load_game(game, SAVE_PATH).contains("sucesso") and grid.reservations.size() == 1 and grid.reservations[BED] == ClassD.ID, "load releases previous and stale reservations before rebuilding one")
	arrive()
	var at_point := person.position
	var start := person.rest
	person._process(GameSettings.CLASSD_REST_SECONDS * 0.25)
	check(person.position == at_point and is_equal_approx(person.rest, lerpf(start, 100.0, 0.25)), "bed recovers gradually while stationary")
	snapshot = restore_exact()
	var reservations_events := {"count": 0}
	var count_reservations := func() -> void: reservations_events.count += 1
	grid.availability_changed.connect(count_reservations)
	check(slot.load_game(game, SAVE_PATH).contains("sucesso") and slot.capture(game) == snapshot and reservations_events.count == 0, "repeated load during use preserves progress without intermediate signals")
	var people := 0
	for child: Node in game.get_children():
		if child is ClassD:
			people += 1
	check(people == 1 and grid.reservations.size() == 1, "repeated load duplicates neither person nor reservation")
	person._process(GameSettings.CLASSD_REST_SECONDS * 0.75)
	check(person.rest == 100.0 and not grid.reservations.has(BED), "remaining use completes once and releases bed")
	grid.availability_changed.disconnect(count_reservations)
	person._process(0.0)
	check(person.need == "Fome" and person.reserved_object == MEAL, "only after use finishes seeks next urgent need")
	arrive()
	start = person.hunger
	person._process(GameSettings.CLASSD_MEAL_SECONDS * 0.5)
	check(is_equal_approx(person.hunger, lerpf(start, 100.0, 0.5)), "meal dispenser recovers hunger gradually")
	restore_exact()
	person._process(GameSettings.CLASSD_MEAL_SECONDS * 0.5)
	check(person.hunger == 100.0 and grid.reservations.is_empty(), "meal completion releases reservation")
	person._process(0.0)
	check(person.state == ClassD.IDLE and person.route.is_empty(), "satisfied person stays idle at a free point")

	reset_case()
	person.hunger = 10.0
	person.rest = 15.0
	person._process(0.0)
	check(person.state == ClassD.BLOCKED and person.impediment == "Objeto inexistente.", "no resources yields explicit missing-object impediment")
	check(game.hud.alerts_label.text.contains("Classe-D 001: sem distribuidor de refeições acessível.") and game.hud.alerts_label.text.contains("Classe-D 001: sem cama acessível."), "both required alerts are readable in population panel")
	install(BED, 1)
	install(MEAL, 4)
	person._process(0.0)
	check(person.need == "Fome" and person.alerts.is_empty() and game.hud.alerts_label.text == "Alertas: nenhum", "installing accessible resources clears alerts and serves lower hunger")
	person.cancel_action()
	check(grid.reservations.is_empty(), "cancelling action releases identifier reservation")
	person._process(0.137)
	var before := person.position
	person.cancel_action()
	check(person.position == before and grid.reservations.is_empty(), "cancel in transit releases reservation without teleporting")
	person._process(1.0)
	check(person.route.is_empty() and person.position == grid.center(person.cell), "cancellation completes current orthogonal segment")

	# A full dividing wall leaves exactly one door as the route to a bed.
	reset_case()
	grid.walls.clear()
	for y in GameSettings.GRID_SIZE.y:
		grid.walls[Vector2i(7, y)] = true
	grid.changed.emit()
	check(grid.install_door(Vector2i(7, 7)), "closed door in actual separating wall")
	install(Vector2i(9, 7), 1)
	person.rest = 10.0
	person._process(0.0)
	check(person.state == ClassD.BLOCKED and person.impediment.contains("Porta fechada") and grid.reservations.is_empty(), "closed door prevents route and identifies cause")
	game.select_cell(Vector2i(7, 7))
	game.toggle_selected_door()
	person._process(0.0)
	check(person.state == ClassD.MOVING and person.route.has(Vector2i(7, 7)) and person.alerts.is_empty(), "opening real door resumes route and clears alert")
	person._process(0.1)
	before = person.position
	check(grid.set_door_open(Vector2i(7, 7), false), "close future route door")
	check(person.position == before and grid.reservations.is_empty(), "door change invalidates route and releases reservation without teleporting")
	person._process(1.0)
	person._process(0.0)
	check(person.state == ClassD.BLOCKED and person.impediment.contains("Porta fechada"), "stops before door and reports blockage")
	grid.set_door_open(Vector2i(7, 7), true)
	person._process(0.0)
	arrive()
	check(grid.reservations.size() == 1, "door reopening reserves once")
	grid.remove_object(Vector2i(9, 7))
	person._process(0.0)
	check(person.state == ClassD.BLOCKED and grid.reservations.is_empty() and person.impediment.contains("inexistente"), "object removal during use stops recovery and releases reservation")

	reset_case()
	install(BED, 1)
	person.rest = 10.0
	check(grid.reserve_object(BED, "classd-002"), "fixture reserves bed for another identifier")
	person._process(0.0)
	check(person.state == ClassD.BLOCKED and person.reserved_object == ClassD.NONE and person.impediment.contains("ocupado/reservado"), "occupied object cannot be chosen")
	grid.release_reservations("classd-002")
	person._process(0.0)
	check(person.state == ClassD.MOVING, "reservation release retries without needing a grid edit")
	person._process(0.1)
	before = person.position
	check(grid.add_wall(Vector2i(7, 7)), "place wall on future route, beyond occupied segment")
	check(person.position == before and grid.reservations.is_empty(), "wall invalidation releases reservation without snap")
	person._process(1.0)
	person._process(0.0)
	check(person.state == ClassD.MOVING and not person.route.has(Vector2i(7, 7)), "replans an alternate orthogonal route around new wall")
	before = person.position
	grid.remove_object(BED)
	check(person.position == before and grid.reservations.is_empty(), "object removed in transit cancels without teleporting")
	person._process(1.0)
	person._process(0.0)
	check(person.alerts.size() == 1, "removed destination produces current readable alert")

	# A sole interaction point can be structurally free but occupied by a person.
	reset_case()
	grid.walls.clear()
	var surrounded := Vector2i(4, 6)
	grid.walls[Vector2i(3, 6)] = true
	grid.walls[Vector2i(5, 6)] = true
	grid.walls[Vector2i(4, 7)] = true
	grid.changed.emit()
	install(surrounded, 1)
	person.rest = 10.0
	person._process(0.0)
	check(person.state == ClassD.BLOCKED and person.impediment.contains("sem ponto de interação livre"), "engineer occupying sole point prevents bed selection")
	game.engineer.move_to(Vector2i(3, 5))
	game.engineer._process(1.0)
	person._process(0.0)
	check(person.state == ClassD.MOVING and person.alerts.is_empty(), "freeing interaction point resolves impediment")

	reset_case()
	install(Vector2i(19, 19), 1)
	person.rest = 10.0
	person._process(0.0)
	check(person.state == ClassD.BLOCKED and person.impediment == "Rota bloqueada.", "sealed room identifies blocked route separately from absent object")

	# A new solid object on a later route segment forces a physical detour.
	reset_case()
	install(BED, 1)
	person.rest = 10.0
	person._process(0.1)
	grid.set_area(Vector2i(7, 7), 2)
	before = person.position
	check(grid.add_object(Vector2i(7, 7), 3), "install another solid object on future route")
	check(person.position == before and grid.reservations.is_empty(), "new object invalidates route without teleporting")
	person._process(1.0)
	person._process(0.0)
	arrive()
	person._process(2.0)
	game.reset_scenario()
	check(person.hunger == 100.0 and person.rest == 100.0 and person.state == ClassD.IDLE and person.cell == GameSettings.CLASSD_SPAWN and grid.reservations.is_empty(), "restart during use restores needs, position and no reservations")

	# Legacy snapshots acquire exactly one initial person, even if its preferred cell is blocked.
	for version in [1, 2, 3]:
		reset_case()
		var legacy := slot.capture(game)
		legacy.schema_version = version
		legacy.erase("classd")
		legacy.walls.append(SaveSlot.coordinates(Vector2(GameSettings.CLASSD_SPAWN)))
		if version < 3:
			legacy.erase("objects")
			legacy.erase("object_blueprints")
			legacy.erase("object_type")
		if version == 1:
			for key in ["doors", "areas", "area_type", "selected_cell"]:
				legacy.erase(key)
		var decoded := slot.decode(legacy)
		check(not decoded.has("error"), "migrate valid schema %d" % version)
		if not decoded.has("error"):
			slot.apply(game, decoded.state)
			check(grid.is_walkable(person.cell) and person.cell != game.engineer.cell and person.hunger == 100.0 and grid.reservations.is_empty(), "legacy migration chooses a separate free cell without reservations")
			check(slot.capture(game).schema_version == 4, "migrated snapshot saves as schema 4")

	reset_case()
	install(BED, 1)
	person.rest = 10.0
	person._process(0.137)
	snapshot = slot.capture(game)
	var invalid := snapshot.duplicate(true)
	invalid.classd.hunger = 101
	reject(invalid, "reject out-of-range need atomically")
	invalid = snapshot.duplicate(true)
	invalid.classd.id = "classd-002"
	reject(invalid, "reject inconsistent fixed identity")
	invalid = snapshot.duplicate(true)
	invalid.classd.position.y += 2.0
	reject(invalid, "reject position outside orthogonal segment")
	invalid = snapshot.duplicate(true)
	invalid.classd.reserved_object = SaveSlot.coordinates(Vector2(MEAL))
	reject(invalid, "reject reservation without correct object")
	invalid = snapshot.duplicate(true)
	invalid.classd.use_elapsed = 1.0
	reject(invalid, "reject recovery progress while travelling")
	invalid = snapshot.duplicate(true)
	invalid.classd = [invalid.classd, invalid.classd]
	reject(invalid, "reject duplicate population payload")
	arrive()
	person._process(1.0)
	snapshot = slot.capture(game)
	invalid = snapshot.duplicate(true)
	invalid.classd.rest += 1.0
	reject(invalid, "reject mismatched use progress and recovered need")

	reset_case()
	await runner.process_frame
	var transform: Transform2D = game.get_canvas_transform()
	runner.click(runner.root, transform * person.position, MOUSE_BUTTON_LEFT)
	check(person.selected and not game.engineer.selected and game.hud.selection_label.text.contains(ClassD.NAME), "viewport selects Classe-D with independent panel")
	runner.click(runner.root, transform * grid.center(Vector2i(8, 8)), MOUSE_BUTTON_RIGHT)
	check(person.route.is_empty() and game.engineer.route.is_empty(), "right click on selected Classe-D issues no engineering order")
	runner.click(runner.root, transform * game.engineer.position, MOUSE_BUTTON_LEFT)
	check(game.engineer.selected and not person.selected, "engineer selection and controls remain available")
	runner.click(runner.root, transform * grid.center(Vector2i(7, 5)), MOUSE_BUTTON_RIGHT)
	check(game.engineer.destination == Vector2i(7, 5), "engineer still accepts movement command")
	var scroll: ScrollContainer = game.hud.get_child(0).get_child(0)
	check(game.hud.population_label.get_global_rect().end.y < 720 and game.hud.alerts_label.get_global_rect().end.y < 720, "population and alerts visible at 1280x720")
	game.set_object_mode()
	await runner.process_frame
	scroll.ensure_control_visible(game.hud.object_type)
	await runner.process_frame
	check(game.hud.object_type.get_global_rect().intersects(scroll.get_global_rect()), "object engineering control reachable with scrolling")
	var load_rect: Rect2 = game.hud.load_button.get_global_rect()
	scroll.scroll_vertical = 0
	await runner.process_frame
	check(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(load_rect) and game.hud.load_button.get_global_rect() == load_rect, "save/load controls remain fixed and reachable at 720p")
	scroll.scroll_vertical = 0
	DirAccess.remove_absolute(SAVE_PATH)
	reset_case()
