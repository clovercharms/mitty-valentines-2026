extends "res://addons/MetroidvaniaSystem/Template/Scripts/MetSysGame.gd"
class_name GameBase

const SaveManager = preload("res://addons/MetroidvaniaSystem/Template/Scripts/SaveManager.gd")
const SAVE_PATH = "user://save0.sav"
const QUEST_STATE = "quest_state"
const PLAYER_ABILITIES = "player_abilities"
const COLLECTED_MESSGAES = "collected_messages"
const UNIQUE_ENEMIES = "unique_enemies"
const PICKUPS = "pickups"
const CURRENT_ROOM = "current_room"

@onready var ui_layer : CanvasLayer = $"UI Layer"
@onready var BGM: AudioStreamPlayer = $BGMPlayer
@onready var BossMusic: AudioStreamPlayer = $BossMusicPlayer

@export_group("Game Settings")
@export var startingMap: String
@export var playerScene: PackedScene
@export var deathResetWait: float = 7

signal game_saved

enum PlayerAbility { DOUBLE_JUMP }

# Saved data. Just let other classes access it directly for this project.
var questState: Dictionary
var playerAbilities: Array[bool]
var collectedMessages: Array[int]
var uniqueEnemies: Dictionary
var pickups: Array[String]
var impost0rId: float = 0

# Unsaved global game state
var enemiesKilledSinceSave: Dictionary #To handle non-respawning enemies

var currentMessageID : int

func _ready() -> void:
	# A trick for static object reference
	get_script().set_meta(&"singleton", self)
	# Make sure MetSys is in initial state.
	MetSys.reset_state()
	
	# CreatePlayer
	var createdPlayer : MittyPlayer = spawn_object_at_location(playerScene, Vector2i())
	set_player(createdPlayer)
	createdPlayer.find_child("Health").connect("death", on_player_death)
	for i in PlayerAbility.size():
		playerAbilities.append(false)
	#TESTING
	
	if FileAccess.file_exists(SAVE_PATH) and not SessionState.isNewGame:
		# If save data exists, load it using MetSys SaveManager.
		var save_manager := SaveManager.new()
		save_manager.load_from_text(SAVE_PATH)
		# Assign loaded values.
		questState.assign(save_manager.get_value(QUEST_STATE))
		playerAbilities.assign(save_manager.get_value(PLAYER_ABILITIES))
		collectedMessages.assign(save_manager.get_value(COLLECTED_MESSGAES))
		uniqueEnemies.assign(save_manager.get_value(UNIQUE_ENEMIES))
		pickups.assign(save_manager.get_value(PICKUPS))
		
		var loaded_starting_map: String = save_manager.get_value(CURRENT_ROOM)
		if not loaded_starting_map.is_empty(): # Some compatibility problem.
			startingMap = loaded_starting_map
	else:
		# If no data exists, set empty one.
		MetSys.set_save_data()
		save_game()
	
	SessionState.isNewGame = false
	for messageId in collectedMessages:
		MessageDatabase.discover_message(messageId)
	print("Loaded ", collectedMessages.size(), " collected messages")
	
	# Initialize room when it changes.
	room_loaded.connect(init_room, CONNECT_DEFERRED)
	# Load the starting room.
	load_room(startingMap)
	
	# Find the save point and teleport the player to it, to start at the save point.
	var start := map.get_node_or_null(^"Triggers/SavePoint")
	player.position = start.position
	
	# Add module for room transitions.
	add_module("RoomTransitions.gd")
	# You can enable alternate transition effect by using this module instead.
	#add_module("ScrollingRoomTransitions.gd")

# Returns this node from anywhere.
static func get_singleton() -> GameBase:
	return (GameBase as Script).get_meta(&"singleton") as GameBase

static func spawn_object_at_location(object: PackedScene, location: Vector2i) -> Node:
	var instance = object.instantiate()
	get_singleton().add_child(instance)
	if(instance is Node2D):
		instance.global_position = location
	return instance

func save_game():
	var save_manager := SaveManager.new()
	save_manager.set_value(QUEST_STATE, questState)
	save_manager.set_value(PLAYER_ABILITIES, playerAbilities)
	save_manager.set_value(COLLECTED_MESSGAES, collectedMessages)
	save_manager.set_value(UNIQUE_ENEMIES, uniqueEnemies)
	save_manager.set_value(PICKUPS, pickups)
	save_manager.set_value(CURRENT_ROOM, MetSys.get_current_room_id())
	save_manager.save_as_text(SAVE_PATH)
	
	game_saved.emit()

func init_room():
	player.on_enter()
	
	# Initializes MetSys.get_current_coords(), so you can use it from the beginning.
	if MetSys.last_player_position.x == Vector2i.MAX.x:
		MetSys.set_player_position(player.position)
		

func unlock_player_ability(ability: PlayerAbility):
	playerAbilities[ability] = true

func player_has_ability(ability: PlayerAbility) -> bool:
	return playerAbilities[ability]

func on_player_death(_cause: Node):
	BGM.stop()
	BossMusic.stop()
	var resetTimer = get_tree().create_timer(deathResetWait, true, false, true)
	await resetTimer.timeout
	get_tree().reload_current_scene()
	BGM.play()


func _on_bgm_player_finished() -> void:
	if not BossMusic.playing:
		BGM.play()


func _on_boss_music_player_finished() -> void:
	if not BGM.playing:
		BossMusic.play()
