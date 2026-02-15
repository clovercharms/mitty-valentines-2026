extends Sprite2D

func _ready():
	Adobe.ShowAdobe2.connect(_on_show_Adobe2)
	Adobe.ShowAdobeFinal.connect(_on_show_AdobeFinal)

func _on_show_Adobe2():
	self.visible = true

func _on_show_AdobeFinal():
	self.visible = false
