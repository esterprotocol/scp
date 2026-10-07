class_name SiteHUD
extends CanvasLayer

signal move_requested
signal inspect_demolish_requested
signal inspect_cancel_requested
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
signal speed_requested(speed: float)

var move_button: Button
var move_reason: Label
var inspect_demolish_button: Button
var inspect_cancel_button: Button
var preview_label: Label
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
var mode_label: Label
var availability_label: Label
var pause_button: Button
var normal_button: Button
var fast_button: Button
var help_label: Label
var inspection_panel: PanelContainer
var inspection_scroll: ScrollContainer
var session_controls: PanelContainer
var message_card: PanelContainer
var area_heading: Label
var object_heading: Label
var shared_theme: Theme
var current_speed := 1.0

func _ready() -> void:
	shared_theme = SiteUITheme.shared()
	var panel_root := PanelContainer.new()
	panel_root.theme = shared_theme
	panel_root.position = Vector2(12, 12)
	panel_root.custom_minimum_size.x = 322
	panel_root.add_theme_stylebox_override("panel", SiteUITheme.panel(SiteUITheme.BG, SiteUITheme.BORDER, 3, 10))
	add_child(panel_root)
	# The first child stays the scroll area so existing UI automation can reach it.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 300
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel_root.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", SiteUITheme.SPACING)
	scroll.add_child(box)
	add_label(box, "DIRETORIA DE CONTENÇÃO  /  SD", 11, SiteUITheme.MUTED)
	var title := add_label(box, "SITE DIRECTOR", 24, SiteUITheme.TEXT)
	title.add_theme_color_override("font_color", SiteUITheme.TEXT)
	add_label(box, "CONTROLE DA INSTALAÇÃO", 10, SiteUITheme.MUTED)
	var status := card(box, "01  /  CONTROLE OPERACIONAL")
	mode_label = add_label(status, "MODO / SELECIONAR", 12, SiteUITheme.ACCENT)
	message_card = PanelContainer.new()
	message_card.add_theme_stylebox_override("panel", SiteUITheme.panel(SiteUITheme.BG, SiteUITheme.BORDER, 2, 8))
	status.add_child(message_card)
	message_label = add_label(message_card, "", 13, SiteUITheme.TEXT)
	message_label.custom_minimum_size.y = 42
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_label = add_label(status, "", 12, SiteUITheme.ACCENT)
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var tool_card := card(box, "02  /  FERRAMENTAS")
	var tools := GridContainer.new()
	tools.columns = 2
	tools.add_theme_constant_override("h_separation", 5)
	tools.add_theme_constant_override("v_separation", 5)
	tool_card.add_child(tools)
	select_button = tool(tools, "Selecionar", func() -> void: mode_requested.emit(false))
	plan_button = tool(tools, "Parede", func() -> void: mode_requested.emit(true))
	demolish_button = tool(tools, "Demolir", func() -> void: demolish_requested.emit())
	door_button = tool(tools, "Porta", func() -> void: door_requested.emit())
	area_button = tool(tools, "Área", func() -> void: area_requested.emit())
	object_button = tool(tools, "Objeto", func() -> void: object_requested.emit())
	area_heading = add_label(tool_card, "DESIGNAÇÃO DE ÁREA", 11, SiteUITheme.MUTED)
	area_type = OptionButton.new()
	for index in GridState.AREA_NAMES.size():
		area_type.add_item(GridState.AREA_NAMES[index], index)
	area_type.item_selected.connect(func(index: int) -> void: area_type_requested.emit(index))
	style_button(area_type)
	tool_card.add_child(area_type)
	object_heading = add_label(tool_card, "OBJETO A INSTALAR", 11, SiteUITheme.MUTED)
	object_type = OptionButton.new()
	for kind in range(1, GridState.OBJECT_NAMES.size()):
		object_type.add_item(GridState.OBJECT_NAMES[kind], kind)
	object_type.item_selected.connect(func(index: int) -> void:
		object_type_requested.emit(index + 1)
		refresh_availability(index + 1))
	style_button(object_type)
	tool_card.add_child(object_type)
	availability_label = add_label(tool_card, "", 12, SiteUITheme.MUTED)
	availability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	refresh_availability(1)
	var work := card(box, "03  /  OBRAS E AUTORIZAÇÕES", SiteUITheme.CONSTRUCTION)
	task_label = add_label(work, "Tarefa atual: nenhuma", 13)
	task_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 18
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", SiteUITheme.button(SiteUITheme.SURFACE))
	progress_bar.add_theme_stylebox_override("fill", SiteUITheme.button(SiteUITheme.CONSTRUCTION, SiteUITheme.CONSTRUCTION))
	work.add_child(progress_bar)
	queue_label = add_label(work, "", 12, SiteUITheme.MUTED)
	blocked_label = add_label(work, "", 12, SiteUITheme.DANGER)
	blocked_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	authorize_button = add_button(work, "Autorizar planejados", func() -> void: authorize_requested.emit(), SiteUITheme.ACCENT)
	cancel_active_button = add_button(work, "Cancelar tarefa atual", func() -> void: cancel_active_requested.emit())
	cancel_all_button = add_button(work, "Cancelar todas as obras", func() -> void: cancel_all_requested.emit())
	session_controls = PanelContainer.new()
	session_controls.theme = shared_theme
	session_controls.custom_minimum_size.x = 322
	session_controls.add_theme_stylebox_override("panel", SiteUITheme.panel(SiteUITheme.BG, SiteUITheme.BORDER, 3, 6))
	add_child(session_controls)
	var session_box := VBoxContainer.new()
	session_box.add_theme_constant_override("separation", 4)
	session_controls.add_child(session_box)
	var archive := card(box, "04  /  SESSÃO")
	var time_row := HBoxContainer.new()
	time_row.add_theme_constant_override("separation", 5)
	session_box.add_child(time_row)
	pause_button = add_button(time_row, "|| Pausa", func() -> void: speed_requested.emit(0.0))
	normal_button = add_button(time_row, "1×", func() -> void: speed_requested.emit(1.0))
	fast_button = add_button(time_row, "2×", func() -> void: speed_requested.emit(2.0))
	for button: Button in [pause_button, normal_button, fast_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_speed(1.0)
	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 5)
	session_box.add_child(save_row)
	save_button = add_button(save_row, "Salvar", func() -> void: save_requested.emit())
	load_button = add_button(save_row, "Carregar", func() -> void: load_requested.emit())
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart_button = add_button(archive, "Reiniciar cenário", func() -> void: restart_requested.emit(), SiteUITheme.WARNING)
	var help_button := add_button(archive, "Controles e legenda  ▾", func() -> void:
		help_label.visible = not help_label.visible)
	help_button.tooltip_text = "Mostrar ou ocultar os controles e a legenda do mapa."
	help_label = add_label(archive, "ESQUERDO  Seleciona ou aplica ferramenta\nDIREITO  Move ou cancela obra\nESC  Selecionar e limpar seleção\nWASD / SETAS  Deslocar câmera\nCENTRAL  Arrastar câmera\nRODA  Zoom\n\nAZUL  Blueprint\nDOURADO  Obra autorizada\nLARANJA  Demolição\nROXO  Porta\nVERMELHO  Bloqueio\nVERDE  Saída de referência", 12, SiteUITheme.MUTED)
	help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_label.visible = false
	inspection_panel = PanelContainer.new()
	inspection_panel.theme = shared_theme
	inspection_panel.add_theme_stylebox_override("panel", SiteUITheme.panel(SiteUITheme.BG, SiteUITheme.BORDER, 3, 10))
	add_child(inspection_panel)
	inspection_scroll = ScrollContainer.new()
	inspection_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inspection_scroll.custom_minimum_size = Vector2(192, 480)
	inspection_panel.add_child(inspection_scroll)
	var inspection := VBoxContainer.new()
	inspection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspection.add_theme_constant_override("separation", SiteUITheme.SPACING)
	inspection_scroll.add_child(inspection)
	add_label(inspection, "REGISTRO DA INSTALAÇÃO", 11, SiteUITheme.MUTED)
	var cell_card := card(inspection, "ALVO / CÉLULA")
	cell_label = add_label(cell_card, "Célula: nenhuma", 13)
	cell_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toggle_door_button = add_button(cell_card, "Abrir/fechar porta", func() -> void: toggle_door_requested.emit())
	toggle_door_button.disabled = true
	inspect_demolish_button = add_button(cell_card, "Demolir alvo", func() -> void: inspect_demolish_requested.emit())
	inspect_cancel_button = add_button(cell_card, "Cancelar obra do alvo", func() -> void: inspect_cancel_requested.emit())
	var npc_card := card(inspection, "PESSOAL / SELEÇÃO", SiteUITheme.ACCENT)
	selection_label = add_label(npc_card, "Selecionado: nenhum", 13)
	move_button = add_button(npc_card, "Mover · destino", func() -> void: move_requested.emit(), SiteUITheme.ACCENT)
	move_button.toggle_mode = true
	move_reason = add_label(npc_card, "", 12, SiteUITheme.MUTED)
	move_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	state_label = add_label(npc_card, "", 13)
	state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	destination_label = add_label(npc_card, "", 13)
	var population_card := card(inspection, "CLASSE-D / CONDIÇÃO")
	population_label = add_label(population_card, "", 12, SiteUITheme.TEXT)
	population_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alerts_label = add_label(population_card, "Alertas: nenhum", 12, SiteUITheme.DANGER)
	alerts_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	get_viewport().size_changed.connect(func() -> void: resize_scroll(scroll))
	resize_scroll(scroll)

func resize_scroll(scroll: ScrollContainer) -> void:
	scroll.custom_minimum_size.y = maxf(160.0, get_viewport().get_visible_rect().size.y - 128.0)
	session_controls.position = Vector2(12, get_viewport().get_visible_rect().size.y - 86)
	var width := get_viewport().get_visible_rect().size.x
	inspection_panel.custom_minimum_size.x = 218.0 if width <= 1280.0 else 260.0
	inspection_scroll.custom_minimum_size.x = inspection_panel.custom_minimum_size.x - 24.0
	inspection_scroll.custom_minimum_size.y = maxf(160.0, get_viewport().get_visible_rect().size.y - 46.0)
	inspection_panel.position = Vector2(width - inspection_panel.custom_minimum_size.x - 12.0, 12.0)

func section(parent: Node, title: String) -> void:
	var heading := add_label(parent, title, 11, SiteUITheme.BLUE)
	heading.add_theme_constant_override("line_spacing", 2)

func add_label(parent: Node, value: String, size: int = 13, color: Color = SiteUITheme.TEXT) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func style_button(button: BaseButton) -> void:
	button.custom_minimum_size.y = 32
	button.theme = shared_theme

func add_button(parent: Node, value: String, action: Callable, accent: Color = SiteUITheme.TEXT) -> Button:
	var button := Button.new()
	button.text = value
	style_button(button)
	button.add_theme_color_override("font_color", accent)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func tool(parent: Node, value: String, action: Callable) -> Button:
	var button := add_button(parent, value, action)
	button.toggle_mode = true
	button.custom_minimum_size.x = 127
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button

func set_speed(value: float) -> void:
	current_speed = value
	pause_button.set_pressed_no_signal(value == 0.0)
	normal_button.set_pressed_no_signal(value == 1.0)
	fast_button.set_pressed_no_signal(value == 2.0)
	for button: Button in [pause_button, normal_button, fast_button]:
		button.toggle_mode = true

func active_tool(button: Button, title: String) -> void:
	var color := SiteUITheme.ACCENT if button == select_button else SiteUITheme.WARNING if button == demolish_button else SiteUITheme.BLUE
	button.add_theme_stylebox_override("pressed", SiteUITheme.button(color, color))
	button.add_theme_stylebox_override("hover_pressed", SiteUITheme.button(color, color))
	for other: Button in [select_button, plan_button, demolish_button, door_button, area_button, object_button]:
		other.set_pressed_no_signal(other == button)
	mode_label.text = "MODO / " + title

func set_planning(value: bool) -> void:
	active_tool(plan_button if value else select_button, "PLANEJAR PAREDE" if value else "SELECIONAR")

func set_demolishing() -> void:
	active_tool(demolish_button, "DEMOLIR")

func set_door_mode() -> void:
	active_tool(door_button, "PORTA")

func set_area_mode() -> void:
	active_tool(area_button, "DESIGNAR ÁREA")

func set_object_mode() -> void:
	active_tool(object_button, "INSTALAR OBJETO")

func refresh_availability(kind: int) -> void:
	if availability_label == null:
		return
	var area_name := "Alojamento" if kind == 1 else "Refeitório"
	availability_label.text = "REQUISITO  %s · célula livre" % area_name

func refresh_cell(grid: GridState, cell: Vector2i) -> void:
	if not grid.contains(cell):
		toggle_door_button.visible = false
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
	toggle_door_button.visible = grid.doors.has(cell)
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
	blocked_label.add_theme_color_override("font_color", SiteUITheme.DANGER if blocked_label.text != "Nenhum bloqueio." else SiteUITheme.MUTED)

func refresh(engineer: Engineer) -> void:
	selection_label.text = "Selecionado: " + ("Engenheiro 01" if engineer.selected else "nenhum")
	state_label.text = "Estado: " + engineer.state_text()
	destination_label.text = "Destino: (%d, %d)" % [engineer.destination.x, engineer.destination.y]

func show_message(value: String) -> void:
	message_label.text = value
	var lower := value.to_lower()
	var warning := lower.contains("bloque") or lower.contains("inválid") or lower.contains("inacess") or lower.contains("não ") or lower.contains("erro") or lower.contains("falha") or lower.contains("recus")
	var color := SiteUITheme.DANGER if warning else SiteUITheme.ACCENT if lower.contains("sucesso") else SiteUITheme.TEXT
	message_label.add_theme_color_override("font_color", color)
	var style := SiteUITheme.panel(SiteUITheme.BG, SiteUITheme.BORDER, 2, 8)
	style.border_color = SiteUITheme.DANGER if warning else SiteUITheme.ACCENT if lower.contains("sucesso") else SiteUITheme.BORDER
	style.border_width_left = 3
	message_card.add_theme_stylebox_override("panel", style)

func refresh_population(person: ClassD) -> void:
	population_label.text = ClassD.NAME
	if not person.selected:
		population_label.text += "\nEstado: %s\nDestino: (%d, %d)" % [person.state, person.destination.x, person.destination.y]
	population_label.text += "\nFome: %.1f / 100\nDescanso: %.1f / 100\nNecessidade: %s\nImpedimento: %s" % [person.hunger, person.rest, person.current_need(), person.impediment if not person.impediment.is_empty() else "nenhum"]
	if person.state == ClassD.USING:
		population_label.text += "\nUso: %.1f / %.1f s" % [person.use_elapsed, person.use_seconds()]
	alerts_label.text = "Alertas: nenhum" if person.alerts.is_empty() else "ALERTAS\n" + "\n".join(person.alerts)
	alerts_label.add_theme_color_override("font_color", SiteUITheme.MUTED if person.alerts.is_empty() else SiteUITheme.DANGER)

func refresh_selection(worker: Engineer, person: ClassD) -> void:
	move_button.visible = worker.selected or person.selected
	move_reason.visible = move_button.visible
	move_button.disabled = person.selected or worker.construction_busy
	move_button.tooltip_text = "Classe-D se move automaticamente." if person.selected else "Cancele a tarefa para liberar o engenheiro." if worker.construction_busy else "Escolha o destino no mapa. Clique direito também move."
	move_reason.text = move_button.tooltip_text
	if person.selected:
		selection_label.text = "Selecionado: " + ClassD.NAME
		state_label.text = "Estado: " + person.state
		destination_label.text = "Destino: (%d, %d)" % [person.destination.x, person.destination.y]
	else:
		refresh(worker)

func card(parent: Node, title: String, accent: Color = SiteUITheme.BLUE) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", SiteUITheme.panel(SiteUITheme.SURFACE, SiteUITheme.BORDER, 3, 8))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	add_label(box, title, 11, accent)
	var line := HSeparator.new()
	line.add_theme_stylebox_override("separator", SiteUITheme.panel(accent, accent, 0, 0))
	line.custom_minimum_size.y = 2
	box.add_child(line)
	return box

func _process(_delta: float) -> void:
	preview_label.visible = not preview_label.text.is_empty()
	area_heading.visible = area_button.button_pressed
	area_type.visible = area_heading.visible
	object_heading.visible = object_button.button_pressed
	object_type.visible = object_heading.visible
	availability_label.visible = object_heading.visible
