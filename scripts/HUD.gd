extends CanvasLayer

signal restart
signal exit

func _ready():
	pass # Replace with function body.

func _on_Exit_pressed():
	emit_signal("exit")


func _on_Restart_pressed():
	emit_signal("restart")
