class_name SaveSlot
extends RefCounted

const PATH := "user://site_director.json"
const SCHEMA_VERSION := 4
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
	var objects: Array = []
	for cell: Vector2i in game.grid.objects:
		objects.append({"cell": coordinates(Vector2(cell)), "type": game.grid.objects[cell]})
	var object_blueprints: Array = []
	for cell: Vector2i in jobs.object_blueprints:
		object_blueprints.append({"cell": coordinates(Vector2(cell)), "type": jobs.object_blueprints[cell]})
	return {
		"classd": capture_classd(game.classd),
		"schema_version": SCHEMA_VERSION, "godot_version": GameSettings.GODOT_VERSION,
		"walls": cells(game.grid.walls), "doors": doors, "areas": areas, "objects": objects,
		"blueprints": cells(jobs.blueprints), "object_blueprints": object_blueprints, "tasks": queue,
		"active": null if jobs.active == Construction.NONE else coordinates(Vector2(jobs.active)),
		"work_cell": null if jobs.work_cell == Construction.NONE else coordinates(Vector2(jobs.work_cell)),
		"dirty": jobs.dirty,
		"engineer": {"cell": coordinates(Vector2(worker.cell)), "position": coordinates(worker.position),
			"destination": coordinates(Vector2(worker.destination)), "route": cells(worker.route),
			"selected": worker.selected, "busy": worker.construction_busy, "working": worker.working, "action": worker.work_action},
		"camera": {"position": coordinates(game.camera.position), "zoom": game.camera.zoom.x},
		"tool": "object" if game.placing_object else ("area" if game.painting_area else ("door" if game.installing_door else ("demolish" if game.demolishing else ("plan" if game.planning else "select")))),
		"area_type": game.area_type, "object_type": game.object_type,
		"selected_cell": null if game.selected_cell.x < 0 else coordinates(Vector2(game.selected_cell))
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
	if not _number(data.get("schema_version")) or float(data.schema_version) != floorf(float(data.schema_version)) or int(data.schema_version) not in [1, 2, 3, SCHEMA_VERSION]:
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
	var raw_objects: Variant = data.get("objects", []) if int(data.schema_version) < 3 else data.get("objects")
	var raw_object_blueprints: Variant = data.get("object_blueprints", []) if int(data.schema_version) < 3 else data.get("object_blueprints")
	if not raw_objects is Array or raw_objects.size() > 576 or not raw_object_blueprints is Array or raw_object_blueprints.size() > 576:
		return _invalid("objetos ou blueprints de objeto inválidos.")
	for entry in raw_objects:
		if not entry is Dictionary or not _number(entry.get("type")):
			return _invalid("objeto inválido.")
		var object_cell = _point(entry.get("cell"), true)
		if object_cell == null or grid.walls.has(object_cell) or grid.doors.has(object_cell) or grid.objects.has(object_cell) or float(entry.type) != floorf(float(entry.type)) or entry.type < 1 or entry.type >= GridState.OBJECT_NAMES.size():
			return _invalid("objeto duplicado, fora da grade ou sobre estrutura.")
		grid.objects[object_cell] = int(entry.type)
		if grid.area_at(object_cell) != grid.object_area(grid.objects[object_cell]):
			return _invalid("objeto fora da área compatível.")
	for object_cell: Vector2i in grid.objects:
		if grid.interaction_cells(object_cell).is_empty():
			return _invalid("objeto sem ponto de interação transitável.")
	var object_planned: Dictionary = {}
	for entry in raw_object_blueprints:
		if not entry is Dictionary or not _number(entry.get("type")):
			return _invalid("blueprint de objeto inválido.")
		var planned_cell = _point(entry.get("cell"), true)
		if planned_cell == null or object_planned.has(planned_cell) or float(entry.type) != floorf(float(entry.type)) or entry.type < 1 or entry.type >= GridState.OBJECT_NAMES.size() or not grid.is_walkable(planned_cell):
			return _invalid("blueprint de objeto duplicado ou sobre obstáculo.")
		object_planned[planned_cell] = int(entry.type)
	var planned: Dictionary = {}
	for cell: Vector2i in blueprints:
		if not grid.is_walkable(cell) or object_planned.has(cell):
			return _invalid("blueprint sobre parede.")
		planned[cell] = true
	if not data.get("tasks") is Array or data.tasks.size() > 576 or not data.get("dirty") is bool:
		return _invalid("fila de tarefas inválida.")
	var tasks: Dictionary = {}
	for task in data.tasks:
		if not task is Dictionary:
			return _invalid("tarefa inválida.")
		var target = _point(task.get("target"), true)
		if target == null or tasks.has(target) or task.get("action") not in [Construction.BUILD, Construction.DEMOLISH, Construction.INSTALL_DOOR, Construction.BUILD_OBJECT, Construction.DEMOLISH_OBJECT]:
			return _invalid("alvo/ação inválido ou tarefa duplicada.")
		var object_type: Variant = task.get("object_type", 0) if int(data.schema_version) < 3 else task.get("object_type")
		if not _number(object_type) or float(object_type) != floorf(float(object_type)) or object_type < 0 or object_type >= GridState.OBJECT_NAMES.size():
			return _invalid("tipo de objeto na tarefa inválido.")
		if (task.action in [Construction.BUILD_OBJECT, Construction.DEMOLISH_OBJECT]) != (object_type > 0):
			return _invalid("ação e tipo de objeto inconsistentes.")
		if task.get("status") not in ["Na fila", "Bloqueada", "Deslocando", "Construindo", "Demolindo", "Instalando"] or not task.get("reason") is String or task.reason.length() > 4096:
			return _invalid("estado de tarefa inválido.")
		var duration := GameSettings.WALL_BUILD_SECONDS
		if task.action in [Construction.DEMOLISH, Construction.DEMOLISH_OBJECT]:
			duration = GameSettings.OBJECT_DEMOLISH_SECONDS if task.action == Construction.DEMOLISH_OBJECT else GameSettings.WALL_DEMOLISH_SECONDS
		elif task.action in [Construction.INSTALL_DOOR, Construction.BUILD_OBJECT]:
			duration = GameSettings.OBJECT_INSTALL_SECONDS if task.action == Construction.BUILD_OBJECT else GameSettings.DOOR_INSTALL_SECONDS
		if not task.get("preserve_exit") is bool or not _number(task.get("elapsed")) or task.elapsed < 0 or task.elapsed >= duration:
			return _invalid("progresso/obrigação de saída inválido.")
		if task.action == Construction.BUILD and (not planned.has(target) or not grid.is_walkable(target)):
			return _invalid("construção sem blueprint ou sobre parede.")
		if task.action == Construction.DEMOLISH and not grid.walls.has(target) and not grid.doors.has(target):
			return _invalid("demolição sem parede ou porta.")
		if task.action == Construction.INSTALL_DOOR and not grid.walls.has(target):
			return _invalid("instalação sem parede.")
		if task.action == Construction.BUILD_OBJECT and (not object_planned.has(target) or object_planned[target] != int(object_type) or not grid.is_walkable(target)):
			return _invalid("instalação de objeto sem blueprint ou sobre obstáculo.")
		if task.action == Construction.DEMOLISH_OBJECT and (not grid.objects.has(target) or grid.objects[target] != int(object_type)):
			return _invalid("demolição sem objeto correspondente.")
		if task.status in ["Na fila", "Bloqueada", "Deslocando"] and task.elapsed != 0:
			return _invalid("progresso fora de trabalho ativo.")
		if (task.status == "Bloqueada") != (not task.reason.is_empty()):
			return _invalid("motivo de bloqueio inconsistente.")
		tasks[target] = {"action": task.action, "object_type": int(object_type), "status": task.status, "reason": task.reason, "elapsed": float(task.elapsed), "preserve_exit": task.preserve_exit}
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
	if saved_worker.get("action") not in [Construction.BUILD, Construction.DEMOLISH, Construction.INSTALL_DOOR, Construction.BUILD_OBJECT, Construction.DEMOLISH_OBJECT]:
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
		var expected := ("Construindo" if task.action == Construction.BUILD else ("Instalando" if task.action in [Construction.INSTALL_DOOR, Construction.BUILD_OBJECT] else "Demolindo")) if saved_worker.working else "Deslocando"
		if task.status != expected or (saved_worker.working and (not route.is_empty() or position != grid.center(work_cell))):
			return _invalid("estado de trabalho inconsistente.")
		if task.action in [Construction.BUILD, Construction.BUILD_OBJECT]:
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
	if camera_position.x < -128 or camera_position.y < -128 or camera_position.x > 896 or camera_position.y > 896 or data.get("tool") not in ["select", "plan", "demolish", "door", "area", "object"]:
		return _invalid("câmera/modo fora dos limites.")
	var area_type: Variant = data.get("area_type", 1) if int(data.schema_version) == 1 else data.get("area_type")
	var object_type: Variant = data.get("object_type", 1) if int(data.schema_version) < 3 else data.get("object_type")
	var raw_selected: Variant = data.get("selected_cell", null) if int(data.schema_version) == 1 else data.get("selected_cell")
	var selected_cell = Construction.NONE if raw_selected == null else _point(raw_selected, true)
	if not _number(area_type) or float(area_type) != floorf(float(area_type)) or area_type < 0 or area_type >= GridState.AREA_NAMES.size() or selected_cell == null:
		return _invalid("tipo de área ou célula selecionada inválidos.")
	if not _number(object_type) or float(object_type) != floorf(float(object_type)) or object_type < 1 or object_type >= GridState.OBJECT_NAMES.size():
		return _invalid("tipo selecionado de objeto inválido.")
	var person := decode_classd(data.get("classd"), grid, int(data.schema_version), cell)
	if person.has("error"):
		return person
	if saved_worker.selected and person.state.selected:
		return _invalid("duas pessoas selecionadas.")
	return {"state": {"classd": person.state, "walls": grid.walls, "doors": grid.doors, "areas": grid.areas, "objects": grid.objects,
		"blueprints": planned, "object_blueprints": object_planned, "tasks": tasks, "active": active, "work_cell": work_cell, "dirty": data.dirty,
		"cell": cell, "position": position, "destination": destination, "route": route, "worker": saved_worker,
		"camera_position": camera_position, "zoom": float(camera.zoom), "tool": data.tool, "area_type": int(area_type), "object_type": int(object_type), "selected_cell": selected_cell}}

func apply(game: Node2D, state: Dictionary) -> void:
	# Synchronous commit on Godot's main thread: no await, signals, reset,
	# scheduling or movement between assigning related fields.
	var worker: Engineer = game.engineer
	var jobs: Construction = game.construction
	game.grid.walls = state.walls
	game.grid.doors = state.doors
	game.grid.areas = state.areas
	game.grid.objects = state.objects
	game.grid.reservations.clear()
	apply_classd(game.classd, state.classd)
	jobs.blueprints = state.blueprints
	jobs.object_blueprints = state.object_blueprints
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
	game.object_type = state.object_type
	game.hud.object_type.select(state.object_type - 1)
	if state.tool == "demolish":
		game.set_demolishing()
	elif state.tool == "door":
		game.set_door_mode()
	elif state.tool == "area":
		game.set_area_mode()
	elif state.tool == "object":
		game.set_object_mode()
	else:
		game.set_planning(state.tool == "plan")
	game.select_cell(state.selected_cell)
	worker.queue_redraw()
	game.map_view.queue_redraw()
	game.hud.refresh_selection(worker, game.classd)
	game.hud.refresh_population(game.classd)
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

func capture_classd(person: ClassD) -> Dictionary:
	return {"id": ClassD.ID, "cell": coordinates(Vector2(person.cell)), "position": coordinates(person.position),
		"destination": coordinates(Vector2(person.destination)), "route": cells(person.route), "selected": person.selected,
		"hunger": person.hunger, "rest": person.rest, "state": person.state, "need": person.need,
		"reserved_object": null if person.reserved_object == ClassD.NONE else coordinates(Vector2(person.reserved_object)),
		"use_elapsed": person.use_elapsed, "use_initial": person.use_initial, "impediment": person.impediment,
		"alerts": Array(person.alerts), "dirty": person.dirty}

func decode_classd(raw: Variant, grid: GridState, version: int, worker_cell: Vector2i) -> Dictionary:
	if version < 4:
		var initial := ClassD.initial_cell(grid, worker_cell)
		if initial == ClassD.NONE:
			return _invalid("sem célula livre para migrar Classe-D.")
		return {"state": {"cell": initial, "position": grid.center(initial), "destination": initial, "route": [],
			"selected": false, "hunger": GameSettings.CLASSD_INITIAL_NEEDS, "rest": GameSettings.CLASSD_INITIAL_NEEDS,
			"state": ClassD.IDLE, "need": "", "reserved_object": ClassD.NONE, "use_elapsed": 0.0, "use_initial": 0.0,
			"impediment": "", "alerts": [], "dirty": true}}
	if not raw is Dictionary or raw.get("id") != ClassD.ID:
		return _invalid("identidade do Classe-D inválida.")
	var cell = _point(raw.get("cell"), true)
	var position = _point(raw.get("position"))
	var destination = _point(raw.get("destination"), true)
	var route = _cell_list(raw.get("route"), false)
	if cell == null or position == null or destination == null or route == null or not grid.is_walkable(cell) or not grid.is_walkable(grid.to_cell(position)):
		return _invalid("posição/rota do Classe-D inválida.")
	for key in ["hunger", "rest", "use_elapsed", "use_initial"]:
		if not _number(raw.get(key)) or raw[key] < 0 or raw[key] > 100:
			return _invalid("necessidade/progresso do Classe-D inválido.")
	if not raw.get("selected") is bool or not raw.get("dirty") is bool or raw.get("state") not in [ClassD.IDLE, ClassD.MOVING, ClassD.USING, ClassD.BLOCKED, ClassD.STOPPING] or raw.get("need") not in ["", "Fome", "Descanso"]:
		return _invalid("estado do Classe-D inválido.")
	if not raw.get("impediment") is String or raw.impediment.length() > 4096 or not raw.get("alerts") is Array or raw.alerts.size() > 2:
		return _invalid("alertas do Classe-D inválidos.")
	for alert in raw.alerts:
		if not alert is String or alert.length() > 4096:
			return _invalid("texto de alerta inválido.")
	var previous: Vector2i = cell
	for index in route.size():
		var step: Vector2i = route[index] - previous
		if not grid.is_walkable(route[index]) or (absi(step.x) + absi(step.y) != 1 and not (index == 0 and route[index] == cell)):
			return _invalid("rota do Classe-D atravessa obstáculo ou corta quina.")
		previous = route[index]
	if route.is_empty():
		if position != grid.center(cell) or destination != cell:
			return _invalid("Classe-D parado fora do ponto correto.")
	else:
		var offset: Vector2 = position - grid.center(cell)
		var segment: Vector2 = grid.center(route[0]) - grid.center(cell)
		if destination != route[-1]:
			return _invalid("destino do Classe-D diverge da rota.")
		if segment == Vector2.ZERO:
			if (offset.x != 0 and offset.y != 0) or offset.length() > GameSettings.CELL_SIZE:
				return _invalid("retorno do Classe-D fora do segmento.")
		elif absf(segment.cross(offset)) > 0.01 or offset.dot(segment) < 0 or offset.dot(segment) > segment.length_squared():
			return _invalid("Classe-D fora do segmento ortogonal.")
	if not raw.has("reserved_object"):
		return _invalid("reserva do Classe-D ausente.")
	var reserved = ClassD.NONE if raw.reserved_object == null else _point(raw.reserved_object, true)
	if reserved == null:
		return _invalid("reserva do Classe-D inválida.")
	var active: bool = raw.state in [ClassD.MOVING, ClassD.USING]
	if active:
		var kind := 4 if raw.need == "Fome" else 1
		if raw.need.is_empty() or grid.objects.get(reserved, 0) != kind or not grid.interaction_cells(reserved).has(destination):
			return _invalid("objeto e ponto de interação do Classe-D inconsistentes.")
	elif reserved != ClassD.NONE or raw.use_elapsed != 0 or raw.use_initial != 0 or not route.is_empty() and raw.state != ClassD.STOPPING:
		return _invalid("Classe-D inativo com reserva/progresso/rota.")
	if raw.state == ClassD.USING:
		var duration := GameSettings.CLASSD_MEAL_SECONDS if raw.need == "Fome" else GameSettings.CLASSD_REST_SECONDS
		var value: float = raw.hunger if raw.need == "Fome" else raw.rest
		if not route.is_empty() or raw.use_elapsed >= duration or not is_equal_approx(value, lerpf(raw.use_initial, 100.0, raw.use_elapsed / duration)):
			return _invalid("progresso de uso inconsistente.")
	elif raw.use_elapsed != 0 or raw.use_initial != 0:
		return _invalid("recuperação antes do uso.")
	var normalized: Dictionary = raw.duplicate(true)
	normalized.cell = cell
	normalized.position = position
	normalized.destination = destination
	normalized.route = route
	normalized.reserved_object = reserved
	return {"state": normalized}

func apply_classd(person: ClassD, state: Dictionary) -> void:
	person.cell = state.cell
	person.position = state.position
	person.destination = state.destination
	person.route.assign(state.route)
	person.selected = state.selected
	person.hunger = state.hunger
	person.rest = state.rest
	person.state = state.state
	person.need = state.need
	person.reserved_object = state.reserved_object
	person.use_elapsed = state.use_elapsed
	person.use_initial = state.use_initial
	person.impediment = state.impediment
	person.alerts = PackedStringArray(state.alerts)
	person.dirty = state.dirty
	if person.reserved_object != ClassD.NONE:
		# Rebuild the transient index without intermediate simulation signals.
		person.grid.reservations[person.reserved_object] = ClassD.ID
	person.queue_redraw()
