class_name CharacterVisual
extends Node2D

# Drawn locally so every worker can share the same silhouette and animation.
# Logic and save state remain in Engineer and ClassD.
var role := "engineer"
var activity := "idle"
var facing := Vector2i(0, 1)
var elapsed := 0.0
var previous_position := Vector2.ZERO
var position_initialized := false

func reset_pose(world_position: Vector2) -> void:
	previous_position = world_position
	position_initialized = true
	activity = "idle"
	facing = Vector2i(0, 1)
	elapsed = 0.0
	queue_redraw()

func tick(delta: float, world_position: Vector2, next_activity: String) -> void:
	if not position_initialized:
		reset_pose(world_position)
	var displacement := world_position - previous_position
	if displacement.length_squared() > 0.0001:
		if absf(displacement.x) > absf(displacement.y):
			facing = Vector2i(1 if displacement.x > 0.0 else -1, 0)
		else:
			facing = Vector2i(0, 1 if displacement.y > 0.0 else -1)
	previous_position = world_position
	if activity != next_activity:
		activity = next_activity
		elapsed = 0.0
	elapsed += maxf(delta, 0.0)
	queue_redraw()

func _draw() -> void:
	var walking := activity == "walk"
	var working := activity == "work"
	var eating := activity == "eat"
	var resting := activity == "rest"
	var step := sin(elapsed * GameSettings.CHARACTER_WALK_RATE) * GameSettings.CHARACTER_STEP if walking else 0.0
	var bob := absf(step) * 0.45 if walking else sin(elapsed * GameSettings.CHARACTER_IDLE_RATE) * 0.25
	if resting:
		bob = 2.0
	var side := facing.x
	var back := facing.y < 0
	var outline := Color("18252c")
	var skin := Color("ddb89a")
	var hair := Color("352d2c")
	var uniform := Color("daa84c") if role == "engineer" else Color("d76636")
	var shade := Color("846532") if role == "engineer" else Color("873b2b")
	var highlight := Color("f4cf73") if role == "engineer" else Color("f3965a")

	# The shadow remains on the floor while the body moves a fraction of a pixel.
	draw_circle(Vector2(0, 9), 8, Color(0.02, 0.06, 0.08, 0.38))
	var left_foot := Vector2(-4, 8 + step)
	var right_foot := Vector2(4, 8 - step)
	draw_rect(Rect2(left_foot + Vector2(-2, -2), Vector2(5, 5)), outline)
	draw_rect(Rect2(right_foot + Vector2(-2, -2), Vector2(5, 5)), outline)
	draw_rect(Rect2(left_foot + Vector2(-1, -2), Vector2(3, 3)), Color("35414a"))
	draw_rect(Rect2(right_foot + Vector2(-1, -2), Vector2(3, 3)), Color("35414a"))

	var torso_y := -3.0 + bob
	var arm_swing := sin(elapsed * GameSettings.CHARACTER_WORK_RATE) * 2.0 if working else step * 0.7
	var right_arm_y := torso_y + 2.0 - arm_swing
	if eating:
		right_arm_y = torso_y - 3.0 + sin(elapsed * GameSettings.CHARACTER_IDLE_RATE) * 0.8
	draw_rect(Rect2(-11, torso_y - 1, 5, 10), outline)
	draw_rect(Rect2(6, right_arm_y - 1, 5, 10), outline)
	draw_rect(Rect2(-10, torso_y, 3, 7), shade)
	draw_rect(Rect2(7, right_arm_y, 3, 7), shade)
	draw_rect(Rect2(-7, torso_y - 3, 14, 13), outline)
	draw_rect(Rect2(-6, torso_y - 2, 12, 11), uniform)
	draw_rect(Rect2(-6, torso_y + 5, 12, 2), shade)
	if role == "engineer":
		# Reflective vest strips and a small shoulder patch.
		draw_rect(Rect2(-5, torso_y, 2, 7), highlight)
		draw_rect(Rect2(3, torso_y, 2, 7), highlight)
		draw_rect(Rect2(-10, torso_y + 1, 2, 2), Color("dae6dd"))
	else:
		# An ID stripe stays visible at the normal management-game zoom.
		draw_rect(Rect2(-3, torso_y + 1, 6, 2), Color("f6d9b8"))
		draw_rect(Rect2(-3, torso_y + 4, 6, 1), shade)

	var head := Vector2(side * 1.5, torso_y - 7.0)
	draw_circle(head, 6.5, outline)
	draw_circle(head + Vector2(0, 0.5), 5.3, skin)
	if role == "engineer":
		draw_rect(Rect2(head + Vector2(-6, -6), Vector2(12, 3)), outline)
		draw_rect(Rect2(head + Vector2(-5, -6), Vector2(10, 2)), highlight)
		draw_rect(Rect2(head + Vector2(-7, -3), Vector2(14, 2)), uniform)
	else:
		draw_arc(head + Vector2(0, -1), 5.4, PI, TAU, 12, hair, 2.0, true)
		if back:
			draw_rect(Rect2(head + Vector2(-4, -4), Vector2(8, 4)), hair)
	if not back:
		if side == 0:
			draw_circle(head + Vector2(-2, 1), 0.8, outline)
			draw_circle(head + Vector2(2, 1), 0.8, outline)
		else:
			draw_circle(head + Vector2(side * 2, 1), 0.8, outline)
	if working:
		# A small tool makes construction readable even without a sprite sheet.
		var hand := Vector2(9, right_arm_y + 5)
		draw_line(hand, hand + Vector2(3, -5 - arm_swing), Color("a9bbc2"), 2.0)
		draw_line(hand + Vector2(1, -5 - arm_swing), hand + Vector2(6, -5 - arm_swing), Color("364b54"), 2.0)
