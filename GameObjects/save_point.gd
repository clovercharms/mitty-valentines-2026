extends Node2D

@export var saveSoundEffect: AudioStream
@export var saveCooldown: float = 5
var saveCooldownTimer: SceneTreeTimer

func _ready() -> void:
	saveCooldownTimer = get_tree().create_timer(0)

func _on_player_trigger_player_entered() -> void:
	if saveCooldownTimer.time_left > 0:
		return
	
	GameBase.get_singleton().save_game()
	print("game saved")
	var playerHealth = GameBase.get_singleton().player.find_child("Health")
	if playerHealth:
		playerHealth.heal(100, self)
	if saveSoundEffect: MittyUtils.play_sound(saveSoundEffect)
	
	saveCooldownTimer = get_tree().create_timer(saveCooldown)
