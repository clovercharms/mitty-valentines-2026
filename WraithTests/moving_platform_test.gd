class_name MovingPlatform extends Node2D

@export var move_to : Marker2D
@export var loop_speed : float

@onready var platform : AnimatableBody2D = $Platform

func _ready() -> void:
    start_tweening()
    
func start_tweening() -> void:
    var tween = get_tree().create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
    tween.set_loops().set_parallel(false)
    tween.tween_property(platform, "global_position", move_to.global_position, loop_speed / 2)
    tween.tween_property(platform, "position", Vector2.ZERO, loop_speed / 2)
    
