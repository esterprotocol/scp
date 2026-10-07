class_name SimClock
extends Node

# Fixed-step simulation clock. All gameplay state advances only through
# `ticked`; rendering reads `alpha()` to interpolate between ticks.

signal ticked(tick: int)

const TICK_SECONDS := 1.0 / GameSettings.SIM_TICK_HZ

var tick := 0
var paused := false
var speed := 1
var _accumulator := 0.0

func set_speed(value: int) -> bool:
	if not GameSettings.SIM_SPEEDS.has(value):
		return false
	speed = value
	return true

func alpha() -> float:
	return clampf(_accumulator / TICK_SECONDS, 0.0, 1.0)

# Test and replay entry point: runs exactly `count` ticks, ignoring pause.
func advance(count: int) -> void:
	for _i in count:
		tick += 1
		ticked.emit(tick)

func reset() -> void:
	tick = 0
	paused = false
	speed = 1
	_accumulator = 0.0

func _process(delta: float) -> void:
	if paused:
		return
	_accumulator += maxf(delta, 0.0) * speed
	var executed := 0
	while _accumulator >= TICK_SECONDS and executed < GameSettings.SIM_MAX_TICKS_PER_FRAME:
		_accumulator -= TICK_SECONDS
		executed += 1
		advance(1)
	# Drop backlog beyond the cap instead of spiralling after a long frame.
	if _accumulator >= TICK_SECONDS:
		_accumulator = fmod(_accumulator, TICK_SECONDS)
