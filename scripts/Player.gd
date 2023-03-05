extends Area2D

signal game_exit()
signal game_ended()
signal game_restarted()

const UP_DIRECTION = "up"
const DOWN_DIRECTION = "down"
const VELOCITY = 300
const DEFAULT_SCORES_TO_WIN = 5
const CONFIG_PATH = "res://config.cfg"
const HUD_SCENE = preload("res://scenes/HUD.tscn")

var soundIsActivate = true
var config = ConfigFile.new()
var err = config.load(CONFIG_PATH)
var points = 0
var screen_size
var initial_position
var controls = {
	"up": {
		"name" : "W",
		"key" : "ui_up",
	}, 
	"down": {
		"name" : "S",
		"key" : "ui_down",
	}
}
var skin = {"name": "Branco", "sprite_name": "white"}

onready var sprite = $Sprite
onready var audio_win = $AudioWin
onready var audio_point = $AudioPoint
onready var audio_colision = $AudioColision

func _ready():
	if (err == OK):
		soundIsActivate = config.get_value("General", "sound")
		
	initial_position = position
	screen_size = get_viewport_rect().size
	load_hud()
	load_skin()
	
func _process(delta):
	var dir = Vector2()
	
	if (Input.is_action_pressed(controls.down.key)):
		dir.y = VELOCITY
	if (Input.is_action_pressed(controls.up.key)):
		dir.y = -VELOCITY
	
	position += (delta*dir)
	position.y = clamp(position.y, 0, screen_size.y)
	
	if (dir.length()>0):
		if dir.y < 0:
			sprite.animation = get_skin_animation(UP_DIRECTION)
		else:
			sprite.animation = get_skin_animation(DOWN_DIRECTION)
		sprite.play()
	else:
		sprite.stop()

func _on_Player_body_entered(body):
	if (body.name.match("*Car*")):
		if (soundIsActivate):
			$AudioColision.play()
		
	if (body.name == "FinishLine"):
		score()
		
	position = initial_position

func set_control(_control):
	controls = _control
	
func set_skin(sprite_name):
	skin.sprite_name = sprite_name

func get_skin_animation(direction):
	return str(skin.sprite_name + "_" + direction)

func load_skin():
	sprite.animation = get_skin_animation(UP_DIRECTION)
	sprite.play()

func score():
	var score = get_hud_score()
	
	points += 1
	score.set_text(String(points) + "/" + String(get_score_to_win()))
	
	if (points == get_score_to_win()):
		var restart_button = get_hud_restart_button()
		var exit_button = get_hud_exit_button()
		var message = get_hud_message()
		var win_message = str("Vitoria do " + name)
		
		if (soundIsActivate):
			audio_win.play()
		
		restart_button.visible = true
		exit_button.visible = true
		message.visible = true
		message.set_text(win_message)
		
		emit_signal("game_ended")
		return
	
	if (soundIsActivate):
		audio_point.play()

func load_hud():
	var hud = HUD_SCENE.instance()
	var score = hud.get_node("Control")
	var skinImage = hud.get_node("Control/Skin")
	var message = hud.get_node("Message")
	var restart_button = hud.get_node("RestartButton")
	var exit_button = hud.get_node("ExitButton")
	var score_position = Vector2(initial_position.x - 64, 0)
	var score_text = "0/" + String(get_score_to_win())
	
	restart_button.visible = false
	exit_button.visible = false
	message.visible = false
	score.set_position(score_position)
	score.get_node("Score").set_text(score_text)
	score.get_node("Controls").set_text(controls.up.name + "\n" + controls.down.name)
	skinImage.animation = skin.sprite_name
	hud.connect("restart", self, "_on_Game_Restart")
	hud.connect("exit", self, "_on_Game_Exit")
	
	add_child(hud)

func get_score_to_win():
	if err != OK:
		return DEFAULT_SCORES_TO_WIN
		
	return config.get_value("General", "max_points")

func get_hud():
	return get_node("HUD")

func get_hud_score():
	return get_hud().get_node("Control/Score")

func get_hud_message():
	return get_hud().get_node("Message")
	
func get_hud_restart_button():
	return get_hud().get_node("RestartButton")
	
func get_hud_exit_button():
	return get_hud().get_node("ExitButton")

func restart_player():
	var score = get_hud_score()
	var restart_button = get_hud_restart_button()
	var exit_button = get_hud_exit_button()
	var message = get_hud_message()
	
	points = 0
	score.set_text(str(0))
	restart_button.hide()
	exit_button.hide()
	message.hide()

func _on_Game_Restart():
	restart_player()
	emit_signal("game_restarted")

func _on_Game_Exit():
	emit_signal("game_exit")
