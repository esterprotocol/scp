class_name SiteHUD
extends CanvasLayer

signal restart_requested
signal save_requested
signal load_requested
signal mode_requested(planning: bool)
signal demolish_requested
signal authorize_requested
signal cancel_active_requested
signal cancel_all_requested

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
	add_label(box, "03 / OBRAS\nConstrução e demolição")
	select_button = add_button(box, "Selecionar", func() -> void: mode_requested.emit(false))
	plan_button = add_button(box, "Planejar parede", func() -> void: mode_requested.emit(true))
	demolish_button = add_button(box, "Demolir", func() -> void: demolish_requested.emit())
	select_button.toggle_mode = true
	plan_button.toggle_mode = true
	demolish_button.toggle_mode = true
	box.add_child(HSeparator.new())
	selection_label = add_label(box, "")
	state_label = add_label(box, "")
	destination_label = add_label(box, "")
	task_label = add_label(box, "Tarefa atual: nenhuma")
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
	add_label(box, "CONTROLES\nSelecionar: esquerdo seleciona;\ndireito move.\nPlanejar: esquerdo marca;\ndireito cancela obra.\nDemolir: esquerdo solicita;\ndireito cancela tarefa.\nWASD / setas: câmera\nBotão central: arrastar\nRoda do mouse: zoom\n\nAzul: blueprint não autorizado\nDourado: construção autorizada\nLaranja: demolição solicitada\nVermelho: tarefa bloqueada\nCinza: parede concluída\nVerde: referência de saída\n\n24 × 24 · célula 32 px\nCoordenadas de 0 a 23")
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

func set_demolishing() -> void:
	select_button.set_pressed_no_signal(false)
	plan_button.set_pressed_no_signal(false)
	demolish_button.set_pressed_no_signal(true)

func refresh_construction(construction: Construction) -> void:
	var active := construction.active
	task_label.text = "Tarefa atual: nenhuma" if active == Construction.NONE else "%s (%d, %d)\n%s" % [construction.tasks[active].action, active.x, active.y, construction.tasks[active].status]
	progress_bar.value = construction.progress() * 100.0
	queue_label.text = "Blueprints: %d · Tarefas: %d" % [construction.blueprints.size(), construction.tasks.size()]
	blocked_label.text = construction.blocked_text()

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
