class_name MapView
extends Node2D

var grid: GridState
var engineer: Engineer
var construction: Construction
var hovered := Vector2i(-1, -1)

func _process(_delta: float) -> void:
	hovered = grid.to_cell(get_global_mouse_position())
	queue_redraw()

func _draw() -> void:
	if grid == null:
		return
	var size := GameSettings.CELL_SIZE
	for y in GameSettings.GRID_SIZE.y:
		for x in GameSettings.GRID_SIZE.x:
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell) * size, Vector2.ONE * size)
			var color := Color("172c37") if (x + y) % 2 == 0 else Color("1a303c")
			if not grid.is_walkable(cell):
				color = Color("647782")
			draw_rect(rect.grow(-1), color)
	if construction != null:
		for cell: Vector2i in construction.blueprints:
			var rect := Rect2(Vector2(cell) * size, Vector2.ONE * size).grow(-4)
			var color := Color("62b9ef")
			if construction.tasks.has(cell):
				color = Color("f2867f") if construction.tasks[cell].status == "Bloqueada" else Color("e8b95c")
			draw_rect(rect, Color(color, 0.18))
			draw_rect(rect, color, false, 2)
			draw_line(rect.position, rect.end, color, 1, true)
			draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), color, 1, true)
		for cell: Vector2i in construction.tasks:
			if construction.tasks[cell].action == Construction.DEMOLISH:
				var color := Color("f2867f") if construction.tasks[cell].status == "Bloqueada" else Color("ff994f")
				draw_arc(grid.center(cell), 12, 0, TAU, 32, color, 2, true)
				draw_line(grid.center(cell) - Vector2(8, 8), grid.center(cell) + Vector2(8, 8), color, 3, true)
	draw_rect(Rect2(grid.center(GameSettings.EXIT_CELL) - Vector2(7, 7), Vector2(14, 14)), Color("64e6b6"), false, 2)
	var last := engineer.position
	for cell in engineer.route:
		var next := grid.center(cell)
		draw_line(last, next, Color(0.39, 0.9, 0.71, 0.65), 2, true)
		last = next
	if not engineer.route.is_empty():
		draw_arc(grid.center(engineer.destination), 9, 0, TAU, 24, Color("64e6b6"), 2, true)
	if grid.contains(hovered):
		var color := Color("64e6b6") if grid.is_walkable(hovered) else Color("f2867f")
		draw_rect(Rect2(Vector2(hovered) * size, Vector2.ONE * size).grow(-1), color, false, 2)
	draw_rect(Rect2(Vector2.ZERO, Vector2(GameSettings.GRID_SIZE) * size), Color("526c7a"), false, 2)
