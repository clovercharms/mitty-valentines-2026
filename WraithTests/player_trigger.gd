class_name PlayerTrigger extends Area2D

signal player_entered

@export var one_shot : bool

var triggered : bool = false


func _on_area_entered(area: Area2D) -> void:
    if area.get_parent() is not MittyPlayer:
        return
    print("player entered trigger area: ", self.name)
    if one_shot and not triggered:
        triggered = true
        player_entered.emit()
    elif not one_shot:
        player_entered.emit()
        
