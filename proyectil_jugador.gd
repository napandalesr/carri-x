extends Area2D

var velocidad: float = 1200.0
var color_laser: Color = Color(0.2, 0.8, 1.0, 1.0) # Azul policía / cian brillante

func _ready() -> void:
	add_to_group("proyectiles_jugador")
	monitoring = true
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	position.y -= velocidad * delta
	if position.y < -100:
		queue_free()

func _draw() -> void:
	# Dibujar rayo de energía / proyectil con brillo
	var p_rect = Rect2(-4.0, -18.0, 8.0, 36.0)
	draw_rect(p_rect, color_laser, true)
	# Núcleo blanco brillante
	draw_rect(Rect2(-2.0, -15.0, 4.0, 30.0), Color.WHITE, true)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemigos"):
		var mundo = get_tree().current_scene
		
		# 1. Barricadas de concreto: Indestructibles (desvían el disparo)
		if area.is_in_group("barricadas") or area.name.to_lower().contains("barricada"):
			if mundo and mundo.has_method("crear_efecto_impacto"):
				mundo.crear_efecto_impacto(global_position)
			queue_free()
			return
			
		# 2. Camiones pesados / Volquetas: Resistencia de 2 disparos
		if "vida" in area and area.vida > 1:
			area.vida -= 1
			if mundo and mundo.has_method("crear_efecto_impacto"):
				mundo.crear_efecto_impacto(global_position)
			queue_free()
			return
			
		# 3. Autos normales, motos y patrullas rivales: Destrucción + 2 puntos
		if mundo:
			if mundo.has_method("sumar_puntos_extra"):
				mundo.sumar_puntos_extra(2)
			elif mundo.has_method("sumar_punto"):
				mundo.sumar_punto()
				mundo.sumar_punto()
			if mundo.has_method("crear_efecto_impacto"):
				mundo.crear_efecto_impacto(area.global_position)
			if mundo.has_method("reproducir_sonido_impacto"):
				mundo.reproducir_sonido_impacto()
				
		area.queue_free()
		queue_free()
