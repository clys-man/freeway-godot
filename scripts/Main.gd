extends Node

const CONFIG_PATH = "res://config.cfg"
const SECONDS_TO_START = 5
const CAR_SCENE = preload("res://scenes/Car.tscn")
const PLAYER_SCENE = preload("res://scenes/Player.tscn")
const LANES = [600, 544, 488, 438, 384, 324, 272, 216, 160, 104]
const CONTROLS = [
	{
		"up": {
			"name" : "W",
			"key" : "w_up",
		}, 
		"down": {
			"name" : "S",
			"key" : "s_down",
		}
	},
	{
		"up": {
			"name" : "C",
			"key" : "c_up",
		}, 
		"down": {
			"name" : "V",
			"key" : "v_down",
		}
	},
	{
		"up": {
			"name" : "J",
			"key" : "j_up",
		}, 
		"down": {
			"name" : "K",
			"key" : "k_down",
		}
	},
	{
		"up": {
			"name" : "↑",
			"key" : "ui_up",
		}, 
		"down": {
			"name" : "↓",
			"key" : "ui_down",
		}
	},
]

const PLAYERS = [
	{
		"name": "Branco",
		"skin": "white",
	},
	{
		"name": "Verde",
		"skin": "green",
	},
	{
		"name": "Azul",
		"skin": "blue",
	},
	{
		"name": "Rosa",
		"skin": "pink"
	}
]

var game_started = false
var slowLanes = []
var fastLanes = []
var config = ConfigFile.new()
var err = config.load(CONFIG_PATH)

onready var menu = $Menu
onready var audio_theme = $AudioTheme
onready var audio_countdown = $AudioCountdown
onready var timer_fast = $TimerFast
onready var timer_slow = $TimerSlow
onready var start_line = $StartLine
onready var leave_game_popup = $LeaveGamePopup

func _ready():
	randomize()
	load_menu()

func _process(delta):
	if (Input.is_action_pressed("ui_cancel") && game_started):
		leave_game_popup.show()

func start_game(qtyPlayers, hasMenu = false):
	load_lanes()
	load_sound()
	load_players(qtyPlayers)
	
	if(qtyPlayers > 0):
		load_countdown()
		game_started = true
	
	timer_fast.start()
	timer_slow.start()
	menu.visible = hasMenu

func restart_game():
	var players = get_players()
	reset_players_score()
	start_game(get_players().size())

func exit_game():
	var hasMenu = true
	var clearPlayers = true
	
	end_game(clearPlayers)
	start_game(0, hasMenu)

func end_game(clearPlayers = false):
	add_child(start_line)
	remove_old_cars()
	set_players_to_initial_position()
	
	if (clearPlayers):
		remove_all_players()
	
	game_started = false
	audio_theme.stop()
	timer_fast.stop()
	timer_slow.stop()

func load_sound():
	var soundIsActivate = true
	if (err == OK):
		soundIsActivate = config.get_value("General", "sound")
	if (!soundIsActivate):
		return
	
	audio_theme.play()

func load_menu():
	menu.visible = true
	start_game(0, true)

func load_lanes():
	if (!get_cars().empty()):
		remove_old_cars()

	var size = LANES.size()
	var mid = size/2
	
	LANES.shuffle()
	slowLanes = LANES.slice(0, mid)
	fastLanes = LANES.slice(mid+1, size-1)

func load_players(qtyPlayers: int):
	if (!get_players().empty()):
		set_players_to_initial_position()
		return
	
	if (qtyPlayers == 0):
		return
	
	var _controls = CONTROLS
	if (qtyPlayers == 2):
		_controls = [CONTROLS[0], CONTROLS[3]]
	
	var initial_position = (1280/qtyPlayers)/2	
	PLAYERS.shuffle()
	
	for i in range(0, qtyPlayers):
		var player = PLAYERS[i]
		var control = _controls[i]
		var instance = PLAYER_SCENE.instance()
		var xPosition = initial_position*((i*2)+1)
		var positionVector = Vector2(xPosition, 690)
		
		instance.position = positionVector
		instance.set_name(player.name)
		instance.set_control(control)
		instance.set_skin(player.skin)
		instance.connect("game_ended", self, "end_game")
		instance.connect("game_restarted", self, "restart_game")
		instance.connect("game_exit", self, "exit_game")
		instance.add_to_group("Players")
		
		add_child(instance)
		
func load_countdown():
	add_child(start_line)
	for i in range(SECONDS_TO_START, 0, -1):
		var text = str("Começando em ", i)
		
		send_message_to_all_players(text)
		audio_countdown.play()
		yield(wait(1), "completed")
	
	remove_child(start_line)
	send_message_to_all_players("")

func _on_Slow_timeout():
	var x = 1290
	var y = slowLanes[randi()%slowLanes.size()]
	var rotation = -90
	var velocity = Vector2(rand_range(-300,-325), 0)
	
	load_car(x, y, rotation, velocity)

func _on_Fast_timeout():
	var x = -10
	var y = fastLanes[randi()%fastLanes.size()]
	var rotation = 90
	var velocity = Vector2(rand_range(680,690),0)
	
	load_car(x, y, rotation, velocity)
	
func load_car(x, y, rotation, velocity):
	var car = CAR_SCENE.instance()
	car.position.x = x
	car.position.y = y
	car.rotation_degrees = rotation
	car.linear_velocity = velocity
	car.add_to_group("Cars")
	
	add_child(car)

func remove_all_players():
	var currentPlayers = get_players()
	
	for player in currentPlayers:
		player.queue_free()

func reset_players_score():
	var players = get_players()
	
	for player in players:
		player.points = 0
		player.get_hud_score().set_text("0/" + String(player.get_score_to_win()))

func set_players_to_initial_position():
	var currentPlayers = get_players()
	if (currentPlayers.size() == 0): 
		return;
		
	var initial_position = (1280/currentPlayers.size())/2
	
	for i in range(0, currentPlayers.size()):
		var player = currentPlayers[i]
		var xPosition = initial_position*((i*2)+1)
		var positionVector = Vector2(xPosition, 690)
		
		player.position = positionVector
		
func send_message_to_player(player, text, duration = 1):
	var message = player.get_node("HUD").get_node("Message")
	message.visible = true
	message.set_text(text)
	
func send_message_to_all_players(text):
	var players = get_players()

	for player in players:
		send_message_to_player(player, text)

func get_group_from_tree(group_name):
	return get_tree().get_nodes_in_group(group_name)	

func get_players():
	return get_group_from_tree("Players")
	
func get_cars():
	return get_group_from_tree("Cars")

func remove_group(group_name):
	var itens = get_group_from_tree(group_name)
	
	for item in itens:
		item.queue_free()

func remove_old_players():
	remove_group("Players")

func remove_old_cars():
	remove_group("Cars")

func wait(seconds):
	var timer = Timer.new()
	timer.set_wait_time(seconds)
	timer.set_one_shot(true)
	timer.add_to_group("Timers")
	
	add_child(timer)
	timer.start()
	
	yield(timer, "timeout")
	timer.queue_free()

func _on_Menu_one_player_game():
	start_game(1)

func _on_Menu_two_players_game():
	start_game(2)

func _on_Menu_four_players_game():
	start_game(4)

func _on_LeaveGamePopup_confirmed():
	exit_game()
