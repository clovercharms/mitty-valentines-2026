extends Node2D

@onready var boss_marker : Marker2D = $"Enemies/Boss Spawn"

@onready var boss : PackedScene = preload("res://GameObjects/Enemies/charmfly.tscn")

func _ready() -> void:
	pass
	
func spawn_boss() -> void:
	if GameBase.get_singleton().pickups.has("boss_exit_key"):
		return
	var boss_instance : Charmfly = MittyUtils.spawn_at_location(boss, boss_marker.global_position)
	boss_instance.connect("dead", open_door)
	boss_instance.connect("dead", display_unlock)

func open_door() -> void:
	$"Door Parts/Door".open()
	
func display_unlock():
	var popup : PopupMessage = preload("res://GameObjects/popup_message.tscn").instantiate()
	popup.message = "Double Jump unlocked!"
	add_child(popup)
	popup.popup()
