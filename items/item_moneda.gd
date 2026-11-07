extends Area2D

var velocidad: float = 300.0
var siendo_atraida: bool = false
var objetivo_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("items")
	add_to_group("monedas")

func _process(delta: float) -> void:
	if get_tree().paused:
		return
		
	if siendo_atraida:
		# Atracción por el imán del Cyberpunk Neón o F1
		position = position.move_toward(objetivo_pos, 750.0 * delta)
		siendo_atraida = false # Resetear cada frame; el jugador lo reactiva en su _process
		return
		
	var mundo = get_tree().current_scene
	var mult = mundo.obtener_factor_ralentizacion() if mundo and mundo.has_method("obtener_factor_ralentizacion") else 1.0
	position.y += (velocidad * mult) * delta

func atraer(pos_jugador: Vector2) -> void:
	siendo_atraida = true
	objetivo_pos = pos_jugador

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("jugador"):
		var mundo = get_tree().current_scene
		if mundo and mundo.has_method("reproducir_sonido_item"):
			mundo.reproducir_sonido_item("res://sonidos/moneda.wav")
		if mundo and mundo.has_method("recolectar_moneda"):
			mundo.recolectar_moneda()
		queue_free()
