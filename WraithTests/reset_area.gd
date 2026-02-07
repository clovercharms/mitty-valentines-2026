class_name ResetArea extends Marker2D

@onready var area : Area2D = $Area2D



func _on_area_2d_area_entered(area: Area2D) -> void:
    if area.get_parent() is MittyPlayer:
        print("reset_marker changed")
        var player = area.get_parent() as MittyPlayer
        player.reset_position = self
