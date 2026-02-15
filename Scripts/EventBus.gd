extends Node

#just exists to define signals for reliable inter-object communication

@warning_ignore("unused_signal")
signal request_edge_flash(time: float)
@warning_ignore("unused_signal")
signal request_screen_shake(strength: float, axis_bias: Vector2)
