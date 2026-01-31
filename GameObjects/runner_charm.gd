extends CharacterBody2D

@export var speed: float = 450
@export var acceleration: float = 900
@export var pounceRange: float = 400
@export var minPounceDistance: float = 100
@export var maxPounceDistance: float = 600
@export var maxPounceHeight: float = 400
@export var pounceFullArcHeight: float = 140
@export var pounceTargetVariation: float = 20
@export var sensingRange: float = 1000
@export var minWindupTime: float = 0.4
@export var maxWindupTime: float = 0.8
@export var minAiUpdateTime: float = 0.1
@export var maxAiUpdateTime: float = 0.3
@export var speedToFaceplant: float = 500
@export var minFaceplantTime: float = 1
@export var maxFaceplantTime: float = 1.5

enum states { IDLE, CHASE, WINDUP, IN_AIR, FACEPLANT }
var currentState: states = states.IDLE
var forceFaceplant: bool = false
var stateTimer: SceneTreeTimer

func _enter_tree() -> void:
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
	stateTimer = get_tree().create_timer(randf_range(minAiUpdateTime, maxAiUpdateTime))

func update_chase(delta: float):
	var target: Vector2 = GameBase.get_singleton().player.position
	if(stateTimer.time_left <= 0):
		var distanceToTarget: float = (position - target).length()
		if(distanceToTarget > sensingRange):
			enter_idle()
			return
		if(distanceToTarget < pounceRange):
			enter_windup()
			return
	
	var direction: Vector2 = MittyUtils.xDirectionToPosition(position, target)
	velocity.x = move_toward(velocity.x, (direction * speed).x, acceleration * delta)

func enter_windup():
	print("runner enter windup")
	currentState = states.WINDUP
	velocity.x = 0
	stateTimer = get_tree().create_timer(randf_range(minWindupTime, maxWindupTime))

func update_windup():
	if(stateTimer.time_left > 0):
		return
	var target: Vector2 = GameBase.get_singleton().player.position
	var direction: Vector2 = target - position
	if(direction.length() < minPounceDistance):
		direction.y = 0
		target = direction.normalized() * minPounceDistance
	else:
		target.x += randf_range(-pounceTargetVariation, pounceTargetVariation)
	
	direction = target - position
	var arcHeight: float = abs(direction.x) / pounceRange * pounceFullArcHeight
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
