extends Area2D

signal habilidad_activada(tipo: String, duracion: float)
signal habilidad_cooldown(restante: float, total: float)
signal habilidad_lista()

var carril_actual: int = 1
var velocidad_suavizado: float = 15.0
var tiene_escudo: bool = false
var tiempo_escudo: float = 0.0
const DURACION_ESCUDO_BASE: float = 7.0
var deslizando: bool = false
var tiempo_deslizando: float = 0.0
var tiempo_siguiente_derrape_lateral: float = 0.0

# --- SISTEMA DE HABILIDADES DE VEHÍCULOS ---
var habilidad_activa: bool = false
var tiempo_habilidad: float = 0.0
const DURACION_HABILIDAD: float = 4.0
var tiempo_cooldown: float = 0.0
const COOLDOWN_HABILIDAD: float = 6.0
var tiempo_entre_disparos: float = 0.0
var escena_proyectil: PackedScene = preload("res://proyectil_jugador.tscn")

var touch_inicio_pos: Vector2 = Vector2.ZERO
var touch_activo: bool = false
var swipe_consumido: bool = false
const UMBRAL_SWIPE: float = 45.0

var script_impacto = preload("res://efecto_impacto.gd")

func obtener_carriles() -> Array:
	var info_nivel = DatosNiveles.NIVELES.get(DatosNiveles.nivel_actual, DatosNiveles.NIVELES[1])
	return info_nivel["carriles"]

func _obtener_carril_mas_cercano(pos_x: float, carriles: Array) -> int:
	if carriles.is_empty():
		return 0
	var carril_cercano: int = 0
	var menor_dist: float = abs(carriles[0] - pos_x)
	for i in range(1, carriles.size()):
		var dist: float = abs(carriles[i] - pos_x)
		if dist < menor_dist:
			menor_dist = dist
			carril_cercano = i
	return carril_cercano

func _ready() -> void:
	add_to_group("jugador")
	actualizar_textura_auto()
	actualizar_modo_control()
	resetear_posicion()

func actualizar_modo_control() -> void:
	var es_botones = (DatosNiveles.modo_control == "botones")
	if has_node("InterfazUI/BotonIzquierda"):
		$InterfazUI/BotonIzquierda.visible = es_botones
	if has_node("InterfazUI/BotonDerecha"):
		$InterfazUI/BotonDerecha.visible = es_botones

func actualizar_textura_auto() -> void:
	if has_node("Sprite2D") and ResourceLoader.exists(DatosNiveles.auto_seleccionado):
		var tex: Texture2D = load(DatosNiveles.auto_seleccionado)
		$Sprite2D.texture = tex
		if tex:
			var s = tex.get_size()
			if s.x > 0 and s.y > 0:
				$Sprite2D.scale = Vector2(132.0 / s.x, 220.0 / s.y)

func es_inmune_al_aceite() -> bool:
	var auto = DatosNiveles.auto_seleccionado
	return auto == "res://auto_rojo.svg" or auto == "res://auto_f1.svg"

func obtener_tipo_habilidad() -> String:
	return DatosNiveles.obtener_habilidad_auto(DatosNiveles.auto_seleccionado)

func puede_usar_habilidad() -> bool:
	var tipo = obtener_tipo_habilidad()
	if tipo == "ninguna" or tipo == "inmune_aceite":
		return false
	return not habilidad_activa and tiempo_cooldown <= 0.0

func activar_habilidad_especial() -> bool:
	if not puede_usar_habilidad():
		return false
		
	var tipo = obtener_tipo_habilidad()
	habilidad_activa = true
	tiempo_habilidad = DURACION_HABILIDAD
	tiempo_entre_disparos = 0.0
	
	# Efecto sonoro de activación
	if has_node("AudioCambioCarril"):
		$AudioCambioCarril.pitch_scale = 1.4
		$AudioCambioCarril.play()
		
	# Disparo inicial para Patrulla o F1
	if tipo in ["disparo", "todas"]:
		disparar_proyectil()
		
	habilidad_activada.emit(tipo, DURACION_HABILIDAD)
	queue_redraw()
	return true

func disparar_proyectil() -> void:
	if not escena_proyectil:
		return
	var p = escena_proyectil.instantiate()
	p.global_position = global_position + Vector2(0, -70.0)
	var mundo = get_tree().current_scene
	if mundo:
		mundo.add_child(p)

func activar_escudo(duracion: float = 7.0) -> void:
	tiene_escudo = true
	tiempo_escudo = duracion
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.4, 0.9, 1.0, 1.0)
	queue_redraw()

func desactivar_escudo() -> void:
	tiene_escudo = false
	tiempo_escudo = 0.0
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
	queue_redraw()

func _draw() -> void:
	# 1. Escudo pasivo regular recogido en pista
	if tiene_escudo:
		var radio: float = 76.0
		var color_escudo = Color(0.1, 0.6, 1.0, 0.35)
		var color_borde = Color(0.3, 0.85, 1.0, 0.95)
		
		if tiempo_escudo <= 2.0:
			var parpadeo = abs(sin(Time.get_ticks_msec() * 0.018))
			color_escudo = Color(1.0, 0.3, 0.3, 0.15 + (parpadeo * 0.45))
			color_borde = Color(1.0, 0.5, 0.2, 0.5 + (parpadeo * 0.5))
			
		draw_circle(Vector2.ZERO, radio, color_escudo)
		draw_arc(Vector2.ZERO, radio, 0.0, TAU, 36, color_borde, 4.0)
		draw_arc(Vector2.ZERO, radio - 7.0, 0.0, TAU, 28, Color(color_borde.r, color_borde.g, color_borde.b, 0.4), 2.0)

	# 2. Habilidad Activa Especial
	if habilidad_activa:
		var tipo = obtener_tipo_habilidad()
		var radio_hab: float = 85.0
		
		if tipo in ["escudo_embestida", "todas"]:
			# Escudo de embestida dorado/naranja
			var col_emb = Color(1.0, 0.65, 0.0, 0.4)
			var col_emb_borde = Color(1.0, 0.85, 0.2, 0.95)
			draw_circle(Vector2.ZERO, radio_hab, col_emb)
			draw_arc(Vector2.ZERO, radio_hab, 0.0, TAU, 40, col_emb_borde, 5.0)
			# Onda exterior
			var pulso = abs(sin(Time.get_ticks_msec() * 0.012)) * 12.0
			draw_arc(Vector2.ZERO, radio_hab + pulso, 0.0, TAU, 32, Color(1.0, 0.5, 0.0, 0.4), 2.5)
			
		if tipo in ["iman", "todas"]:
			# Ondas magnéticas cian y violeta
			var radio_iman = 95.0 + (abs(sin(Time.get_ticks_msec() * 0.01)) * 15.0)
			draw_arc(Vector2.ZERO, radio_iman, 0.0, TAU, 32, Color(0.3, 0.9, 1.0, 0.8), 3.0)
			draw_arc(Vector2.ZERO, radio_iman - 16.0, 0.0, TAU, 24, Color(0.8, 0.3, 1.0, 0.6), 2.0)
			
		if tipo == "disparo":
			# Brillo de torreta activa
			draw_circle(Vector2(0, -65), 14.0, Color(0.2, 0.8, 1.0, 0.7))

func _unhandled_input(event: InputEvent) -> void:
	if deslizando or get_tree().paused:
		return
		
	var mundo = get_tree().current_scene
	if mundo and ("juego_activo" in mundo and not mundo.juego_activo or "en_transicion" in mundo and mundo.en_transicion or "juego_pausado" in mundo and mundo.juego_pausado):
		return

	# Tecla Espacio o W para activar habilidad en teclado
	if event.is_action_pressed("ui_select") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_W)):
		activar_habilidad_especial()

	var carriles = obtener_carriles()
	if carriles.is_empty():
		return

	if DatosNiveles.modo_control != "carriles":
		return

	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event.pressed:
			touch_inicio_pos = event.position
			touch_activo = true
			swipe_consumido = false
			
			var carril_cercano = _obtener_carril_mas_cercano(event.position.x, carriles)
			if carril_cercano != carril_actual:
				carril_actual = carril_cercano
				if has_node("AudioCambioCarril"):
					$AudioCambioCarril.pitch_scale = 1.0
					$AudioCambioCarril.play()
		else:
			touch_activo = false
			swipe_consumido = false

	elif (event is InputEventScreenDrag or (event is InputEventMouseMotion and touch_activo)) and touch_activo:
		var delta_x = event.position.x - touch_inicio_pos.x
		if not swipe_consumido and abs(delta_x) >= UMBRAL_SWIPE:
			if delta_x > 0 and carril_actual < carriles.size() - 1:
				carril_actual += 1
				if has_node("AudioCambioCarril"):
					$AudioCambioCarril.pitch_scale = 1.0
					$AudioCambioCarril.play()
				swipe_consumido = true
			elif delta_x < 0 and carril_actual > 0:
				carril_actual -= 1
				if has_node("AudioCambioCarril"):
					$AudioCambioCarril.pitch_scale = 1.0
					$AudioCambioCarril.play()
				swipe_consumido = true

func deslizar() -> void:
	# El Deportivo Rojo y el Bólido F1 son completamente inmunes al aceite
	if es_inmune_al_aceite():
		crear_efecto_impacto(global_position + Vector2(0, 50))
		return
		
	deslizando = true
	tiempo_deslizando = 1.6
	tiempo_siguiente_derrape_lateral = 0.28
	
	var mundo = get_tree().current_scene
	if mundo and mundo.has_method("activar_vibracion"):
		mundo.activar_vibracion(0.4, 15.0)
		
	if has_node("AudioColision"):
		$AudioColision.pitch_scale = 1.4
		$AudioColision.play()

	var carriles = obtener_carriles()
	if carriles.size() > 1:
		var cambio = 1 if (carril_actual == 0 or randf() > 0.5) and carril_actual < carriles.size() - 1 else -1
		carril_actual = clampi(carril_actual + cambio, 0, carriles.size() - 1)

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	var mundo = get_tree().current_scene
	
	if mundo and ("juego_activo" in mundo and not mundo.juego_activo or "en_transicion" in mundo and mundo.en_transicion or "juego_pausado" in mundo and mundo.juego_pausado):
		return
		
	# Procesamiento del escudo regular
	if tiene_escudo:
		tiempo_escudo -= delta
		queue_redraw()
		if tiempo_escudo <= 0.0:
			desactivar_escudo()

	# Procesamiento de Habilidad Activa
	if habilidad_activa:
		tiempo_habilidad -= delta
		queue_redraw()
		var tipo = obtener_tipo_habilidad()
		
		# Disparo periódico (cada 0.45s) durante los 4s activos
		if tipo in ["disparo", "todas"]:
			tiempo_entre_disparos -= delta
			if tiempo_entre_disparos <= 0.0:
				tiempo_entre_disparos = 0.45
				disparar_proyectil()
				
		# Imán activo: atrae monedas y escudos en un radio de 650px
		if tipo in ["iman", "todas"]:
			var items = get_tree().get_nodes_in_group("items")
			for it in items:
				if is_instance_valid(it) and it is Node2D:
					if global_position.distance_to(it.global_position) <= 650.0:
						if it.has_method("atraer"):
							it.atraer(global_position)
							
		if tiempo_habilidad <= 0.0:
			habilidad_activa = false
			tiempo_cooldown = COOLDOWN_HABILIDAD
			queue_redraw()
			
	elif tiempo_cooldown > 0.0:
		tiempo_cooldown -= delta
		habilidad_cooldown.emit(tiempo_cooldown, COOLDOWN_HABILIDAD)
		if tiempo_cooldown <= 0.0:
			tiempo_cooldown = 0.0
			habilidad_lista.emit()
			
	var carriles = obtener_carriles()
	carril_actual = clampi(carril_actual, 0, carriles.size() - 1)
	
	if deslizando:
		tiempo_deslizando -= delta
		rotation += 18.0 * delta
		tiempo_siguiente_derrape_lateral -= delta
		if tiempo_siguiente_derrape_lateral <= 0.0:
			tiempo_siguiente_derrape_lateral = 0.32
			if carriles.size() > 1:
				var cambio_extra = 1 if randf() > 0.5 else -1
				carril_actual = clampi(carril_actual + cambio_extra, 0, carriles.size() - 1)
				
		if tiempo_deslizando <= 0:
			deslizando = false
			rotation = 0.0
	else:
		if Input.is_action_just_pressed("mover_izquierda") and carril_actual > 0:
			carril_actual -= 1
			if has_node("AudioCambioCarril"):
				$AudioCambioCarril.pitch_scale = 1.0
				$AudioCambioCarril.play()
		elif Input.is_action_just_pressed("mover_derecha") and carril_actual < carriles.size() - 1:
			carril_actual += 1
			if has_node("AudioCambioCarril"):
				$AudioCambioCarril.pitch_scale = 1.0
				$AudioCambioCarril.play()

	var x_objetivo: float = carriles[carril_actual]
	position.x = lerp(position.x, x_objetivo, velocidad_suavizado * delta)
	
	if not deslizando:
		var desplazamiento = x_objetivo - position.x
		rotation = lerp(rotation, deg_to_rad(desplazamiento * 0.08), 12.0 * delta)

func crear_efecto_impacto(pos: Vector2) -> void:
	var fx = Node2D.new()
	fx.set_script(script_impacto)
	fx.global_position = pos
	var mundo = get_tree().current_scene
	if mundo:
		mundo.add_child(fx)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemigos"):
		var mundo = get_tree().current_scene
		
		# 1. HABILIDAD DE ESCUDO EMBESTIDOR (Superdeportivo GT o F1 Dorado)
		var tipo = obtener_tipo_habilidad()
		if habilidad_activa and (tipo in ["escudo_embestida", "todas"]):
			crear_efecto_impacto(area.global_position)
			var es_barricada = area.is_in_group("barricadas") or area.name.to_lower().contains("barricada")
			if not es_barricada:
				# Si es un espejismo holográfico, disolverlo de inmediato
				if area.is_in_group("espejismos") or area.get("es_espejismo") == true:
					if area.has_method("disolver_espejismo"):
						area.disolver_espejismo()
					else:
						area.queue_free()
				else:
					# Empujar al rival al carril de al lado
					var carriles = obtener_carriles()
					var empuje_dir = 1.0 if (randf() > 0.5 or area.global_position.x < global_position.x) else -1.0
					var nuevo_x = area.global_position.x + (empuje_dir * 140.0)
					if carriles.size() > 0:
						nuevo_x = clampf(nuevo_x, carriles[0], carriles[carriles.size() - 1])
					area.global_position.x = nuevo_x
				
				# Sumar +2 puntos de bonificación por embestida
				if mundo and mundo.has_method("sumar_puntos_extra"):
					mundo.sumar_puntos_extra(2)
				elif mundo and mundo.has_method("sumar_punto"):
					mundo.sumar_punto()
					mundo.sumar_punto()
					
				if has_node("AudioColision"):
					$AudioColision.play()
				return # El jugador sale ileso y conserva su habilidad activa

		# 2. Espejismos Fantasma sin daño (el jugador cruza la ilusión holográfica ileso)
		if area.is_in_group("espejismos") or area.get("es_espejismo") == true:
			crear_efecto_impacto(area.global_position)
			if area.has_method("disolver_espejismo"):
				area.disolver_espejismo()
			else:
				area.queue_free()
			return # Atraviesa el espejismo sin recibir daño
		
		crear_efecto_impacto(area.global_position)

		# 3. Escudo regular recogido en pista
		if tiene_escudo:
			desactivar_escudo()
			area.queue_free()
			if has_node("AudioColision"):
				$AudioColision.play()
			return

		# 4. Colisión normal con daño
		if mundo and mundo.has_method("restar_vida"):
			mundo.restar_vida()
			if has_node("AudioColision"):
				$AudioColision.play()

func resetear_posicion() -> void:
	actualizar_textura_auto()
	actualizar_modo_control()
	desactivar_escudo()
	deslizando = false
	tiempo_deslizando = 0.0
	habilidad_activa = false
	tiempo_habilidad = 0.0
	tiempo_cooldown = 0.0
	var carriles = obtener_carriles()
	carril_actual = carriles.size() / 2
	position.x = carriles[carril_actual]
	position.y = 950.0
	rotation = 0.0
	queue_redraw()
