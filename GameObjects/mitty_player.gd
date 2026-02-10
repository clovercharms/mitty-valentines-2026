class_name MittyPlayer extends CharacterBody2D

@export_group("Move")
@export var speed: float = 900.0
@export var accelerationBoostThreshold: float = 550
@export var acceleration: float = 2500
@export var boostedAcceleration: float = 8000
@export var airControl: float = 0.8
@export var jumpSpeed: float = -1200.0
@export var terminalFallSpeed: float = 2000
@export var controllerTopEnd: float = 0.7

@export_group("Attack")
@export var attackMovementSpeed: float = 1200
@export var attackDrag: float = 2500
@export var attackTime: float = 0.25
@export var attackCooldownTime: float = 0.35
@export var sideAttackScene: PackedScene
@export var verticalAttackScene: PackedScene
@export var pogoSpeed: float = -1000

@export_group("Flinch")
@export var flinchGroundVelocity: Vector2 = Vector2(-500, -150)
@export var flinchAirVelocity: Vector2 = Vector2(-500, 0)
@export var flinchTime: float = 0.3
@export var hitstopTime: float = 0.2

@export_group("Death")
@export var ghostAnimDelay: float = 1.5
@export var ghostScene: PackedScene
@export var deathLaunchVelocity: Vector2 = Vector2(-750, -400)
@export var deathDrag: float = 1200
@export var deathTimeSlowAmount: float = 0.2
@export var deathTimeSlowDuration: float = 1

@onready var coyote_timer: Timer = $CoyoteTimer
@onready var main_sprite: AnimatedSprite2D = $MainSprite
@onready var camera: Camera2D = $Camera2D
@onready var sideAttackLocation: Node2D = $SideAttackLocation
@onready var verticalAttackLocation: Node2D = $VerticalAttackLocation
@onready var feetLocation: Node2D = $FeetLocation
@onready var ghostLocation: Node2D = $GhostLocation

enum ControlState { MOVE, ATTACK, FLINCH, DEAD }

var currentState: ControlState = ControlState.MOVE
var stateTimer: SceneTreeTimer
var lastMoveDirection: float = 1

var attackCooldownTimer: SceneTreeTimer
var currentAttackIsPogo: bool = false
var currentAttackIsUp: bool = false
@onready var damage_timer = $DamageTimer

# double jump
@onready var can_double_jump = true
var has_double_jumped = false

var has_control : bool = true

var reset_position : Marker2D


func on_enter():
	var roomInstance = GameBase.get_singleton().map.find_child("RoomInstance")
	if roomInstance:
		roomInstance.adjust_camera_limits(camera)

func _ready() -> void:
	pass

func _enter_tree() -> void:
	attackCooldownTimer = get_tree().create_timer(0, true, true)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Attack") and attackCooldownTimer.time_left <= 0 and has_control:
		enter_attack()
	
	update_gravity(delta)
	
	if currentState == ControlState.DEAD:
		#being dead takes precendence over all other states
		update_dead(delta)
	elif not has_control:
		pass
	elif currentState == ControlState.MOVE:
		update_move(delta)
	elif currentState == ControlState.ATTACK:
		update_attack(delta)
	elif currentState == ControlState.FLINCH:
		update_flinch()
	else:
		print("Warning! Player in unknown ControlState")
	
	# Coyote Time logic
	var was_on_floor = is_on_floor()
	
	move_and_slide()
	
	if was_on_floor && !is_on_floor():
		coyote_timer.start()
	
	if is_on_floor and not was_on_floor:
		#play landing effects
		pass

func enter_move():
	if currentState == ControlState.DEAD:
		return
	currentState = ControlState.MOVE

func update_move(delta: float):
	# Handle jump.
	var jumpedThisFrame = false
	if Input.is_action_just_pressed("Jump") and canJump() and has_control:
		jumpedThisFrame = true
		setAnimationNoRepeats("ascend")
		velocity.y = jumpSpeed
	# enable short jumps by releasing jump early
	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y = jumpSpeed / 4
	
	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("Move_Left", "Move_Right")
	direction = MittyUtils.map_range_clamped(direction, -controllerTopEnd, controllerTopEnd, -1, 1)
	
	var currentAcceleration = acceleration
	if abs(velocity.x) < accelerationBoostThreshold:
		currentAcceleration = boostedAcceleration
	if not is_on_floor():
		currentAcceleration *= airControl
	velocity.x = move_toward(velocity.x, direction * speed, currentAcceleration * delta)
	
	if direction:
		if direction > 0:
			lastMoveDirection = 1
			main_sprite.flip_h = false
		elif direction < 0:
			lastMoveDirection = -1
			main_sprite.flip_h = true
	else:
		velocity.x = move_toward(velocity.x, 0, currentAcceleration * delta)
	
	if is_on_floor() and not jumpedThisFrame:
		if direction:
			setAnimationNoRepeats("run")
		if abs(velocity.x) < 1:
			setAnimationNoRepeats("idle")

func enter_attack():
	if currentState == ControlState.DEAD:
		return
	currentState = ControlState.ATTACK
	currentAttackIsPogo = false
	currentAttackIsUp = false
	var lookDirection = Input.get_axis("Look_Down", "Look_Up")
	var moveDirection = Input.get_axis("Move_Left", "Move_Right")
	if lookDirection > 0:
		if canJump():
			velocity.y = -attackMovementSpeed
		setAnimationNoRepeats("attack_up")
		currentAttackIsUp = true
		velocity.x *= 0.5
		
		MittyUtils.spawn_child(self, verticalAttackScene, verticalAttackLocation.position)
	elif lookDirection < 0:
		velocity.y = move_toward(velocity.y, terminalFallSpeed, attackMovementSpeed)
		setAnimationNoRepeats("attack_down")
		
		var currentLoc = verticalAttackLocation.position
		currentLoc.y *= -1
		var spawnedAttack = MittyUtils.spawn_child(self, verticalAttackScene, currentLoc)
		spawnedAttack.scale.y *= -1
		
		spawnedAttack.body_entered.connect(on_down_attack_connected)
	else:
		var attackDirection = lastMoveDirection
		if moveDirection > 0:
			attackDirection = 1
		if moveDirection < 0:
			attackDirection = -1
		velocity.x = attackDirection * attackMovementSpeed
		if velocity.y > 0:
			velocity.y = 0
		elif not is_on_floor():
			velocity.y = jumpSpeed / 4
		setAnimationNoRepeats("attack_side")
		
		var currentLoc = sideAttackLocation.position
		currentLoc.x *= attackDirection
		var spawnedAttack = MittyUtils.spawn_child(self, sideAttackScene, currentLoc)
		spawnedAttack.scale.x *= attackDirection
	main_sprite.set_frame(0)
	main_sprite.play()
	
	attackCooldownTimer = get_tree().create_timer(attackCooldownTime, true, true)
	
	# play audio cue

func update_attack(delta: float):
	if not currentAttackIsPogo:
		velocity.x = move_toward(velocity.x, 0, attackDrag * delta)

func enter_flinch(hurtLocation: Vector2):
	if currentState == ControlState.DEAD:
		return
	currentState = ControlState.FLINCH
	stateTimer = get_tree().create_timer(flinchTime, true, true)
	setAnimationNoRepeats("hurt")
	MittyUtils.hit_stop(hitstopTime)
	if not hurtLocation:
		velocity = Vector2.ZERO
		return
	var hurtDirection: float = 1
	var toHurt = hurtLocation - global_position
	if(toHurt.x < 0):
		hurtDirection = -1
	var currentFlinchVel = flinchGroundVelocity
	if not is_on_floor():
		currentFlinchVel = flinchAirVelocity
	currentFlinchVel.x *= hurtDirection
	velocity = currentFlinchVel

func update_flinch():
	if stateTimer.time_left <= 0:
		enter_move()

func update_dead(delta: float):
	velocity.x = move_toward(velocity.x, 0, deathDrag * delta)

func update_gravity(delta: float):
	if not is_on_floor():
		if velocity.y < 0:
			velocity += get_gravity() * delta
			if currentState == ControlState.MOVE:
				setAnimationNoRepeats("ascend")
		elif velocity.y != terminalFallSpeed:
			
			# faster drop down after reaching apex, add terminal fall velocity
			#velocity += get_gravity() * delta * 3
			#velocity.y = min(velocity.y, terminalFallSpeed)
			velocity.y = move_toward(velocity.y, terminalFallSpeed, get_gravity().y * delta * 3)
		if velocity.y > 0 and currentState == ControlState.MOVE:
			setAnimationNoRepeats("descend")

func canJump() -> bool:
	return is_on_floor() or !coyote_timer.is_stopped()

func setAnimationNoRepeats(animation: String):
	if main_sprite.animation != animation:
		main_sprite.play(animation)

func on_down_attack_connected(body: Node2D) -> void:
	if body.is_in_group("triggersPogo") and not currentAttackIsPogo:
		print("Pogo!")
		currentAttackIsPogo = true;
		velocity.y = pogoSpeed

func _on_main_sprite_animation_finished() -> void:
	if currentState == ControlState.ATTACK:
		enter_move()
		if currentAttackIsUp and velocity.y < 0:
			velocity.y = jumpSpeed / 4
			
func tween_to_reset_marker() -> void:
	if reset_position == null:
		return
	change_player_agency(false)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", reset_position.global_position, 0.5)
	tween.tween_property(self, "rotation_degrees", 360 * 10, 0.5)
	await tween.finished
	rotation_degrees = 0
	change_player_agency(true)
	
func change_player_agency(controllable : bool) -> void:
	has_control = controllable
	main_sprite.stop()
	enter_move()

func _on_hurt(_amount: int, cause: Node) -> void:
	if cause and "global_position" in cause:
		print("hurt from ", cause.global_position)
		enter_flinch(cause.global_position)
	else:
		enter_flinch(Vector2.ZERO)

func _on_death(cause: Node) -> void:
	setAnimationNoRepeats("dead")
	currentState = ControlState.DEAD
	if cause and "global_position" in cause:
		var hurtDirection: float = 1
		var toHurt = cause.global_position - global_position
		if(toHurt.x < 0):
			hurtDirection = -1
		var currentLaunchVel = deathLaunchVelocity
		currentLaunchVel.x *= hurtDirection
		velocity = currentLaunchVel
	
	MittyUtils.time_slow(deathTimeSlowAmount, deathTimeSlowDuration)
	var ghostTimer = get_tree().create_timer(ghostAnimDelay)
	await ghostTimer.timeout
	MittyUtils.spawn_at_location(ghostScene, ghostLocation.global_position)
	#play ghost sound effect
