extends IHealth

@export var baseHealth: int = 5
@export var hitInvulnerabilityTime: float = 0.5

var currentHealth: int = baseHealth
var hitInvulnerability: bool = false
var hardInvulnerability: bool = false

### Interface implementation
func damage(amount: int, cause: Node):
	if(isInvulnerable() or amount <= 0 or currentHealth == 0):
		return
	currentHealth -= amount
	_clampHealth()
	
	print("Mitty took damage! Current health: ", currentHealth)
	
	if(currentHealth == 0):
		death.emit(cause)
	else:
		_setHitInvulnerability(hitInvulnerabilityTime)
		hurt.emit(amount, cause)

func heal(amount: int, cause: Node):
	var startingHealth = currentHealth
	if(amount <= 0):
		return
	currentHealth += amount
	_clampHealth()
	
	if(currentHealth > startingHealth):
		healed.emit(amount, cause)

func instantKill(_cause: Node):
	print("instantKill not implemented for Mitty")

func getCurrentHealth() -> int:
	return currentHealth

func getMaxHealth() -> int:
	return computeMaxHealth()

### Helpers
func computeMaxHealth() -> int:
	return baseHealth

func isInvulnerable():
	return hardInvulnerability or hitInvulnerability

func _clampHealth():
	currentHealth = clamp(currentHealth, 0, computeMaxHealth())

func _setHitInvulnerability(time: float):
	hitInvulnerability = true
	hitInvulnerabilityStart.emit()
	await get_tree().create_timer(time).timeout
	hitInvulnerability = false
	hitInvulnerabilityStop.emit()
