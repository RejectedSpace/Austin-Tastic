extends CharacterBody2D

@onready var animation = $AnimatedSprite2D
@onready var coyote_timer = $Timer
@onready var glitch_timer = $Timer2

const MAX_SPEED = 500
const MOVE_ACCEL = 600
const JUMP_SPEED = 500
const FRICTION = 1500
const AIR_RESISTANCE = FRICTION*0.3
const MAX_JUMPS = 2
var jumps = MAX_JUMPS
var glitchy = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float):
	apply_gravity(delta)
	
	var direction = Input.get_axis("left", "right")
	handle_crouch()
	handle_jump(direction)
	handle_movement(direction, delta)
	handle_air_movement(direction, delta)
	apply_friction(direction, delta)
	apply_air_resistance(direction, delta)
	apply_animations(direction)
	
	var was_on_floor = is_on_floor()
	move_and_slide()
	if was_on_floor and not is_on_floor() and jumps == MAX_JUMPS:
		coyote_timer.start()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity*delta

func handle_jump(direction: float) -> void:
	if is_on_floor():
		jumps = MAX_JUMPS
	if is_on_floor() or not coyote_timer.is_stopped():
		if Input.is_action_just_pressed("jump"):
			jump(direction)
	elif not is_on_floor():
		if Input.is_action_just_released("jump") and velocity.y < JUMP_SPEED*0.5:
			velocity.y = -JUMP_SPEED*0.5
		if Input.is_action_just_pressed("jump") and jumps > 0:
			jump(direction)

func handle_crouch() -> void:
	set_collision_mask_value(3, not Input.is_action_pressed("down"))

func jump(direction: float) -> void:
	velocity.y = -JUMP_SPEED
	jumps -= 1
	if direction * velocity.x <= 0:
		velocity.x = 0

func handle_movement(direction: float, delta: float) -> void:
	if direction and is_on_floor():
		velocity.x = move_toward(velocity.x, MAX_SPEED*direction, MOVE_ACCEL*delta)

func handle_air_movement(direction: float, delta: float) -> void:
	if direction and not is_on_floor():
		velocity.x = move_toward(velocity.x, MAX_SPEED*direction, MOVE_ACCEL*delta)

func apply_friction(direction: float, delta: float) -> void:
	if not direction and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, FRICTION*delta)

func apply_air_resistance(direction: float, delta: float) -> void:
	if not direction and not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, AIR_RESISTANCE*delta)

func apply_animations(direction: float) -> void:
	if direction:
		animation.flip_h = direction > 0
		animation.play("Walk")
	else:
		animation.play("Idle")
		easter()
		if glitchy == true:
			animation.play("Glitch")
	if not is_on_floor():
		if velocity.y <= 0:
			animation.play("Rise")
		if velocity.y > 0:
			animation.play("Fall")

func easter():
	if randi() % 1000 == 69:
		glitch_timer.start()
		glitchy = true
		
func _on_timer_timeout() -> void:
	if jumps == MAX_JUMPS:
		jumps -= 1

func _on_timer_2_timeout() -> void:
	glitchy = false
