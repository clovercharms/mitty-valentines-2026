extends Node2D
class_name UiHeart

@export var pulseTime: float = 0.25
@export var pulseCurve: Curve
@export var emptyScene: PackedScene

@onready var emptyGraphic: CanvasItem = $EmptyPip
@onready var fullGraphic: CanvasItem = $FullHeart

var baseScale: Vector2
var isFull: bool = true
var isPulsing: bool = false
var pulseTimer: SceneTreeTimer

func _ready() -> void:
	baseScale = scale

func _process(_delta: float) -> void:
	if not isPulsing:
		return
	
	if pulseTimer.time_left <= 0:
		scale = baseScale
		isPulsing = false
		return
	
	var effectProgress = MittyUtils.map_range(pulseTimer.time_left, pulseTime, 0, 0, 1)
	var uniformScale = pulseCurve.sample_baked(effectProgress)
	scale = baseScale * uniformScale

func fill():
	emptyGraphic.visible = false
	fullGraphic.visible = true
	if not isFull:
		pulse()
	isFull = true

func empty():
	emptyGraphic.visible = true
	fullGraphic.visible = false
	
	if not isFull:
		return
	isFull = false
	
	var heartClone: Sprite2D = fullGraphic.duplicate()
	heartClone.visible = true
	heartClone.z_index = 10
	var emptyEffect = MittyUtils.spawn_child(self, emptyScene, Vector2(0,0))
	emptyEffect.takeGraphicalNode(heartClone)
	print(heartClone.visible)

func pulse():
	isPulsing = true
	pulseTimer = get_tree().create_timer(pulseTime)
