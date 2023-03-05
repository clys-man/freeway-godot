extends CanvasLayer

signal one_player_game()
signal two_players_game()
signal four_players_game()

func _on_OnePlayerButton_pressed():
	emit_signal("one_player_game")

func _on_TwoPlayersButton_pressed():
	emit_signal("two_players_game")

func _on_FourPlayersButton_pressed():
	emit_signal("four_players_game")

func _on_SettingsButton_pressed():
	$SettingsMenu.show()
