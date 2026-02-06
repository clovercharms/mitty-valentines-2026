extends IHealth

@export var startingHealth: int

var currentHealth: int = startingHealth

### Interface implementation
func damage(amount: int, cause: Node):
	if(amount <= 0):
		return
	currentHealth -= amount
	_clampHealth()
	
	if(currentHealth == 0):
		death.emit(cause)
	else:
		hurt.emit(amount, cause)

func instantKill(cause: Node):
	currentHealth = 0
	death.emit(cause)

### Helpers
func _clampHealth():
	currentHealth = clamp(currentHealth, 0, startingHealth)
