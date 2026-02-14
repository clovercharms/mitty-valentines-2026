extends Node2D

@onready var boss_marker : Marker2D = $"Enemies/Boss Spawn"

@onready var boss : PackedScene = preload("res://GameObjects/Enemies/charmfly.tscn")
@onready var key_on_death : DoorKey = preload("res://Resources/dead_boss_key.tres")

func _ready() -> void:
	pass
	
func spawn_boss() -> void:
	if GameBase.get_singleton().keysCollected.has(key_on_death):
		return
	var boss_instance : Charmfly = MittyUtils.spawn_at_location(boss, boss_marker.global_position)
	boss_instance.connect("dead", open_door)

func open_door() -> void:
	$"Door Parts/Door".open()
