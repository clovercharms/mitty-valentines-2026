extends Node

@export var lifespan: float = 1

func _ready() -> void:
	var timer = get_tree().create_timer(lifespan)
	await timer.timeout
	queue_free()
