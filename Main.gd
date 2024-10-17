extends ViewportContainer

export(bool) var talked_to_newspaper_guy = false
export(bool) var gave_old_guy_newspaper = false
export(bool) var homeless_guy_gave_newspaper = false
export(bool) var talked_to_homeless_guy = false
export(bool) var spoke_to_little_girl = false
export(bool) var gave_away_lighter = false
export(bool) var talked_to_vomit_girl = false
export(String, FILE, "*.tscn") var first_scene = "res://SceneTrain1.tscn"
export(bool) var should_shake_camera = true
export(bool) var show_window_flash = true
export(float) var next_window_flash_timer = 3.0
export(int) var override_brightness = 1
export(int) var state = 0


const GAME_WIDTH = 320
const GAME_HEIGHT = 180
const GAP_LEFT = 132
const MAX_LIGHTS = 10
const SPIN_GAP = 0.5

var spin_multiply = 1
var cur_scene = ""
var last_scene = ""
var num_lights = 0
var window_flash = 0
var show_final_convo = false
var spin_timer=0
var spin_count = 0
var first_spin_dir = -1
var last_spin_dir = 0
var last_spin_count = spin_count
var ambient_current_volume = 0
var alpha = 0
var request_reset = false
var lightning_brightness = 1
var accept_event = InputEventAction.new()

enum {
	ITEM_LIGHTER,
	ITEM_NEWSPAPER,
	ITEM_PILL_BOTTLE,
	ITEM_
}

enum {
	FACING_RIGHT,
	FACING_LEFT,
}

enum {
  IN_NEWSPAPER_GUY_SAY = 100,
  IN_NEWSPAPER_GUY_REMIND = 200,
  IN_FADE_IN = 300,
  IN_GOTO_SCENE_LEFT = 400,
  IN_GOTO_SCENE_RIGHT = 500,
  IN_VOMIT_GIRL_TALK = 600,
  IN_WONT_OPEN = 700,
  IN_HOMELESS_GUY_TALK = 800,
  IN_SMOKER_TALK = 900,
  IN_LITTLE_GIRL_SAY = 1000,
  IN_FIRST_FLASHLIGHT = 1200,
  IN_FADE_OUT = 1300,
  IN_ENCOUNTER = 1400,
  IN_GOTO_FINAL_CONVERSATION = 1600,
  IN_GO_HOME = 2000,
  IN_EPILOG = 3000,
}

enum facing {
	FACING_RIGHT,
	FACING_LEFT,
}

enum {
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

enum {
	KEY_LEFT,
	KEY_RIGHT
}

var resources = [
	"Dummy",
	"Player",
	"Door",
	"",
	"NewspaperGuy",
	"VomitGirl",
	"HomelessGuy",
	"Smoker",
	"LittleGirl",
	"Light",
	"Timer",
	"RailHandle",
	"EvilLittleGirl",
	"Spider",
	"TrainDoor"
]

var prompt_active = false
var speech_choice_index = -1
var speech_active = false
var proc
var requested_scene
var shake_timer = 0
var impulse_gap = 0.05
var total_magnitude = 0
var impulse_timer = 0
var first_shake =  false
var curtain_is_fading = false
var timer_duration = 0
var rng = RandomNumberGenerator.new()
var little_girl_rhyme_index = 0
var wait_for_type_removed = 0
var flashlight_on = false
var flash_first_on = false
var positions = []
var colors = []
var radii = []
var app_time = 0
var scene_change_fadein_duration_override = 0
var scene_change_fadein_wait_override = 0
var lighting_brightness = 0
var speech_override_timer = 0
var play_animation_type = 0
var button_pressed = false

onready var tween = $Tween
onready var canvas = $Canvas
onready var speechbox = $SpeechBox
onready var prompt = $Prompt
onready var background = $Background
onready var curtain = $Curtain 
onready var music_list = $MusicList
onready var music_list_fade_out_tween = $MusicListFadeOutTween
onready var ambient_volume_tween = $AmbientVolumeTween
onready var ending_text_fade_in = $EndingTextFadeIn
onready var end_text = $EndText
onready var item_notification = $ItemNotification
onready var items = $Items
onready var action_button = $"Virtual Joystick/TouchScreenButton"

func _ready():
	if OS.has_touchscreen_ui_hint() :
		spin_multiply = 0.2

	rng.randomize()
	requested_scene = first_scene
	change_scene()
	set_state(IN_FADE_IN)
	for i in MAX_LIGHTS:
		positions.push_back(Vector2.ZERO)
		radii.push_back(0)
		colors.push_back(Color(0,0,0,0))
	speechbox.connect("dismiss", self, "_on_SpeechBox_dismiss")

func reset_game():
	delete_items()
	fade_out_all_music()
	fade_ambient_sound(1,1)
	reset_end_text()
	set_state(IN_FADE_IN)
	# clear flags
	talked_to_newspaper_guy = false
	gave_old_guy_newspaper = false
	homeless_guy_gave_newspaper = false
	talked_to_homeless_guy = false
	spoke_to_little_girl = false
	gave_away_lighter = false
	talked_to_vomit_girl = false
	
	# clear_items
	requested_scene = first_scene
	curtain_is_fading = false
	should_shake_camera = true
	show_window_flash = true
	flash_first_on = false
	flashlight_on = false
	alpha = 0

func delete_items():
	for item in items.get_children():
		item.queue_free()

func update_state(dt):
	if speech_active:
		return
	if curtain_is_fading:
		return
	if timer_duration:
		return
	if play_animation_type:
		var en = find_entity(play_animation_type)
		if !en.is_playing():
			play_animation_type = 0
		return
	if wait_for_type_removed:
		var en = find_entity(wait_for_type_removed)
		if !en:
			wait_for_type_removed = 0
		return

	match state:
		0,1,2,4,5,6,7,8,10,11,12,13,14,15,16,17,18,19:pass
		IN_NEWSPAPER_GUY_SAY:
			if gave_old_guy_newspaper:
				set_state(IN_NEWSPAPER_GUY_SAY + 50)
				return
			elif has_item(ITEM_NEWSPAPER):
				set_state(IN_NEWSPAPER_GUY_SAY + 20)
				return
			elif talked_to_newspaper_guy:
				set_state(IN_NEWSPAPER_GUY_REMIND)
				return
			talked_to_newspaper_guy = true
		101:
			show_speech_for(ENTITY_NEWSPAPER_GUY, "No, this is not it either...")
		102:
			show_speech_for(ENTITY_NEWSPAPER_GUY, "!")
		103:
			show_speech_for(ENTITY_NEWSPAPER_GUY, "You there, young man!")
		104:
			show_speech_for(ENTITY_NEWSPAPER_GUY, "Have you seen the latest papers!?")
		105:
			show_speech_for(ENTITY_NEWSPAPER_GUY, "I've been looking for it everywhere.")
		106: pass
		107:
			show_speech_for(ENTITY_NEWSPAPER_GUY, "If you happen to find it, please bring it to me.")
		108: pass
		109: clear_state()
		110,111,112,113,114,115,116,117,118,119: pass
		120:
			show_speech_for(ENTITY_NEWSPAPER_GUY, "Ah! The papers you're holding!")
		121,122: pass
		123:
			show_speech_for(ENTITY_NEWSPAPER_GUY, "It's exactly what I'm looking for!")
		124: pass
		125:
			take_away_item(ITEM_NEWSPAPER)
			gave_old_guy_newspaper = true
		126,127: pass
		128:
			show_speech_for(ENTITY_NEWSPAPER_GUY, "Thanks a bunch, young man!")
		129,130: pass
		131:
			show_speech_for(ENTITY_NEWSPAPER_GUY, "Here, take this!")
		132: pass
		133:
			give_item(ITEM_LIGHTER)
			#has_item_ligther = true
		134,135: pass
		135:
			show_speech_for(ENTITY_NEWSPAPER_GUY, "I have no use for it anymore.")
		136:
			clear_state()
		137,138,139,140,141,142,143,144,145,146,147,148,149: pass
		150:
			show_speech_for(ENTITY_NEWSPAPER_GUY, "Thanks again, young man.")
		151,152: pass
		153:
			show_speech_for(ENTITY_NEWSPAPER_GUY, "Now let's see... 4-13-6-...")
		154: pass
		155:
			show_speech_for(ENTITY_NEWSPAPER_GUY, "Oh, rats!")
		156,157,158,159: pass
		IN_NEWSPAPER_GUY_REMIND:
			show_speech_for(ENTITY_NEWSPAPER_GUY, "Don't forget, it's the latest papers!")
		IN_FADE_IN:
			curtain_set(Color.black)
			curtain_fade(Color(0,0,0,0), 3)
		IN_FADE_OUT:fade_out_all_music()
		1301: curtain_fade(Color.black, 3)
		1302:timer_wait(2)
		1303:request_reset = true
		1304:clear_state()
			
		IN_FADE_OUT:fade_out_all_music()
		IN_GOTO_SCENE_RIGHT:
			curtain_fade(Color.black, 0.2)
		501:
			requested_scene = cur_scene.right_scene
		502: pass
		503:
			curtain_fade(Color(0,0,0,0), 0.2 + + scene_change_fadein_duration_override)
			scene_change_fadein_duration_override = 0
		IN_GOTO_SCENE_LEFT:
			curtain_fade(Color.black, 0.2)
		401:
			requested_scene = cur_scene.left_scene
		402: 
			if scene_change_fadein_wait_override:
				timer_wait(scene_change_fadein_duration_override)
				scene_change_fadein_duration_override = 0
		403: 
			curtain_fade(Color(0,0,0,0), 0.2 + scene_change_fadein_duration_override)
			scene_change_fadein_duration_override = 0
		IN_VOMIT_GIRL_TALK:
			if has_item(ITEM_PILL_BOTTLE):
				set_state(IN_VOMIT_GIRL_TALK + 20)
				return
			else:
				set_state(IN_VOMIT_GIRL_TALK + 3)
				return
		601,602: pass
		603:
			show_speech_for(ENTITY_VOMIT_GIRL, "Ughhh..")
		604:
			timer_wait(1.5)
		605:
			show_speech_for(ENTITY_VOMIT_GIRL, "Urghhhhhhhhh..")
		606: clear_state()
		607,608,609,610,611,612,613,614,615,616,617,618,619: pass
		620:
			show_speech_for(ENTITY_VOMIT_GIRL, "Ughhh..")
			talked_to_vomit_girl = true
		621,622,623: pass
		624:
			show_speech_for(ENTITY_VOMIT_GIRL, "Ah... You found my medicine.")
		625: pass
		626:
			timer_wait(0.5)
		627:
			take_away_item(ITEM_PILL_BOTTLE)
			suspend_entity_type(ENTITY_VOMIT_GIRL)
			play_animation_for_and_wait(ENTITY_VOMIT_GIRL, "recover")
		628: pass
		629:
			show_speech_for(ENTITY_VOMIT_GIRL, "...That's better.")
		630,631: pass
		632:
			timer_wait(0.5)
		633: pass
		634:
			show_speech_for(ENTITY_VOMIT_GIRL, "Sir, you're a life saver! I can't believe...")
		635: pass
		636:
			timer_wait(0.5)
		637,638: pass
		639:
			show_speech_for(ENTITY_VOMIT_GIRL, "Wait..")
		640,641: pass
		642:
			show_speech_for(ENTITY_VOMIT_GIRL, "This is all wrong..")
		643: pass
		644:
			show_speech_for(ENTITY_VOMIT_GIRL, "You shouldn't be here.")
		645: pass
		646:
			show_speech_for(ENTITY_VOMIT_GIRL, "Listen, you have to leave.")
		647: pass
		648:
			show_speech_for(ENTITY_VOMIT_GIRL, "Quick, follow me!")
		649,650: pass
		651:
			var en = find_entity(ENTITY_VOMIT_GIRL)
			en.state = 20
			unsuspend_entity_type(ENTITY_VOMIT_GIRL)
		652:
			wait_for_entity_type_removed(ENTITY_VOMIT_GIRL)
		653: pass
		654:
			clear_state()
		655,656,657,658,659,660,661,662,663,664,665,666,667,668,669: pass
		IN_SMOKER_TALK:pass
		901:
			if gave_away_lighter:
				set_state(IN_SMOKER_TALK + 45)
				return
			elif has_item(ITEM_LIGHTER):
				set_state(IN_SMOKER_TALK + 8)
				return
			else:
				show_speech_for(ENTITY_SMOKER, "Damn... This lighter doesn't work.")
		902:
			clear_state()
			return
		903,904,905,906,907: pass
		908:
			show_speech_for(ENTITY_SMOKER, "Hey kid! That lighter you're holding, could you let me borrow it?")
			gave_away_lighter = true
		909: pass
		910: timer_wait(1.0)
		911: pass
		912:
			show_speech_for(ENTITY_SMOKER, "Ahhh.. That hits the spot.")
		913,914,915: pass
		916:
			show_speech_for(ENTITY_SMOKER, "You know kid, this was going to be my last cigarette.")
		917,918,919,920: pass
		921:
			show_speech_for(ENTITY_SMOKER, "I was going to retire from the force too.")
		922: pass
		923:
			show_speech_for(ENTITY_SMOKER, "After this last train ride, I'll go home and see my family.")
		924,925:pass
		926:
			show_speech_for(ENTITY_SMOKER, "Here look, a picture of my dog. Ain't she cute.")
		927: timer_wait(0.5)
		928:
			show_speech_for(ENTITY_SMOKER, "Anyway kid, smoking is bad for you.")
		929,930: pass
		931:
			show_speech_for(ENTITY_SMOKER, "Here's a bit of intel for you.")
		932:
			show_speech_for(ENTITY_SMOKER, "The lass who's sick between those the two cars...")
		933:
			show_speech_for(ENTITY_SMOKER, "She dropped something of hers earlier.")
		934: timer_wait(0.5)
		935:
			show_speech_for(ENTITY_SMOKER, "(Whisper) I saw a child took it.")
		936:
			show_speech_for(ENTITY_SMOKER, "What could a child want with something like that?")
		937: pass
		938: timer_wait(0.5)
		939:
			show_speech_for(ENTITY_SMOKER, "Anyways kid, take it easy!")
		940: timer_wait(0.5)
		941: clear_state()
		942,943,944: pass
		945:
			show_speech_for(ENTITY_SMOKER, "Don't forget, smoking is bad for you!")
		946: clear_state()
		947,948,949,950,951,952,953,954,955,956,957,958,959,960,961,962,963,964,965,966,967,968,969: pass
			
		IN_HOMELESS_GUY_TALK:
			if !talked_to_newspaper_guy:
				show_speech_for(ENTITY_HOMELESS_GUY, "Zzz...")
			else:
				set_state(IN_HOMELESS_GUY_TALK + 3)
				return
		801:
			clear_state()
			return
		803:
			if homeless_guy_gave_newspaper:
				set_state(IN_HOMELESS_GUY_TALK + 60)
				return
			elif talked_to_homeless_guy:
				set_state(IN_HOMELESS_GUY_TALK + 30)
				return
			else:
				talked_to_homeless_guy = true
				show_speech_for(ENTITY_HOMELESS_GUY, "Oh hey there brother, I didn't see you there.")
		804: pass
		805:
			show_speech_for(ENTITY_HOMELESS_GUY, "Is there something you need?")
		806,807:pass
		808:
			show_speech_for(ENTITY_HOMELESS_GUY, "Oh, you want one of my newspapers.")
		809,810:pass
		811:
			show_speech_for(ENTITY_HOMELESS_GUY, "Well for sure, brother!")
		812,813:pass
		814:
			show_speech_for(ENTITY_HOMELESS_GUY, "I can only give you one though, or I'll get cold.")
		815,816: pass
		817:
			show_speech_for(ENTITY_HOMELESS_GUY, "Which one do you want?", ["This one...", "Nevermind"])
		818:
			if speech_choice_index == 1:
				set_state(IN_HOMELESS_GUY_TALK + 45)
				return
			else:
				give_item(ITEM_NEWSPAPER)
				homeless_guy_gave_newspaper = true
		819,820,821,822:pass
		823:
			show_speech_for(ENTITY_HOMELESS_GUY, "Here you go! Sleep tight brother!")
		824:
			clear_state()
			return
		825,826,827,828,829:pass
		830:
			show_speech_for(ENTITY_HOMELESS_GUY, "Hello again brother! Still want that paper?")
		831:
			set_state(IN_HOMELESS_GUY_TALK + 17)
			return
		832,833,834,835,836,837,838,839,840,841,842,843,844:pass
		845:
			show_speech_for(ENTITY_HOMELESS_GUY, "Let me know if you change your mind brother!")
		846:
			clear_state()
			return
		847,848,849,850,851,852,853,854,855,856,857,858,859:pass
		860:
			show_speech_for(ENTITY_HOMELESS_GUY, "What is it brother? Anything else you need?")
		861,862,863,864,865,866,867,868,869:pass
		870:
			clear_state()
			return
		IN_LITTLE_GIRL_SAY:pass
		1001:
			if !gave_away_lighter || spoke_to_little_girl:
				set_state(IN_LITTLE_GIRL_SAY + 5)
				return
			else:
				set_state(IN_LITTLE_GIRL_SAY + 20)
				return
		1002,1003,1004:pass
		1005:
			suspend_entity_type(ENTITY_LITTLE_GIRL)
			var lines = [
				"One, two, buckle my shoes..",
				"three, four, lock the door..",
				"five, six, get your fix..",
				"seven, eight, don't be late..",
				"nine, ten, you're not my friend..",
			]
			show_speech_for(ENTITY_LITTLE_GIRL, lines[little_girl_rhyme_index])
			little_girl_rhyme_index = (little_girl_rhyme_index + 1) % lines.size()
		1006:
			unsuspend_entity_type(ENTITY_LITTLE_GIRL)
			clear_state()
		1007,1008,1009,1010,1011,1012,1013,1014,1015,1016,1017,1018,1019:pass
		1020:
			suspend_entity_type(ENTITY_LITTLE_GIRL)
			spoke_to_little_girl = true
			show_speech_for(ENTITY_LITTLE_GIRL, "Hi, mister!")
		1021: pass
		1022:
			show_speech_for(ENTITY_LITTLE_GIRL, "You want what that lady dropped?")
		1023: pass
		1024:
			show_speech_for(ENTITY_LITTLE_GIRL, "Sure mister, but you have to answer a question first.")
		1025: pass
		1026:
			show_speech_for(ENTITY_LITTLE_GIRL, "Ready? here goes.")
		1027:
			timer_wait(0.7)
		1028: pass
		1029:
			show_speech_for(ENTITY_LITTLE_GIRL, "Which way do you think the train is going?", [
				"<- East", "West ->"
			])
		1030: pass
		1031:
			show_speech_for(ENTITY_LITTLE_GIRL, "So that's what you think..")
		1032: pass
		1033:
			show_speech_for(ENTITY_LITTLE_GIRL, "Hahaha wrong! That was a trick question.")
		1034,1035: pass
		1036:
			show_speech_for(ENTITY_LITTLE_GIRL, "We're not going east OR west!")
		1037,1038: pass
		1039:
			show_speech_for(ENTITY_LITTLE_GIRL, "Huh? Where exactly IS it that we're going?")
		1040: pass
		1041:
			show_speech_for(ENTITY_LITTLE_GIRL, "You're funny, mister!")
		1042: pass
		1043:
			show_speech_for(ENTITY_LITTLE_GIRL, "Shouldn't you know where you want to go before getting on a train?")
		1044: pass
		1045:
			timer_wait(0.7)
		1046: pass
		1047:
			show_speech_for(ENTITY_LITTLE_GIRL, "Since you answered my question, here.")
		1048:
			timer_wait(0.7)
		1049:
			give_item(ITEM_PILL_BOTTLE)
		1050:
			timer_wait(0.7)
		1051:
			show_speech_for(ENTITY_LITTLE_GIRL, "You better give it to her soon, mister.")
		1052:
			show_speech_for(ENTITY_LITTLE_GIRL, "She's getting pretty sick.")
		1053: pass
		1054:
			unsuspend_entity_type(ENTITY_LITTLE_GIRL)
			clear_state()
		1055,1056,1057,1059:pass
			
		IN_WONT_OPEN:
			var messages = [
				"This door won't open.",
				"Looks like it's locked.",
				"Can't go through here.",
				"This isn't the way to go.",
			]
			var idx = rng.randi() % messages.size()
			show_speech_for(ENTITY_PLAYER, messages[idx])
		IN_FIRST_FLASHLIGHT:
			timer_wait(0.6)
		1201:
			override_brightness = 1
			flashlight_on = true
		1202:
			clear_state()
		1203:
			timer_wait(0.3)
		IN_ENCOUNTER:
			show_speech_for(ENTITY_PLAYER, "It won't open.");
		1401:
			if override_brightness > 0:
				override_brightness = move_to(override_brightness, 0, dt)
				return
		1402_:
			timer_wait(1)
		1403:
			fade_ambient_sound(-80,6)
			fade_out_all_music()
		1404_:
			timer_wait(1)
		1405:pass
		1406:
			if window_flash == 0:
				add_entity(ENTITY_EVIL_LITTLE_GIRL, 277, 0)
			else:
				return
		1407:
			var en = find_entity(ENTITY_EVIL_LITTLE_GIRL)
			if en:
				en.position.x -= dt * 10
			if en.position.x > 187:
				return
			en.position.x = 187
		1408:
			if window_flash == 0:
				var en = find_entity(ENTITY_EVIL_LITTLE_GIRL)
				if en:
					add_entity(ENTITY_SPIDER, en.position.x + en.width / 2 - 53, 0)
					en.queue_free()
			else:
				return
		1409:
			var en = find_entity(ENTITY_SPIDER)
			var tx = 55
			if en:
				if en.position.x > tx:
					en.position.x -= 10 * dt
					return
				else:
					curtain_set(Color.black)
					en.position.x = tx
					show_window_flash = false
		1410:
			timer_wait(1.0)
		1411:pass
		1412:
			show_speech_for(ENTITY_PLAYER, "Quick! Get in here!")
			speech_override_timer = 1.0
		1413: pass
		1414:
			cur_scene.left_scene = filename("SceneTrainFinal")
			goto_left_scene()
			scene_change_fadein_wait_override = 3.0
			scene_change_fadein_duration_override = 3.0
			return
		IN_GOTO_FINAL_CONVERSATION:
			timer_wait(0.8)
		1601:
			show_speech_for(ENTITY_VOMIT_GIRL, "That was close...")
		1602: pass
		1603: 
			show_speech_for(ENTITY_VOMIT_GIRL, "You almost became her food.")
		1604:
			timer_wait(0.8)
		1605:
			show_speech_for(ENTITY_VOMIT_GIRL, "...or worse.")
		1606:
			timer_wait(0.8)
		1607:
			show_speech_for(ENTITY_VOMIT_GIRL, "Listen, thanks for helping me.")
		1608,1609: pass
		1610:
			show_speech_for(ENTITY_VOMIT_GIRL, "But you need to get out of here.")
		1611:pass
		1612:
			show_speech_for(ENTITY_VOMIT_GIRL, "This train can't take you home.")
		1613:
			timer_wait(0.8)
		1614:pass
		1615:
			show_speech_for(ENTITY_VOMIT_GIRL, "All you need to do...")
		1616:
			show_speech_for(ENTITY_VOMIT_GIRL, "Is spin around 7 times.")
		1617:pass
		1618:
			show_speech_for(ENTITY_VOMIT_GIRL, "You hear me? 7 times.")
		1619:
			show_speech_for(ENTITY_VOMIT_GIRL, "Don't forget.")
		1620:pass
		1621:
			timer_wait(0.8)
		1622:
			suspend_entity_type(ENTITY_TRAIN_DOOR)
		1623:
			play_animation_for_and_wait(ENTITY_TRAIN_DOOR, "open")
		1624:
			unsuspend_entity_type(ENTITY_TRAIN_DOOR)
		1625:
			show_speech_for(ENTITY_VOMIT_GIRL, "Looks like this is my stop.")
		1626:pass
		1627:
			var door = find_entity(ENTITY_TRAIN_DOOR)
			var vg = find_entity(ENTITY_VOMIT_GIRL)
			if vg && door:
				var tx = door.position.x + door.width/2-vg.width/2
				if vg.position.x > tx:
					vg.set_facing(FACING_LEFT)
				elif vg.position.x < tx:
					vg.set_facing(FACING_RIGHT)
				vg.position.x = move_to(vg.position.x, tx, dt * 60)
				vg.play_animation("walk")
				if vg.position.x == tx:
					vg.play_animation("idle_2")
				else:
					return
		1628:
			show_speech_for(ENTITY_VOMIT_GIRL, "May we meet again.")
		1629:pass
		1630:
			show_speech_for(ENTITY_VOMIT_GIRL, "Remember, 7 times.")
		1631:timer_wait(0.5)
		1632:
			var vg = find_entity(ENTITY_VOMIT_GIRL)
			if vg && vg.modulate.a > 0:
				vg.modulate.a = move_to(vg.modulate.a, 0, dt * 2)
				return
			else:
				vg.queue_free()
		1633:pass
		1634:timer_wait(0.5)
		1635:suspend_entity_type(ENTITY_TRAIN_DOOR)
		1636:play_animation_for_and_wait(ENTITY_TRAIN_DOOR, "close")
		1637:unsuspend_entity_type(ENTITY_TRAIN_DOOR)
		1638:pass
		1639:
			clear_state()
			return
		1640,1641,1642,1643,1644,1645,1646,1647,1648,1649,1650:pass
		1651,1652,1653,1654,1655,1656,1657,1658,1669:pass
		IN_GO_HOME:pass
		2001:
			curtain_set(Color(1,1,1,0))
			curtain_fade(Color.white, 4)
			fade_ambient_sound(-80,4)
		2002:
			timer_wait(2)
			play_music('epilog')
		2003:
			should_shake_camera = false
			requested_scene = filename("SceneTrainHome")
		2004:suspend_entity_type(ENTITY_PLAYER)
		2005:curtain_fade(Color(1,1,1,0), 3)
		2006,2007:pass
		2008:play_animation_for_and_wait(ENTITY_PLAYER, "get_up")
		2009:unsuspend_entity_type(ENTITY_PLAYER)
		2010:add_entity(ENTITY_TIMER)
		2011:clear_state()
		2012,2013,2014,2015,2016,2017,2018,2019,2020:pass
		2021,2022,2023,2024,2025,2026,2027,2028,2029:pass
		2030,2031,2032,2033,2034,2035,2036,2037,2038,2039:pass
		2040,2041,2042,2043,2044,2045,2046,2047,2048,2049:pass
		IN_EPILOG:pass
		3001:
			var player = find_entity(ENTITY_PLAYER)
			if player:
				if player.modulate.a > 0:
					player.modulate.a = move_to(player.modulate.a, 0, dt * 2)
					return
		3002:pass
		3003:timer_wait(1.8)
		3004:pass
		3005:curtain_fade(Color.white, 3)
		3006:pass
		3007:show_ending_text()
		3008,3009:pass
		_:
			state = 0
	
	if state != 0:
		state +=1
	speech_choice_index = -1
	
func _process(dt):
	app_time += dt
	
	if request_reset:
		reset_game()
		request_reset = false
		
	if alpha == 1:
		if is_action():
			set_state(IN_FADE_OUT)
	
	update_state(dt)
	
	if cur_scene.name == "SceneTrainFinal" && !show_final_convo && !state:
		show_final_convo = true
		set_state(IN_GOTO_FINAL_CONVERSATION)
	lighting_brightness = 1
	
	if world_is_dark():
		if !flash_first_on:
			if !state:
				if !flash_first_on:
					override_brightness = 0
					set_state(IN_FIRST_FLASHLIGHT)
					flash_first_on = true
		else:
			flashlight_on = true
		
		# lightning flash
		background.set_color(Color.black)
		
		next_window_flash_timer -= dt
		if next_window_flash_timer <= 0:
			next_window_flash_timer = 2
			window_flash = 1
		
		if window_flash > 0:
			lighting_brightness = 0
			if show_window_flash:
				background.set_color(Color8(127,132,105))
			window_flash = move_to(window_flash, 0, dt / 0.2)
	else:
		flashlight_on = false
	
	lighting_brightness *= override_brightness
	cur_scene.set_modulate(Color(lighting_brightness, lighting_brightness, lighting_brightness, 1))
	
	update_timer(dt)
	
	if requested_scene:
		change_scene()
	
	update_camera_shake(dt)
	
	if cur_scene.entities:
		for en in cur_scene.entities.get_children():
			update_entity(en, dt)
			if en.type == ENTITY_LIGHT:
				add_light_to_lightning(en.position.x + en.width / 2, en.position.y + en.height / 2, en.light_radius, en.color)
		
	# do 7 spins in last scene
	if !state && cur_scene.name == "SceneTrainFinal":
		if Input.is_action_just_pressed("ui_left"):
			last_spin_dir = KEY_RIGHT
			if first_spin_dir == -1:
				first_spin_dir = KEY_LEFT
			if first_spin_dir != KEY_LEFT:
				spin_count += 1 * spin_multiply
			spin_timer = 0
		elif Input.is_action_just_pressed("ui_right"):
			if first_spin_dir == -1:
				first_spin_dir = KEY_RIGHT
			if first_spin_dir != KEY_RIGHT:
				spin_count += 1 * spin_multiply
			spin_timer = 0
		else:
			spin_timer += dt
			if spin_timer >= SPIN_GAP && spin_timer <= SPIN_GAP * 2 :
				spin_timer = 0
				spin_count = 0
				first_spin_dir = -1
		if spin_count >= 7 && last_spin_count != spin_count:
			spin_count = 0
			set_state(IN_GO_HOME)
	
	draw_lightning()

func change_scene():
	show_window_flash = true
	override_brightness = 1
	if cur_scene:
		last_scene = cur_scene.filename
		cur_scene.queue_free()
	cur_scene = load(requested_scene).instance()
	requested_scene = ""
	cur_scene.connect("ready", self, "onSceneReady")
	canvas.call_deferred("add_child", cur_scene)

func update_entity(en, dt):
	if en.suspended:
		return
	match en.type:
		ENTITY_PLAYER:
			update_player(en, dt)
		ENTITY_LITTLE_GIRL:
			update_little_girl(en, dt)
		ENTITY_EVIL_LITTLE_GIRL:
			update_evil_little_girl(en)
		ENTITY_VOMIT_GIRL:
			update_vomit_girl(en, dt)
		ENTITY_LIGHT:
			update_light(en)
		ENTITY_SPIDER:
			update_spider(en)
		ENTITY_TIMER:
			update_time(en, dt)

func update_time(en, dt):
	if !state:
		en.timer_left -= dt
		if en.timer_left <= 0:
			if en.on_over:
				call(en.on_over)
			en.queue_free()

func update_evil_little_girl(en):
	en.play_animation("shadow_running")

func update_spider(en):
	en.play_animation("walk")

func world_is_dark():
	return cur_scene.ambient.length_squared() < 0.5

func add_light_to_lightning(x,y,radius,color):
	if num_lights >= MAX_LIGHTS:
		return
	positions[num_lights] = Vector2(x,y)
	colors[num_lights] = color
	radii[num_lights] = radius

	num_lights += 1

func draw_lightning():
	for i in range(num_lights, MAX_LIGHTS - 1):
		colors[i].a = 0
	
	for i in num_lights:
		positions[i].x = floor(positions[i].x)
		positions[i].y = floor(positions[i].y)
	material.set_shader_param("camera_pos", Vector2.ZERO)
	material.set_shader_param("ambient", cur_scene.ambient)
	material.set_shader_param("screen_size", Vector2(float(GAME_WIDTH), float(GAME_HEIGHT)))
	
	for i in MAX_LIGHTS:
		material.set_shader_param("position"+String(i), positions[i])
		material.set_shader_param("color"+String(i), colors[i])
		material.set_shader_param("radii"+String(i), radii[i])

	num_lights = 0

func update_light(en):
	if en.is_flashlight:
		en.light_radius = 40 + Helper.get_wave(app_time, 0.5) * 2
		var player = find_entity(ENTITY_PLAYER)
		var x = player.position.x + player.width / 2
		var y = player.position.y + player.height / 2
		if player.is_facing(FACING_LEFT):
			x -= 13
		else:
			x += 13
		en.position.x = x - en.width / 2
		en.position.y = y - en.width / 2
		
		en.color = Color8(143,123,84)
		
		if flashlight_on && player:
			en.color.a = 1
		else:
			en.color.a = 0

func update_vomit_girl(en, dt):
	match en.state:
		0:
			en.play_animation("idle")
		20:
			en.play_animation("walk")
			en.position.x -= dt * en.speed
			if en.position.x < GAP_LEFT:
				en.queue_free()

func update_little_girl(en, dt):
	en.position.x -= dt * en.speed * en.direction
	en.play_animation("running")
	if en.position.x < 90:
		en.position.x = 90
		en.direction *= -1
		en.set_facing(FACING_RIGHT)
	elif en.position.x > 253:
		en.position.x = 253
		en.direction *= -1
		en.set_facing(FACING_LEFT)

func update_player(player, dt):
	player.position.x = clamp(player.position.x, cur_scene.left, cur_scene.right - player.width)
	var walk_anim = "walk"
	var idle_anim = "idle"
	if flashlight_on:
		walk_anim = "walk_lighter"
		idle_anim = "idle_lighter"
	
	if state:
		player.play_animation(idle_anim)
		if is_action() && speech_active:
			speechbox.next()
		return
	prompt_active = false
	proc = null
	if !state && Input.is_action_pressed("ui_left"):
		player.position.x -= player.speed * dt
		player.set_facing(facing.FACING_LEFT)
		player.play_animation(walk_anim)
	elif !state && Input.is_action_pressed("ui_right"):
		player.position.x += player.speed * dt
		player.set_facing(facing.FACING_RIGHT)
		player.play_animation(walk_anim)
	else:
		player.play_animation(idle_anim)
	
	if player.position.x <= cur_scene.left + 2 && player.is_facing(facing.FACING_LEFT):
		show_prompt(cur_scene.left, 80, "goto_left_scene")
	elif player.position.x + player.width >= cur_scene.right - 2 && player.is_facing(facing.FACING_RIGHT):
		show_prompt(cur_scene.right, 80, "goto_right_scene")

	# interact with npc, if they have on_use
	for en in cur_scene.entities.get_children():
		if en.type == ENTITY_PLAYER || !en.on_use:
			continue
		var px = player.position.x + player.width / 2
		if px >= en.position.x && px <= en.position.x + en.width:
			show_prompt(en.position.x + en.width / 2, en.position.y, en.on_use)
	
	if is_action():
		if proc:
			call(proc)
			hide_prompt()
			proc = null
	
	if !prompt_active:
		hide_prompt()

func hide_prompt():
	prompt_active = false
	prompt.deactivate()

func timer_wait(duration):
	timer_duration = duration

func update_timer(dt):
	timer_duration -= dt
	if timer_duration <= 0:
		timer_duration = 0

func wait_for_entity_type_removed(type):
	wait_for_type_removed = type

func play_animation_for_and_wait(type, anim):
	var en = find_entity(type)
	if en:
		en.play_animation(anim)
	play_animation_type = type


func on_epilog_use():
	set_state(IN_EPILOG)

func timer_over_open_door():
	var door = find_entity(ENTITY_TRAIN_DOOR)
	if door:
		door.play_animation("open")
	add_entity(ENTITY_UNKNOWN)
	var dummy = find_entity(ENTITY_UNKNOWN)
	entity_set_center_x(dummy, 57)
	
func suspend_entity_type(type):
	var en = find_entity(type)
	en.suspend()
	
func unsuspend_entity_type(type):
	var en = find_entity(type)
	en.unsuspend()

func show_prompt(x,y,next_proc):
	prompt_active = true
	prompt.set_position(Vector2(x,y))
	prompt.activate()
	proc = next_proc

func filename(res):
	return "res://" + res + ".tscn"

func scene_train_1():
	add_entity(ENTITY_TRAIN_DOOR, 36, 83)
	if !homeless_guy_gave_newspaper:
		add_entity(ENTITY_HOMELESS_GUY, 211, 99)
	add_entity(ENTITY_PLAYER, 85, 0)
	add_rail_handles()
	if talked_to_vomit_girl:
		cur_scene.left_scene = filename("SceneDarkGap0")

func scene_dark_gap_0():
	add_entity(ENTITY_PLAYER, 1000, 0)
	var player = find_entity(ENTITY_PLAYER)
	player.set_facing(FACING_LEFT)

func scene_dark_gap_1():
	add_entity(ENTITY_PLAYER)
	

func scene_dark_gap_2():
	add_entity(ENTITY_PLAYER)

func scene_dark_gap_3():
	add_entity(ENTITY_PLAYER)

func scene_train_web_0():
	add_entity(ENTITY_PLAYER)
	
func scene_train_web_1():
	add_entity(ENTITY_PLAYER)

func scene_train_web_2():
	add_entity(ENTITY_PLAYER, 1000, 0)
	var player = find_entity(ENTITY_PLAYER)
	player.set_facing(FACING_LEFT)

	
func scene_train_2():
	add_entity(ENTITY_TRAIN_DOOR, 36, 83)
	add_entity(ENTITY_PLAYER, 85, 0)
	if !spoke_to_little_girl:
		add_entity(ENTITY_LITTLE_GIRL)
	add_rail_handles()

func scene_train_3():
	add_entity(ENTITY_TRAIN_DOOR, 36, 83)
	if !has_item((ITEM_LIGHTER)):
		add_entity(ENTITY_NEWSPAPER_GUY, 196, 91)
	add_entity(ENTITY_PLAYER)
	add_rail_handles()

func scene_train_dark_1():
	play_music('pulse')
	add_entity(ENTITY_PLAYER)

func scene_train_final():
	var off = 30
	add_entity(ENTITY_TRAIN_DOOR, 36, 83)
	add_entity(ENTITY_PLAYER, 220 - off, 0)
	var player = find_entity(ENTITY_PLAYER)
	player.set_facing(FACING_LEFT)
	
	add_entity(ENTITY_VOMIT_GIRL, 195 - off, 0)
	var vg = find_entity(ENTITY_VOMIT_GIRL)
	vg.set_facing(FACING_RIGHT)
	vg.suspend()
	vg.play_animation("idle_2")

func scene_train_home():
	background.set_color(Color.white)
	add_entity(ENTITY_TRAIN_DOOR, 36, 83)
	add_entity(ENTITY_PLAYER,220,0)
	var player = find_entity(ENTITY_PLAYER)
	if player:
		player.play_animation("sit_idle")
		player.set_facing(FACING_LEFT)
		player.suspend()
		entity_set_center_x(player, 107)
	add_rail_handles()

func add_rail_handles():
	var x = 3
	var y = 85
	add_entity(ENTITY_RAIL_HANDLE, x + 57, y)
	add_entity(ENTITY_RAIL_HANDLE, x + 96, y)
	add_entity(ENTITY_RAIL_HANDLE, x + 166, y)
	add_entity(ENTITY_RAIL_HANDLE, x + 240, y)

func scene_gap_1():
	add_entity(ENTITY_PLAYER)
	if !gave_away_lighter:
		add_entity(ENTITY_SMOKER, 171, 91)

func scene_gap_2():
	if !talked_to_vomit_girl:
		add_entity(ENTITY_VOMIT_GIRL, 167, 91)
	add_entity(ENTITY_PLAYER)


func add_entity(type, x = 0, y = 0):
	var resource = "res://" + get_entity(type) + ".tscn"
	var en = load(resource).instance()
	en.set_position(Vector2(x, y))
	cur_scene.entities.add_child(en)

func goto_right_scene():
	if cur_scene.right_scene:
		set_state(IN_GOTO_SCENE_RIGHT)
	else:
		set_state(IN_WONT_OPEN)

func goto_left_scene():
	if cur_scene.left_scene:
		set_state(IN_GOTO_SCENE_LEFT)
	else:
		set_state(IN_WONT_OPEN)
		if cur_scene.name == "SceneTrainWeb2":
			set_state(IN_ENCOUNTER)

func update_camera_shake(dt):
	shake_timer -= dt
	if shake_timer <= 0:
		shake_timer = rng.randf_range(5.7, 6.75)
		total_magnitude = rng.randf_range(1.0, 1.5)
		first_shake = true
	
	if should_shake_camera:
		total_magnitude = move_to(total_magnitude, 0, dt * 0.5)
		impulse_timer -= dt
		if impulse_timer <= 0:
			impulse_timer = impulse_gap
			# apply camera impulse
			var ang = rng.randf() * 2 * PI
			cur_scene.position.x = floor(sin(ang) * total_magnitude)
			cur_scene.position.y = floor(cos(ang) * total_magnitude)
		if first_shake:
			first_shake = false
			var anim = "swing2" if cur_scene.position.x > 0 else "swing"
			# animate rail handles
			if cur_scene.entities:
				for entity in cur_scene.entities.get_children():
					if entity.type == ENTITY_RAIL_HANDLE:
						entity.set_animation_speed(rng.randf_range(0.8, 1.3))
						entity.play_animation(anim)

func move_to(x, tx, dt):
	if x < tx:
		x += dt
		return min(x, tx)
	elif x > tx:
		x -= dt
		return max(x, tx)
	return x

func curtain_set(color):
	curtain.set_color(color)

func curtain_fade(target, time):
	curtain_is_fading = true
	tween.interpolate_method(curtain, "set_color", curtain.color ,target, time)
	tween.start()

func set_state(st):
	state = st

func get_entity(type):
	return resources[type]

func show_speech_for(type, content, choices = []):
	var en = find_entity(type)
	speechbox.set_position(Vector2(en.position.x + en.width / 2, en.position.y - 10))
	speechbox.set_content(content, choices)
	speechbox.activate()
	hide_prompt()
	speech_active = true


func find_entity(type):
	for entity in cur_scene.entities.get_children():
		if entity.type == type:
			return entity

func take_away_item(type):
	for item in items.get_children():
		if item.type == type:
			item.queue_free()
			return

func show_notification(type):
	var item_name = ""
	
	match type:
		ITEM_NEWSPAPER:
			item_name = "Newspaper"
		ITEM_LIGHTER:
			item_name = "Ligthter"
		ITEM_PILL_BOTTLE:
			item_name = "Pill Bottle"
	
	item_notification.speech_content = "Got '%s'" % item_name
	item_notification.fade_out()
	

func has_item(type):
	for item in items.get_children():
		if item.type == type:
			return true
	return false

func give_item(type):
	show_notification(type)
	var item = load("res://Item.tscn").instance()
	var x_offset = items.get_child_count() * (item.box_size + 3)
	item.set_type(type)
	item.position.x = x_offset
	items.add_child(item)
	
func clear_state():
	state = 0

func homeless_guy_talk():
	set_state(IN_HOMELESS_GUY_TALK)

func smoker_talk():
	set_state(IN_SMOKER_TALK)

func little_girl_talk():
	set_state(IN_LITTLE_GIRL_SAY)

func vomit_girl_talk():
	set_state(IN_VOMIT_GIRL_TALK)

func newspaper_guy_talk():
	set_state(IN_NEWSPAPER_GUY_SAY)
	
func entity_set_center_x(en, x):
	en.position.x = x - en.width / 2

func _on_SpeechBox_dismiss(option):
	speech_choice_index = option
	speech_active = false

func _on_Tween_tween_completed(_object, _key):
	curtain_is_fading = false

func onSceneReady():
	add_entity(ENTITY_LIGHT)
	update_ambient_audio_list(ambient_current_volume)
	if !world_is_dark():
		background.set_color(Color.black)
	if cur_scene.name == "SceneTrainFinal":
		fade_ambient_sound(0,3)
	if cur_scene.ready_function:
		call(cur_scene.ready_function)
		cur_scene.add_ambient_sound('train_ambient' if cur_scene.is_gap else 'train_ambient_interior', ambient_current_volume)
	if last_scene:
		var player = find_entity(ENTITY_PLAYER)
		if cur_scene.right_scene == last_scene:
			player.position.x = GAME_WIDTH
			player.set_facing(FACING_LEFT)
		elif cur_scene.left_scene == last_scene:
			player.position.x = 0
			player.set_facing(FACING_RIGHT)

func play_music(source):
	var music = AudioStreamPlayer.new()
	music.set_name(source)
	music.set_stream(load('data/' + source + '.ogg'))
	music_list.add_child(music)
	music.play()

func fade_ambient_sound(target, duration):
	ambient_volume_tween.interpolate_property(self,"ambient_current_volume", null, target, duration)
	ambient_volume_tween.start()

func fade_out_all_music():
	for sound in music_list.get_children():
		music_list_fade_out_tween.interpolate_property(sound, "volume_db", 0, -80, 1)
		music_list_fade_out_tween.start()

func _on_MusicListFadeOutTween_tween_completed(sound, _key):
	sound.queue_free()

func _on_AmbientVolumeTween_tween_step(_object, _key, _elapsed, value):
	update_ambient_audio_list(value)

func update_ambient_audio_list(volume):
	for sound in cur_scene.ambient_audio_list.get_children():
		sound.set_volume_db(volume)

func show_ending_text():
	if alpha == 0:
		ending_text_fade_in.interpolate_property(self, "alpha", 0, 1, 1)
		ending_text_fade_in.start()

func reset_end_text():
	for text in end_text.get_children():
		text.modulate.a = 0

func _on_EndingTextFadeIn_tween_step(_object, _key, _elapsed, value):
	for i in end_text.get_child_count():
		var multiplier = 1
		if i > 0:
			multiplier = 0.5
		end_text.get_child(i).modulate.a = value * multiplier

func is_action():
	var st = Input.is_action_just_pressed("ui_accept") || button_pressed
	if button_pressed:
		button_pressed = false
	return st
	
func _on_TouchScreenButton_pressed():
	button_pressed = true
