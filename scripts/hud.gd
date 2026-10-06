class_name SiteHUD
extends CanvasLayer

signal restart_requested
signal save_requested
signal load_requested
signal mode_requested(planning: bool)
signal demolish_requested
signal door_requested
signal area_requested
signal area_type_requested(kind: int)
signal toggle_door_requested
signal object_requested
signal object_type_requested(kind: int)
signal authorize_requested
signal cancel_active_requested
signal cancel_all_requested

var population_label: Label
var alerts_label: Label
var selection_label: Label
var state_label: Label
var destination_label: Label
var message_label: Label
var restart_button: Button
var save_button: Button
var load_button: Button
var select_button: Button
var plan_button: Button
var demolish_button: Button
var door_button: Button
var area_button: Button
var object_button: Button
var object_type: OptionButton
var area_type: OptionButton
var toggle_door_button: Button
var cell_label: Label
var authorize_button: Button
var cancel_active_button: Button
var cancel_all_button: Button
var task_label: Label
var progress_bar: ProgressBar
var blocked_label: Label
var queue_label: Label

func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(256, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("10212e")
	style.border_color = Color("365365")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	# Keep every action reachable even when blocked reasons grow or the window
	# is small. A fixed-height scroll area avoids pushing reset below the screen.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(238, 800)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	var title := add_label(box, "SITE DIRECTOR")
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("64e6b6"))
	add_label(box, "POPULAÇÃO · 1 Classe-D")
	population_label = add_label(box, "")
	population_label.custom_minimum_size.x = 220
	population_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	population_label.add_theme_color_override("font_color", Color("ffb780"))
	alerts_label = add_label(box, "Alertas: nenhum")
	alerts_label.custom_minimum_size.x = 220
	alerts_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alerts_label.add_theme_color_override("font_color", Color("f2867f"))
	box.add_child(HSeparator.new())
	add_label(box, "ENGENHARIA")
	select_button = add_button(box, "Selecionar", func() -> void: mode_requested.emit(false))
	plan_button = add_button(box, "Planejar parede", func() -> void: mode_requested.emit(true))
	demolish_button = add_button(box, "Demolir", func() -> void: demolish_requested.emit())
	door_button = add_button(box, "Porta", func() -> void: door_requested.emit())
	area_button = add_button(box, "Área", func() -> void: area_requested.emit())
	object_button = add_button(box, "Objeto", func() -> void: object_requested.emit())
	select_button.toggle_mode = true
	plan_button.toggle_mode = true
	demolish_button.toggle_mode = true
	door_button.toggle_mode = true
	area_button.toggle_mode = true
	object_button.toggle_mode = true
	area_type = OptionButton.new()
	for index in GridState.AREA_NAMES.size():
		area_type.add_item(GridState.AREA_NAMES[index], index)
	area_type.item_selected.connect(func(index: int) -> void: area_type_requested.emit(index))
	box.add_child(area_type)
	object_type = OptionButton.new()
	for kind in range(1, GridState.OBJECT_NAMES.size()):
		object_type.add_item(GridState.OBJECT_NAMES[kind], kind)
	object_type.item_selected.connect(func(index: int) -> void: object_type_requested.emit(index + 1))
	box.add_child(object_type)
	box.add_child(HSeparator.new())
	selection_label = add_label(box, "")
	cell_label = add_label(box, "Célula: nenhuma")
	cell_label.custom_minimum_size.x = 220
	cell_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toggle_door_button = add_button(box, "Abrir/fechar porta", func() -> void: toggle_door_requested.emit())
	toggle_door_button.disabled = true
	state_label = add_label(box, "")
	destination_label = add_label(box, "")
	task_label = add_label(box, "Tarefa atual: nenhuma")
	task_label.custom_minimum_size.x = 220
	task_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 22
	box.add_child(progress_bar)
	queue_label = add_label(box, "")
	blocked_label = add_label(box, "")
	blocked_label.custom_minimum_size.x = 220
	blocked_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blocked_label.add_theme_color_override("font_color", Color("f2867f"))
	message_label = add_label(box, "")
	message_label.custom_minimum_size = Vector2(220, 66)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_color_override("font_color", Color("e8b95c"))
	authorize_button = add_button(box, "Autorizar planejados", func() -> void: authorize_requested.emit())
	cancel_active_button = add_button(box, "Cancelar tarefa atual", func() -> void: cancel_active_requested.emit())
	cancel_all_button = add_button(box, "Cancelar todas as obras", func() -> void: cancel_all_requested.emit())
	restart_button = Button.new()
	restart_button.text = "Reiniciar cenário"
	restart_button.custom_minimum_size.y = 40
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	box.add_child(restart_button)
	var save_row := HBoxContainer.new()
	box.add_child(save_row)
	save_button = add_button(save_row, "Salvar", func() -> void: save_requested.emit())
	load_button = add_button(save_row, "Carregar", func() -> void: load_requested.emit())
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(HSeparator.new())
	var controls_label := add_label(box, "CONTROLES\nSelecionar: esquerdo escolhe pessoa, porta ou objeto; direito move.\nPlanejar/Objeto: esquerdo marca; direito cancela obra.\nDemolir/Porta: esquerdo solicita; direito cancela tarefa.\nÁrea: escolha tipo e pinte com esquerdo.\nWASD / setas: câmera\nBotão central: arrastar\nRoda do mouse: zoom\n\nAzul: blueprint de parede\nContorno colorido cruzado: blueprint de objeto\nForma sólida: objeto instalado\nDourado: construção autorizada\nLaranja: demolição solicitada\nRoxo: porta/instalação\nVermelho: tarefa bloqueada\nCinza: parede concluída\nVerde: referência de saída\n\n24 × 24 · célula 32 px\nCoordenadas de 0 a 23")
	controls_label.custom_minimum_size.x = 220
	controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	get_viewport().size_changed.connect(func() -> void: scroll.custom_minimum_size.y = maxf(160.0, get_viewport().get_visible_rect().size.y - 68.0))
	scroll.custom_minimum_size.y = maxf(160.0, get_viewport().get_visible_rect().size.y - 68.0)

func add_button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 32
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func set_planning(value: bool) -> void:
	select_button.set_pressed_no_signal(not value)
	plan_button.set_pressed_no_signal(value)
	demolish_button.set_pressed_no_signal(false)
	door_button.set_pressed_no_signal(false)
	area_button.set_pressed_no_signal(false)
	object_button.set_pressed_no_signal(false)

func set_demolishing() -> void:
	select_button.set_pressed_no_signal(false)
	plan_button.set_pressed_no_signal(false)
	demolish_button.set_pressed_no_signal(true)
	door_button.set_pressed_no_signal(false)
	area_button.set_pressed_no_signal(false)
	object_button.set_pressed_no_signal(false)

func set_door_mode() -> void:
	set_planning(false)
	select_button.set_pressed_no_signal(false)
	door_button.set_pressed_no_signal(true)

func set_area_mode() -> void:
	set_planning(false)
	select_button.set_pressed_no_signal(false)
	area_button.set_pressed_no_signal(true)

func set_object_mode() -> void:
	set_planning(false)
	select_button.set_pressed_no_signal(false)
	object_button.set_pressed_no_signal(true)

func refresh_cell(grid: GridState, cell: Vector2i) -> void:
	if not grid.contains(cell):
		cell_label.text = "Célula: nenhuma"
		toggle_door_button.disabled = true
		return
	var description: String = GridState.OBJECT_NAMES[grid.objects[cell]] if grid.objects.has(cell) else ("Porta aberta" if grid.doors.get(cell, false) else "Porta fechada" if grid.doors.has(cell) else "Parede" if grid.walls.has(cell) else "Piso")
	cell_label.text = "Célula (%d, %d): %s\nÁrea: %s" % [cell.x, cell.y, description, GridState.AREA_NAMES[grid.area_at(cell)]]
	if grid.objects.has(cell):
		var points: PackedStringArray = []
		for neighbor: Vector2i in grid.interaction_cells(cell):
			points.append("(%d, %d)" % [neighbor.x, neighbor.y])
		cell_label.text += "\nInteração: " + (", ".join(points) if not points.is_empty() else "nenhuma")
		if grid.reservations.has(cell):
			cell_label.text += "\nReserva: " + str(grid.reservations[cell])
	toggle_door_button.disabled = not grid.doors.has(cell)
	toggle_door_button.text = "Fechar porta" if grid.doors.get(cell, false) else "Abrir porta"

func refresh_construction(construction: Construction) -> void:
	var active := construction.active
	var title: String = "" if active == Construction.NONE else construction.tasks[active].action
	if active != Construction.NONE and construction.tasks[active].action in [Construction.BUILD_OBJECT, Construction.DEMOLISH_OBJECT]:
		title += " " + GridState.OBJECT_NAMES[construction.tasks[active].object_type]
	task_label.text = "Tarefa atual: nenhuma" if active == Construction.NONE else "%s (%d, %d)\n%s" % [title, active.x, active.y, construction.tasks[active].status]
	progress_bar.value = construction.progress() * 100.0
	queue_label.text = "Blueprints: %d · Tarefas: %d" % [construction.blueprints.size() + construction.object_blueprints.size(), construction.tasks.size()]
	blocked_label.text = construction.blocked_text()
	blocked_label.add_theme_color_override("font_color", Color("f2867f") if blocked_label.text != "Nenhum bloqueio." else Color("b4c3cc"))

func add_label(parent: Node, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	parent.add_child(label)
	return label

func refresh(engineer: Engineer) -> void:
	selection_label.text = "Selecionado: " + ("Engenheiro 01" if engineer.selected else "nenhum")
	state_label.text = "Estado: " + engineer.state_text()
	destination_label.text = "Destino: (%d, %d)" % [engineer.destination.x, engineer.destination.y]

func show_message(text: String) -> void:
	message_label.text = text

func refresh_population(person: ClassD) -> void:
	population_label.text = "%s%s\nEstado: %s\nDestino: (%d, %d)\nFome: %.1f / 100\nDescanso: %.1f / 100\nNecessidade: %s\nImpedimento: %s" % [ClassD.NAME, " · selecionado" if person.selected else "", person.state, person.destination.x, person.destination.y, person.hunger, person.rest, person.current_need(), person.impediment if not person.impediment.is_empty() else "nenhum"]
	if person.state == ClassD.USING:
		population_label.text += "\nUso: %.1f / %.1f s" % [person.use_elapsed, person.use_seconds()]
	alerts_label.text = "Alertas: nenhum" if person.alerts.is_empty() else "ALERTAS\n" + "\n".join(person.alerts)

func refresh_selection(worker: Engineer, person: ClassD) -> void:
	if person.selected:
		selection_label.text = "Selecionado: " + ClassD.NAME
		state_label.text = "Estado: " + person.state
		destination_label.text = "Destino: (%d, %d)" % [person.destination.x, person.destination.y]
	else:
		refresh(worker)
