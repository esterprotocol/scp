class_name SimTests
extends RefCounted

var runner: SceneTree

func check(condition: bool, description: String) -> void:
	runner.check(condition, "sim: " + description)

func open_grid() -> GridState:
	var grid := GridState.new()
	grid.walls.clear()
	grid.doors.clear()
	grid.areas.clear()
	grid.objects.clear()
	grid.reservations.clear()
	return grid

func new_world(grid: GridState) -> SimWorld:
	var world := SimWorld.new()
	world.setup(grid)
	return world

# Every agent holds exactly the keys of the cells it occupies, nothing else.
func invariants_ok(world: SimWorld) -> bool:
	var expected_total := 0
	var seen: Dictionary = {}
	for id: int in world.agents:
		var agent: Agent = world.agents[id]
		var expected: Array[String] = [Reservations.cell_key(agent.cell)]
		if agent.stepping():
			expected.append(Reservations.cell_key(agent.next_cell))
		expected.sort()
		if world.reservations.keys_of(id) != expected:
			return false
		expected_total += expected.size()
		for key in expected:
			if seen.has(key):
				return false
			seen[key] = true
	return world.reservations.holders.size() == expected_total

func run_checked(world: SimWorld, ticks: int) -> bool:
	var ok := true
	for _i in ticks:
		world.clock.advance(1)
		ok = ok and invariants_ok(world)
	return ok

func trace_scenario() -> String:
	var grid := open_grid()
	var world := new_world(grid)
	var first := world.spawn_agent(&"person", Vector2i(2, 2))
	var second := world.spawn_agent(&"person", Vector2i(1, 2))
	first.go_to(grid, Vector2i(8, 2))
	second.go_to(grid, Vector2i(7, 4))
	var lines: PackedStringArray = []
	for _i in 40:
		world.clock.advance(1)
		for id: int in world.agents:
			var agent: Agent = world.agents[id]
			lines.append("%d:%d:%s>%s" % [world.clock.tick, id, agent.cell, agent.next_cell])
	world.free()
	return "\n".join(lines)

func run(harness: SceneTree) -> void:
	runner = harness
	run_clock()
	run_registry()
	run_reservations()
	run_agents()

func run_clock() -> void:
	var clock := SimClock.new()
	var count := [0]
	clock.ticked.connect(func(_tick: int) -> void: count[0] += 1)
	clock._process(0.105)
	check(clock.tick == 1 and count[0] == 1, "one frame of 105 ms runs one 100 ms tick")
	check(clock.alpha() > 0.0 and clock.alpha() < 1.0, "fractional progress is exposed for interpolation")
	clock.reset()
	check(clock.set_speed(4) and not clock.set_speed(3) and clock.speed == 4, "only configured speeds are accepted")
	clock._process(0.105)
	check(clock.tick == 4, "4x speed runs four ticks per 105 ms")
	clock.reset()
	clock.paused = true
	clock._process(5.0)
	check(clock.tick == 0, "paused clock never ticks")
	clock.paused = false
	clock._process(-3.0)
	check(clock.tick == 0, "negative delta is ignored")
	clock._process(10.0)
	check(clock.tick == GameSettings.SIM_MAX_TICKS_PER_FRAME, "a long frame is capped")
	check(clock.alpha() < 1.0, "backlog beyond the cap is dropped")
	clock.reset()
	clock.advance(5)
	check(clock.tick == 5, "advance runs exact ticks for tests and replays")
	clock.free()

func run_registry() -> void:
	var registry := Registry.new()
	var first := registry.create(&"person")
	var second := registry.create(&"object")
	var third := registry.create(&"person")
	check(first != second and second != third and first < second and second < third, "ids are unique and increasing")
	check(registry.kind_of(second) == &"object" and registry.ids_of(&"person") == [first, third], "kind lookup")
	check(registry.destroy(first) and not registry.exists(first) and not registry.destroy(first), "destroy once")
	check(registry.create(&"person") > third, "ids are never reused")
	check(registry.kind_of(9999) == &"" and not registry.exists(9999), "unknown id has no kind")
	registry.reset()
	check(registry.create(&"person") == 1, "reset restarts numbering")

func run_reservations() -> void:
	var res := Reservations.new()
	var events := [0]
	res.changed.connect(func() -> void: events[0] += 1)
	var a := Reservations.cell_key(Vector2i(1, 1))
	var b := Reservations.cell_key(Vector2i(2, 1))
	var obj := Reservations.object_key(1)
	check(a != obj and Reservations.cell_key(Vector2i(1, 1)) == a, "cell and object keys never collide")
	check(res.reserve_all(1, [a, b]).ok and res.keys_of(1) == [a, b], "reserve several keys")
	check(events[0] == 1, "one change event per reservation batch")
	check(res.reserve_all(1, [a]).ok and events[0] == 1, "re-reserving own key is a no-op")
	var denied := res.reserve_all(2, [obj, b])
	check(not denied.ok and denied.key == b and denied.holder == 1 and not denied.reason.is_empty(), "denial names key and holder")
	check(res.owner_of(obj) == Reservations.NO_OWNER, "reservation is all-or-nothing")
	check(not res.release(2, a) and res.holds(1, a), "only the owner can release")
	check(res.release(1, a) and res.owner_of(a) == Reservations.NO_OWNER, "owner releases a key")
	check(res.reserve_all(2, [a]).ok, "released key is reservable")
	res.reserve_all(3, [obj], 10)
	check(res.expire(10).is_empty() and res.owner_of(obj) == 3, "reservation lives through its last tick")
	check(res.expire(11) == [obj] and res.owner_of(obj) == Reservations.NO_OWNER, "expired reservation is freed")
	var alive := func(owner: int) -> bool: return owner != 2
	check(res.orphans(alive) == [a], "orphan scan finds reservations of dead owners")
	check(res.release_owner(2) == 1 and res.release_owner(2) == 0, "release_owner frees everything once")
	res.clear()
	check(res.holders.is_empty() and res.expiry.is_empty(), "clear")

func run_agents() -> void:
	var grid := open_grid()
	var world := new_world(grid)
	var agent := world.spawn_agent(&"person", Vector2i(2, 2))
	check(agent != null and agent.cell == Vector2i(2, 2) and world.registry.kind_of(agent.id) == &"person", "spawn registers an id")
	check(world.reservations.keys_of(agent.id) == [Reservations.cell_key(Vector2i(2, 2))], "spawn claims its cell")
	check(world.spawn_agent(&"person", Vector2i(2, 2)) == null and world.registry.ids_of(&"person").size() == 1, "occupied spawn is refused and leaks no id")
	check(world.spawn_agent(&"person", Vector2i(-1, 0)) == null, "spawn outside the map is refused")
	check(agent.go_to(grid, Vector2i(7, 2)) == "" and agent.route.size() == 5, "route planned")
	var steps := GameSettings.AGENT_STEP_TICKS
	check(run_checked(world, 5 * steps), "claims stay consistent during a straight walk")
	check(agent.cell != Vector2i(7, 2), "five cells need more than five steps of ticks")
	world.clock.advance(1)
	check(agent.cell == Vector2i(7, 2) and agent.route.is_empty() and not agent.stepping(), "arrives on the exact tick")
	check(world.reservations.keys_of(agent.id) == [Reservations.cell_key(Vector2i(7, 2))], "only the final cell stays claimed")
	check(agent.go_to(grid, Vector2i(24, 0)).contains("fora") and agent.go_to(grid, Vector2i(7, 2)) == "", "invalid orders are refused")

	var sealed := GridState.new()
	sealed.objects.clear()
	var sealed_world := new_world(sealed)
	var locked := sealed_world.spawn_agent(&"person", Vector2i(4, 5))
	check(locked.go_to(sealed, Vector2i(19, 19)).contains("inacessível"), "unreachable goal")
	check(locked.go_to(sealed, Vector2i(10, 5)).contains("não transitável"), "wall goal")
	var kept := locked.go_to(sealed, Vector2i(6, 5))
	check(kept == "" and locked.go_to(sealed, Vector2i(19, 19)) != "" and locked.route.size() == 2, "failed order keeps the current route")
	sealed_world.free()

	# Follower waits for the leader and neither overlaps.
	world.reset()
	grid = open_grid()
	world.grid = grid
	var leader := world.spawn_agent(&"person", Vector2i(2, 2))
	var follower := world.spawn_agent(&"person", Vector2i(1, 2))
	leader.go_to(grid, Vector2i(8, 2))
	follower.go_to(grid, Vector2i(7, 2))
	check(run_checked(world, 80), "leader and follower never share a cell")
	check(leader.cell == Vector2i(8, 2) and follower.cell == Vector2i(7, 2), "both arrive")
	world.reset()

	# A one-wide corridor head-on: no overlap, a readable deadlock.
	grid = open_grid()
	world.grid = grid
	for x in GameSettings.GRID_SIZE.x:
		for y in GameSettings.GRID_SIZE.y:
			if y != 5:
				grid.walls[Vector2i(x, y)] = true
	var east := world.spawn_agent(&"person", Vector2i(3, 5))
	var west := world.spawn_agent(&"person", Vector2i(10, 5))
	east.go_to(grid, Vector2i(14, 5))
	west.go_to(grid, Vector2i(1, 5))
	check(run_checked(world, 100), "head-on agents never overlap")
	check(east.blocked_ticks > 10 and west.blocked_ticks > 10, "deadlock is reported by blocked ticks")
	check(east.blocked_reason.contains("ocupada") and west.blocked_reason.contains("ocupada"), "deadlock has a readable reason")
	check(absi(east.cell.x - west.cell.x) == 1, "they stop adjacent")
	world.reset()

	# Cancelling mid-step finishes the step and never teleports.
	grid = open_grid()
	world.grid = grid
	var walker := world.spawn_agent(&"person", Vector2i(2, 2))
	walker.go_to(grid, Vector2i(12, 2))
	run_checked(world, 2)
	var committed := walker.next_cell
	walker.cancel()
	check(walker.stepping() and walker.route.is_empty() and walker.destination == committed, "cancel keeps the committed step")
	check(run_checked(world, 12), "claims stay consistent after cancel")
	check(walker.cell == committed and not walker.stepping(), "stops exactly on the committed cell")
	check(world.reservations.keys_of(walker.id) == [Reservations.cell_key(committed)], "cancel leaks no claim")

	# Re-planning during a step starts from the cell being entered.
	walker.go_to(grid, Vector2i(2, 8))
	run_checked(world, 1)
	var entering := walker.next_cell
	check(walker.go_to(grid, Vector2i(2, 2)) == "" and walker.route[0] != entering and absi(walker.route[0].x - entering.x) + absi(walker.route[0].y - entering.y) == 1, "replan starts from the next cell, orthogonally")
	var orthogonal := true
	var previous := walker.cell
	for _i in 120:
		world.clock.advance(1)
		if walker.cell != previous:
			var step := walker.cell - previous
			orthogonal = orthogonal and absi(step.x) + absi(step.y) == 1
			previous = walker.cell
	check(orthogonal and walker.cell == Vector2i(2, 2), "replanned walk stays orthogonal and arrives")

	# A wall appearing on the route blocks without corrupting state, then recovers.
	walker.go_to(grid, Vector2i(9, 2))
	run_checked(world, 4)
	var wall_cell := walker.route[1]
	grid.walls[wall_cell] = true
	check(run_checked(world, 20), "claims stay consistent when a wall appears")
	check(walker.blocked_reason.contains("não transitável") and not walker.cell == Vector2i(9, 2), "agent waits before the new wall")
	grid.walls.erase(wall_cell)
	check(run_checked(world, 30) and walker.cell == Vector2i(9, 2) and walker.blocked_reason.is_empty(), "agent resumes after the wall is gone")

	# Visual position stays on the segment between the two claimed cells.
	walker.go_to(grid, Vector2i(9, 6))
	world.clock.advance(1)
	var start := grid.center(walker.cell)
	var finish := grid.center(walker.next_cell)
	var inside := true
	for tick_index in GameSettings.AGENT_STEP_TICKS:
		var shown := walker.visual_position(grid, 0.5)
		inside = inside and is_equal_approx(shown.distance_to(start) + shown.distance_to(finish), start.distance_to(finish))
		world.clock.advance(1)
	check(inside, "visual position never leaves the step segment")
	world.reset()

	# Removing an agent frees its cells for others and the orphan scan stays clean.
	grid = open_grid()
	world.grid = grid
	var removed := world.spawn_agent(&"person", Vector2i(3, 3))
	var removed_id := removed.id
	world.remove_agent(removed_id)
	check(world.reservations.holders.is_empty() and not world.registry.exists(removed_id), "removal frees claims and id")
	var replacement := world.spawn_agent(&"person", Vector2i(3, 3))
	check(replacement != null and replacement.id != removed_id, "freed cell is reusable with a new id")
	check(world.reservations.orphans(world.is_alive).is_empty(), "no orphan reservations in normal operation")
	world.reservations.reserve_all(9999, [Reservations.object_key(5)])
	check(world.reservations.orphans(world.is_alive) == [Reservations.object_key(5)], "orphan scan detects a leak")
	world.reset()
	check(world.agents.is_empty() and world.reservations.holders.is_empty() and world.clock.tick == 0, "world reset")
	world.free()

	check(trace_scenario() == trace_scenario(), "identical scenarios produce identical traces")
