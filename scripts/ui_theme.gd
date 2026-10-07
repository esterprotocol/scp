class_name SiteUITheme
extends RefCounted

# One palette and spacing scale for the management HUD.
const BG := Color("10151b")
const SURFACE := Color("18212b")
const ELEVATED := Color("222e3b")
const BORDER := Color("354453")
const TEXT := Color("edf2f5")
const MUTED := Color("aebdca")
const ACCENT := Color("70dfbf")
const BLUE := Color("79b9ee")
const WARNING := Color("efc477")
const DANGER := Color("ff958e")
const SPACING := 8
const PADDING := 14

static func panel(color: Color = SURFACE, border: Color = BORDER, radius: int = 6, padding: int = PADDING) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = padding
	box.content_margin_right = padding
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	return box

static func button(color: Color = ELEVATED, border: Color = BORDER) -> StyleBoxFlat:
	return panel(color, border, 4, 7)

const CONSTRUCTION := Color("efc477")

static func shared() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 13
	for type in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", type, button())
		theme.set_stylebox("hover", type, button(ELEVATED, ACCENT))
		theme.set_stylebox("pressed", type, button(ACCENT, ACCENT))
		theme.set_stylebox("hover_pressed", type, button(ACCENT, ACCENT))
		theme.set_stylebox("disabled", type, button(BG, BORDER))
		var focus := button(Color(0, 0, 0, 0), TEXT)
		focus.set_border_width_all(2)
		theme.set_stylebox("focus", type, focus)
		theme.set_color("font_color", type, TEXT)
		theme.set_color("font_hover_color", type, TEXT)
		theme.set_color("font_pressed_color", type, BG)
		theme.set_color("font_hover_pressed_color", type, BG)
		theme.set_color("font_disabled_color", type, MUTED)
	theme.set_color("font_color", "Label", TEXT)
	theme.set_stylebox("panel", "PanelContainer", panel())
	theme.set_stylebox("panel", "PopupMenu", panel(BG))
	theme.set_color("font_color", "PopupMenu", TEXT)
	theme.set_stylebox("hover", "PopupMenu", button(ELEVATED))
	theme.set_stylebox("scroll", "VScrollBar", panel(BG, BG, 2, 0))
	var grabber := panel(BORDER, BORDER, 2, 0)
	grabber.content_margin_left = 4
	grabber.content_margin_right = 4
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", panel(MUTED, MUTED, 2, 0))
	return theme
