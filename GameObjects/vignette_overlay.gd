extends CanvasLayer

@export var flash_curve: Curve
@export var canvas: CanvasItem

var base_vignette_intensity: float
var base_vignette_opacity: float
var flash_timer: float = 0
var current_flash_time: float = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	base_vignette_intensity = 0.4
	base_vignette_opacity = 0.5
	visible = false
	
	EventBus.request_edge_flash.connect(flash)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if flash_timer <= 0:
		visible = false
		return
	
	flash_timer -= delta
	var intensity: float = 1 - flash_curve.sample_baked(MittyUtils.map_range_clamped(flash_timer, 0, current_flash_time, 0, 1))
	canvas.material.set_shader_parameter("vignette_intensity", MittyUtils.map_range_clamped(intensity, 0, 1, 0, base_vignette_intensity))
	canvas.material.set_shader_parameter("vignette_opacity", MittyUtils.map_range_clamped(intensity, 0, 1, 0, base_vignette_opacity))

func flash(time: float):
	print("vignette flash")
	visible = true
	current_flash_time = time
	flash_timer = time
