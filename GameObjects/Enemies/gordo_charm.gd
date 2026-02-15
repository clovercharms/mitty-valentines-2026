extends CharacterBody2D

@export_group("Wander")
@export var wanderSpeed: float = 250
@export var wanderAcceleration: float = 500
@export var wanderDirectionTimeMin: float = 1
@export var wanderDirectionTimeMax: float = 3
@export var aggroSound: AudioStream
@export_group("Charge")
@export var chargeYThreshold: float = 100
@export var chargeXAbort: float = -400
@export var chargeMinAbortTime: float = 1
@export var windupTime: float = 0.7
@export var chargeSpeed: float = 900
@export var chargePushVelocity: Vector2 = Vector2(1200, -100)
@export var chargePushCooldown: float = 0.2
@export var chargeBrakeAcceleration: float = 2000
@export var chargeCooldownMin: float = 1.5
@export var chargeCooldownMax: float = 3
@export var chargeMercyHits: int = 2
@export var chargeCry: AudioStream
@export_group("Stun")
@export var stunTime: float = 0.5
@export var stunLaunch: Vector2 = Vector2(-500, -500)
@export var stunBrakeAcceleration: float = 1000
@export_flags_2d_physics var stunWallCheckMask
@export_group("Player Sensing")
@export var sensingUpdateMin: float = 0.1
@export var sensingUpdateMax: float = 0.3
@export var sensingRange: float = 1000
@export var giveUpRange: float = 2000
@export_group("Death")
@export var deathEffect: PackedScene

const GORDO_DEBUG: bool = false

@onready var mainSprite: AnimatedSprite2D = $MainSprite
@onready var hitbox: Node = $Hitbox
@onready var crushShapecast: ShapeCast2D = $CrushShapecast
var crushCastBasePosition: Vector2

enum States { IDLE, WANDER, WINDUP, CHARGE, STUN }
var currentState: States = States.IDLE
var stateTimer: SceneTreeTimer
var sensingTimer: SceneTreeTimer
var chargeCooldownTimer: SceneTreeTimer
var chargePushCooldownTimer: SceneTreeTimer

var currentMoveDirection: float = 1
var chargeAborted: bool = false
var hitsSinceCharge: int = 0

func _ready() -> void:
	crushCastBasePosition = crushShapecast.position
	resetSensingTimer()
	resetChargePushTimer()
	enter_idle()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	#state machine
	match currentState:
		States.IDLE:
			update_idle(delta)
		States.WANDER:
			update_wander(delta)
		States.WINDUP:
			update_windup()
		States.CHARGE:
			update_charge(delta)
		States.STUN:
			update_stun(delta)
	
	updateSpriteFacing()
	resetSensingTimer() #needs to happen AFTER state machine so timeout can be checked
	move_and_slide()
	checkForChargeCollisions() #needs to happen immedately after moving to respond promptly

func enter_idle():
	if GORDO_DEBUG: print("Gordo enter idle")
	currentState = States.IDLE
	hitbox.setEnabled(true)
	setAnimationNoRepeats("idle")

func update_idle(delta: float):
	velocity.x = move_toward(velocity.x, 0, wanderAcceleration * delta)
	
	if(sensingTimer.time_left <= 0):
		if GORDO_DEBUG: print("Gordo checking for player")
		var target: Vector2 = GameBase.get_singleton().player.global_position
		if((global_position - target).length() < sensingRange):
			#alert sound
			if aggroSound: MittyUtils.play_sound_at_2d(aggroSound, global_position, 1)
			enter_wander()

func enter_wander():
	if GORDO_DEBUG: print("Gordo enter wander")
	currentState = States.WANDER
	hitbox.setEnabled(true)
	decideWanderDirection(true)
	setStateTimer(randf_range(wanderDirectionTimeMin, wanderDirectionTimeMax))
	chargeCooldownTimer = get_tree().create_timer(randf_range(chargeCooldownMin, chargeCooldownMax))
	setAnimationNoRepeats("move")

func update_wander(delta: float):
	if sensingTimer.time_left <= 0:
		if chargeCooldownTimer.time_left <= 0 and isPlayerInChargeRange():
			enter_windup()
			return
		var target: Vector2 = GameBase.get_singleton().player.global_position
		if((global_position - target).length() > giveUpRange):
			enter_idle()
	
	if stateTimer.time_left <= 0:
		decideWanderDirection()
		setStateTimer(randf_range(wanderDirectionTimeMin, wanderDirectionTimeMax))
	velocity.x = move_toward(velocity.x, currentMoveDirection * wanderSpeed, wanderAcceleration * delta)

func enter_windup():
	if GORDO_DEBUG: print("Gordo enter windup")
	currentState = States.WINDUP
	hitbox.setEnabled(false)
	velocity.x = 0
	setStateTimer(windupTime)
	setAnimationNoRepeats("charge")
	if chargeCry: MittyUtils.play_sound_at_2d(chargeCry, global_position, 1)

func update_windup():
	var toPlayer: Vector2 = GameBase.get_singleton().player.global_position - global_position
	if toPlayer.x > 0:
		currentMoveDirection = 1
	else:
		currentMoveDirection = -1
	
	if stateTimer.time_left <= 0:
		enter_charge()

func enter_charge():
	if GORDO_DEBUG: print("Gordo enter charge")
	currentState = States.CHARGE
	hitbox.setEnabled(true)
	chargeAborted = false
	hitsSinceCharge = 0
	velocity.x = currentMoveDirection * chargeSpeed
	setStateTimer(chargeMinAbortTime)

func update_charge(delta: float):
	if shouldChargeAbort():
		chargeAborted = true
	if chargeAborted:
		velocity.x = move_toward(velocity.x, 0, chargeBrakeAcceleration * delta)
		if velocity.x < 5:
			enter_wander()
	else:
		velocity.x = currentMoveDirection * chargeSpeed

func enter_stun():
	if GORDO_DEBUG: print("Gordo enter stun")
	currentState = States.STUN
	hitbox.setEnabled(false)
	mainSprite.stop()
	setStateTimer(stunTime)
	velocity = stunLaunch
	velocity.x *= currentMoveDirection

func update_stun(delta: float):
	velocity.x = move_toward(velocity.x, 0, stunBrakeAcceleration * delta)
	if stateTimer.time_left <= 0:
		enter_wander()

func updateSpriteFacing():
	if currentMoveDirection == 1:
		mainSprite.flip_h = false
	elif currentMoveDirection == -1:
		mainSprite.flip_h = true
	else:
		print("Warning: Gordo charm has invalid currentMoveDirection!")

func setStateTimer(time: float):
	stateTimer = get_tree().create_timer(time)

func resetSensingTimer():
	if not sensingTimer or sensingTimer.time_left <= 0:
		sensingTimer = get_tree().create_timer(randf_range(sensingUpdateMin, sensingUpdateMax))

func resetChargePushTimer():
	chargePushCooldownTimer = get_tree().create_timer(chargePushCooldown)

func setAnimationNoRepeats(animation: String):
	if mainSprite.animation != animation:
		mainSprite.play(animation)

func isPlayerInChargeRange() -> bool:
	var toPlayer: Vector2 = GameBase.get_singleton().player.global_position - global_position
	if abs(toPlayer.y) <= chargeYThreshold:
		return true
	return false

func shouldChargeAbort() -> bool:
	if stateTimer.time_left > 0:
		return false
	
	var toPlayer: Vector2 = GameBase.get_singleton().player.global_position - global_position
	if toPlayer.x * currentMoveDirection < chargeXAbort:
		return true
	
	return false

func decideWanderDirection(random: bool = false):
	if random:
		if randi() % 2:
			currentMoveDirection = 1
		else:
			currentMoveDirection = -1
	else:
		currentMoveDirection *= -1

func checkForChargeCollisions() -> bool:
	if currentState != States.CHARGE:
		return false
	if not is_on_wall():
		return false
	
	pushPlayer()
	
	var didCollide: bool = false
	var currentCrushCastPosition = crushCastBasePosition
	currentCrushCastPosition.x *= currentMoveDirection
	crushShapecast.position = currentCrushCastPosition
	crushShapecast.enabled = true
	
	crushShapecast.force_shapecast_update()
	var collisionResults = crushShapecast.collision_result
	if collisionResults:
		print(collisionResults)
		# our mask should be set up so that any result from the shapecast means we hit a wall, or are crushing the player agaist one
		didCollide = true
	crushShapecast.enabled = false #gotta make sure to disable before returning to avoid costly calculations every frame
	
	if didCollide:
		enter_stun()
	
	return didCollide

func pushPlayer():
	if chargePushCooldownTimer.time_left > 0:
		return
	
	var playerRef: CharacterBody2D = GameBase.get_singleton().player
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		if collision.get_collider() == playerRef:
			if GORDO_DEBUG: print("Gordo pushing player")
			resetChargePushTimer()
			var currentPushVelocity: Vector2 = chargePushVelocity
			currentPushVelocity.x *= currentMoveDirection
			playerRef.velocity = currentPushVelocity
			#if playerRef.velocity.y > currentPushVelocity.y:
			#	playerRef.velocity.y = currentPushVelocity.y
			hitsSinceCharge += 1
			if hitsSinceCharge >= chargeMercyHits:
				if GORDO_DEBUG: print("Gordo having mercy")
				chargeAborted = true
			return
	

func _on_death(_cause: Node) -> void:
	MittyUtils.hit_stop(0.1)
	var deathEffectInstance = MittyUtils.spawn_at_location(deathEffect, global_position)
	deathEffectInstance.takeGraphicalNode(mainSprite)
	queue_free()
