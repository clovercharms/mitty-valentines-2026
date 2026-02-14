extends Node

@export var amplify_db: float = 0: set = amplify_setter, get = amplify_getter

func amplify_setter(value: float):
	amplify_db = value
	# we just have to know the bus effect layout for this
	AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 0).volume_db = value

func amplify_getter() -> float:
	return amplify_db

@export var filter_cutoff: float = 20000: set = filter_setter, get = filter_getter

func filter_setter(value: float):
	filter_cutoff = value
	# we just have to know the bus effect layout for this
	AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 1).cutoff_hz = value

func filter_getter() -> float:
	return filter_cutoff
