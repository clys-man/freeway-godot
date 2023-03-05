extends AcceptDialog

const SECTION = "General"
const SOUND = {"key": "sound", "value": true}
const MAX_POINTS = {"key": "max_points", "value": 5}
const CONFIG_PATH = "res://config.cfg"

var config = ConfigFile.new()
var err = config.load(CONFIG_PATH)

onready var sound_option = $Options/Sound
onready var max_point_option = $Options/MaxPoints

func _ready():
	add_button("Cancelar", false, "cancel")
	
	if err != OK:
		set_config_value(SOUND.key, SOUND.value)
		set_config_value(MAX_POINTS.key, MAX_POINTS.value)

		config.save(CONFIG_PATH)
	
	var soundConfigIsActive = get_config_value(SOUND.key)
	sound_option.get_node("CheckButton").pressed = soundConfigIsActive
	
	var maxPointConfigValue = get_config_value(MAX_POINTS.key)
	max_point_option.get_node("TextEdit").text = str(maxPointConfigValue)
	
	# Removing 'X' button
	var children = get_children()
	remove_child(children[0])
	
func _process(delta):
	if(Input.is_action_pressed("ui_cancel")):
		_on_SettingsMenu_custom_action("cancel")
	
func set_config_value(key: String, value):
	config.set_value(SECTION, key, value)
	config.save(CONFIG_PATH)
	
func get_config_value(key: String):
	return config.get_value(SECTION, key)

func _on_SettingsMenu_confirmed():
	var max_points = int(max_point_option.get_node("TextEdit").text)
	var button_pressed = sound_option.get_node("CheckButton").pressed
	
	set_config_value(MAX_POINTS.key, max_points)
	set_config_value(SOUND.key, button_pressed)

func _on_SettingsMenu_custom_action(action):
	if (action == "cancel"):
		var soundConfigIsActive = get_config_value(SOUND.key)
		var maxPointConfigValue = get_config_value(MAX_POINTS.key)
		
		sound_option.get_node("CheckButton").set_toggle_mode(soundConfigIsActive)
		max_point_option.get_node("TextEdit").text = str(maxPointConfigValue)
		hide() 
