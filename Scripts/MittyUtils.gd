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
func getLaunchVelocity(origin: Vector2, target: Vector2, gravity: float, extraHeight: float) -> Vector2:
	const MINIMUM_DISTANCE = 5
	var travel: Vector2 = target - origin
	if(travel.length() < MINIMUM_DISTANCE):
		print("Warning: Trajectory distance was too short. Returning zero launch velocity.")
		return Vector2(0,0)
	
	# Godot uses screen space so Y up is negative and this is definitely going to screw up the ballistic calculations I looked up
	var startHeight: float = origin.y
	var endHeight: float = target.y
	var peakHeight: float = min(startHeight, endHeight) - extraHeight
	var heightDiff: float = startHeight - endHeight
	var peakGain: float = peakHeight - startHeight;
	var velocityY: float = sqrt(2 * gravity * (peakGain - heightDiff))
	var flightTime: float = sqrt(2 * (peakGain - heightDiff) / gravity) + sqrt(2 * peakGain / gravity)
	var velocityX: float = travel.x / flightTime
	
	return Vector2(velocityX,velocityY)
