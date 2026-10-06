class_name Engineer
extends Node2D

signal changed

var grid: GridState
var cell := GameSettings.SPAWN
var destination := GameSettings.SPAWN
var selected := false
var route: Array[Vector2i] = []

func setup(state: GridState) -> void:
	grid = state
	reset()

func reset() -> void:
	cell = GameSettings.SPAWN
	destination = cell
	position = grid.center(cell)
	route.clear()
	selected = false
	queue_redraw()
	changed.emit()

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()
	changed.emit()

func state_text() -> String:
	return "Em movimento" if not route.is_empty() else "Parado"

func move_to(goal: Vector2i) -> String:
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

func _draw() -> void:
	if selected:
		draw_arc(Vector2.ZERO, 14, 0, TAU, 32, Color("64e6b6"), 2.0, true)
	draw_circle(Vector2.ZERO, 10, Color("e8b95c"))
	draw_rect(Rect2(-8, -8, 16, 6), Color("ffe2a0"))
	draw_line(Vector2(-4, 3), Vector2(4, 3), Color("513e28"), 2)
