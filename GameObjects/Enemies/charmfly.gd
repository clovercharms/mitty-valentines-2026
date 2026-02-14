class_name Charmfly extends CharacterBody2D

signal dead

@export_group("movement")
@export var speed: float = 400
@export var speedVariation: float = 0.2
@export var acceleration: float = 1000

@export_group("attack")
@export var charge_speed : float = 800
@export var bounce_speed : float = 1500

@export_group("distances")
@export var x_distance_to_player_for_attack : float = 50.0
@export var hover_height : float = 750.0
@export var min_distance_from_player : float = 50.0
@export var max_distance_from_player : float = 100.0

@onready var sprite : AnimatedSprite2D = $MainSprite
@onready var hitbox : SimpleHitbox = $SimpleHitbox
@onready var key_on_death : DoorKey = preload("res://Resources/dead_boss_key.tres")

enum states { ENTERING, HOVER, MOVE, CHARGE, ROTATING, BOUNCE }

var current_state = states.ENTERING
var current_tween : Tween

var current_direction : Vector2 = Vector2(1, 0)
var just_bounced : bool = false

func _ready() -> void:
    intro_sequence()
    
func _physics_process(delta: float) -> void:
    # Don't bother while entering
    if current_state == states.ENTERING:
        return
        
    decide_direction()
    # Bounce if not doing something else and over player
    var player_pos: Vector2 = GameBase.get_singleton().player.global_position
    if abs(player_pos.x - global_position.x) <= x_distance_to_player_for_attack:
        if current_state != states.CHARGE and current_state != states.ROTATING and current_state != states.BOUNCE and current_state != states.MOVE:
            if not just_bounced:
                enter_bounce()
    # Else do other shit
    match current_state:
        states.ENTERING:
            pass
        states.HOVER:
            update_hover()
        states.ROTATING:
            pass
        states.MOVE:
            update_move()
        states.CHARGE:
            update_charge()
        states.BOUNCE:
            update_bounce()
            
func intro_sequence() -> void:
    #bgm
    var gb = GameBase.get_singleton()
    gb.BossMusic.play()
    var music_tween = get_tree().create_tween().set_parallel(true)
    music_tween.tween_property(gb.BGM, "volume_db", -80, 2.5)
    music_tween.tween_property(gb.BossMusic, "volume_db", -28, 2.5)
    #intro sounds
    var sound : AudioStreamPlayer = $Sounds/Intro
    sound.play()
    #intro animation
    sprite.play("enter")
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(0.75, 0.75), 2.5)
    await tween.finished
    gb.BGM.stop()
    enter_hover()

func decide_direction() -> void:
    var target: Vector2 = GameBase.get_singleton().player.global_position
    var toTarget: Vector2 = target - global_position
    if(toTarget.x < 0):
        current_direction = Vector2(1, 0)
        sprite.flip_h = false
    else:
        current_direction = Vector2(-1, 0)
        sprite.flip_h = true

func enter_hover() -> void:
    print("charmfly hovering")
    current_state = states.HOVER
    sprite.play("hover")
    var rand = randf_range(1, 3)
    var hover_timer = get_tree().create_timer(rand)
    hover_timer.connect("timeout", finish_hover)

func finish_hover() -> void:
    var rand = randf()
    if rand < 0.5:
        enter_charge()
    else:
        enter_move(choose_move_target())
    just_bounced = false
        
func update_hover() -> void:
    if sprite.animation != "hover":
        sprite.play("hover")

func choose_move_target() -> Vector2:
    var player_pos: Vector2 = GameBase.get_singleton().player.global_position
    return Vector2(player_pos.x, player_pos.y - hover_height)
    
func enter_move(target : Vector2) -> void:
    if current_state == states.MOVE:
        return
    print("charmfly moving : ", target)
    current_state = states.MOVE
    sprite.play("hover")
    var tweenTime: float = (global_position - target).length() / speed
    current_tween = create_tween().set_trans(Tween.TRANS_SINE)
    current_tween.tween_property(self, "global_position", target, tweenTime)
    await current_tween.finished
    print("move_complete")
    
func update_move() -> void:
    if not current_tween.is_running() and current_state == states.MOVE:
        enter_hover()

func enter_charge() -> void:
    print("charmfly charging")
    current_state = states.CHARGE
    sprite.play("charge")
    var tweenTarget = choose_attack_vector()
    var tweenTime: float = (global_position - tweenTarget).length() / charge_speed
    current_tween = create_tween().set_trans(Tween.TRANS_SINE)
    current_tween.tween_property(self, "global_position", tweenTarget, tweenTime)
    await current_tween.finished
    print("charge complete, returning to hover position")
    await get_tree().create_timer(0.5).timeout
    var player_y: float = GameBase.get_singleton().player.global_position.y
    tweenTarget = Vector2(global_position.x, player_y - hover_height)
    enter_move(tweenTarget)
    
func choose_attack_vector() -> Vector2:
    #choose a location that takes you right through the player's current location
    var playerPos: Vector2 = GameBase.get_singleton().player.global_position
    var toPlayer: Vector2 = playerPos - global_position
    var attackLength: float = toPlayer.length() + randf_range(min_distance_from_player, max_distance_from_player)
    return global_position + toPlayer.normalized() * attackLength

func update_charge() -> void:
    if sprite.animation != "charge":
        sprite.play("charge")

func enter_bounce() -> void:
    var sound : AudioStreamPlayer = $Sounds/Impact
    print("charmfly bouncing")
    just_bounced = true
    current_state = states.ROTATING
    var target = GameBase.get_singleton().player.global_position
    # rotate
    print("rotating")
    var rotate_tween = create_tween()
    rotate_tween.tween_property(sprite, "rotation_degrees", -90, 0.2)
    await rotate_tween.finished
    print("rotation complete, bouncing")
    #bounce
    sprite.rotation_degrees = 0
    current_state = states.BOUNCE
    current_tween = create_tween()
    current_tween.tween_property(self, "global_position", target, 0.5)
    await current_tween.finished
    sound.play()
    print("bounce complete, recovering")
    #recover
    var player_y: float = GameBase.get_singleton().player.global_position.y
    var tween_target = Vector2(global_position.x, player_y - hover_height)
    current_tween = create_tween()
    current_tween.tween_property(self, "global_position", tween_target, 1)
    await current_tween.finished
    print("recovery complete, hovering")
    enter_hover()

func update_bounce() -> void:
    if sprite.animation != "bounce":
        sprite.play("bounce")


func _on_death(cause: Node) -> void:
    # change music back
    var gb = GameBase.get_singleton()
    gb.BGM.play()
    var music_tween = get_tree().create_tween().set_parallel(true)
    music_tween.tween_property(gb.BGM, "volume_db", -28, 1.7)
    music_tween.tween_property(gb.BossMusic, "volume_db", -80, 1.7)
    # death
    await death_animation()
    gb.BossMusic.stop()
    # open door
    gb.pickups.append("boss_exit_key")
    gb.unlock_player_ability(GameBase.PlayerAbility.DOUBLE_JUMP)
    dead.emit()
    # remove
    queue_free()
    
func death_animation():
    var sound : AudioStreamPlayer = $Sounds/Death
    sound.play()
    var tween = create_tween().set_parallel(true)
    tween.tween_property(self, "scale", Vector2.ZERO, 1.7)
    tween.tween_property(self, "rotation_degrees", 360 * 20, 1.7)
    await tween.finished
    


func _on_health_hurt(amount: int, cause: Node) -> void:
    var sound : AudioStreamPlayer = $Sounds/Hurt
    sound.play()


func _on_damage_hitbox_body_entered(body: Node2D) -> void:
    var sound : AudioStreamPlayer = $Sounds/Bite
    sound.play()
