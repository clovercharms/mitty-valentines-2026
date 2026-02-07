extends Node2D

var runner_scene : PackedScene = preload("res://GameObjects/RunnerCharm.tscn")

func spawn_runners(markers : Array) -> void:
    for marker in markers:
        if marker is not Marker2D:
            print("error: not a marker2d")
            pass
        else:
            print("spawning runner at ", marker.name )
            var runner = runner_scene.instantiate()
            marker.add_child(runner)
            
func spawner_1_triggered() -> void:
    spawn_runners([$"Markers/Runner Spawn 1", $"Markers/Runner Spawn 2"])
    
func spawner_2_triggered() -> void:
    spawn_runners([$"Markers/Runner Spawn 3", $"Markers/Runner Spawn 4"])
    
func spawner_3_triggered() -> void:
    spawn_runners([$"Markers/Runner Spawn 5", $"Markers/Runner Spawn 6"])
    
func spawner_4_triggered() -> void:
    spawn_runners([$"Markers/Runner Spawn 7", $"Markers/Runner Spawn 8"])
