extends Control

@onready var counter_label = $HBoxContainer/MarginContainer/Label


func _ready():
	MessageDatabase.note_found.connect(_update_counter)
	_update_counter()
	
	
func _update_counter():
	var max = MessageDatabase.vmessage_database.size()
	var current = MessageDatabase.vmessage_database.values().filter(func(data): return data.discovered).size()
	var current_string = "%02d" % current
	counter_label.text = str(current_string) + " / " + str(max)
