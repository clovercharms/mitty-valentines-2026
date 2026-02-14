extends CharacterBody2D

@export var averageSpeed: float = 800
@export var moveIntervalMin: float = 0.5
@export var moveIntervalMax: float = 2
@export var targetDistanceFromPlayerMin: float = 150
@export var targetDistanceFromPlayerMax: float = 350
@export var attackChance: float = 0.2
@export var flinchTime: float = 0.2
@export var flinchLaunchSpeed: float = 2000
@export var flinchDrag: float = 10000
@export var deathEffect: PackedScene
@export var aggroSound: AudioStream

@export_category("aggro")
@export var aggro_range : float = 500

const UFO_DEBUG: bool = false

@onready var mainSprite: AnimatedSprite2D = $MainSprite
@onready var hitbox = $Hitbox
@onready var aggro_area : Area2D = $"Aggro Range"
@onready var aggro_collider : CollisionShape2D = $"Aggro Range/Aggro Collider"
@onready var engineNoise: AudioStreamPlayer2D = $EngineNoise

enum State {IDLE, MOVE, WAIT, FLINCH }

var currentState: State = State.IDLE
var stateTimer: SceneTreeTimer
var currentTween: Tween

func _ready() -> void:
    set_aggro()

func _physics_process(delta: float) -> void:
    match currentState:
        State.IDLE:
            pass
        State.MOVE:
            update_move()
        State.WAIT:
            update_wait()
        State.FLINCH:
            update_flinch(delta)

func enter_move():
    currentState = State.MOVE
    hitbox.setEnabled(true)
    var tweenTarget: Vector2
    if(randf() < attackChance):
        tweenTarget = choose_attack_target()
    else:
        tweenTarget = choose_annoy_target()
    var tweenTime: float = (global_position - tweenTarget).length() / averageSpeed
    currentTween = create_tween().set_trans(Tween.TRANS_SINE)
    currentTween.tween_property(self, "global_position", tweenTarget, tweenTime)

func update_move():
    if not currentTween.is_running():
        enter_wait()

func enter_wait():
    currentState = State.WAIT
    hitbox.setEnabled(true)
    velocity = Vector2.ZERO
    stateTimer = get_tree().create_timer(randf_range(moveIntervalMin, moveIntervalMax))

func update_wait():
    if stateTimer.time_left <= 0:
        enter_move()

func enter_flinch(hurtLocation: Vector2):
    if UFO_DEBUG: print("UFO flinching")
    currentState = State.FLINCH
    hitbox.setEnabled(false)
    if currentTween:
        if UFO_DEBUG: print("UFO killing tween")
        currentTween.kill()
    
    stateTimer = get_tree().create_timer(flinchTime)
    if not hurtLocation:
        hurtLocation = GameBase.get_singleton().player.global_position
    var fromHurt: Vector2 = global_position - hurtLocation
    velocity = fromHurt.normalized() * flinchLaunchSpeed

func update_flinch(delta: float):
    if(stateTimer.time_left <= 0):
        enter_wait()
        return
    
    velocity = velocity.move_toward(Vector2.ZERO, flinchDrag * delta)
    move_and_slide()

func choose_annoy_target() -> Vector2:
    #just choose a random location vaguely close to the player
    var playerPos: Vector2 = GameBase.get_singleton().player.global_position
    var offset: Vector2 = Vector2.RIGHT.rotated(randf_range(0, 2 * PI)) * randf_range(targetDistanceFromPlayerMin, targetDistanceFromPlayerMax)
    return playerPos + offset

func choose_attack_target() -> Vector2:
    #choose a location that takes you right through the player's current location
    var playerPos: Vector2 = GameBase.get_singleton().player.global_position
    var toPlayer: Vector2 = playerPos - global_position
    var attackLength: float = toPlayer.length() + randf_range(targetDistanceFromPlayerMin, targetDistanceFromPlayerMax)
    return global_position + toPlayer.normalized() * attackLength

func _on_hurt(_amount: int, cause: Node) -> void:
    if cause and "global_position" in cause:
        enter_flinch(cause.global_position)
    else:
        enter_flinch(Vector2.ZERO)

func _on_death(_cause: Node) -> void:
    MittyUtils.hit_stop(0.05)
    var deathEffectInstance = MittyUtils.spawn_at_location(deathEffect, global_position)
    mainSprite.pause()
    deathEffectInstance.takeGraphicalNode(mainSprite)
    queue_free()
    
func set_aggro() -> void:
    if aggro_collider == null or aggro_collider.shape is not CircleShape2D:
        return
    aggro_collider.shape.radius = aggro_range
    
func aggroed(area : Area2D) -> void:
    if UFO_DEBUG: print("ufo aggroed")
    if area.get_parent() is not MittyPlayer:
        return
    aggro_area.queue_free()
    enter_wait()
    MittyUtils.play_sound_at_2d(aggroSound, global_position)
    engineNoise.play()
