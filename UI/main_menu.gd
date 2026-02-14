extends Control

@onready var start_btn = $VBoxContainer/StartButton
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    start_btn.grab_focus()
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    pass


func _on_start_button_pressed() -> void:
    get_tree().change_scene_to_file("res://GameBase.tscn")


func _on_quit_button_pressed() -> void:
    get_tree().quit()


func _on_new_game_button_pressed() -> void:
    SessionState.isNewGame = true
    get_tree().change_scene_to_file("res://GameBase.tscn")
