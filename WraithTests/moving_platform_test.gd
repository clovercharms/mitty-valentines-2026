class_name MovingPlatform extends Node2D

@export var move_to : Marker2D
@export var one_shot : bool = false
@export var one_way : bool = false
@export var loop_speed : float
@export var triggered : bool = false

var has_been_triggered : bool = false

@onready var platform : AnimatableBody2D = $Platform

var movement_tween : Tween

func _ready() -> void:
    if not triggered:
        start_tweening()
        
func trigger() -> void:
    if triggered and not has_been_triggered:
        start_tweening()
        has_been_triggered = true
    
func start_tweening() -> void:
    movement_tween = get_tree().create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
    movement_tween.bind_node(self)
    if one_shot:
        movement_tween.set_loops(1).set_parallel(true)
    else:
        movement_tween.set_loops().set_parallel(false)
    movement_tween.tween_property(platform, "global_position", move_to.global_position, loop_speed / 2)
    if not one_way:
        movement_tween.tween_property(platform, "position", Vector2.ZERO, loop_speed / 2)
    
