class_name Pickup extends StaticBody2D

signal picked_up

@export var texture : Texture2D
@export var texture_scale : Vector2 = Vector2.ONE
@export var pickup_id : String = ""

func _ready() -> void:
    if GameBase.get_singleton().pickups.has(pickup_id):
        queue_free()
    $Sprite.texture = texture
    $Sprite.scale = texture_scale
    hover()
    
func hover() -> void:
    var tween = create_tween().set_parallel(true)
    tween.tween_property(self, "global_position", global_position + Vector2(0, -50), 1)
    tween.tween_property(self, "scale", Vector2(1.1, 1.1), 1)
    await tween.finished
    tween = create_tween().set_parallel(true)
    tween.tween_property(self, "global_position", global_position + Vector2(0, 50), 1)
    tween.tween_property(self, "scale", Vector2.ONE, 1)
    await tween.finished
    hover()
    
func area_entered(area : Area2D) -> void:
    var player = GameBase.get_singleton().player
    var pos = player.global_position
    if area.get_parent() is not MittyPlayer:
        return
    
    var tween = create_tween().set_parallel(true)
    tween.tween_property(self, "global_position", pos, 0.75)
    tween.tween_property(self, "rotation_degrees", 360 * 10, 0.75)
    await tween.finished
    
    GameBase.get_singleton().pickups.append(pickup_id)
    picked_up.emit()
    queue_free()
    
    
