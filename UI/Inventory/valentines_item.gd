extends Button

# Signal to tell the Menu to update the details
signal item_focused(item_data)

@onready var new_indicator = $NewIndicator

var my_data = {} # Holds texture, description, etc.

func setup(data: MessageData):
    my_data = data
    if data.discovered:
        text = data.name
        icon = data.avatar_texture
        
        if data.new == true:
            new_indicator.visible = true
        else:
            new_indicator.visible = false
        
    else:
        text = "     ???"
        icon = load("res://ArtAssets/UI/unknown.png")
    
func _ready():
    # Connect Godot's built-in focus signal
    focus_entered.connect(_on_focus_entered)

func _on_focus_entered():
    # Emit our custom signal with data up to the UI
    if my_data.id != null:
        item_focused.emit(my_data)
    if my_data.new == true:
        mark_as_read()
    

func mark_as_read():
    # Update the local data object
    my_data.new = false
    
    # Hide the visual indicator immediately
    new_indicator.visible = false
    MessageDatabase.message_seen(my_data.id)
