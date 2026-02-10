extends Node2D

@export var velocityReference: CharacterBody2D
@export var minFlipVelocity: float = 10

func _process(_delta: float) -> void:
	if not velocityReference:
		return
	
	if(velocityReference.velocity.x > minFlipVelocity and scale.x < 0):
		scale.x = abs(scale.x)
	elif(velocityReference.velocity.x < -minFlipVelocity and scale.x > 0):
		scale.x *= -1
