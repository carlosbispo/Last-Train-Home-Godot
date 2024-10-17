extends Node2D

enum items {
	ITEM_LIGHTER,
	ITEM_NEWSPAPER,
	ITEM_PILL_BOTTLE,
	ITEM_
}

var textures = [
	preload("res://data/item_lighter.png"),
	preload("res://data/item_newspaper.png"),
	preload("res://data/item_medicine.png"),
]

var sizes = [
	Vector2(10,17),
	Vector2(19,17),
	Vector2(9,13)
]
var width = 0
var height = 0

export(items) var type = items.ITEM_
export(int) var box_size = 22

onready var sprite = $Sprite

func _ready():
	sprite.texture = textures[type]
	width = sizes[type].x
	height = sizes[type].y
	sprite.set_offset(Vector2((box_size - width) / 2, (box_size - height) / 2))

func set_type(t):
	type = t
