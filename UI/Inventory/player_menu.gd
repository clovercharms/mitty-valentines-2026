extends Control

@onready var header_label = $Panel/MainLayout/HeaderMargin/Header/HeaderLabel
@onready var content_switcher = $Panel/MainLayout/ContentSwitcher

@onready var vday_item_list = $Panel/MainLayout/ContentSwitcher/ItemMenu/MarginContainer/ItemListSection/VDayItemContainer

@onready var vday_active_text = $Panel/MainLayout/ContentSwitcher/ItemMenu/VMessageContainer/MarginContainer/ScrollContainer/RichTextLabel
@onready var vday_active_image_preview = $Panel/MainLayout/ContentSwitcher/ItemMenu/VMessageContainer/MarginContainer2/PreviewImage

@onready var fullsize_overlay = $Panel/FullScreenOverlay
@onready var fullsize_image = $Panel/FullScreenOverlay/MarginContainer/FullSizeImage
@onready var hud = get_parent().get_node("HUD")

var current_focused_item_data: MessageData = null
var dirty: bool = true
var decoded = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	MessageDatabase.note_found.connect(_on_note_found)
	reload_messages()

func _physics_process(_delta):
	handle_menu_switching_input()
	handle_fullscreen_input()
	
func reload_messages():
	for child in vday_item_list.get_children():
		child.queue_free()
		
	# Loop through all loaded item objects
	var messages = MessageDatabase.vmessage_database.values().filter(filter_discovered)
	for item: MessageData in messages:
		var btn = preload("res://UI/Inventory/ValentinesItem.tscn").instantiate()
		vday_item_list.add_child(btn)
		
		# Setup the button
		btn.setup(item)
		btn.item_focused.connect(_update_details_panel)
	
func filter_discovered(data: MessageData):
	return data.discovered

func handle_menu_switching_input():
	if Input.is_action_just_pressed("UI_Left") and visible == true: # L1 or Q
		# Logic to cycle tabs backwards
		content_switcher.current_tab -= 1
	elif Input.is_action_just_pressed("UI_Right") and visible == true: # R1 or E
		# Logic to cycle tabs forward
		content_switcher.current_tab += 1
	elif Input.is_action_just_pressed("Toggle_Menu"): # R1 or E
		#if dirty and !visible:
			#reload_messages()
			#dirty = false;
		if visible:
			fullsize_overlay.visible = false
		visible = !visible
		get_tree().paused = visible
		hud.visible = !visible
		# focus last item
		if visible && vday_item_list.get_children().size() > 0:
			if current_focused_item_data != null && vday_item_list.get_child_count() > current_focused_item_data.id:
				vday_item_list.get_child(current_focused_item_data.id).grab_focus()
			else:
				vday_item_list.get_child(0).grab_focus()


func _update_details_panel(data: MessageData):
	decoded = GameBase.get_singleton().pickups.has("decoder")
	current_focused_item_data = data
	# Update the right side UI
	if decoded:
		vday_active_image_preview.texture = data.drawing_texture
		vday_active_text.text = data.message
	else:
		# reads: findthekey
		vday_active_text.text = "░▀░▀█▀░ ░▀░ █▀░ █▀░▀░ █ ░▀░▀░▀░ ░ █▀░▀█ ░ █▀░▀█▀█\n\n" + scramble_text(data.message)
		vday_active_image_preview.texture = load("res://ArtAssets/UI/unknown.png")
		
func handle_fullscreen_input():
	# Toggle Full Screen
	if Input.is_action_just_pressed("UI_Details") and visible == true:
		if fullsize_overlay.visible:
			close_fullscreen()
		else:
			open_fullscreen()

func open_fullscreen():
	if current_focused_item_data.has_drawing:
		fullsize_image.texture = current_focused_item_data.drawing_texture
		fullsize_overlay.visible = true
		# Pause navigation of background menu
		vday_item_list.process_mode = Node.PROCESS_MODE_DISABLED

func close_fullscreen():
	fullsize_overlay.visible = false
	# Re-enable navigation
	vday_item_list.process_mode = Node.PROCESS_MODE_INHERIT
	# Important: Return focus to the list so controller doesn't get lost
	var focus = get_viewport().gui_get_focus_owner()
	if focus != null:
		focus.grab_focus()
	
const CHARACTERS := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 !@#$%^&*()"

func scramble_text(text : String) -> String:
	var result : String = ""
	var chars = CHARACTERS.length()
	for i in range(text.length()):
		var index = randi_range(0, chars - 1)
		result += CHARACTERS[index]
	return result

func _on_note_found() -> void:
	reload_messages()
