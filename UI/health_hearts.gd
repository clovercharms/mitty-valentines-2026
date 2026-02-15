extends Node2D

@export var heartSpacing: float = 120
@export var heartScene: PackedScene

var isInitialized: bool = false
var hearts: Array[UiHeart]
var playerHealth: IHealth

func _process(_delta: float) -> void:
	tryLazyInit()

func tryLazyInit():
	if isInitialized: return
	if not GameBase.get_singleton(): return
	
	playerHealth = GameBase.get_singleton().player.find_child("Health")
	for i in playerHealth.getMaxHealth():
		var newHeart: Node2D = heartScene.instantiate()
		add_child(newHeart)
		newHeart.global_position = global_position
		newHeart.position.x += heartSpacing * i
		hearts.append(newHeart)
	
	playerHealth.connect("hurt", on_hurt)
	playerHealth.connect("healed", on_healed)
	playerHealth.connect("death", on_death)
	
	isInitialized = true

func updateHealthState(currentHealth: int):
	for i in hearts.size():
		if i < currentHealth:
			hearts[i].fill()
		else:
			hearts[i].empty()

func on_hurt(_amount: int, _cause: Node):
	updateHealthState(playerHealth.getCurrentHealth())

func on_healed(_amount: int, _cause: Node):
	updateHealthState(playerHealth.getCurrentHealth())

func on_death(_cause: Node):
	updateHealthState(0)

func _on_heart_pulse_timer_timeout() -> void:
	#pulse the heart at the end of the bar
	var currentHealth: int = playerHealth.getCurrentHealth()
	if currentHealth > 0:
		hearts[currentHealth - 1].pulse()
