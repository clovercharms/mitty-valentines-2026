extends Node

signal note_found()

# Dictionary is better here: we can look up items by ID easily
# Format: { 0: ItemData, 1: ItemData, ... }
var vmessage_database: Dictionary = {}

func _ready():
	load_items_from_csv("res://UI/Inventory/vmessages/messages.csv")

func load_items_from_csv(file_path: String):
	if not FileAccess.file_exists(file_path):
		printerr("CSV file not found: ", file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	
	# 1. Skip the Header row (ID, Name, Description)
	file.get_csv_line()
	
	# 2. Loop through lines
	while not file.eof_reached():
		var line = file.get_csv_line(";")
		
		# Safety check: Ensure line has enough columns
		if line.size() < 5: 
			continue
			
		var new_item = MessageData.new()

		var id_val = line[0].to_int()
		new_item.id = id_val
		
		new_item.name = line[1]
		new_item.message = line[2].replace("\\n","\n\n")
		new_item.has_avatar = line[3].to_lower() == "true"
		new_item.has_drawing = line[4].to_lower() == "true"
		new_item.discovered = false
		new_item.new = false
		
		# zero pad ids to length 2
		var filename_string = "%02d" % id_val
		
		var icon_path = "res://UI/Inventory/vmessages/avatars/%s.png" % filename_string
		var image_path_png = "res://UI/Inventory/vmessages/drawings/%s.png" % filename_string
		var image_path_jpg = "res://UI/Inventory/vmessages/drawings/%s.jpg" % filename_string
		var image_path_jpeg = "res://UI/Inventory/vmessages/drawings/%s.jpeg" % filename_string

		# Load textures if they exist
		if ResourceLoader.exists(icon_path):
			new_item.avatar_texture = load(icon_path)
		elif new_item.has_avatar:
			printerr("ID " + str(new_item.id) + ": "+ new_item.name + " SHOULD HAVE A N AVATAR!!!")
		
		if ResourceLoader.exists(image_path_png):
			new_item.drawing_texture = load(image_path_png)
		elif ResourceLoader.exists(image_path_jpg):
			new_item.drawing_texture = load(image_path_jpg)
		elif ResourceLoader.exists(image_path_jpeg):
			new_item.drawing_texture = load(image_path_jpeg)
		elif new_item.has_drawing:
			printerr("ID " + str(new_item.id) + ": "+ new_item.name + " SHOULD HAVE A DRAWING!!!")
		
		# Add to dictionary using the ID as the Key
		vmessage_database[id_val] = new_item
		
	print("Database loaded with %d items." % vmessage_database.size())

func get_vmessage(id: int) -> MessageData:
	return vmessage_database.get(id)
	
func discover_message(id: int):
	if !vmessage_database[id].discovered:
		vmessage_database[id].new = true
	vmessage_database[id].discovered = true
	note_found.emit()
	
func message_seen(id: int):
	vmessage_database[id].new = false
	# just sets UI state to dirty so it can be refreshed on next lookup
	note_found.emit()
