extends Area2D

@export var enabled : bool = true

func _on_area_entered(area: Area2D) -> void:
    if area.get_parent() is not MittyPlayer or not enabled:
        return
    
    print("player touched reset zone")
    
    var player = area.get_parent() as MittyPlayer
    player.tween_to_reset_marker()
