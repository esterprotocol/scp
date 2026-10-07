class_name Engineer
extends Node2D

signal changed

var grid: GridState
var cell := GameSettings.SPAWN
var destination := GameSettings.SPAWN
var selected := false
var construction_busy := false
var working := false
var work_action := "Construir"
var route: Array[Vector2i] = []
var visual: CharacterVisual

func _ready() -> void:
	visual = CharacterVisual.new()
	visual.role = "engineer"
	add_child(visual)
	visual.reset_pose(position)

func setup(state: GridState) -> void:
	grid = state
	grid.changed.connect(_on_grid_changed)
	reset()

func reset() -> void:
	cell = GameSettings.SPAWN
	destination = cell
	position = grid.center(cell)
	route.clear()
	selected = false
	construction_busy = false
	working = false
	work_action = "Construir"
	if visual != null:
		visual.reset_pose(position)
	queue_redraw()
	changed.emit()

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()
	changed.emit()

func state_text() -> String:
	if working:
		if work_action == "Instalar objeto":
			return "Instalando objeto"
		if work_action == "Demolir objeto":
			return "Demolindo objeto"
		if work_action == "Demolir":
			return "Demolindo parede/porta"
		if work_action == "Instalar porta":
			return "Instalando porta"
		return "Construindo parede"
	if construction_busy:
		return "Indo para obra"
	return "Em movimento" if not route.is_empty() else "Parado"

func move_to(goal: Vector2i) -> String:
	if construction_busy:
		return "Ordem recusada: engenheiro em obra. Cancele a tarefa para liberá-lo."
	return _set_destination(goal)

func move_for_task(goal: Vector2i) -> void:
	_set_destination(goal)

func occupies(target: Vector2i) -> bool:
	# Protect both ends of the segment, including the engineer's body while
	# crossing a cell boundary. Future cells in a route are not reservations.
	return target == cell or target == grid.to_cell(position) or (not route.is_empty() and target == route[0])

func stop_after_segment() -> void:
	if not route.is_empty() and position != grid.center(cell):
		route = [route[0]]
		destination = route[0]
	else:
		route.clear()
		destination = cell
	changed.emit()

func _on_grid_changed() -> void:
	for target in route:
		if not grid.is_walkable(target):
			# Drop the affected route without snapping the unit to a center.
			# Construction never places a wall on either occupied segment end.
			if not route.is_empty() and not grid.is_walkable(route[0]):
				route = [cell] if position != grid.center(cell) else []
			else:
				stop_after_segment()
			destination = cell if route.is_empty() else route[-1]
			changed.emit()
			return

func _set_destination(goal: Vector2i) -> String:
	if not grid.contains(goal):
		return "Destino inválido: fora do mapa."
	if not grid.is_walkable(goal):
		return "Destino inválido: há uma parede nessa célula."
	# Finish the current orthogonal segment before replanning. This prevents
	# diagonal shortcuts when a new order arrives between cell centers.
	var anchor := cell if route.is_empty() else route[0]
	var path := GridNavigation.find_path(grid, anchor, goal)
	if path.is_empty():
		return "Destino inacessível: não há caminho até essa célula."
	var next_route: Array[Vector2i] = []
	if not route.is_empty():
		next_route.append(anchor)
	next_route.append_array(path.slice(1))
	route = next_route
	destination = goal
	changed.emit()
	return "Destino alcançado." if route.is_empty() else "Ordem recebida. Engenheiro a caminho."

func _process(delta: float) -> void:
	var budget := GameSettings.ENGINEER_SPEED * delta
	while not route.is_empty() and budget > 0.0:
		var target := grid.center(route[0])
		var distance := position.distance_to(target)
		if distance <= budget:
			position = target
			cell = route.pop_front()
			budget -= distance
			changed.emit()
		else:
			position = position.move_toward(target, budget)
			budget = 0.0
	if visual != null:
		visual.tick(delta, position, "work" if working else ("walk" if not route.is_empty() else "idle"))

func _draw() -> void:
	if selected:
		draw_arc(Vector2.ZERO, 14, 0, TAU, 32, Color("64e6b6"), 2.0, true)
