extends Node2D

const TRAIN_LEFT = 7
const TRAIN_RIGHT = 309
const GAP_LEFT = 132
const GAP_RIGHT = 216


export(bool) var is_gap = false
export(String, FILE, "*.tscn") var left_scene
export(String, FILE, "*.tscn") var right_scene
export(String) var ready_function
export(bool) var skip_left = false
export(Vector3) var ambient = Vector3(1,1,1)
var left = TRAIN_LEFT
var right = TRAIN_RIGHT

onready var entities = $Entities
onready var ambient_audio_list = $AmbientAudioList

func _ready():
	if is_gap:
		left = GAP_LEFT
		right = GAP_RIGHT
		
	if skip_left:
		left_scene = "res://SceneDarkGap0.tscn"
	
func add_ambient_sound(source, volume):
	var sound = AudioStreamPlayer.new()
	sound.set_stream(load('data/'+source+'.ogg'))
	ambient_audio_list.add_child(sound)
	sound.set_volume_db(volume)
	sound.play()
