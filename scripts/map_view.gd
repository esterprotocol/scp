class_name MapView
extends Node2D

var grid: GridState
var classd: ClassD
var engineer: Engineer
var construction: Construction
var selected_cell := Vector2i(-1, -1)
var preview_active := false
var preview_valid := false
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
			if grid.walls.has(cell):
				color = Color("647782")
			draw_rect(rect.grow(-1), color)
			var area_kind := grid.area_at(cell)
			if area_kind > 0:
				draw_rect(rect.grow(-2), Color(GridState.AREA_COLORS[area_kind], 0.23))
			if grid.doors.has(cell):
				var door_color := Color("70dcdb") if grid.doors[cell] else Color("cf83e9")
				draw_rect(rect.grow(-4), door_color, false, 3)
				if grid.doors[cell]:
					draw_line(rect.position + Vector2(5, 5), rect.position + Vector2(5, size - 5), door_color, 3)
				else:
					draw_line(rect.position + Vector2(5, size / 2.0), rect.position + Vector2(size - 5, size / 2.0), door_color, 3)
			if grid.objects.has(cell):
				var kind: int = grid.objects[cell]
				var object_rect := rect.grow(-5)
				var object_color: Color = GridState.OBJECT_COLORS[kind]
				draw_rect(object_rect, object_color)
				if kind == 1: # Bed and pillow.
					draw_rect(Rect2(object_rect.position + Vector2(2, 2), Vector2(object_rect.size.x - 4, 5)), Color("dfeaf8"))
				elif kind == 2: # Table top.
					draw_rect(object_rect.grow(-5), Color("754e39"), false, 2)
				elif kind == 3: # Seat back.
					draw_line(object_rect.position + Vector2(3, 3), object_rect.position + Vector2(object_rect.size.x - 3, 3), Color("4d6940"), 3)
				elif kind == 4: # Meal dispenser slot.
					draw_rect(Rect2(object_rect.position + Vector2(3, 8), Vector2(object_rect.size.x - 6, 5)), Color("713f49"))
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
		for cell: Vector2i in construction.object_blueprints:
			var rect := Rect2(Vector2(cell) * size, Vector2.ONE * size).grow(-4)
			var color: Color = GridState.OBJECT_COLORS[construction.object_blueprints[cell]]
			if construction.tasks.has(cell) and construction.tasks[cell].status == "Bloqueada":
				color = Color("f2867f")
			draw_rect(rect, Color(color, 0.14))
			draw_rect(rect, color, false, 2)
			draw_line(rect.position + Vector2(4, 4), rect.end - Vector2(4, 4), color, 2, true)
			draw_line(Vector2(rect.end.x - 4, rect.position.y + 4), Vector2(rect.position.x + 4, rect.end.y - 4), color, 2, true)
		for cell: Vector2i in construction.tasks:
			if construction.tasks[cell].action in [Construction.DEMOLISH, Construction.DEMOLISH_OBJECT, Construction.INSTALL_DOOR]:
				var color := Color("f2867f") if construction.tasks[cell].status == "Bloqueada" else (Color("ff994f") if construction.tasks[cell].action in [Construction.DEMOLISH, Construction.DEMOLISH_OBJECT] else Color("cf83e9"))
				draw_arc(grid.center(cell), 12, 0, TAU, 32, color, 2, true)
				if construction.tasks[cell].action in [Construction.DEMOLISH, Construction.DEMOLISH_OBJECT]:
					draw_line(grid.center(cell) - Vector2(8, 8), grid.center(cell) + Vector2(8, 8), color, 3, true)
				else:
					draw_line(grid.center(cell) - Vector2(8, 0), grid.center(cell) + Vector2(8, 0), color, 3, true)
	draw_rect(Rect2(grid.center(GameSettings.EXIT_CELL) - Vector2(7, 7), Vector2(14, 14)), Color("64e6b6"), false, 2)
	var last := engineer.position
	for cell in engineer.route:
		var next := grid.center(cell)
		draw_line(last, next, Color(0.39, 0.9, 0.71, 0.65), 2, true)
		last = next
	if not engineer.route.is_empty():
		draw_arc(grid.center(engineer.destination), 9, 0, TAU, 24, Color("64e6b6"), 2, true)
	if classd != null:
		last = classd.position
		for cell: Vector2i in classd.route:
			var next := grid.center(cell)
			draw_line(last, next, Color("ff9955"), 2, true)
			last = next
		if classd.state in [ClassD.MOVING, ClassD.USING]:
			draw_arc(grid.center(classd.destination), 11, 0, TAU, 24, Color("ff9955"), 2, true)
	if grid.contains(hovered):
		var color := Color("64e6b6") if (preview_valid if preview_active else grid.is_walkable(hovered)) else Color("f2867f")
		if preview_active:
			draw_rect(Rect2(Vector2(hovered) * size, Vector2.ONE * size).grow(-3), Color(color, 0.25))
		draw_rect(Rect2(Vector2(hovered) * size, Vector2.ONE * size).grow(-1), color, false, 2)
	if grid.contains(selected_cell):
		draw_rect(Rect2(Vector2(selected_cell) * size, Vector2.ONE * size).grow(-2), Color("ffffff"), false, 2)
	draw_rect(Rect2(Vector2.ZERO, Vector2(GameSettings.GRID_SIZE) * size), Color("526c7a"), false, 2)
