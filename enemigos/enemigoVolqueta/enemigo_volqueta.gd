extends Area2D

var velocidad: float = 400.0

func _ready() -> void:
	add_to_group("enemigos")
	ajustar_escala_dinamica()

func ajustar_escala_dinamica() -> void:
	var info_nivel = DatosNiveles.NIVELES.get(DatosNiveles.nivel_actual, DatosNiveles.NIVELES[1])
	var carriles = info_nivel.get("carriles", [216.0, 432.0])
	
	var ancho_carril = 216.0
	if carriles.size() > 1:
		ancho_carril = carriles[1] - carriles[0]
		
	var factor_escala = clampf(ancho_carril / 200.0, 0.48, 1.0)
	scale = Vector2(factor_escala, factor_escala)

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	var mundo = get_tree().current_scene
	var mult = mundo.obtener_factor_ralentizacion() if mundo and mundo.has_method("obtener_factor_ralentizacion") else 1.0
	position.y += (velocidad * 0.85 * mult) * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	var mundo = get_tree().current_scene
	if mundo and mundo.has_method("sumar_punto"):
		mundo.sumar_punto()
	queue_free()

func _on_area_entered(_area: Area2D) -> void:
	pass
