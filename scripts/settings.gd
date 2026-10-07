class_name GameSettings
extends RefCounted

const GRID_SIZE := Vector2i(24, 24)
const GODOT_VERSION := "4.6.3.stable.official.7d41c59c4"
const CELL_SIZE := 32
const ENGINEER_SPEED := 128.0
const WALL_BUILD_SECONDS := 2.0
const SPAWN := Vector2i(4, 5)
const EXIT_CELL := SPAWN
const WALL_DEMOLISH_SECONDS := 1.5
const DOOR_INSTALL_SECONDS := 1.5
const OBJECT_INSTALL_SECONDS := 2.0
const OBJECT_DEMOLISH_SECONDS := 1.5
const CAMERA_SPEED := 420.0
const ZOOM_MIN := 0.65
const ZOOM_MAX := 1.8
const INITIAL_ZOOM := 0.9
const INITIAL_MAP_MARGIN := 24.0
const INITIAL_CAMERA := Vector2(320, 384)
const CLASSD_SPAWN := Vector2i(5, 7)
const CLASSD_SPEED := 96.0
const CLASSD_INITIAL_NEEDS := 100.0
const CLASSD_NEED_THRESHOLD := 35.0
const CLASSD_SIMULATION_SPEED := 1.0
const CLASSD_HUNGER_DECAY := 0.12 # Points per simulated second.
const CLASSD_REST_DECAY := 0.08
const CLASSD_MEAL_SECONDS := 8.0
const CLASSD_REST_SECONDS := 12.0
const CHARACTER_WALK_RATE := 11.0
const CHARACTER_WORK_RATE := 9.0
const CHARACTER_IDLE_RATE := 2.5
const CHARACTER_STEP := 1.5

const SELECTION_RADIUS := 15.0
