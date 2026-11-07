extends Area2D

var velocidad: float = 300.0

func _ready() -> void:
	add_to_group("items")

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	var mundo = get_tree().current_scene
	var mult = mundo.obtener_factor_ralentizacion() if mundo and mundo.has_method("obtener_factor_ralentizacion") else 1.0
	position.y += (velocidad * mult) * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("jugador"):
		var mundo = get_tree().current_scene
		if mundo and mundo.has_method("sumar_vida"):
			mundo.sumar_vida()
		queue_free()
