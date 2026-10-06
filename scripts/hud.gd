class_name SiteHUD
extends CanvasLayer

signal restart_requested

var selection_label: Label
var state_label: Label
var destination_label: Label
var message_label: Label
var restart_button: Button

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
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := add_label(box, "SITE DIRECTOR")
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("64e6b6"))
	add_label(box, "01 / OPERAÇÕES\nProtótipo de navegação")
	box.add_child(HSeparator.new())
	selection_label = add_label(box, "")
	state_label = add_label(box, "")
	destination_label = add_label(box, "")
	message_label = add_label(box, "")
	message_label.custom_minimum_size = Vector2(220, 90)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_color_override("font_color", Color("e8b95c"))
	restart_button = Button.new()
	restart_button.text = "Reiniciar cenário"
	restart_button.custom_minimum_size.y = 40
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	box.add_child(restart_button)
	box.add_child(HSeparator.new())
	add_label(box, "CONTROLES\n\nClique esquerdo: selecionar\nClique direito: mover\nWASD / setas: câmera\nBotão central: arrastar\nRoda do mouse: zoom\n\nDourado: engenheiro\nCinza: parede\nVerde: rota / seleção\n\nGrade 24 × 24 · célula 32 px\nCoordenadas de 0 a 23")

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
