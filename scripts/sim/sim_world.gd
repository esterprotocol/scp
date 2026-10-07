class_name SimWorld
extends Node

# Owns the simulation core and drives it from the clock. Agents tick in
# ascending id order, which keeps runs deterministic.

signal agent_added(id: int)
signal agent_removed(id: int)

var grid: GridState
var clock := SimClock.new()
var registry := Registry.new()
var reservations := Reservations.new()
var agents: Dictionary = {} # id -> Agent

func setup(state: GridState) -> void:
	grid = state
	if clock.get_parent() == null:
		add_child(clock)
		clock.ticked.connect(_on_tick)

func spawn_agent(kind: StringName, start: Vector2i) -> Agent:
	var agent := Agent.new()
	agent.id = registry.create(kind)
	var problem := agent.place(grid, reservations, start)
	if not problem.is_empty():
		registry.destroy(agent.id)
		return null
	agents[agent.id] = agent
	agent_added.emit(agent.id)
	return agent

func remove_agent(id: int) -> void:
	if not agents.has(id):
		return
	agents[id].remove(reservations)
	agents.erase(id)
	registry.destroy(id)
	agent_removed.emit(id)

func is_alive(id: int) -> bool:
	return agents.has(id)

func reset() -> void:
	for id: int in agents.keys():
		remove_agent(id)
	reservations.clear()
	registry.reset()
	clock.reset()

func _on_tick(tick: int) -> void:
	reservations.expire(tick)
	var ids: Array = agents.keys()
	ids.sort()
	for id: int in ids:
		agents[id].tick(grid, reservations)
