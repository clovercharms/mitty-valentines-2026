class_name RunnerCharm extends EnemyBase

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
@export var maxPounceYSpeed: float = 2500 #hack because I don't have any more time to mess with ballistics calculations
#random amount added-subtracted from target location for variation
@export var pounceTargetVariation: float = 40
#how close to the player to activate
@export var sensingRange: float = 1000
@export var giveUpRange: float = 2000
#pounce windup time
@export var minWindupTime: float = 0.4
@export var maxWindupTime: float = 0.8
#how often to check activation.deactivation
@export var minSensingUpdateTime: float = 0.1
@export var maxSensingUpdateTime: float = 0.5
#fall speed to faceplant, pounces always faceplant
@export var speedToFaceplant: float = 1200
@export var minFaceplantTime: float = 1
@export var maxFaceplantTime: float = 1.5

@export var flinchVelocity: Vector2 = Vector2(-500, -200)
@export var flinchTime: float = 0.3

@export var deathEffect: PackedScene

@onready var mainSprite: Sprite2D = $MainSprite

const RUNNER_DEBUG: bool = false

enum states { IDLE, CHASE, WINDUP, IN_AIR, FACEPLANT, FLINCH }
var currentState: states = states.IDLE
var forceFaceplant: bool = false
var stateTimer: SceneTreeTimer
var turnaroundTimer: SceneTreeTimer
var pounceCooldownTimer: SceneTreeTimer
var currentPounceAttempt: float = minPounceAttempt
var currentDirection: Vector2 = Vector2.RIGHT
var hitBox: Node

func _enter_tree() -> void:
	# Randomize abilities
	speed *= randf_range(1 - speedVariation, 1 + speedVariation)
	pounceCooldownTimer = get_tree().create_timer(randf_range(minPounceCooldown, maxPounceCooldown))
	hitBox = $SimpleHitbox
	# Init state machine
	enter_idle()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		if(currentState != states.IN_AIR and currentState != states.FLINCH):
			enter_in_air()
	
	# Run state machine
	match currentState:
		states.IDLE:
			update_idle(delta)
		states.CHASE:
			update_chase(delta)
		states.WINDUP:
			update_windup()
		states.IN_AIR:
			update_in_air()
		states.FACEPLANT:
			update_faceplant()
		states.FLINCH:
			update_flinch(delta)
	
	move_and_slide()

func enter_idle():
	if RUNNER_DEBUG: print("runner enter idle")
	currentState = states.IDLE
	hitBox.setEnabled(true)
	stateTimer = get_tree().create_timer(randf_range(minSensingUpdateTime, maxSensingUpdateTime))

func update_idle(delta: float):
	velocity.x = move_toward(velocity.x, 0, acceleration * delta)
	if(stateTimer.time_left <= 0):
		var target: Vector2 = GameBase.get_singleton().player.position
		if RUNNER_DEBUG: print("distance to player: ", (global_position - target).length())
		if((global_position - target).length() < sensingRange):
			#alert sound
			enter_chase()
		else:
			stateTimer = get_tree().create_timer(randf_range(minSensingUpdateTime, maxSensingUpdateTime))

func enter_chase():
	if RUNNER_DEBUG: print("runner enter chase")
	currentState = states.CHASE
	hitBox.setEnabled(true)
	currentPounceAttempt = randf_range(minPounceAttempt, maxPounceAttempt)
	decide_direction()
	stateTimer = get_tree().create_timer(randf_range(minSensingUpdateTime, maxSensingUpdateTime))

func update_chase(delta: float):
	if(stateTimer.time_left <= 0):
		var target: Vector2 = GameBase.get_singleton().player.position
		var distanceToTarget: float = (global_position - target).length()
		if(distanceToTarget > giveUpRange):
			enter_idle()
			return
		if(pounceCooldownTimer.time_left <= 0 and distanceToTarget < currentPounceAttempt):
			enter_windup()
			return
	
	if(turnaroundTimer.time_left <= 0):
		decide_direction()
	
	velocity.x = move_toward(velocity.x, (currentDirection * speed).x, acceleration * delta)

func enter_windup():
	if RUNNER_DEBUG: print("runner enter windup")
	currentState = states.WINDUP
	hitBox.setEnabled(false)
	velocity.x = 0
	stateTimer = get_tree().create_timer(randf_range(minWindupTime, maxWindupTime))
	pounceCooldownTimer = get_tree().create_timer(randf_range(minPounceCooldown, maxPounceCooldown))

func update_windup():
	if(stateTimer.time_left > 0):
		return
	var target: Vector2 = GameBase.get_singleton().player.position
	var direction: Vector2 = target - global_position
	if(direction.length() < minPounceDistance):
		direction.y = 0
		target = global_position + direction.normalized() * minPounceDistance
	else:
		target.x += randf_range(-pounceTargetVariation, pounceTargetVariation)
	
	direction = target - position
	var arcHeight: float = abs(direction.x) / maxPounceDistance * maxPounceArcHeight
	arcHeight -= abs(direction.y)
	arcHeight = clamp(arcHeight, minPounceArcHeight, maxPounceArcHeight)
	velocity = MittyUtils.getLaunchVelocity(global_position, target, get_gravity().y, arcHeight, RUNNER_DEBUG)
	velocity.y = clamp(velocity.y, -maxPounceYSpeed, maxPounceYSpeed) #remove this if you fix the ballistics calculations
	if RUNNER_DEBUG: print("launch velocity: ", velocity)
	
	forceFaceplant = true
	enter_in_air()

func enter_in_air():
	if RUNNER_DEBUG: print("runner enter in air")
	currentState = states.IN_AIR
	hitBox.setEnabled(true)

func update_in_air():
	if(abs(velocity.y) > speedToFaceplant):
		forceFaceplant = true
	if(is_on_floor()):
		if(forceFaceplant):
			enter_faceplant()
		else:
			enter_chase()

func enter_faceplant():
	if RUNNER_DEBUG: print("runner enter faceplant")
	currentState = states.FACEPLANT
	hitBox.setEnabled(false)
	forceFaceplant = false
	stateTimer = get_tree().create_timer(randf_range(minFaceplantTime, maxFaceplantTime))
	velocity = Vector2.ZERO
	#update animation
	#faceplant sound

func update_faceplant():
	if(stateTimer.time_left <= 0):
		enter_chase()

func enter_flinch(hurtLocation: Vector2):
	currentState = states.FLINCH
	hitBox.setEnabled(false)
	stateTimer = get_tree().create_timer(flinchTime)
	
	if not hurtLocation:
		velocity = Vector2.ZERO
		return
	var hurtDirection: float = 1
	var toHurt = hurtLocation - global_position
	if(toHurt.x < 0):
		hurtDirection = -1
	var currentFlinchVel = flinchVelocity
	currentFlinchVel.x *= hurtDirection
	velocity = currentFlinchVel

func update_flinch(delta: float):
	velocity.x = move_toward(velocity.x, 0, acceleration * delta)
	if(stateTimer.time_left <= 0):
		enter_chase()

func decide_direction():
	var target: Vector2 = GameBase.get_singleton().player.position
	var toTarget: Vector2 = target - global_position
	if(toTarget.x > 0):
		currentDirection = Vector2(1, 0)
	else:
		currentDirection = Vector2(-1, 0)
	turnaroundTimer = get_tree().create_timer(randf_range(minTurnaroundTime, maxTurnaroundTime))

func _on_area_2d_area_entered(area: Area2D) -> void:
	if (area.get_parent() is not MittyPlayer):
		return
	damage_player(area.get_parent())

func _on_hurt(_amount: int, cause: Node) -> void:
	if cause and "global_position" in cause:
		enter_flinch(cause.global_position)
	else:
		enter_flinch(GameBase.get_singleton().player.global_position)

func _on_death(_cause: Node) -> void:
	MittyUtils.hit_stop(0.05)
	var deathEffectInstance = MittyUtils.spawn_at_location(deathEffect, global_position)
	deathEffectInstance.takeGraphicalNode(mainSprite)
	queue_free()
