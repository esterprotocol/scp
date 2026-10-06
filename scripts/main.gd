extends Node2D

var grid := GridState.new()
var engineer := Engineer.new()
var map_view := MapView.new()
var camera := SiteCamera.new()
var hud := SiteHUD.new()
var construction := Construction.new()
var planning := false
var demolishing := false

func _ready() -> void:
	map_view.grid = grid
	map_view.engineer = engineer
	add_child(map_view)
	engineer.setup(grid)
	add_child(engineer)
	construction.setup(grid, engineer)
	add_child(construction)
	map_view.construction = construction
	add_child(camera)
	camera.reset()
	add_child(hud)
	hud.restart_requested.connect(reset_scenario)
	hud.mode_requested.connect(set_planning)
	hud.demolish_requested.connect(set_demolishing)
	hud.authorize_requested.connect(func() -> void: hud.show_message(construction.authorize()))
	hud.cancel_active_requested.connect(func() -> void: hud.show_message(construction.cancel_active()))
	hud.cancel_all_requested.connect(func() -> void: hud.show_message(construction.cancel_all()))
	construction.changed.connect(_on_construction_changed)
	engineer.changed.connect(_on_engineer_changed)
	reset_scenario()

func reset_scenario() -> void:
	construction.reset()
	grid.reset()
	engineer.reset()
	camera.reset()
	set_planning(false)
	hud.refresh(engineer)
	hud.refresh_construction(construction)
	hud.show_message("Selecione o engenheiro dourado para dar uma ordem.")

func _on_engineer_changed() -> void:
	hud.refresh(engineer)
	if engineer.route.is_empty() and engineer.selected and not engineer.construction_busy:
		hud.show_message("Engenheiro pronto. Clique direito para mover.")

func _on_construction_changed() -> void:
	hud.refresh(engineer)
	hud.refresh_construction(construction)

func set_planning(value: bool) -> void:
	planning = value
	demolishing = false
	hud.set_planning(value)
	hud.show_message("Planejar: clique esquerdo marca; clique direito cancela blueprint/tarefa." if value else "Modo Selecionar: selecione o engenheiro para mover.")

func set_demolishing() -> void:
	planning = false
	demolishing = true
	hud.set_demolishing()
	hud.show_message("Demolir: clique esquerdo solicita; clique direito cancela a tarefa. A parede só desaparece ao concluir.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var point: Vector2 = get_canvas_transform().affine_inverse() * event.position
		if demolishing:
			if event.button_index == MOUSE_BUTTON_LEFT:
				hud.show_message(construction.request_demolition(grid.to_cell(point)))
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				hud.show_message(construction.cancel(grid.to_cell(point)))
			return
		if planning:
			if event.button_index == MOUSE_BUTTON_LEFT:
				hud.show_message(construction.plan(grid.to_cell(point)))
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				hud.show_message(construction.cancel(grid.to_cell(point)))
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			engineer.set_selected(point.distance_to(engineer.position) <= 15.0)
			hud.show_message("Engenheiro selecionado. Clique direito para mover." if engineer.selected else "Selecione o engenheiro dourado para dar uma ordem.")
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if engineer.selected:
				hud.show_message(engineer.move_to(grid.to_cell(point)))
			else:
				hud.show_message("Selecione o engenheiro antes de dar uma ordem.")
