extends Area2D



func _on_area_entered(area: Area2D) -> void:
    if area.get_parent() is not MittyPlayer:
        return
    
    print("player touched reset zone")
    
    var player = area.get_parent() as MittyPlayer
    player.tween_to_reset_position()
