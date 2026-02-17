extends Panel

var minutes: int = 0
var seconds: int = 0
var miliseconds: int = 0

var gb : GameBase

func _process(delta) -> void:
	if not gb:
		gb = GameBase.get_singleton()
	if gb.deathCounter != 0:
		$DeathCounterGhost.visible = true
		$DeathCounterGhost/DeathCounter.text = str(gb.deathCounter)
		
	if gb.doTimer:
		gb.time += delta
	
	miliseconds = fmod(gb.time, 1) * 100
	seconds = fmod(gb.time, 60)
	minutes = fmod(gb.time, 3600) / 60
	$TimeIcon/minutes.text = "%02d:" % minutes
	$TimeIcon/seconds.text = "%02d." % seconds
	$TimeIcon/miliseconds.text = "%02d" % miliseconds
