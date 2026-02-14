extends Node2D

@onready var terrain : TileMapLayer = $Terrain

var runner_scene : PackedScene = preload("res://GameObjects/RunnerCharm.tscn")

func spawn_runners(markers : Array) -> void:
	for marker in markers:
		if marker is not Marker2D:
			print("error: not a marker2d")
			pass
		else:
			print("spawning runner at ", marker.name )
			MittyUtils.spawn_at_location(runner_scene, marker.global_position)
			
func spawner_1_triggered() -> void:
	spawn_runners([$"Markers/Runner Spawn 1", $"Markers/Runner Spawn 2"])
	
func spawner_2_triggered() -> void:
	spawn_runners([$"Markers/Runner Spawn 3", $"Markers/Runner Spawn 4"])
	
func spawner_3_triggered() -> void:
	spawn_runners([$"Markers/Runner Spawn 5", $"Markers/Runner Spawn 6"])
	
func spawner_4_triggered() -> void:
	spawn_runners([$"Markers/Runner Spawn 7", $"Markers/Runner Spawn 8"])

func drop_trap_triggered() -> void:
	terrain.erase_cell(Vector2i(1,9))

func _on_mini_boss_death(cause: Node) -> void:
	$"Objects/Triggered Door".open()

func _on_key_picked_up() -> void:
	var popup : PopupMessage = preload("res://GameObjects/popup_message.tscn").instantiate()
	popup.message = "You got the boss key!"
	add_child(popup)
	popup.popup()
