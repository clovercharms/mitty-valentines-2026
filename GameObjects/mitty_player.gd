class_name MittyPlayer extends CharacterBody2D

@export_group("Game Variables")
@export var speed: float = 900.0
@export var accelerationBoostThreshold: float = 550
@export var acceleration: float = 2500
@export var boostedAcceleration: float = 8000
@export var airControl: float = 0.8
@export var jumpSpeed: float = -1200.0
@export var terminalFallSpeed: float = 2000
@export var attackMovementSpeed: float = 1200
@export var attackDrag: float = 2500
@export var attackTime: float = 0.25
@export var attackCooldownTime: float = 0.4

@onready var coyote_timer = $CoyoteTimer
@onready var main_sprite: AnimatedSprite2D = $MainSprite
@onready var camera: Camera2D = $Camera2D

enum ControlState { MOVE, ATTACK, FLINCH }

var currentState: ControlState = ControlState.MOVE
var stateTimer: SceneTreeTimer
var lastMoveDirection: float = 1

var attackCooldownTimer: SceneTreeTimer
@onready var damage_timer = $DamageTimer
@onready var detection_area : Area2D = $Detector

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

func _physics_process(delta: float) -> void:
    if Input.is_action_just_pressed("Attack") and has_control:
        enter_attack()
    
    update_gravity(delta)
    
    if not has_control:
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
    if direction:
        var currentAcceleration = acceleration
        if abs(velocity.x) < accelerationBoostThreshold:
            currentAcceleration = boostedAcceleration
        if not is_on_floor():
            currentAcceleration *= airControl
        velocity.x = move_toward(velocity.x, direction * speed, currentAcceleration * delta)
        if direction > 0:
            lastMoveDirection = 1
            main_sprite.flip_h = false
        elif direction < 0:
            lastMoveDirection = -1
            main_sprite.flip_h = true
    else:
        velocity.x = move_toward(velocity.x, 0, acceleration * 2 * delta)
    
    if is_on_floor() and not jumpedThisFrame:
        if direction:
            setAnimationNoRepeats("run")
        if abs(velocity.x) < 1:
            setAnimationNoRepeats("idle")

func enter_attack():
    currentState = ControlState.ATTACK
    var lookDirection = Input.get_axis("Look_Down", "Look_Up")
    var moveDirection = Input.get_axis("Move_Left", "Move_Right")
    if lookDirection > 0:
        if canJump():
            velocity.y = -attackMovementSpeed
        setAnimationNoRepeats("attack_up")
        velocity.x *= 0.5
        # spawn hitbox
    elif lookDirection < 0:
        velocity.y = move_toward(velocity.y, terminalFallSpeed, attackMovementSpeed)
        setAnimationNoRepeats("attack_down")
        # spawn hitbox
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
        # spawn hitbox
    main_sprite.set_frame(0)
    main_sprite.play()
    
    # play audio cue

func update_attack(delta: float):
    velocity.x = move_toward(velocity.x, 0, attackDrag * delta)

func update_flinch():
    pass

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


func _on_main_sprite_animation_finished() -> void:
    if currentState == ControlState.ATTACK:
        currentState = ControlState.MOVE
        if not is_on_floor() and velocity.y < 0:
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
    currentState = ControlState.MOVE
    
    
