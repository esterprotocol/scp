class_name SaveSlot
extends RefCounted

const PATH := "user://site_director.json"
const SCHEMA_VERSION := 2
const MAX_BYTES := 2 * 1024 * 1024

static func coordinates(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}

static func cells(values: Variant) -> Array:
	var result: Array = []
	for value: Vector2i in values:
		result.append({"x": value.x, "y": value.y})
	return result

func capture(game: Node2D) -> Dictionary:
	var worker: Engineer = game.engineer
	var jobs: Construction = game.construction
	var queue: Array = []
	for target: Vector2i in jobs.tasks:
		var task: Dictionary = jobs.tasks[target].duplicate()
		task.target = {"x": target.x, "y": target.y}
		queue.append(task)
	var doors: Array = []
	for cell: Vector2i in game.grid.doors:
		doors.append({"cell": coordinates(Vector2(cell)), "open": game.grid.doors[cell]})
	var areas: Array = []
	for cell: Vector2i in game.grid.areas:
		areas.append({"cell": coordinates(Vector2(cell)), "type": game.grid.areas[cell]})
	return {
		"schema_version": SCHEMA_VERSION, "godot_version": GameSettings.GODOT_VERSION,
		"walls": cells(game.grid.walls), "doors": doors, "areas": areas, "blueprints": cells(jobs.blueprints), "tasks": queue,
		"active": null if jobs.active == Construction.NONE else coordinates(Vector2(jobs.active)),
		"work_cell": null if jobs.work_cell == Construction.NONE else coordinates(Vector2(jobs.work_cell)),
		"dirty": jobs.dirty,
		"engineer": {"cell": coordinates(Vector2(worker.cell)), "position": coordinates(worker.position),
			"destination": coordinates(Vector2(worker.destination)), "route": cells(worker.route),
			"selected": worker.selected, "busy": worker.construction_busy, "working": worker.working, "action": worker.work_action},
		"camera": {"position": coordinates(game.camera.position), "zoom": game.camera.zoom.x},
		"tool": "area" if game.painting_area else ("door" if game.installing_door else ("demolish" if game.demolishing else ("plan" if game.planning else "select"))),
		"area_type": game.area_type, "selected_cell": null if game.selected_cell.x < 0 else coordinates(Vector2(game.selected_cell))
	}

func _invalid(message: String) -> Dictionary:
	return {"error": "Save inválido: " + message}

func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

func _point(value: Variant, integral: bool = false) -> Variant:
	if not value is Dictionary or not _number(value.get("x")) or not _number(value.get("y")):
		return null
	if absf(float(value.x)) > 8192 or absf(float(value.y)) > 8192:
		return null
	if integral and (float(value.x) != floorf(float(value.x)) or float(value.y) != floorf(float(value.y))):
		return null
	if integral:
		if value.x < 0 or value.y < 0 or value.x >= GameSettings.GRID_SIZE.x or value.y >= GameSettings.GRID_SIZE.y:
			return null
		return Vector2i(int(value.x), int(value.y))
	return Vector2(float(value.x), float(value.y))

func _cell_list(value: Variant, unique: bool) -> Variant:
	if not value is Array or value.size() > 577:
		return null
	var result: Array[Vector2i] = []
	for entry in value:
		var cell = _point(entry, true)
		if cell == null or (unique and result.has(cell)):
			return null
		result.append(cell)
	return result

func decode(data: Variant) -> Dictionary:
	# Validate and normalize a detached snapshot. No live nodes are modified.
	if not data is Dictionary:
		return _invalid("o documento precisa ser um objeto JSON.")
	if not _number(data.get("schema_version")) or float(data.schema_version) != floorf(float(data.schema_version)) or int(data.schema_version) not in [1, SCHEMA_VERSION]:
		return _invalid("versão do esquema incompatível.")
	if data.get("godot_version") != GameSettings.GODOT_VERSION:
		return _invalid("versão do Godot incompatível.")
	var walls = _cell_list(data.get("walls"), true)
	var blueprints = _cell_list(data.get("blueprints"), true)
	if walls == null or blueprints == null:
		return _invalid("paredes ou blueprints duplicados/fora da grade.")
	var grid := GridState.new()
	grid.walls.clear()
	for cell: Vector2i in walls:
		grid.walls[cell] = true
	var raw_doors: Variant = data.get("doors", []) if int(data.schema_version) == 1 else data.get("doors")
	var raw_areas: Variant = data.get("areas", []) if int(data.schema_version) == 1 else data.get("areas")
	if not raw_doors is Array or raw_doors.size() > 576 or not raw_areas is Array or raw_areas.size() > 576:
		return _invalid("portas ou áreas inválidas.")
	for entry in raw_doors:
		if not entry is Dictionary or not entry.get("open") is bool:
			return _invalid("porta inválida.")
		var door_cell = _point(entry.get("cell"), true)
		if door_cell == null or grid.walls.has(door_cell) or grid.doors.has(door_cell):
			return _invalid("porta duplicada, fora da grade ou sobre parede.")
		grid.doors[door_cell] = entry.open
	for entry in raw_areas:
		if not entry is Dictionary or not _number(entry.get("type")):
			return _invalid("área inválida.")
		var area_cell = _point(entry.get("cell"), true)
		if area_cell == null or grid.areas.has(area_cell) or float(entry.type) != floorf(float(entry.type)) or entry.type < 1 or entry.type >= GridState.AREA_NAMES.size():
			return _invalid("área duplicada, fora da grade ou com tipo inválido.")
		grid.areas[area_cell] = int(entry.type)
	var planned: Dictionary = {}
	for cell: Vector2i in blueprints:
		if not grid.is_walkable(cell):
			return _invalid("blueprint sobre parede.")
		planned[cell] = true
	if not data.get("tasks") is Array or data.tasks.size() > 576 or not data.get("dirty") is bool:
		return _invalid("fila de tarefas inválida.")
	var tasks: Dictionary = {}
	for task in data.tasks:
		if not task is Dictionary:
			return _invalid("tarefa inválida.")
		var target = _point(task.get("target"), true)
		if target == null or tasks.has(target) or task.get("action") not in [Construction.BUILD, Construction.DEMOLISH, Construction.INSTALL_DOOR]:
			return _invalid("alvo/ação inválido ou tarefa duplicada.")
		if task.get("status") not in ["Na fila", "Bloqueada", "Deslocando", "Construindo", "Demolindo", "Instalando"] or not task.get("reason") is String or task.reason.length() > 4096:
			return _invalid("estado de tarefa inválido.")
		var duration := GameSettings.WALL_BUILD_SECONDS if task.action == Construction.BUILD else (GameSettings.DOOR_INSTALL_SECONDS if task.action == Construction.INSTALL_DOOR else GameSettings.WALL_DEMOLISH_SECONDS)
		if not task.get("preserve_exit") is bool or not _number(task.get("elapsed")) or task.elapsed < 0 or task.elapsed >= duration:
			return _invalid("progresso/obrigação de saída inválido.")
		if task.action == Construction.BUILD and (not planned.has(target) or not grid.is_walkable(target)):
			return _invalid("construção sem blueprint ou sobre parede.")
		if task.action == Construction.DEMOLISH and not grid.walls.has(target) and not grid.doors.has(target):
			return _invalid("demolição sem parede ou porta.")
		if task.action == Construction.INSTALL_DOOR and not grid.walls.has(target):
			return _invalid("instalação sem parede.")
		if task.status in ["Na fila", "Bloqueada", "Deslocando"] and task.elapsed != 0:
			return _invalid("progresso fora de trabalho ativo.")
		if (task.status == "Bloqueada") != (not task.reason.is_empty()):
			return _invalid("motivo de bloqueio inconsistente.")
		tasks[target] = {"action": task.action, "status": task.status, "reason": task.reason, "elapsed": float(task.elapsed), "preserve_exit": task.preserve_exit}
	var saved_worker = data.get("engineer")
	if not saved_worker is Dictionary:
		return _invalid("engenheiro ausente.")
	var cell = _point(saved_worker.get("cell"), true)
	var position = _point(saved_worker.get("position"))
	var destination = _point(saved_worker.get("destination"), true)
	var route = _cell_list(saved_worker.get("route"), false)
	if cell == null or position == null or destination == null or route == null or not grid.is_walkable(cell) or not grid.is_walkable(grid.to_cell(position)):
		return _invalid("posição/rota do engenheiro inválida.")
	for flag in ["selected", "busy", "working"]:
		if not saved_worker.get(flag) is bool:
			return _invalid("estado do engenheiro inválido.")
	if saved_worker.get("action") not in [Construction.BUILD, Construction.DEMOLISH, Construction.INSTALL_DOOR]:
		return _invalid("ação do engenheiro inválida.")
	var previous: Vector2i = cell
	for index in route.size():
		var next: Vector2i = route[index]
		var difference := next - previous
		if not grid.is_walkable(next) or (absi(difference.x) + absi(difference.y) != 1 and not (index == 0 and next == cell)):
			return _invalid("rota atravessa parede ou corta quina.")
		previous = next
	var center := grid.center(cell)
	if route.is_empty():
		if position != center or destination != cell:
			return _invalid("engenheiro parado fora do centro/destino.")
	else:
		if destination != route[-1]:
			return _invalid("destino diverge da rota.")
		var offset: Vector2 = position - center
		var segment: Vector2 = grid.center(route[0]) - center
		if segment == Vector2.ZERO:
			# Route invalidation can leave a return to the last reached center.
			if (offset.x != 0 and offset.y != 0) or offset.length() > GameSettings.CELL_SIZE:
				return _invalid("posição fora do segmento de retorno.")
		elif absf(segment.cross(offset)) > 0.01 or offset.dot(segment) < 0 or offset.dot(segment) > segment.length_squared():
			return _invalid("posição fora do segmento de movimento.")
	if not data.has("active") or not data.has("work_cell"):
		return _invalid("vínculos de tarefa ausentes.")
	var active = Construction.NONE if data.active == null else _point(data.active, true)
	var work_cell = Construction.NONE if data.work_cell == null else _point(data.work_cell, true)
	if active == null or work_cell == null:
		return _invalid("vínculos de tarefa inválidos.")
	if active == Construction.NONE:
		if work_cell != Construction.NONE or saved_worker.busy or saved_worker.working:
			return _invalid("engenheiro ocupado sem tarefa ativa.")
	else:
		if not tasks.has(active) or not grid.is_walkable(work_cell) or not saved_worker.busy or saved_worker.action != tasks[active].action or destination != work_cell:
			return _invalid("vínculo entre engenheiro e tarefa inválido.")
		var difference: Vector2i = work_cell - active
		if absi(difference.x) + absi(difference.y) != 1:
			return _invalid("posição de trabalho não adjacente.")
		var task: Dictionary = tasks[active]
		var expected := ("Construindo" if task.action == Construction.BUILD else ("Instalando" if task.action == Construction.INSTALL_DOOR else "Demolindo")) if saved_worker.working else "Deslocando"
		if task.status != expected or (saved_worker.working and (not route.is_empty() or position != grid.center(work_cell))):
			return _invalid("estado de trabalho inconsistente.")
		if task.action == Construction.BUILD:
			if route.is_empty() and (active == cell or active == grid.to_cell(position)):
				return _invalid("construção sobre o engenheiro.")
			var has_exit := not GridNavigation.find_path(grid, work_cell, GameSettings.EXIT_CELL).is_empty()
			if (task.preserve_exit or has_exit) and GridNavigation.find_path(grid, work_cell, GameSettings.EXIT_CELL, active).is_empty():
				return _invalid("construção bloquearia a saída do engenheiro.")
	for target: Vector2i in tasks:
		if target != active and tasks[target].status not in ["Na fila", "Bloqueada"]:
			return _invalid("mais de uma tarefa ativa.")
	var camera = data.get("camera")
	if not camera is Dictionary:
		return _invalid("câmera ausente.")
	var camera_position = _point(camera.get("position"))
	# Vector2 components are float32; preserve valid exact boundary values
	# rather than rounding/clamping the restored zoom.
	if camera_position == null or not _number(camera.get("zoom")) or (camera.zoom < GameSettings.ZOOM_MIN and not is_equal_approx(camera.zoom, GameSettings.ZOOM_MIN)) or (camera.zoom > GameSettings.ZOOM_MAX and not is_equal_approx(camera.zoom, GameSettings.ZOOM_MAX)):
		return _invalid("câmera/zoom inválido.")
	if camera_position.x < -128 or camera_position.y < -128 or camera_position.x > 896 or camera_position.y > 896 or data.get("tool") not in ["select", "plan", "demolish", "door", "area"]:
		return _invalid("câmera/modo fora dos limites.")
	var area_type: Variant = data.get("area_type", 1) if int(data.schema_version) == 1 else data.get("area_type")
	var raw_selected: Variant = data.get("selected_cell", null) if int(data.schema_version) == 1 else data.get("selected_cell")
	var selected_cell = Construction.NONE if raw_selected == null else _point(raw_selected, true)
	if not _number(area_type) or float(area_type) != floorf(float(area_type)) or area_type < 0 or area_type >= GridState.AREA_NAMES.size() or selected_cell == null:
		return _invalid("tipo de área ou célula selecionada inválidos.")
	return {"state": {"walls": grid.walls, "doors": grid.doors, "areas": grid.areas, "blueprints": planned, "tasks": tasks, "active": active, "work_cell": work_cell, "dirty": data.dirty,
		"cell": cell, "position": position, "destination": destination, "route": route, "worker": saved_worker,
		"camera_position": camera_position, "zoom": float(camera.zoom), "tool": data.tool, "area_type": int(area_type), "selected_cell": selected_cell}}

func apply(game: Node2D, state: Dictionary) -> void:
	# Synchronous commit on Godot's main thread: no await, signals, reset,
	# scheduling or movement between assigning related fields.
	var worker: Engineer = game.engineer
	var jobs: Construction = game.construction
	game.grid.walls = state.walls
	game.grid.doors = state.doors
	game.grid.areas = state.areas
	jobs.blueprints = state.blueprints
	jobs.tasks = state.tasks
	jobs.active = state.active
	jobs.work_cell = state.work_cell
	jobs.dirty = state.dirty
	worker.cell = state.cell
	worker.position = state.position
	worker.destination = state.destination
	worker.route = state.route
	worker.selected = state.worker.selected
	worker.construction_busy = state.worker.busy
	worker.working = state.worker.working
	worker.work_action = state.worker.action
	game.camera.position = state.camera_position
	game.camera.zoom = Vector2.ONE * state.zoom
	game.area_type = state.area_type
	game.hud.area_type.select(state.area_type)
	if state.tool == "demolish":
		game.set_demolishing()
	elif state.tool == "door":
		game.set_door_mode()
	elif state.tool == "area":
		game.set_area_mode()
	else:
		game.set_planning(state.tool == "plan")
	game.select_cell(state.selected_cell)
	worker.queue_redraw()
	game.map_view.queue_redraw()
	game.hud.refresh(worker)
	game.hud.refresh_construction(jobs)

func save_game(game: Node2D, path: String = PATH) -> String:
	var snapshot := capture(game)
	var validated := decode(snapshot)
	if validated.has("error"):
		return "Não foi possível salvar. " + validated.error
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return "Não foi possível salvar: falha ao abrir arquivo temporário (%s)." % error_string(FileAccess.get_open_error())
	file.store_string(JSON.stringify(snapshot, "\t", false, true))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary)
		return "Não foi possível salvar: falha de gravação (%s)." % error_string(write_error)
	var verify := read_state(temporary)
	if verify.has("error"):
		DirAccess.remove_absolute(temporary)
		return "Não foi possível salvar: verificação do arquivo temporário falhou."
	# Same-directory rename replaces the slot atomically on supported desktop
	# filesystems. Never delete the old slot to make a failed rename succeed.
	var rename_error := DirAccess.rename_absolute(temporary, path)
	if rename_error != OK:
		DirAccess.remove_absolute(temporary)
		return "Não foi possível salvar: substituição falhou (%s). Save anterior preservado." % error_string(rename_error)
	return "Cenário salvo com sucesso."

func read_state(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "Não foi possível carregar: arquivo ausente ou sem acesso (%s)." % error_string(FileAccess.get_open_error())}
	if file.get_length() > MAX_BYTES:
		return _invalid("arquivo excede 2 MiB.")
	var contents := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK:
		return _invalid("falha de leitura.")
	var json := JSON.new()
	if json.parse(contents) != OK:
		return _invalid("JSON corrompido, linha %d." % json.get_error_line())
	return decode(json.data)

func load_game(game: Node2D, path: String = PATH) -> String:
	var validated := read_state(path)
	if validated.has("error"):
		return validated.error
	apply(game, validated.state)
	return "Cenário carregado com sucesso."
