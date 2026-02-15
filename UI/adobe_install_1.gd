extends Sprite2D

func _ready():
	Adobe.ShowAdobe1.connect(_on_show_Adobe1)
	Adobe.ShowAdobe2.connect(_on_show_Adobe2)

func _on_show_Adobe1():
	self.visible = true

func _on_show_Adobe2():
	self.visible = false
