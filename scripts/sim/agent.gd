class_name Agent
extends RefCounted

# Movement component shared by every person. Logical position is always a
# cell. A step claims the next cell before entering it and holds both cells
# until the step completes, so two people can never overlap and a route can be
# cancelled at any time without teleporting. Smooth motion is visual only.

signal moved(from_cell: Vector2i, to_cell: Vector2i)

const NONE := Vector2i(-1, -1)

var id := 0
var cell := NONE
var next_cell := NONE
var route: Array[Vector2i] = []
var destination := NONE
var blocked_reason := ""
var blocked_ticks := 0
var _step_left := 0

func stepping() -> bool:
	return next_cell != NONE

func occupies(target: Vector2i) -> bool:
	return target == cell or target == next_cell

func place(grid: GridState, reservations: Reservations, start: Vector2i) -> String:
	if not grid.is_walkable(start):
		return "Célula inicial não transitável."
	var claim := reservations.reserve_all(id, [Reservations.cell_key(start)])
	if not claim.ok:
		return "Célula inicial ocupada."
	cell = start
	next_cell = NONE
	route.clear()
	destination = start
	blocked_reason = ""
	blocked_ticks = 0
	_step_left = 0
	return ""

func remove(reservations: Reservations) -> void:
	reservations.release_owner(id)
	cell = NONE
	next_cell = NONE
	route.clear()

# Plans from where the agent will be once the current step finishes.
# Returns "" on success or a readable reason; the existing route is kept on failure.
func go_to(grid: GridState, goal: Vector2i) -> String:
	if not grid.contains(goal):
		return "Destino fora do mapa."
	if not grid.is_walkable(goal):
		return "Destino não transitável."
	var anchor := next_cell if stepping() else cell
	var path := GridNavigation.find_path(grid, anchor, goal)
	if path.is_empty():
		return "Destino inacessível."
	route.assign(path.slice(1))
	destination = goal
	blocked_reason = ""
	blocked_ticks = 0
	return ""

# Drops the route. A step in progress still completes: stopping is safe at
# every tick because the next cell is already claimed.
func cancel() -> void:
	route.clear()
	destination = next_cell if stepping() else cell
	blocked_reason = ""
	blocked_ticks = 0

func tick(grid: GridState, reservations: Reservations) -> void:
	if cell == NONE:
		return
	if stepping():
		_step_left -= 1
		if _step_left > 0:
			return
		var from := cell
		cell = next_cell
		next_cell = NONE
		reservations.release(id, Reservations.cell_key(from))
		moved.emit(from, cell)
	if route.is_empty():
		blocked_reason = ""
		blocked_ticks = 0
		return
	var target := route[0]
	var delta := target - cell
	if absi(delta.x) + absi(delta.y) != 1:
		route.clear()
		blocked_reason = "Rota inválida."
		return
	if not grid.is_walkable(target):
		_blocked("Rota bloqueada: célula não transitável.")
		return
	var claim := reservations.reserve_all(id, [Reservations.cell_key(target)])
	if not claim.ok:
		_blocked("Célula ocupada por outra pessoa.")
		return
	route.pop_front()
	next_cell = target
	_step_left = GameSettings.AGENT_STEP_TICKS
	blocked_reason = ""
	blocked_ticks = 0

func _blocked(reason: String) -> void:
	blocked_reason = reason
	blocked_ticks += 1

# Visual only. `alpha` is the clock's fractional progress inside the tick.
func visual_position(grid: GridState, alpha: float = 0.0) -> Vector2:
	if cell == NONE:
		return Vector2.ZERO
	if not stepping():
		return grid.center(cell)
	var done := float(GameSettings.AGENT_STEP_TICKS - _step_left) + clampf(alpha, 0.0, 1.0)
	var t := clampf(done / GameSettings.AGENT_STEP_TICKS, 0.0, 1.0)
	return grid.center(cell).lerp(grid.center(next_cell), t)
