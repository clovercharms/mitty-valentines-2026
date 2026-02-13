class_name PopupMessage extends PopupPanel

@onready var label : Label = $Label

@export var message : String = ""

func _ready() -> void:
    label.text = message
    
func kill_popup() -> void:
    await get_tree().create_timer(5).timeout
    queue_free()
