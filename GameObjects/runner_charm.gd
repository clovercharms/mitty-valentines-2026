extends CharacterBody2D

#basic movement
@export var speed: float = 600
@export var speedVariation: float = 0.2
@export var acceleration: float = 1000
#how long it takes to turn around after running past/through the player
@export var minTurnaroundTime: float = 0.2
@export var maxTurnaroundTime: float = 0.6
#how long inbetween pounces
@export var minPounceCooldown: float = 1.5
@export var maxPounceCooldown: float = 4
#how close to attempt a pounce
@export var minPounceAttempt: float = 250
@export var maxPounceAttempt: float = 450
#how long/short a pounce can go
@export var minPounceDistance: float = 150
@export var maxPounceDistance: float = 600
@export var maxPounceHeight: float = 400
@export var minPounceArcHeight: float = 40
@export var maxPounceArcHeight: float = 140
#random amount added-subtracted from target location for variation
@export var pounceTargetVariation: float = 40
#how close to the player to activate
@export var sensingRange: float = 1000
#pounce windup time
@export var minWindupTime: float = 0.4
@export var maxWindupTime: float = 0.8
#how often to check activation.deactivation
@export var minAiUpdateTime: float = 0.1
@export var maxAiUpdateTime: float = 0.3
#fall speed to faceplant, pounces always faceplant
@export var speedToFaceplant: float = 500
@export var minFaceplantTime: float = 1
@export var maxFaceplantTime: float = 1.5

enum states { IDLE, CHASE, WINDUP, IN_AIR, FACEPLANT }
var currentState: states = states.IDLE
var forceFaceplant: bool = false
var stateTimer: SceneTreeTimer
var turnaroundTimer: SceneTreeTimer
var pounceCooldownTimer: SceneTreeTimer
var currentPounceAttempt: float = minPounceAttempt
var currentDirection: Vector2 = Vector2.RIGHT

func _enter_tree() -> void:
	# Randomize abilities
	speed *= randf_range(1 - speedVariation, 1 + speedVariation)
	pounceCooldownTimer = get_tree().create_timer(randf_range(minPounceCooldown, maxPounceCooldown))
	
	# Init state machine
	enter_idle()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		if(currentState != states.IN_AIR):
			enter_in_air()
	
	# Run state machine
	match currentState:
		states.IDLE:
			update_idle()
		states.CHASE:
			update_chase(delta)
		states.WINDUP:
			update_windup()
		states.IN_AIR:
			update_in_air()
		states.FACEPLANT:
			update_faceplant()
	
	move_and_slide()

func enter_idle():
	print("runner enter idle")
	currentState = states.IDLE
	stateTimer = get_tree().create_timer(randf_range(minAiUpdateTime, maxAiUpdateTime))

func update_idle():
	if(stateTimer.time_left <= 0):
		var target: Vector2 = GameBase.get_singleton().player.position
		if((position - target).length() < sensingRange):
			#alert sound
			enter_chase()
		else:
			stateTimer = get_tree().create_timer(randf_range(minAiUpdateTime, maxAiUpdateTime))

func enter_chase():
	print("runner enter chase")
	currentState = states.CHASE
	currentPounceAttempt = randf_range(minPounceAttempt, maxPounceAttempt)
	decide_direction()
	stateTimer = get_tree().create_timer(randf_range(minAiUpdateTime, maxAiUpdateTime))

func update_chase(delta: float):
	if(stateTimer.time_left <= 0):
		var target: Vector2 = GameBase.get_singleton().player.position
		var distanceToTarget: float = (position - target).length()
		if(distanceToTarget > sensingRange):
			enter_idle()
			return
		if(pounceCooldownTimer.time_left <= 0 and distanceToTarget < currentPounceAttempt):
			enter_windup()
			return
	
	if(turnaroundTimer.time_left <= 0):
		decide_direction()
	
	velocity.x = move_toward(velocity.x, (currentDirection * speed).x, acceleration * delta)

func enter_windup():
	print("runner enter windup")
	currentState = states.WINDUP
	velocity.x = 0
	stateTimer = get_tree().create_timer(randf_range(minWindupTime, maxWindupTime))
	pounceCooldownTimer = get_tree().create_timer(randf_range(minPounceCooldown, maxPounceCooldown))

func update_windup():
	if(stateTimer.time_left > 0):
		return
	var target: Vector2 = GameBase.get_singleton().player.position
	var direction: Vector2 = target - position
	if(direction.length() < minPounceDistance):
		direction.y = 0
		target = position + direction.normalized() * minPounceDistance
	else:
		target.x += randf_range(-pounceTargetVariation, pounceTargetVariation)
	
	direction = target - position
	var arcHeight: float = abs(direction.x) / maxPounceDistance * maxPounceArcHeight
	arcHeight -= abs(direction.y)
	arcHeight = clamp(arcHeight, minPounceArcHeight, maxPounceArcHeight)
	velocity = MittyUtils.getLaunchVelocity(position, target, get_gravity().y, arcHeight)
	print("launch velocity: ", velocity)
	
	forceFaceplant = true
	enter_in_air()

func enter_in_air():
	print("runner enter in air")
	currentState = states.IN_AIR

func update_in_air():
	if(velocity.y > speedToFaceplant):
		forceFaceplant = true
	if(is_on_floor()):
		if(forceFaceplant):
			enter_faceplant()
		else:
			enter_chase()

func enter_faceplant():
	print("runner enter faceplant")
	currentState = states.FACEPLANT
	forceFaceplant = false
	stateTimer = get_tree().create_timer(randf_range(minAiUpdateTime, maxAiUpdateTime))
	velocity = Vector2.ZERO
	#update animation
	#faceplant sound

func update_faceplant():
	if(stateTimer.time_left <= 0):
		enter_chase()

func decide_direction():
	var target: Vector2 = GameBase.get_singleton().player.position
	var toTarget: Vector2 = target - position
	if(toTarget.x > 0):
		currentDirection = Vector2(1, 0)
	else:
		currentDirection = Vector2(-1, 0)
	turnaroundTimer = get_tree().create_timer(randf_range(minTurnaroundTime, maxTurnaroundTime))
	
