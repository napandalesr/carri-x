extends Area2D

var velocidad: float = 400.0

func _ready() -> void:
	add_to_group("enemigos")

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	var mundo = get_tree().current_scene
	var mult = mundo.obtener_factor_ralentizacion() if mundo and mundo.has_method("obtener_factor_ralentizacion") else 1.0
	position.y += (velocidad * mult) * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	var mundo = get_tree().current_scene
	if mundo and mundo.has_method("sumar_punto"):
		mundo.sumar_punto()
	queue_free()

func _on_area_entered(_area: Area2D) -> void:
	pass
