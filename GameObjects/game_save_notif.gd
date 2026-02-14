extends Label

@export var displayTime: float = 1

var visibleTimer: SceneTreeTimer

func _process(_delta: float) -> void:
	if not visible:
		return
	
	if visibleTimer and visibleTimer.time_left <= 0:
		visible = false

func _on_game_base_game_saved() -> void:
	visible = true
	visibleTimer = get_tree().create_timer(displayTime)
