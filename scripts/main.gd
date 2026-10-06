extends Node2D

var grid := GridState.new()
var engineer := Engineer.new()
var map_view := MapView.new()
var camera := SiteCamera.new()
var hud := SiteHUD.new()

func _ready() -> void:
	map_view.grid = grid
	map_view.engineer = engineer
	add_child(map_view)
	engineer.setup(grid)
	add_child(engineer)
	add_child(camera)
	camera.reset()
	add_child(hud)
	hud.restart_requested.connect(reset_scenario)
	engineer.changed.connect(_on_engineer_changed)
	reset_scenario()

func reset_scenario() -> void:
	engineer.reset()
	camera.reset()
	hud.refresh(engineer)
	hud.show_message("Selecione o engenheiro dourado para dar uma ordem.")

func _on_engineer_changed() -> void:
	hud.refresh(engineer)
	if engineer.route.is_empty() and engineer.selected:
		hud.show_message("Engenheiro pronto. Clique direito para mover.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var point: Vector2 = get_canvas_transform().affine_inverse() * event.position
		if event.button_index == MOUSE_BUTTON_LEFT:
			engineer.set_selected(point.distance_to(engineer.position) <= 15.0)
			hud.show_message("Engenheiro selecionado. Clique direito para mover." if engineer.selected else "Selecione o engenheiro dourado para dar uma ordem.")
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if engineer.selected:
				hud.show_message(engineer.move_to(grid.to_cell(point)))
			else:
				hud.show_message("Selecione o engenheiro antes de dar uma ordem.")
