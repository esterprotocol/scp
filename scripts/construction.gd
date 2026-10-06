class_name Construction
extends Node

signal changed

const NONE := Vector2i(-1, -1)
const BUILD := "Construir"
const DEMOLISH := "Demolir"
const UNSAFE_EXIT := "Construção bloquearia a saída do engenheiro"

var grid: GridState
var engineer: Engineer
var blueprints: Dictionary = {}
# One task per cell. Each entry tracks status, reason and elapsed work time.
var tasks: Dictionary = {}
var active := NONE
var work_cell := NONE
var dirty := true

func setup(state: GridState, worker: Engineer) -> void:
	grid = state
	engineer = worker
	grid.changed.connect(_mark_dirty)
	engineer.changed.connect(_mark_dirty)

func _mark_dirty() -> void:
	dirty = true

func target_reason(target: Vector2i, action: String = BUILD, check_occupation: bool = true) -> String:
	if not grid.contains(target):
		return "Fora do mapa."
	if action == DEMOLISH:
		return "" if grid.walls.has(target) else "Não existe parede nessa célula."
	if not grid.is_walkable(target):
		return "Já existe uma parede nessa célula."
	if check_occupation and engineer.occupies(target):
		return "Célula ocupada pelo engenheiro."
	return ""

func plan(target: Vector2i) -> String:
	var reason := target_reason(target)
	if not reason.is_empty():
		return "Não é possível planejar: " + reason
	if blueprints.has(target):
		return "Já existe um blueprint nessa célula."
	blueprints[target] = true
	changed.emit()
	return "Blueprint planejado. Autorize para iniciar a obra."

func request_demolition(target: Vector2i) -> String:
	var reason := target_reason(target, DEMOLISH)
	if not reason.is_empty():
		return "Não é possível demolir: " + reason
	if tasks.has(target):
		return "Já existe uma tarefa nessa célula."
	tasks[target] = _new_task(DEMOLISH)
	dirty = true
	changed.emit()
	return "Demolição solicitada. A parede permanece até concluir o trabalho."

func _new_task(action: String) -> Dictionary:
	return {"action": action, "status": "Na fila", "reason": "", "elapsed": 0.0, "preserve_exit": false}

func authorize() -> String:
	var count := 0
	for target: Vector2i in blueprints:
		if not tasks.has(target):
			tasks[target] = _new_task(BUILD)
			count += 1
	dirty = true
	changed.emit()
	return "%d nova(s) tarefa(s) autorizada(s)." % count

func _release_worker() -> void:
	active = NONE
	work_cell = NONE
	engineer.construction_busy = false
	engineer.working = false
	engineer.stop_after_segment()
	dirty = true

func cancel(target: Vector2i) -> String:
	if not blueprints.has(target) and not tasks.has(target):
		return "Não há blueprint ou tarefa nessa célula."
	if active == target:
		_release_worker()
	tasks.erase(target)
	blueprints.erase(target)
	dirty = true
	changed.emit()
	return "Trabalho cancelado; tarefa e marcação removidas."

func cancel_active() -> String:
	if active == NONE:
		return "Não há tarefa atual para cancelar."
	return cancel(active)

func cancel_all() -> String:
	if active != NONE:
		_release_worker()
	tasks.clear()
	blueprints.clear()
	dirty = true
	changed.emit()
	return "Todos os blueprints e trabalhos incompletos foram cancelados."

func reset() -> void:
	active = NONE
	work_cell = NONE
	tasks.clear()
	blueprints.clear()
	engineer.construction_busy = false
	engineer.working = false
	dirty = true
	changed.emit()

func _block(target: Vector2i, reason: String) -> void:
	tasks[target].status = "Bloqueada"
	tasks[target].reason = reason
	tasks[target].elapsed = 0.0
	if active == target:
		_release_worker()
	changed.emit()

func _has_exit(start: Vector2i, hypothetical_wall: Vector2i = NONE) -> bool:
	# Pure read: an extra blocked cell is passed to BFS, never to GridState.
	return not GridNavigation.find_path(grid, start, GameSettings.EXIT_CELL, hypothetical_wall).is_empty()

func _safe_work_cell(target: Vector2i, candidate: Vector2i) -> bool:
	return not tasks[target].preserve_exit or _has_exit(candidate, target)

func _choose_work_cell(target: Vector2i) -> Vector2i:
	var best := NONE
	var best_length := 100000
	for direction: Vector2i in GridNavigation.DIRECTIONS:
		var candidate := target + direction
		var path := GridNavigation.find_path(grid, engineer.cell, candidate)
		if not path.is_empty() and (tasks[target].action == DEMOLISH or _safe_work_cell(target, candidate)) and path.size() < best_length:
			best = candidate
			best_length = path.size()
	return best

func _schedule() -> void:
	if not dirty or not engineer.route.is_empty():
		return
	dirty = false
	for target: Vector2i in tasks:
		var action: String = tasks[target].action
		var reason := target_reason(target, action)
		if not reason.is_empty():
			_block(target, reason)
			continue
		tasks[target].preserve_exit = action == BUILD and (tasks[target].preserve_exit or _has_exit(engineer.cell))
		var adjacent := _choose_work_cell(target)
		if adjacent == NONE:
			var reachable := false
			for direction: Vector2i in GridNavigation.DIRECTIONS:
				if not GridNavigation.find_path(grid, engineer.cell, target + direction).is_empty():
					reachable = true
			_block(target, UNSAFE_EXIT if action == BUILD and reachable else "Obra inacessível: nenhuma célula ortogonal adjacente tem caminho.")
			continue
		active = target
		work_cell = adjacent
		tasks[target].status = "Deslocando"
		tasks[target].reason = ""
		engineer.construction_busy = true
		engineer.work_action = action
		engineer.move_for_task(work_cell)
		changed.emit()
		return

func _work_reason() -> String:
	# Travel may cross the still-walkable blueprint to reach the safe side.
	# Occupation must be checked once travel finishes, before work/completion.
	var reason := target_reason(active, tasks[active].action, engineer.route.is_empty())
	if not reason.is_empty():
		return reason
	if not grid.is_walkable(work_cell):
		return "Posição de trabalho bloqueada por uma parede."
	var difference := work_cell - active
	if absi(difference.x) + absi(difference.y) != 1:
		return "Posição de trabalho não é ortogonal adjacente."
	if tasks[active].action == BUILD:
		# Preserve the obligation from dispatch even if access changes in transit.
		# Also enforce any exit that has become available since dispatch.
		if (tasks[active].preserve_exit or _has_exit(work_cell)) and not _has_exit(work_cell, active):
			return UNSAFE_EXIT
	return ""

func _process(delta: float) -> void:
	if active == NONE:
		_schedule()
		return
	var reason := _work_reason()
	if not reason.is_empty():
		_block(active, reason)
		return
	if not engineer.route.is_empty():
		return
	if engineer.cell != work_cell or engineer.position != grid.center(work_cell):
		_block(active, "A rota até a obra foi invalidada; aguardando novo acesso.")
		return
	# Revalidate occupancy and adjacency before starting and on every work tick,
	# including the completion tick. Only a completed task changes navigation.
	if not engineer.working:
		engineer.working = true
		tasks[active].status = "Demolindo" if tasks[active].action == DEMOLISH else "Construindo"
		changed.emit()
		return
	tasks[active].elapsed += maxf(delta, 0.0)
	if tasks[active].elapsed >= work_seconds():
		var completed := active
		var success := grid.remove_wall(completed) if tasks[completed].action == DEMOLISH else grid.add_wall(completed)
		if success:
			tasks.erase(completed)
			blueprints.erase(completed)
			_release_worker()
		else:
			_block(completed, "O alvo mudou antes da conclusão.")
	changed.emit()

func progress() -> float:
	if active == NONE:
		return 0.0
	return clampf(float(tasks[active].elapsed) / work_seconds(), 0.0, 1.0)

func work_seconds() -> float:
	return GameSettings.WALL_DEMOLISH_SECONDS if tasks[active].action == DEMOLISH else GameSettings.WALL_BUILD_SECONDS

func blocked_text() -> String:
	var lines: PackedStringArray = []
	for target: Vector2i in tasks:
		if tasks[target].status == "Bloqueada":
			lines.append("%s (%d, %d): %s" % [tasks[target].action, target.x, target.y, tasks[target].reason])
	return "\n".join(lines) if not lines.is_empty() else "Nenhum bloqueio."
