class_name GridState
extends RefCounted

signal changed

var walls: Dictionary = {}
var doors: Dictionary = {} # Cell -> true when open, false when closed.
var areas: Dictionary = {} # Cell -> area type; absence means no area.
const AREA_NAMES := ["Sem área", "Alojamento", "Refeitório", "Contenção"]
const AREA_COLORS := [Color.TRANSPARENT, Color("809af0"), Color("83d79c"), Color("bb9de6")]

func _init() -> void:
	reset()

func reset() -> void:
	walls.clear()
	doors.clear()
	areas.clear()
	for y in range(3, 19):
		if y != 12:
			walls[Vector2i(10, y)] = true
	for x in range(14, 18):
		walls[Vector2i(x, 7)] = true
	# A sealed room: (19, 19) is floor, but cannot be reached.
	for x in range(18, 22):
		for y in range(18, 22):
			if x == 18 or x == 21 or y == 18 or y == 21:
				walls[Vector2i(x, y)] = true
	changed.emit()

func add_wall(cell: Vector2i) -> bool:
	if not is_walkable(cell) or doors.has(cell):
		return false
	walls[cell] = true
	changed.emit()
	return true

func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GameSettings.GRID_SIZE.x and cell.y < GameSettings.GRID_SIZE.y

func remove_wall(cell: Vector2i) -> bool:
	if not contains(cell) or not walls.has(cell):
		return false
	walls.erase(cell)
	changed.emit()
	return true

func install_door(cell: Vector2i) -> bool:
	if not walls.has(cell):
		return false
	walls.erase(cell)
	doors[cell] = false
	changed.emit()
	return true

func set_door_open(cell: Vector2i, open: bool) -> bool:
	if not doors.has(cell) or doors[cell] == open:
		return false
	doors[cell] = open
	changed.emit()
	return true

func remove_door(cell: Vector2i) -> bool:
	if not doors.has(cell):
		return false
	doors.erase(cell)
	changed.emit()
	return true

func set_area(cell: Vector2i, kind: int) -> bool:
	if not contains(cell) or not is_walkable(cell) or kind < 0 or kind >= AREA_NAMES.size():
		return false
	if area_at(cell) == kind:
		return true
	if kind == 0:
		areas.erase(cell)
	else:
		areas[cell] = kind
	changed.emit()
	return true

func area_at(cell: Vector2i) -> int:
	return int(areas.get(cell, 0))

func is_walkable(cell: Vector2i) -> bool:
	return contains(cell) and not walls.has(cell) and (not doors.has(cell) or doors[cell])

func to_cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / GameSettings.CELL_SIZE), floori(point.y / GameSettings.CELL_SIZE))

func center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * GameSettings.CELL_SIZE
