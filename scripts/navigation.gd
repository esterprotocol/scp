class_name GridNavigation
extends RefCounted

const DIRECTIONS := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

# Breadth-first search is sufficient for 576 equally weighted cells.
# A successful route includes the starting cell; [] means no route.
static func find_path(grid: GridState, start: Vector2i, goal: Vector2i, blocked_cell: Vector2i = Vector2i(-1, -1)) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if start == blocked_cell or goal == blocked_cell or not grid.is_walkable(start) or not grid.is_walkable(goal):
		return path
	var frontier: Array[Vector2i] = [start]
	var previous: Dictionary = {start: start}
	var index := 0
	while index < frontier.size():
		var current := frontier[index]
		index += 1
		if current == goal:
			path.append(current)
			while current != start:
				current = previous[current]
				path.append(current)
			path.reverse()
			return path
		for direction: Vector2i in DIRECTIONS:
			var neighbor := current + direction
			if neighbor != blocked_cell and grid.is_walkable(neighbor) and not previous.has(neighbor):
				previous[neighbor] = current
				frontier.append(neighbor)
	return path
