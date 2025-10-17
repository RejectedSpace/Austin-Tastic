extends CharacterBody2D

@onready var animation = $AnimatedSprite2D
@onready var coyote_timer = $CoyoteTimer
@onready var glitch_timer = $GlitchTimer
@onready var dash_timer = $DashTimer
@onready var windup_timer = $WindupTimer
@onready var attack_timer = $AttackTimer
@onready var cooldown_timer = $CooldownTimer

const MAX_SPEED = 500
const MOVE_ACCEL = 600
const JUMP_SPEED = 650
const FRICTION = MAX_SPEED * 3
const AIR_RESISTANCE = FRICTION*0.3
const MAX_JUMPS = 2
const AIR_JUMP_OFFSET = 50
var jumps = MAX_JUMPS
var cooldown = false
var attack = "dash"
var glitchy = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var dash_direction: String
var starting_position: Vector2

func _ready() -> void:
	starting_position = position

func _physics_process(delta: float):
	apply_gravity(delta)
	var direction = Input.get_axis("left", "right")
	if !cooldown:
		handle_crouch()
		handle_jump(direction)
		
		if direction and not changed_direction(direction):
			if is_on_floor():
				handle_movement(direction, delta)
				handle_dash()
			else:
				handle_air_movement(direction, delta)
		else:
			if is_on_floor():
				apply_friction(delta)
				handle_dash()
			else:
				apply_air_resistance(delta)
		
		if Input.is_action_just_pressed("attack"):
			handle_attack(direction)
	else:
		if is_on_floor():
			apply_friction(delta)
			if attack == "dash" and not attack_timer.is_stopped():
				attack_timer.stop()
				attack_timer.timeout.emit()
		else:
			apply_air_resistance(delta)
	apply_animations(direction)
	
	var was_on_floor = is_on_floor()
	move_and_slide()
	if was_on_floor and not is_on_floor() and jumps == MAX_JUMPS:
		coyote_timer.start()
	
	if position.y > ProjectSettings.get_setting("display/window/size/viewport_height") * 1.25:
		position = starting_position

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
		if Input.is_action_just_released("jump") and velocity.y < -JUMP_SPEED*0.5:
			velocity.y = -JUMP_SPEED*0.5
		if Input.is_action_just_pressed("jump") and jumps > 0:
			jump(direction)

func handle_crouch() -> void:
	set_collision_mask_value(3, not Input.is_action_pressed("down"))

func jump(direction: float) -> void:
	velocity.y = -JUMP_SPEED
	jumps -= 1
	if changed_direction(direction):
		if is_on_floor() and direction:
			velocity.x *= -0.5
		else:
			velocity.x = 0
	if not is_on_floor() and coyote_timer.is_stopped(): 
		emit_air_particles()

func emit_air_particles() -> void:
	air_jump.emit(Vector2(position.x - AIR_JUMP_OFFSET*cos(velocity.angle()), position.y - AIR_JUMP_OFFSET*sin(velocity.angle())), PI/2 + velocity.angle())

func handle_movement(direction: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, MAX_SPEED*direction, MOVE_ACCEL*delta)

func handle_dash() -> void:
	if Input.is_action_just_pressed("left"):
		if not dash_timer.is_stopped() and dash_direction == "left" and velocity.x > -MAX_SPEED*.5:
			velocity.x = -MAX_SPEED*1.25
			emit_air_particles()
		dash_direction = "left"
		dash_timer.start()
	if Input.is_action_just_pressed("right"):
		if not dash_timer.is_stopped() and dash_direction == "right" and velocity.x < MAX_SPEED*.5:
			velocity.x = MAX_SPEED*1.25
			emit_air_particles()
		dash_direction = "right"
		dash_timer.start()

func handle_air_movement(direction: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, MAX_SPEED*direction, MOVE_ACCEL*delta)

func apply_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, FRICTION*delta)

func apply_air_resistance(delta: float) -> void:
	var reduce = 0 if cooldown and attack == "dash" else 1 
	velocity.x = move_toward(velocity.x, 0, AIR_RESISTANCE*reduce*delta)

func changed_direction(direction: float) -> bool:
	return direction * velocity.x < 0

func handle_attack(direction: float) -> void:
	if is_on_floor() and abs(velocity.x) > MAX_SPEED*0.5:
		cooldown = true
		velocity.y = -JUMP_SPEED*0.4
		velocity.x = MAX_SPEED*direction*1.25
		attack = "dash"
		windup_timer.start(0.1)

func apply_animations(direction: float) -> void:
	if cooldown:
		if attack == "dash":
			animation.play("Attack")
	else:
		if direction:
			animation.flip_h = direction > 0
			animation.offset.x = 32 if direction > 0 else 0
			animation.play("Walk")
			animation.speed_scale = velocity.x/MAX_SPEED*5
		else:
			animation.play("Idle")
			animation.speed_scale = 1
			easter()
			if glitchy == true:
				animation.play("Glitch")
		if not is_on_floor():
			if velocity.y <= 0:
				animation.play("Rise")
			else:
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

func _on_windup_timer_timeout() -> void:
	match attack:
		"dash":
			$DashAttack.visible = true
			attack_timer.start(1.25)

func _on_attack_timer_timeout() -> void:
	match attack:
		"dash":
			$DashAttack.visible = false
			cooldown_timer.start(0.5)

func _on_cooldown_timer_timeout() -> void:
	cooldown = false

signal air_jump
