extends Area2D

@export var damage: int = 1
@export var hitBehavior: hitType = hitType.ONCE_PER

enum hitType { REPEATED, FIRST, ONCE_PER }

@export var damageCause: Node = null
var alreadyHit: Array = []
var canHit: bool = true
var isEnabled: bool = true

func setEnabled(enabled: bool):
	isEnabled = enabled

func _on_body_entered(body: Node2D) -> void:
	if(not canHit or not isEnabled):
		return
	
	#print(name, " hit ", body.name)
	
	var health: IHealth = body.get_node("Health")
	if(health == null):
		return
	
	if(hitBehavior == hitType.ONCE_PER):
		if(alreadyHit.has(body)):
			return
		alreadyHit.append(body)
	
	health.damage(damage, damageCause)
	
	if(hitBehavior == hitType.FIRST):
		canHit = false
		disconnect("body_entered", self._on_body_entered)
