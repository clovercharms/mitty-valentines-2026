extends Button

# Signal to tell the Menu to update the details
signal item_focused(item_data)

var my_data = {} # Holds texture, description, etc.

func setup(data: MessageData):
	my_data = data
	if data.discovered:
		text = data.name
		icon = data.avatar_texture
	else:
		text = "???"
		icon = load("res://ArtAssets/UI/unknown.png")
	
func _ready():
	# Connect Godot's built-in focus signal
	focus_entered.connect(_on_focus_entered)

func _on_focus_entered():
	# Emit our custom signal with data up to the UI
	item_focused.emit(my_data)
