class_name GridState
extends RefCounted

var walls: Dictionary = {}

func _init() -> void:
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

func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GameSettings.GRID_SIZE.x and cell.y < GameSettings.GRID_SIZE.y

func is_walkable(cell: Vector2i) -> bool:
	return contains(cell) and not walls.has(cell)

func to_cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / GameSettings.CELL_SIZE), floori(point.y / GameSettings.CELL_SIZE))

func center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * GameSettings.CELL_SIZE
