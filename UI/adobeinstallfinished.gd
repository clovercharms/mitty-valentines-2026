extends Sprite2D

func _ready():
	Adobe.ShowAdobeFinal.connect(_on_show_AdobeFinal)
	Adobe.HideAdobe.connect(_on_hide_Adobe)

func _on_show_AdobeFinal():
	self.visible = true

func _on_hide_Adobe():
	self.visible = false
