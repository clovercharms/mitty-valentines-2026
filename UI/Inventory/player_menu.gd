extends Control

@onready var header_label = $Panel/MainLayout/HeaderMargin/Header/HeaderLabel
@onready var content_switcher = $Panel/MainLayout/ContentSwitcher

@onready var vday_item_list = $Panel/MainLayout/ContentSwitcher/ItemMenu/MarginContainer/ItemListSection/VDayItemContainer

@onready var vday_active_text = $Panel/MainLayout/ContentSwitcher/ItemMenu/VMessageContainer/MarginContainer/ScrollContainer/RichTextLabel
@onready var vday_active_image_preview = $Panel/MainLayout/ContentSwitcher/ItemMenu/VMessageContainer/MarginContainer2/PreviewImage

@onready var fullsize_overlay = $Panel/FullScreenOverlay
@onready var fullsize_image = $Panel/FullScreenOverlay/MarginContainer/FullSizeImage
@onready var db_node = $ItemDatabase

var current_focused_item_data = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	db_node.discover(1) # TODO: probably smarter to make this a signal
	reload_messages()

func _physics_process(_delta):
	handle_menu_switching_input()
	handle_fullscreen_input()
	
# TODO: call this method when data updates (discovers messages, sits on bench, etc)
func reload_messages():
	
	for child in vday_item_list.get_children():
		child.queue_free()
		
	# Loop through all loaded item objects
	for item in db_node.vmessage_database.values():
		var btn = preload("res://UI/Inventory/ValentinesItem.tscn").instantiate()
		vday_item_list.add_child(btn)
		
		# Setup the button
		btn.setup(item)
		btn.item_focused.connect(_update_details_panel)
	_update_details_panel(db_node.vmessage_database[0])
		

func handle_menu_switching_input():
	if Input.is_action_just_pressed("UI_Left"): # L1 or Q
		# Logic to cycle tabs backwards
		content_switcher.current_tab -= 1
	elif Input.is_action_just_pressed("UI_Right"): # R1 or E
		# Logic to cycle tabs forward
		content_switcher.current_tab += 1

func _update_details_panel(data: MessageData):
	current_focused_item_data = data
	# Update the right side UI
	if data.discovered:
		vday_active_image_preview.texture = data.drawing_texture
		vday_active_text.text = data.message
	else:
		# reads: gofinditbrat
		vday_active_text.text = "█▀█▀░ █▀█▀█ ░▀░▀█▀░ ░▀░ █▀░ █▀░▀░ ░▀░ █ █▀░▀░▀░ ░▀█▀░ ░▀█ █"
		vday_active_image_preview.texture = null

func handle_fullscreen_input():
	# Toggle Full Screen
	if Input.is_action_just_pressed("UI_Details"):
		if fullsize_overlay.visible:
			close_fullscreen()
		else:
			open_fullscreen()

func open_fullscreen():
	if current_focused_item_data.discovered:
		fullsize_image.texture = current_focused_item_data.drawing_texture
		fullsize_overlay.visible = true
		# Pause navigation of background menu
		vday_item_list.process_mode = Node.PROCESS_MODE_DISABLED

func close_fullscreen():
	fullsize_overlay.visible = false
	# Re-enable navigation
	vday_item_list.process_mode = Node.PROCESS_MODE_INHERIT
	# Important: Return focus to the list so controller doesn't get lost
	get_viewport().gui_get_focus_owner().grab_focus()
