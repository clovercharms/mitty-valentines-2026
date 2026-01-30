class_name MittyPlayer extends CharacterBody2D


const SPEED = 800.0
const JUMP_VELOCITY = -1200.0
const TERMINAL_FALL_VELOCITY = 2000
@onready var coyote_timer = $CoyoteTimer

@export var stats: StatBlock

# double jump
@onready var can_double_jump = true
var has_double_jumped = false


func on_enter():
    print("player on_enter")

func _physics_process(delta: float) -> void:
    # Add the gravity.
    if not is_on_floor():
        if velocity.y < 0:
            velocity += get_gravity() * delta
        elif velocity.y != TERMINAL_FALL_VELOCITY:
            # faster drop down after reaching apex, add terminal fall velocity
            velocity += get_gravity() * delta * 3
            velocity.y = min(velocity.y, TERMINAL_FALL_VELOCITY)
    # Handle jump.
    if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or !coyote_timer.is_stopped()):
        velocity.y = JUMP_VELOCITY
    # enable short jumps by releasing jump early
    if Input.is_action_just_released("ui_accept") and velocity.y < 0:
        velocity.y = JUMP_VELOCITY / 4
    # double jump logic
    if Input.is_action_just_pressed("ui_accept") and can_double_jump and !has_double_jumped and !is_on_floor():
        velocity.y = JUMP_VELOCITY
        has_double_jumped = true

    if is_on_floor() and has_double_jumped:
        has_double_jumped = false
    
    # Get the input direction and handle the movement/deceleration.
    # As good practice, you should replace UI actions with custom gameplay actions.
    var direction := Input.get_axis("ui_left", "ui_right")
    if direction:
        velocity.x = direction * SPEED * stats.speed_modifier
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
        
    # Coyote Time logic
    var was_on_floor = is_on_floor()

    move_and_slide()
    
    if was_on_floor && !is_on_floor():
        coyote_timer.start()
