extends Node2D

onready var animation = $AnimationPlayer
onready var sprite = $Sprite
onready var foots_steps = $FootSteps

enum types{
  ENTITY_UNKNOWN,
  ENTITY_PLAYER,
  ENTITY_DOOR,
  ENTITY_TRAIN_BG,
  ENTITY_NEWSPAPER_GUY,
  ENTITY_VOMIT_GIRL,
  ENTITY_HOMELESS_GUY,
  ENTITY_SMOKER,
  ENTITY_LITTLE_GIRL,
  ENTITY_LIGHT,
  ENTITY_TIMER,
  ENTITY_RAIL_HANDLE,
  ENTITY_EVIL_LITTLE_GIRL,
  ENTITY_SPIDER,
  ENTITY_TRAIN_DOOR,
}

enum facings {
	FACING_RIGHT,
	FACING_LEFT,
}

export(types) var type = types.ENTITY_UNKNOWN
export(int) var speed = 10
export(int) var width = 10
export(int) var height = 10
export(int) var direction = 1
export(int) var offset_height = 0
export(int) var timer_left = 0
export(bool) var auto_adjust_height = true
export(bool) var suspended = false
export(bool) var is_flashlight = false
export(Color) var color = Color.white
export(int) var light_radius = 50
export(String) var on_use = ""
export(String) var on_over = ""
export(facings) var facing = facings.FACING_RIGHT
const FLOOR_Y = 131
var state

var current_footstep = 0

func _ready():
	if auto_adjust_height:
		position.y = FLOOR_Y - height + offset_height
	set_facing(facing)

func play_animation(anim):
	animation.play(anim)

func set_facing(f):
	sprite.flip_h = (f == facings.FACING_LEFT)

func is_facing(f):
	return (f == facings.FACING_LEFT) if sprite.flip_h else (f == facings.FACING_RIGHT)
	
func do_step_sound():
	foots_steps.get_child(current_footstep).play()
	current_footstep = (current_footstep + 1) % foots_steps.get_child_count()

func set_animation_speed(scale):
	animation.set_speed_scale(scale)

func is_playing():
	return animation.is_playing()

func suspend():
	suspended = true
	animation.stop(false)

func unsuspend():
	suspended = false


