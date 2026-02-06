# Health interface.
# Creates unified way for hitboxes/hurtboxes to interact with health models.

extends Node
class_name IHealth

@warning_ignore("unused_signal")
signal hurt(amount: int, cause: Node)
@warning_ignore("unused_signal")
signal healed(amount: int, cause: Node)
@warning_ignore("unused_signal")
signal death(cause: Node)
@warning_ignore("unused_signal")
signal hitInvulnerabilityStart
@warning_ignore("unused_signal")
signal hitInvulnerabilityStop

@warning_ignore("unused_parameter")
func damage(amount: int, cause: Node):
	pass

@warning_ignore("unused_parameter")
func heal(amount: int, cause: Node):
	pass

@warning_ignore("unused_parameter")
func instantKill(cause: Node):
	pass
