extends CharacterBody2D


const SPEED = 800.0
const JUMP_VELOCITY = -1200.0
const TERMINAL_FALL_VELOCITY = 2000
@onready var coyote_timer = $CoyoteTimer
@onready var main_sprite: AnimatedSprite2D = $MainSprite

func on_enter():
	print("player on_enter")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		if velocity.y < 0:
			velocity += get_gravity() * delta
		elif velocity.y != TERMINAL_FALL_VELOCITY:
			setAnimationNoRepeats("descend")
			# faster drop down after reaching apex, add terminal fall velocity
			velocity += get_gravity() * delta * 3
			velocity.y = min(velocity.y, TERMINAL_FALL_VELOCITY)
	
	# Handle jump.
	var jumpedThisFrame = false
	if Input.is_action_just_pressed("Jump") and (is_on_floor() or !coyote_timer.is_stopped()):
		jumpedThisFrame = true
		setAnimationNoRepeats("ascend")
		velocity.y = JUMP_VELOCITY
	# enable short jumps by releasing jump early
	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y = JUMP_VELOCITY / 4
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("Move_Left", "Move_Right")
	if direction:
		velocity.x = direction * SPEED
		if direction > 0:
			main_sprite.flip_h = false
		elif direction < 0:
			main_sprite.flip_h = true
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if is_on_floor() and not jumpedThisFrame:
		if direction:
			setAnimationNoRepeats("run")
		if velocity.length_squared() < 10:
			setAnimationNoRepeats("idle")
	
	# Coyote Time logic
	var was_on_floor = is_on_floor()

	move_and_slide()
	
	if was_on_floor && !is_on_floor():
		coyote_timer.start()

func setAnimationNoRepeats(animation: String):
	if main_sprite.animation != animation:
		main_sprite.animation = animation
