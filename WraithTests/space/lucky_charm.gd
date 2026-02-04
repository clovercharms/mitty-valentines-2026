class_name SpaceLuckyCharm extends CharacterBody3D

var pivoter : Marker3D

@export var pathfinding_interval : float = 0.1

@onready var navigation : NavigationAgent3D = $Navigator

var wandering : bool
var destination : Vector3
var accumulated_delta : float

func _process(delta: float) -> void:
    accumulated_delta += delta
    if (accumulated_delta >= pathfinding_interval):
        if (global_position != Vector3.ZERO):
            look_at(Vector3.ZERO, Vector3.UP)
        
        wander()
        
        var direction = (navigation.get_next_path_position() - global_position).normalized()
        velocity = velocity.lerp(direction * 3, delta)
        accumulated_delta -= pathfinding_interval

func _physics_process(delta: float) -> void:
    move_and_slide()
    
func wander() -> void:
    if wandering:
        return
        
    #var theta = randf_range(0, PI * 2)
    #var phi = randf_range(0, PI)
    #var radius : float = 50.0
    
    var x : float = randf_range(-365, 365)
    var y : float = randf_range(-365, 365)
    var z : float = pivoter.rotation.z
    
    destination = Vector3(x, y, z)
    
    var tween = create_tween()
    wandering = true
    tween.tween_property(pivoter, "rotation", destination, 5000)
    await tween.finished
    wandering = false
    
