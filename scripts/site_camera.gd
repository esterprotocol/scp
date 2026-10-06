class_name SiteCamera
extends Camera2D

func reset() -> void:
	position = GameSettings.INITIAL_CAMERA
	zoom = Vector2.ONE * GameSettings.INITIAL_ZOOM

func _process(delta: float) -> void:
	var direction := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	position += direction.normalized() * GameSettings.CAMERA_SPEED * delta / zoom.x
	clamp_position()

func clamp_position() -> void:
	position = position.clamp(Vector2(-128, -128), Vector2(GameSettings.GRID_SIZE) * GameSettings.CELL_SIZE + Vector2(128, 128))

func change_zoom(factor: float) -> void:
	zoom = Vector2.ONE * clampf(zoom.x * factor, GameSettings.ZOOM_MIN, GameSettings.ZOOM_MAX)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_zoom(1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_zoom(1.0 / 1.1)
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		position -= event.relative / zoom
		clamp_position()
