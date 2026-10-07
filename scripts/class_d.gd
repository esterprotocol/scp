class_name ClassD
extends Node2D

signal changed
signal occupation_changed

const ID := "classd-001"
const NAME := "Classe-D 001"
const NONE := Vector2i(-1, -1)
const IDLE := "Ocioso"
const MOVING := "Deslocando"
const USING := "Usando"
const BLOCKED := "Aguardando acesso"
const STOPPING := "Interrompendo deslocamento"

var grid: GridState
var engineer: Engineer
var cell := GameSettings.CLASSD_SPAWN
var destination := GameSettings.CLASSD_SPAWN
var route: Array[Vector2i] = []
var selected := false
var hunger := GameSettings.CLASSD_INITIAL_NEEDS
var rest := GameSettings.CLASSD_INITIAL_NEEDS
var state := IDLE
var need := ""
var reserved_object := NONE
var use_elapsed := 0.0
var use_initial := 0.0
var impediment := ""
var alerts: PackedStringArray = []
var dirty := true
var visual: CharacterVisual

func _ready() -> void:
	visual = CharacterVisual.new()
	visual.role = "classd"
	add_child(visual)
	visual.reset_pose(position)

func setup(state_grid: GridState, worker: Engineer) -> void:
	grid = state_grid
	engineer = worker
	grid.changed.connect(_on_grid_changed)
	grid.availability_changed.connect(func() -> void: dirty = true)
	engineer.changed.connect(func() -> void: dirty = true)
	reset()

func reset() -> void:
	grid.release_reservations(ID)
	cell = initial_cell(grid, engineer.cell)
	position = grid.center(cell)
	destination = cell
	route.clear()
	selected = false
	hunger = GameSettings.CLASSD_INITIAL_NEEDS
	rest = GameSettings.CLASSD_INITIAL_NEEDS
	state = IDLE
	need = ""
	reserved_object = NONE
	use_elapsed = 0.0
	use_initial = 0.0
	impediment = ""
	alerts.clear()
	dirty = true
	if visual != null:
		visual.reset_pose(position)
	queue_redraw()
	changed.emit()
	occupation_changed.emit()

static func initial_cell(state_grid: GridState, worker_cell: Vector2i) -> Vector2i:
	if state_grid.is_walkable(GameSettings.CLASSD_SPAWN) and GameSettings.CLASSD_SPAWN != worker_cell:
		return GameSettings.CLASSD_SPAWN
	for y in GameSettings.GRID_SIZE.y:
		for x in GameSettings.GRID_SIZE.x:
			var candidate := Vector2i(x, y)
			if state_grid.is_walkable(candidate) and candidate != worker_cell:
				return candidate
	return NONE

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()
	changed.emit()

func occupies(target: Vector2i) -> bool:
	return target == cell or target == grid.to_cell(position) or (not route.is_empty() and target == route[0])

func use_seconds() -> float:
	return GameSettings.CLASSD_MEAL_SECONDS if need == "Fome" else GameSettings.CLASSD_REST_SECONDS

func current_need() -> String:
	if not need.is_empty():
		return need
	if minf(hunger, rest) <= GameSettings.CLASSD_NEED_THRESHOLD:
		return "Fome" if hunger <= rest else "Descanso"
	return "Nenhuma urgente"

func _kind(which: String) -> int:
	return 4 if which == "Fome" else 1

func _alert(which: String) -> String:
	return NAME + (": sem distribuidor de refeições acessível." if which == "Fome" else ": sem cama acessível.")

func _choose(which: String) -> Dictionary:
	var best: Dictionary = {}
	var exists := false
	var available := false
	var free_point := false
	var closed_door := false
	# Diagnostics use a detached grid with only closed doors opened.
	var open_grid := GridState.new()
	open_grid.walls = grid.walls
	open_grid.objects = grid.objects
	open_grid.doors = grid.doors.duplicate()
	for door: Vector2i in open_grid.doors:
		open_grid.doors[door] = true
	for target: Vector2i in grid.objects:
		if grid.objects[target] != _kind(which):
			continue
		exists = true
		if not grid.object_available(target, ID):
			continue
		available = true
		for point: Vector2i in grid.interaction_cells(target):
			if engineer.occupies(point):
				continue
			free_point = true
			var path := GridNavigation.find_path(grid, cell, point)
			if not path.is_empty() and (best.is_empty() or path.size() < best.path.size()):
				best = {"object": target, "point": point, "path": path}
		for point: Vector2i in open_grid.interaction_cells(target):
			if not engineer.occupies(point) and not GridNavigation.find_path(open_grid, cell, point).is_empty():
				closed_door = true
	if not best.is_empty():
		return best
	var reason := "Rota bloqueada."
	if not exists:
		reason = "Objeto inexistente."
	elif not available:
		reason = "Objeto ocupado/reservado."
	elif closed_door:
		reason = "Porta fechada bloqueia o acesso."
	elif not free_point:
		reason = "Objeto sem ponto de interação livre."
	return {"reason": reason}

func _evaluate() -> void:
	dirty = false
	alerts.clear()
	var urgent: Array[String] = []
	if hunger <= GameSettings.CLASSD_NEED_THRESHOLD:
		urgent.append("Fome")
	if rest <= GameSettings.CLASSD_NEED_THRESHOLD:
		urgent.append("Descanso")
	if urgent.size() == 2 and rest < hunger:
		urgent.reverse()
	var choices: Dictionary = {}
	for which in urgent:
		choices[which] = _choose(which)
		if choices[which].has("reason"):
			alerts.append(_alert(which) + " " + choices[which].reason)
	if state in [MOVING, USING, STOPPING]:
		return
	impediment = ""
	need = "" if urgent.is_empty() else urgent[0]
	for which in urgent:
		var choice: Dictionary = choices[which]
		if choice.has("reason"):
			if impediment.is_empty():
				impediment = choice.reason
			continue
		if grid.reserve_object(choice.object, ID):
			need = which
			impediment = ""
			reserved_object = choice.object
			destination = choice.point
			route.assign(choice.path.slice(1))
			state = MOVING
			return
	state = IDLE if urgent.is_empty() else BLOCKED
	destination = cell

func _valid_action() -> bool:
	return grid.objects.get(reserved_object, 0) == _kind(need) and grid.reservations.get(reserved_object, "") == ID and grid.interaction_cells(reserved_object).has(destination) and not engineer.occupies(destination)

func cancel_action() -> void:
	grid.release_reservations(ID)
	reserved_object = NONE
	use_elapsed = 0.0
	use_initial = 0.0
	need = ""
	if not route.is_empty() and position != grid.center(cell):
		# Complete a safe segment or return along that same edge. Never snap.
		var anchor := route[0] if grid.is_walkable(route[0]) else cell
		route.clear()
		route.append(anchor)
		destination = route[0]
		state = STOPPING
	else:
		route.clear()
		destination = cell
		state = IDLE
	dirty = true
	occupation_changed.emit()
	changed.emit()

func _on_grid_changed() -> void:
	dirty = true
	if state not in [MOVING, USING]:
		return
	if not _valid_action():
		cancel_action()
		return
	for step: Vector2i in route:
		if not grid.is_walkable(step):
			cancel_action()
			return

func _process(delta: float) -> void:
	var previous_cell := cell
	var previous_next := cell if route.is_empty() else route[0]
	var had_hunger := hunger <= GameSettings.CLASSD_NEED_THRESHOLD
	var had_rest := rest <= GameSettings.CLASSD_NEED_THRESHOLD
	var seconds := maxf(delta, 0.0) * GameSettings.CLASSD_SIMULATION_SPEED
	if state != USING or need != "Fome":
		hunger = maxf(0.0, hunger - seconds * GameSettings.CLASSD_HUNGER_DECAY)
	if state != USING or need != "Descanso":
		rest = maxf(0.0, rest - seconds * GameSettings.CLASSD_REST_DECAY)
	if had_hunger != (hunger <= GameSettings.CLASSD_NEED_THRESHOLD) or had_rest != (rest <= GameSettings.CLASSD_NEED_THRESHOLD):
		dirty = true
	if state in [MOVING, USING] and not _valid_action():
		cancel_action()
	var urgent := minf(hunger, rest) <= GameSettings.CLASSD_NEED_THRESHOLD
	var lowest := "Fome" if hunger <= rest else "Descanso"
	if state == BLOCKED and urgent and need != lowest:
		dirty = true
	if dirty or (state == IDLE and urgent):
		_evaluate()
	if state == USING:
		use_elapsed = minf(use_seconds(), use_elapsed + seconds)
		var value := lerpf(use_initial, 100.0, use_elapsed / use_seconds())
		if need == "Fome":
			hunger = value
		else:
			rest = value
		dirty = true
		if use_elapsed >= use_seconds():
			cancel_action()
	elif state in [MOVING, STOPPING]:
		var budget := GameSettings.CLASSD_SPEED * seconds
		while not route.is_empty() and budget > 0.0:
			var point := grid.center(route[0])
			var distance := position.distance_to(point)
			if distance <= budget:
				position = point
				cell = route.pop_front()
				budget -= distance
			else:
				position = position.move_toward(point, budget)
				budget = 0.0
		if route.is_empty():
			if state == MOVING and cell == destination and position == grid.center(destination) and _valid_action():
				state = USING
				use_elapsed = 0.0
				use_initial = hunger if need == "Fome" else rest
			else:
				state = IDLE
				destination = cell
				dirty = true
	var next := cell if route.is_empty() else route[0]
	if previous_cell != cell or previous_next != next:
		occupation_changed.emit()
	if visual != null:
		var activity := "walk" if state in [MOVING, STOPPING] and not route.is_empty() else "idle"
		if state == USING:
			activity = "eat" if need == "Fome" else "rest"
		visual.tick(delta, position, activity)
	changed.emit()

func _draw() -> void:
	if selected:
		draw_arc(Vector2.ZERO, 15, 0, TAU, 32, Color("ff9955"), 2.0, true)
	if state == USING:
		draw_arc(Vector2.ZERO, 12, -PI / 2, -PI / 2 + TAU * use_elapsed / use_seconds(), 32, Color("a4d3ff"), 2.0, true)
