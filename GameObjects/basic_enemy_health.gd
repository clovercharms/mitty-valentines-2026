extends IHealth

@export var startingHealth: int = 1

var currentHealth: int = 1

func _ready() -> void:
    currentHealth = startingHealth

### Interface implementation
func damage(amount: int, cause: Node):
    if(amount <= 0 or currentHealth == 0):
        return
    currentHealth -= amount
    _clampHealth()
    
    print(get_parent().name, "took damage! Remaining health: ", currentHealth)
    
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
