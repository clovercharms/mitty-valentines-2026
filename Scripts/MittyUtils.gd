### Singleton to throw all the utilities on because that's how Godot is structured
extends Node

### Vector math
# Returns a normalized direction vector to get from origin to position, ignoring the Y direction.
# Intended for calculating ground movement for enemy AI.
# Will return a zero vector if the distance is closer than marginOfError
func xDirectionToPosition(origin: Vector2, target: Vector2, marginOfError: float = 5) -> Vector2:
    var direction = Vector2((target - origin).x, 0)
    if(abs(direction.x) < marginOfError):
        return Vector2(0, 0)
    return direction.normalized()

# Returns a normalized direction vector to get from origin to position
# Will return a zero vector if the distance is closer than marginOfError
func directionToPosition(origin: Vector2, target: Vector2, marginOfError: float = 5) -> Vector2:
    var direction: Vector2 = target - origin
    if(direction.length_squared() < marginOfError * marginOfError ) :
        return Vector2(0, 0)
    return direction.normalized()

# Does a highly optimized facing check with a slightly larger than 180 degree "cone of vision"
# marginOfError is in radians, but is not consistent due to a lack of normalization
func fastFacingCheck(origin: Vector2, facing: Vector2, target: Vector2, marginOfError: float = 0.001) -> bool:
    var direction: Vector2 = target - origin
    # Dot product gives the cosine of the angle times the length of the vectors
    # Cosine is always positive if the angle less than 90 degrees and vector length is always positive
    # So if the dot product is positive then the angle is less than 90 degrees
    if(direction.dot(facing) > -abs(marginOfError)):
        return true
    return false

# Calculate a ballistic trajectory with a predefined peak height so the trajectory looks nice.
func getLaunchVelocity(origin: Vector2, target: Vector2, gravity: float, extraHeight: float, debugPrint: bool = false) -> Vector2:
    if debugPrint: print("launch params: origin: ", origin, " target: ", target, " gravity: ", gravity, " extraHeight: ", extraHeight)
    const MINIMUM_DISTANCE = 5
    var travel: Vector2 = target - origin
    if(travel.length() < MINIMUM_DISTANCE):
        print("Warning: Trajectory distance was too short. Returning zero launch velocity.")
        return Vector2(0,0)
    
    # Flip Y coordinate so normal ballistics calculations work
    origin.y = -origin.y
    target.y = -target.y
    gravity = abs(gravity)
    
    var startHeight: float = origin.y
    var endHeight: float = target.y
    var flooringValue: float = min(startHeight, endHeight)
    startHeight -= flooringValue
    endHeight -= flooringValue
    var peakHeight: float = max(startHeight, endHeight) + extraHeight
    var heightDiff: float = startHeight - endHeight
    #var peakGain: float = peakHeight - startHeight;
    if debugPrint: print("peakHeight: ", peakHeight, " heightDiff: ", heightDiff, " peakHeight: ", peakHeight)
    var velocityY: float = sqrt(2 * gravity * (peakHeight - heightDiff))
    var flightTime: float = sqrt(2 * (peakHeight - heightDiff) / gravity) + sqrt(2 * peakHeight / gravity)
    var velocityX: float = travel.x / flightTime
    
    # Flip Y velocity back
    return Vector2(velocityX, -velocityY)

### General utils
#remaps value from linear range Input to linear range Output
func map_range(value: float, InputA: float, InputB: float, OutputA: float, OutputB: float):
    return(value - InputA) / (InputB - InputA) * (OutputB - OutputA) + OutputA

#remaps value from linear range Input to linear range Output, clamped to the output range
func map_range_clamped(value: float, InputA: float, InputB: float, OutputA: float, OutputB: float):
    return(clamp(value, InputA, InputB) - InputA) / (InputB - InputA) * (OutputB - OutputA) + OutputA

func spawn_at_location(to_spawn: PackedScene, location: Vector2) -> Node:
    var instance = to_spawn.instantiate()
    if instance is RunnerCharm:
        instance.holds_message = false
    instance.position = location
    GameBase.get_singleton().map.call_deferred("add_child", instance)
    return instance

func spawn_child(parent: Node, to_spawn: PackedScene, location: Vector2):
    var instance = to_spawn.instantiate()
    instance.position = location
    parent.call_deferred("add_child", instance)
    return instance

func spawn_projectile(projectile: PackedScene, location: Vector2, velocity: Vector2, rotation: float = 0):
    var projectile_instance = projectile.instantiate()
    projectile_instance.position = location
    projectile_instance.apply_impulse(velocity)
    projectile_instance.rotation = rotation
    GameBase.get_singleton().map.call_deferred("add_child", projectile_instance)
    return projectile_instance

func hit_stop(real_time_duration: float):
    const time_scale:float = 0.05 #can't actually use 0, but this is so slow it does the job
    time_slow(time_scale, real_time_duration)

func time_slow(time_scale: float, real_time_duration: float):
    Engine.time_scale = time_scale
    var timer = GameBase.get_singleton().get_tree().create_timer(real_time_duration, true, false, true)
    await timer.timeout
    Engine.time_scale = 1
