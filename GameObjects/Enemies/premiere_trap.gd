extends StaticBody2D

@export var hitboxActivationDelay: float = 0.25
@export var deathScene: PackedScene
@export var extendSound: AudioStream
@export var retractSound: AudioStream

@onready var mainSprite: AnimatedSprite2D = $MainSprite
@onready var hitbox: Node = $Hitbox

# Need to make sure the state is still valid after waiting so we don't get dumb corner cases
enum State { WAIT, OPENING, ACTIVE, CLOSING }
var currentState: State

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enter_wait()

func enter_wait():
	currentState = State.WAIT
	hitbox.setEnabled(false)
	mainSprite.play("wait")

func enter_opening():
	currentState = State.OPENING
	mainSprite.play("open")
	MittyUtils.play_sound(extendSound)
	var hitboxTimer: SceneTreeTimer = get_tree().create_timer(hitboxActivationDelay)
	await hitboxTimer.timeout
	if currentState == State.OPENING:
		print("hitbox activating")
		hitbox.setEnabled(true)
	await mainSprite.animation_finished
	if currentState == State.OPENING:
		enter_active()

func enter_active():
	currentState = State.ACTIVE
	hitbox.setEnabled(true)
	mainSprite.play("active")

func enter_closing():
	currentState = State.CLOSING
	hitbox.setEnabled(false)
	mainSprite.play("close")
	MittyUtils.play_sound(retractSound)
	await mainSprite.animation_finished
	if currentState == State.CLOSING:
		enter_wait()

func _on_activate_trigger_body_entered(_body: Node2D) -> void:
	if currentState != State.ACTIVE:
		enter_opening()

func _on_deactivate_trigger_body_exited(_body: Node2D) -> void:
	if currentState == State.ACTIVE or currentState == State.OPENING:
		enter_closing()

func _on_health_death(_cause: Node) -> void:
	MittyUtils.hit_stop(0.1)
	var deathEffectInstance = MittyUtils.spawn_at_location(deathScene, global_position)
	deathEffectInstance.takeGraphicalNode(mainSprite)
	
	# Easteregg message for Imposter
	var gb = GameBase.get_singleton()
	if Adobe.impost0rId != -1 and not gb.collectedMessages.has(Adobe.impost0rId):
		gb.collectedMessages.append(Adobe.impost0rId)
		MessageDatabase.discover_message(Adobe.impost0rId)
		gb.checkGameFinished()
		print(gb.collectedMessages)
	
	queue_free()
