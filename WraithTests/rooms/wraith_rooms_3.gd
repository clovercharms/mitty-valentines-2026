extends Node2D

func _on_decoder_picked_up() -> void:
    var popup : PopupMessage = preload("res://GameObjects/popup_message.tscn").instantiate()
    popup.message = "You got the decoder!  I wonder if those messages are readable now?"
    add_child(popup)
    popup.popup()
