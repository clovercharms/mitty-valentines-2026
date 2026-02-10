extends Timer

# Deletes its parent when time runs out
# All timer behavior can be set on the base class
func _on_timeout() -> void:
	get_parent().queue_free()
