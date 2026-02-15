extends Camera2D

@export var decay: float = 0.8 #How quickly shaking will stop [0,1].
@export var max_offset := Vector2(100, 75) #Maximum displacement in pixels.
@export var noise : FastNoiseLite #The source of random values.

var noise_y = 0 #Value used to move through the noise

var trauma: float = 0.0 #Current shake strength
var trauma_pwr := 2 #Trauma exponent. Use [2,3]
var offset_scale := Vector2(1,1)

func _ready():
	randomize()
	noise.seed = randi() % 10000
	
	EventBus.request_screen_shake.connect(screen_shake)

func _process(delta):
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()
	#elif offset.x != 0 or offset.y != 0:
	#	lerp(offset.x,0.0,1)
	#	lerp(offset.y,0.0,1)

func shake():
	var amt = pow(trauma, trauma_pwr)
	
	if abs(noise.get_noise_2d(noise.seed*2,noise_y)) > 1:
		print("warning: noise value is greater than 1")
	noise_y += 2
	offset.x = max_offset.x * offset_scale.x * amt * noise.get_noise_2d(noise.seed*2,noise_y)
	offset.y = max_offset.y * offset_scale.y * amt * noise.get_noise_2d(noise.seed*3,noise_y)

func screen_shake(strength: float, axis_bias: Vector2):
	trauma = min(strength, 1.0)
	offset_scale = axis_bias
