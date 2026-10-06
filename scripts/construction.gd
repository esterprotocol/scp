class_name Construction
extends Node

signal changed

const NONE := Vector2i(-1, -1)

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

func target_reason(target: Vector2i) -> String:
	if not grid.contains(target):
		return "Fora do mapa."
	if not grid.is_walkable(target):
		return "Já existe uma parede nessa célula."
	if engineer.occupies(target):
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

func authorize() -> String:
	var count := 0
	for target: Vector2i in blueprints:
		if not tasks.has(target):
			tasks[target] = {"status": "Na fila", "reason": "", "elapsed": 0.0}
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
	if not blueprints.has(target):
		return "Não há blueprint ou tarefa nessa célula."
	if active == target:
		_release_worker()
	tasks.erase(target)
	blueprints.erase(target)
	dirty = true
	changed.emit()
	return "Obra cancelada; blueprint e tarefa removidos."

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

func _choose_work_cell(target: Vector2i) -> Vector2i:
	var best := NONE
	var best_length := 100000
	for direction: Vector2i in GridNavigation.DIRECTIONS:
		var candidate := target + direction
		var path := GridNavigation.find_path(grid, engineer.cell, candidate)
		if not path.is_empty() and path.size() < best_length:
			best = candidate
			best_length = path.size()
	return best

func _schedule() -> void:
	if not dirty or not engineer.route.is_empty():
		return
	dirty = false
	for target: Vector2i in tasks:
		var reason := target_reason(target)
		if not reason.is_empty():
			_block(target, reason)
			continue
		var adjacent := _choose_work_cell(target)
		if adjacent == NONE:
			_block(target, "Obra inacessível: nenhuma célula ortogonal adjacente tem caminho.")
			continue
		active = target
		work_cell = adjacent
		tasks[target].status = "Deslocando"
		tasks[target].reason = ""
		engineer.construction_busy = true
		engineer.move_for_task(work_cell)
		changed.emit()
		return

func _work_reason() -> String:
	var reason := target_reason(active)
	if not reason.is_empty():
		return reason
	if not grid.is_walkable(work_cell):
		return "Posição de trabalho bloqueada por uma parede."
	var difference := work_cell - active
	if absi(difference.x) + absi(difference.y) != 1:
		return "Posição de trabalho não é ortogonal adjacente."
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
		tasks[active].status = "Construindo"
		changed.emit()
		return
	tasks[active].elapsed += maxf(delta, 0.0)
	if tasks[active].elapsed >= GameSettings.WALL_BUILD_SECONDS:
		var completed := active
		if grid.add_wall(completed):
			tasks.erase(completed)
			blueprints.erase(completed)
			_release_worker()
		else:
			_block(completed, "A célula deixou de estar livre antes da conclusão.")
	changed.emit()

func progress() -> float:
	if active == NONE:
		return 0.0
	return clampf(float(tasks[active].elapsed) / GameSettings.WALL_BUILD_SECONDS, 0.0, 1.0)

func blocked_text() -> String:
	var lines: PackedStringArray = []
	for target: Vector2i in tasks:
		if tasks[target].status == "Bloqueada":
			lines.append("(%d, %d): %s" % [target.x, target.y, tasks[target].reason])
	return "\n".join(lines) if not lines.is_empty() else "Nenhum bloqueio."
