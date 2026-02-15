extends RigidBody2D

@export var opacityCurve: Curve
@export var spin_min: float = 20
@export var spin_max: float = 50
@export var scale_min: float = 0.5
@export var scale_max: float = 0.8
@export var start_speed_min: float = 600
@export var start_speed_max: float = 900
@export var start_angle_variance: float = 40

@onready var lifeTimer: Timer = $Timer

var scale_target: float = 1

func takeGraphicalNode(toTake: Node):
	if "global_position" in toTake:
		global_position = toTake.global_position
	if toTake.get_parent():
		toTake.reparent(self, false)
	else:
		add_child(toTake)

func _ready() -> void:
	var initial_speed = randf_range(start_speed_min, start_speed_max)
	
	var initial_direction = Vector2.UP
	initial_direction = initial_direction.rotated(deg_to_rad(randf_range(-start_angle_variance, start_angle_variance)))
	
	apply_impulse(initial_speed * initial_direction)
	
	#need to set this manually to get rotational velocity because no collider
	inertia = 1
	var spin_direction = 1
	if randi() % 2:
		spin_direction = -1
	apply_torque_impulse(randf_range(spin_min, spin_max) * spin_direction)
	
	#also change z index to look like we're moving towards/away from the camera
	var scale_amount = randf_range(scale_min, scale_max)
	scale_target = 1 - scale_amount

func _process(_delta: float) -> void:
	var effectProgress: float = MittyUtils.map_range(lifeTimer.time_left, lifeTimer.wait_time, 0, 0, 1)
	modulate.a = opacityCurve.sample_baked(effectProgress)
	var uniform_scale = MittyUtils.map_range_clamped(effectProgress, 0, 1, 1, scale_target)
	scale = Vector2(uniform_scale, uniform_scale)

func _on_timer_timeout() -> void:
	print("freeing spin away death")
	queue_free()
