class_name TriggeredDoor extends Node2D

@export var move_to : Marker2D
@export var required_key : Resource
@export var trigger_area : Area2D

@onready var door : AnimatableBody2D = $Door

var movement_tween : Tween
var is_open : bool = false

func _ready() -> void:
    if not check_key():
        return
    door.global_position = move_to.global_position
    is_open = true
    await get_tree().create_timer(0.1).timeout
    var overlaps = trigger_area.get_overlapping_areas()
    if !overlaps.any(check_mimty_in_area):
        door.position = Vector2.ZERO
        is_open = false
        
    
func open() -> void:
    if not check_key() or is_open:
        return
    if movement_tween != null:
        movement_tween.stop()
    movement_tween = create_tween()
    movement_tween.tween_property(door, "global_position", move_to.global_position, 0.5)
    is_open = true
    
func close() -> void:
    if not is_open:
        return
    if movement_tween != null:
        movement_tween.stop()
    movement_tween = create_tween()
    movement_tween.tween_property(door, "position", Vector2.ZERO, 0.5)
    is_open = false
    
func check_key() -> bool:
    if required_key == null:
        print("no key required - open")
        return true
    elif GameBase.get_singleton().keysCollected.has(required_key):
        print("has key - open")
        return true
    else:
        print("missing key - closed")
        return false

func check_mimty_in_area(area : Area2D) -> bool:
    return area.get_parent() is MittyPlayer
