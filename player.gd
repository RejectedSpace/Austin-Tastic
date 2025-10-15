extends CharacterBody2D

@onready var coyote_timer = $Timer
@onready var jump_timer = $Timer2

const MOVE_SPEED = 500
const MOVE_ACCEL = 600
const JUMP_SPEED = 350
const FRICTION = 1500
const GRAV = 900
const NUM_JUMPS = 2
var jumps = NUM_JUMPS
var was_on_floor = false
var direction = 0

func _physics_process(delta: float):
	handle_movement(delta)
	handle_jump()
	handle_gravity(delta)
	handle_crouch()
	
	move_and_slide()
	
	if position.y > 648:
		position = Vector2(577, 322)

func handle_movement(delta: float) -> void:
	direction = Input.get_axis("left","right")
	var slowdown = direction * velocity.x <= 0
	var accel = FRICTION if slowdown else MOVE_ACCEL
	if not is_on_floor() and slowdown:
		accel *= .3
		
	if direction:
		velocity.x = move_toward(velocity.x, MOVE_SPEED*direction, accel*delta)
		$Sprite2D.scale.x = abs($Sprite2D.scale.x)*(-direction)
		$Sprite2D.position.x = 0.5 + 11.5*direction
	else:
		velocity.x = move_toward(velocity.x, 0, accel*delta)

func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and jumps > 0:
		velocity.y = -JUMP_SPEED
		jumps -= 1;
		if direction * velocity.x <= 0:
			velocity.x = 0
	
	if not is_on_floor():
		if coyote_timer.is_stopped() and jumps == NUM_JUMPS:
			coyote_timer.start(.3)
	else:
		jumps = NUM_JUMPS

func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		if Input.is_action_pressed("jump") and velocity.y < -200:
			velocity.y += GRAV*delta*.3
		else:
			velocity.y += GRAV*delta

func handle_crouch() -> void:
	set_collision_mask_value(3, not Input.is_action_pressed("down"))

func _on_timer_timeout() -> void:
	if jumps == NUM_JUMPS:
		jumps -= 1
