class_name TestingUI extends Control

@onready var heart_container = $HeartContainer
var testing_heart : PackedScene = preload("res://WraithTests/testing_heart_circle.tscn")

var player_hearts : int
var player_health : float

var player_stats : StatBlock

func update(stats : StatBlock):
	player_hearts = stats.max_health / 4
	player_health = stats.current_health / 4
	
	for i in range(heart_container.get_child_count()):
		if (i != 0):
			heart_container.get_child(i).queue_free()
	
	for i in range(player_hearts):
		print(i)
		var instance : TestingHeartCircle = testing_heart.instantiate()
		heart_container.add_child(instance)
		if (player_health >= i + 1):
			instance.fill(1.0)
		elif (player_health > i):
			var dec : float = player_health - int(player_health)
			instance.fill(dec)
		else:
			instance.fill(0.0)
			
func _unhandled_input(event: InputEvent):
	if player_stats == null:
		return
	if (event is InputEventKey):
		if (event.as_text_keycode() == "Shift+Minus" and event.pressed):
			if (player_stats.current_health == 0):
				return
			player_stats.take_damage(1)
		elif (event.as_text_keycode() == "Shift+Equal" and event.pressed):
			if (player_stats.current_health == player_stats.max_health):
				player_stats.max_health += 4
			player_stats.heal(1)
			update(player_stats)
			  
		
		
