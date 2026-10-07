class_name SiteUITheme
extends RefCounted

# One palette and spacing scale for the management HUD.
const BG := Color("0b141b")
const SURFACE := Color("12222c")
const ELEVATED := Color("1b303a")
const BORDER := Color("37505a")
const TEXT := Color("e1e9e7")
const MUTED := Color("a9bcbf")
const ACCENT := Color("67d9bd")
const BLUE := Color("81bce9")
const WARNING := Color("f1bd6d")
const DANGER := Color("f18d82")
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
