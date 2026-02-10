extends Node

@export_group("Hit Flash")
@export var doHitFlash: bool = false
@export var toModulate: CanvasItem
@export var flashColor: Color = Color("FF0000")
@export var flashDuration: float = 0.2

var originalColor: Color
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if toModulate:
		originalColor = toModulate.modulate

func _on_health_hurt(_amount: int, _cause: Node) -> void:
	if doHitFlash:
		toModulate.modulate = flashColor
		var timer = get_tree().create_timer(flashDuration)
		await timer.timeout
		toModulate.modulate = originalColor
