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
signal speed_requested(speed: float)

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
var current_speed := 1.0

func _ready() -> void:
	var panel_root := PanelContainer.new()
	panel_root.position = Vector2(12, 12)
	panel_root.custom_minimum_size.x = 322
	panel_root.add_theme_stylebox_override("panel", SiteUITheme.panel(SiteUITheme.BG, SiteUITheme.BORDER, 8, 10))
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
	var title := add_label(box, "SITE DIRECTOR", 22, SiteUITheme.TEXT)
	title.add_theme_color_override("font_color", SiteUITheme.ACCENT)
	add_label(box, "INSTALAÇÃO / CONTROLE OPERACIONAL", 10, SiteUITheme.MUTED)
	section(box, "TEMPO E ARQUIVO")
	var time_row := HBoxContainer.new()
	time_row.add_theme_constant_override("separation", 5)
	box.add_child(time_row)
	pause_button = add_button(time_row, "|| Pausa", func() -> void: speed_requested.emit(0.0))
	normal_button = add_button(time_row, "1×", func() -> void: speed_requested.emit(1.0))
	fast_button = add_button(time_row, "2×", func() -> void: speed_requested.emit(2.0))
	for button: Button in [pause_button, normal_button, fast_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_speed(1.0)
	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 5)
	box.add_child(save_row)
	save_button = add_button(save_row, "Salvar", func() -> void: save_requested.emit())
	load_button = add_button(save_row, "Carregar", func() -> void: load_requested.emit())
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_label = add_label(box, "MODO / SELECIONAR", 12, SiteUITheme.ACCENT)
	message_label = add_label(box, "", 13, SiteUITheme.WARNING)
	message_label.custom_minimum_size.y = 54
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section(box, "FERRAMENTAS")
	var tools := GridContainer.new()
	tools.columns = 2
	tools.add_theme_constant_override("h_separation", 5)
	tools.add_theme_constant_override("v_separation", 5)
	box.add_child(tools)
	select_button = tool(tools, "[o] Selecionar", func() -> void: mode_requested.emit(false))
	plan_button = tool(tools, "[#] Parede", func() -> void: mode_requested.emit(true))
	demolish_button = tool(tools, "[-] Demolir", func() -> void: demolish_requested.emit())
	door_button = tool(tools, "[=] Porta", func() -> void: door_requested.emit())
	area_button = tool(tools, "[:] Área", func() -> void: area_requested.emit())
	object_button = tool(tools, "[+] Objeto", func() -> void: object_requested.emit())
	add_label(box, "TIPO DE ÁREA", 10, SiteUITheme.MUTED)
	area_type = OptionButton.new()
	for index in GridState.AREA_NAMES.size():
		area_type.add_item(GridState.AREA_NAMES[index], index)
	area_type.item_selected.connect(func(index: int) -> void: area_type_requested.emit(index))
	style_button(area_type)
	box.add_child(area_type)
	add_label(box, "OBJETO A INSTALAR", 10, SiteUITheme.MUTED)
	object_type = OptionButton.new()
	for kind in range(1, GridState.OBJECT_NAMES.size()):
		object_type.add_item(GridState.OBJECT_NAMES[kind], kind)
	object_type.item_selected.connect(func(index: int) -> void:
		object_type_requested.emit(index + 1)
		refresh_availability(index + 1))
	style_button(object_type)
	box.add_child(object_type)
	availability_label = add_label(box, "", 12, SiteUITheme.MUTED)
	availability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	refresh_availability(1)
	section(box, "TRABALHO E ALERTAS")
	task_label = add_label(box, "Tarefa atual: nenhuma", 13)
	task_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 18
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", SiteUITheme.button(SiteUITheme.SURFACE))
	progress_bar.add_theme_stylebox_override("fill", SiteUITheme.button(SiteUITheme.ACCENT, SiteUITheme.ACCENT))
	box.add_child(progress_bar)
	queue_label = add_label(box, "", 12, SiteUITheme.MUTED)
	blocked_label = add_label(box, "", 12, SiteUITheme.DANGER)
	blocked_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	authorize_button = add_button(box, "Autorizar planejados", func() -> void: authorize_requested.emit(), SiteUITheme.ACCENT)
	cancel_active_button = add_button(box, "Cancelar tarefa atual", func() -> void: cancel_active_requested.emit())
	cancel_all_button = add_button(box, "Cancelar todas as obras", func() -> void: cancel_all_requested.emit())
	section(box, "CENÁRIO")
	restart_button = add_button(box, "Reiniciar cenário", func() -> void: restart_requested.emit(), SiteUITheme.WARNING)
	var help_button := add_button(box, "Controles e legenda  ▾", func() -> void:
		help_label.visible = not help_label.visible)
	help_button.tooltip_text = "Mostrar ou ocultar os controles e a legenda do mapa."
	help_label = add_label(box, "ESQUERDO  Seleciona ou aplica ferramenta\nDIREITO  Move ou cancela obra\nESC  Selecionar e limpar seleção\nWASD / SETAS  Deslocar câmera\nCENTRAL  Arrastar câmera\nRODA  Zoom\n\nAZUL  Blueprint\nDOURADO  Obra autorizada\nLARANJA  Demolição\nROXO  Porta\nVERMELHO  Bloqueio\nVERDE  Saída de referência", 12, SiteUITheme.MUTED)
	help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_label.visible = false
	inspection_panel = PanelContainer.new()
	inspection_panel.add_theme_stylebox_override("panel", SiteUITheme.panel(SiteUITheme.BG, SiteUITheme.BORDER, 8, 12))
	add_child(inspection_panel)
	inspection_scroll = ScrollContainer.new()
	inspection_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inspection_scroll.custom_minimum_size = Vector2(192, 480)
	inspection_panel.add_child(inspection_scroll)
	var inspection := VBoxContainer.new()
	inspection.add_theme_constant_override("separation", SiteUITheme.SPACING)
	inspection_scroll.add_child(inspection)
	section(inspection, "INSPEÇÃO / CÉLULA")
	cell_label = add_label(inspection, "Célula: nenhuma", 13)
	cell_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toggle_door_button = add_button(inspection, "Abrir/fechar porta", func() -> void: toggle_door_requested.emit())
	toggle_door_button.disabled = true
	section(inspection, "EQUIPE / 01")
	selection_label = add_label(inspection, "Selecionado: nenhum", 13)
	state_label = add_label(inspection, "", 13)
	state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	destination_label = add_label(inspection, "", 13)
	section(inspection, "POPULAÇÃO / 01")
	population_label = add_label(inspection, "", 12, SiteUITheme.TEXT)
	population_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alerts_label = add_label(inspection, "Alertas: nenhum", 12, SiteUITheme.DANGER)
	alerts_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	get_viewport().size_changed.connect(func() -> void: resize_scroll(scroll))
	resize_scroll(scroll)

func resize_scroll(scroll: ScrollContainer) -> void:
	scroll.custom_minimum_size.y = maxf(160.0, get_viewport().get_visible_rect().size.y - 46.0)
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
	button.custom_minimum_size.y = 34
	button.add_theme_color_override("font_color", SiteUITheme.TEXT)
	button.add_theme_color_override("font_pressed_color", SiteUITheme.BG)
	button.add_theme_color_override("font_hover_color", SiteUITheme.TEXT)
	button.add_theme_color_override("font_disabled_color", SiteUITheme.MUTED)
	button.add_theme_stylebox_override("normal", SiteUITheme.button())
	button.add_theme_stylebox_override("hover", SiteUITheme.button(SiteUITheme.ELEVATED, SiteUITheme.ACCENT))
	button.add_theme_stylebox_override("pressed", SiteUITheme.button(SiteUITheme.ACCENT, SiteUITheme.ACCENT))
	button.add_theme_stylebox_override("hover_pressed", SiteUITheme.button(SiteUITheme.ACCENT, SiteUITheme.ACCENT))
	button.add_theme_stylebox_override("disabled", SiteUITheme.button(SiteUITheme.BG))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

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
	button.custom_minimum_size.x = 141
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
	blocked_label.add_theme_color_override("font_color", SiteUITheme.DANGER if blocked_label.text != "Nenhum bloqueio." else SiteUITheme.MUTED)

func refresh(engineer: Engineer) -> void:
	selection_label.text = "Selecionado: " + ("Engenheiro 01" if engineer.selected else "nenhum")
	state_label.text = "Estado: " + engineer.state_text()
	destination_label.text = "Destino: (%d, %d)" % [engineer.destination.x, engineer.destination.y]

func show_message(value: String) -> void:
	message_label.text = value
	var lower := value.to_lower()
	var warning := lower.contains("bloque") or lower.contains("inválid") or lower.contains("inacess") or lower.contains("não ") or lower.contains("erro") or lower.contains("falha") or lower.contains("recus")
	var color := SiteUITheme.DANGER if warning else SiteUITheme.ACCENT if lower.contains("sucesso") else SiteUITheme.WARNING
	message_label.add_theme_color_override("font_color", color)

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
	if person.selected:
		selection_label.text = "Selecionado: " + ClassD.NAME
		state_label.text = "Estado: " + person.state
		destination_label.text = "Destino: (%d, %d)" % [person.destination.x, person.destination.y]
	else:
		refresh(worker)
