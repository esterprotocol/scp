extends Node2D

var grid := GridState.new()
var engineer := Engineer.new()
var classd := ClassD.new()
var map_view := MapView.new()
var camera := SiteCamera.new()
var hud := SiteHUD.new()
var construction := Construction.new()
var planning := false
var demolishing := false
var installing_door := false
var painting_area := false
var placing_object := false
var area_drag_active := false
var area_type := 1
var object_type := 1
var selected_cell := Vector2i(-1, -1)
var save_slot := SaveSlot.new()

func _ready() -> void:
	map_view.grid = grid
	map_view.engineer = engineer
	add_child(map_view)
	engineer.setup(grid)
	add_child(engineer)
	classd.setup(grid, engineer)
	add_child(classd)
	map_view.classd = classd
	construction.classd = classd
	construction.setup(grid, engineer)
	add_child(construction)
	map_view.construction = construction
	add_child(camera)
	camera.reset()
	add_child(hud)
	hud.restart_requested.connect(reset_scenario)
	hud.save_requested.connect(func() -> void: hud.show_message(save_slot.save_game(self)))
	hud.load_requested.connect(func() -> void: hud.show_message(save_slot.load_game(self)))
	hud.mode_requested.connect(set_planning)
	hud.demolish_requested.connect(set_demolishing)
	hud.door_requested.connect(set_door_mode)
	hud.area_requested.connect(set_area_mode)
	hud.area_type_requested.connect(func(kind: int) -> void: area_type = kind)
	hud.object_requested.connect(set_object_mode)
	hud.object_type_requested.connect(func(kind: int) -> void: object_type = kind)
	hud.toggle_door_requested.connect(toggle_selected_door)
	hud.authorize_requested.connect(func() -> void: hud.show_message(construction.authorize()))
	hud.cancel_active_requested.connect(func() -> void: hud.show_message(construction.cancel_active()))
	hud.cancel_all_requested.connect(func() -> void: hud.show_message(construction.cancel_all()))
	construction.changed.connect(_on_construction_changed)
	engineer.changed.connect(_on_engineer_changed)
	classd.changed.connect(_on_classd_changed)
	classd.occupation_changed.connect(func() -> void: construction.dirty = true)
	grid.changed.connect(_on_grid_changed)
	grid.availability_changed.connect(func() -> void: hud.refresh_cell(grid, selected_cell))
	reset_scenario()

func reset_scenario() -> void:
	construction.reset()
	grid.reset()
	engineer.reset()
	classd.reset()
	camera.reset()
	selected_cell = Vector2i(-1, -1)
	map_view.selected_cell = selected_cell
	area_type = 1
	object_type = 1
	area_drag_active = false
	hud.area_type.select(area_type)
	hud.object_type.select(object_type - 1)
	set_planning(false)
	hud.refresh_cell(grid, selected_cell)
	hud.refresh(engineer)
	hud.refresh_construction(construction)
	_on_classd_changed()
	hud.show_message("Selecione o engenheiro dourado para dar uma ordem.")

func _on_classd_changed() -> void:
	hud.refresh_population(classd)
	hud.refresh_selection(engineer, classd)
	classd.queue_redraw()

func _on_engineer_changed() -> void:
	hud.refresh_selection(engineer, classd)
	if engineer.route.is_empty() and engineer.selected and not engineer.construction_busy:
		hud.show_message("Engenheiro pronto. Clique direito para mover.")

func _on_construction_changed() -> void:
	hud.refresh_selection(engineer, classd)
	hud.refresh_construction(construction)

func _on_grid_changed() -> void:
	map_view.queue_redraw()
	hud.refresh_cell(grid, selected_cell)

func set_planning(value: bool) -> void:
	area_drag_active = false
	planning = value
	demolishing = false
	installing_door = false
	painting_area = false
	placing_object = false
	hud.set_planning(value)
	hud.show_message("Planejar: clique esquerdo marca; clique direito cancela blueprint/tarefa." if value else "Modo Selecionar: selecione o engenheiro para mover.")

func set_demolishing() -> void:
	area_drag_active = false
	planning = false
	demolishing = true
	installing_door = false
	painting_area = false
	placing_object = false
	hud.set_demolishing()
	hud.show_message("Demolir: clique esquerdo solicita; clique direito cancela a tarefa. A parede só desaparece ao concluir.")

func set_door_mode() -> void:
	area_drag_active = false
	planning = false
	demolishing = false
	installing_door = true
	painting_area = false
	placing_object = false
	hud.set_door_mode()
	hud.show_message("Porta: clique esquerdo solicita instalação em parede; direito cancela tarefa.")

func set_area_mode() -> void:
	area_drag_active = false
	planning = false
	demolishing = false
	installing_door = false
	painting_area = true
	placing_object = false
	hud.set_area_mode()
	hud.show_message("Área: selecione o tipo e pinte células transitáveis com o botão esquerdo.")

func set_object_mode() -> void:
	area_drag_active = false
	planning = false
	demolishing = false
	installing_door = false
	painting_area = false
	placing_object = true
	hud.set_object_mode()
	hud.show_message("Objeto: escolha o tipo, clique esquerdo planeja; direito cancela blueprint ou obra.")

func select_cell(cell: Vector2i) -> void:
	selected_cell = cell if grid.contains(cell) else Vector2i(-1, -1)
	map_view.selected_cell = selected_cell
	map_view.queue_redraw()
	hud.refresh_cell(grid, selected_cell)

func toggle_selected_door() -> void:
	if not grid.doors.has(selected_cell):
		hud.show_message("Selecione uma porta existente.")
		return
	var open: bool = grid.doors[selected_cell]
	if open and (engineer.occupies(selected_cell) or classd.occupies(selected_cell)):
		hud.show_message("Não é possível fechar: uma pessoa ocupa a porta.")
		return
	if grid.set_door_open(selected_cell, not open):
		hud.show_message("Porta fechada." if open else "Porta aberta.")
	else:
		hud.show_message("Não é possível fechar: último ponto de interação de um objeto.")

func paint_area(cell: Vector2i) -> void:
	if grid.set_area(cell, area_type):
		select_cell(cell)
		hud.show_message("Área %s definida." % GridState.AREA_NAMES[area_type])
	else:
		hud.show_message("Área exige uma célula transitável.")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		area_drag_active = false

func _unhandled_input(event: InputEvent) -> void:
	if painting_area and area_drag_active and event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var point: Vector2 = get_canvas_transform().affine_inverse() * event.position
		paint_area(grid.to_cell(point))
		return
	if event is InputEventMouseButton and event.pressed:
		var point: Vector2 = get_canvas_transform().affine_inverse() * event.position
		var cell := grid.to_cell(point)
		if placing_object:
			if event.button_index == MOUSE_BUTTON_LEFT:
				hud.show_message(construction.plan_object(cell, object_type))
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				hud.show_message(construction.cancel(cell))
			return
		if installing_door:
			if event.button_index == MOUSE_BUTTON_LEFT:
				hud.show_message(construction.request_door(cell))
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				hud.show_message(construction.cancel(cell))
			return
		if painting_area:
			if event.button_index == MOUSE_BUTTON_LEFT:
				area_drag_active = true
				paint_area(cell)
			return
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
			select_cell(cell)
			classd.set_selected(false)
			if point.distance_to(classd.position) <= 15.0 and point.distance_to(classd.position) < point.distance_to(engineer.position):
				engineer.set_selected(false)
				classd.set_selected(true)
				hud.show_message("Classe-D 001 selecionado. Necessidades atendidas automaticamente.")
			elif grid.doors.has(cell):
				engineer.set_selected(false)
				hud.show_message("Porta aberta. Use Fechar porta." if grid.doors[cell] else "Porta fechada. Use Abrir porta.")
			elif grid.objects.has(cell):
				engineer.set_selected(false)
				hud.show_message("%s selecionado. Pontos de interação no painel." % GridState.OBJECT_NAMES[grid.objects[cell]])
			else:
				engineer.set_selected(point.distance_to(engineer.position) <= 15.0)
				hud.show_message("Engenheiro selecionado. Clique direito para mover." if engineer.selected else "Célula selecionada.")
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if engineer.selected:
				hud.show_message(engineer.move_to(grid.to_cell(point)))
			else:
				hud.show_message("Selecione o engenheiro antes de dar uma ordem.")
