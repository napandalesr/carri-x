extends Area2D

var velocidad: float = 400.0
var tiempo_sirena: float = 0.0

# Estados de maniobra:
# 0: Descendiendo recto
# 1: Inclinación previa / aviso (telegrafiado hacia el carril de destino)
# 2: Desplazamiento lateral suave hacia el carril
# 3: Enderezado y avance recto final
var estado_maniobra: int = 0
var tiempo_aviso: float = 0.0
const DURACION_AVISO: float = 0.45
var x_destino: float = 0.0
var direccion_giro: float = 0.0

func _ready() -> void:
	add_to_group("enemigos")

func _process(delta: float) -> void:
	if get_tree().paused:
		return
		
	tiempo_sirena += delta * 15.0
	position.y += (velocidad * 1.25) * delta
	
	match estado_maniobra:
		0:
			# Detectar si es momento de planificar el cambio (al superar los 350px)
			if position.y > 350.0:
				var mundo = get_tree().current_scene
				if mundo and mundo.has_method("obtener_carriles"):
					var carriles = mundo.obtener_carriles()
					if carriles.size() > 1:
						var min_dist = 9999.0
						var idx_actual = 0
						for i in range(carriles.size()):
							var dist = abs(carriles[i] - position.x)
							if dist < min_dist:
								min_dist = dist
								idx_actual = i
						
						var desplazamiento = 1 if randf() > 0.5 else -1
						if idx_actual == 0:
							desplazamiento = 1
						elif idx_actual == carriles.size() - 1:
							desplazamiento = -1
							
						var nuevo_idx = clampi(idx_actual + desplazamiento, 0, carriles.size() - 1)
						if nuevo_idx != idx_actual:
							x_destino = carriles[nuevo_idx]
							direccion_giro = float(desplazamiento) # +1 derecha, -1 izquierda
							estado_maniobra = 1
							tiempo_aviso = 0.0
						else:
							estado_maniobra = 3
					else:
						estado_maniobra = 3

		1:
			# FASE 1: Inclinación previa clara para que el jugador sepa hacia dónde va
			tiempo_aviso += delta
			var rot_objetivo = -deg_to_rad(direccion_giro * 16.0)
			rotation = lerp(rotation, rot_objetivo, 12.0 * delta)
			if tiempo_aviso >= DURACION_AVISO:
				estado_maniobra = 2

		2:
			# FASE 2: Maniobra e interpolación suave hacia el carril de destino
			position.x = lerp(position.x, x_destino, 5.5 * delta)
			var rot_maniobra = -deg_to_rad(direccion_giro * 18.0)
			rotation = lerp(rotation, rot_maniobra, 10.0 * delta)
			if abs(position.x - x_destino) < 4.0:
				position.x = x_destino
				estado_maniobra = 3

		3:
			# FASE 3: Enderezar el auto y continuar en el nuevo carril
			rotation = lerp(rotation, 0.0, 10.0 * delta)

	queue_redraw()

func _draw() -> void:
	var alternar = int(tiempo_sirena) % 2 == 0
	var col_sirena = Color(1.0, 0.15, 0.15, 0.45) if alternar else Color(0.1, 0.55, 1.0, 0.45)
	draw_circle(Vector2(0, 0), 55.0, col_sirena)
	
	# Durante el aviso previo de giro, proyectar un destello indicativo hacia el lado de giro
	if estado_maniobra == 1:
		var col_guiño = Color(1.0, 0.8, 0.1, 0.6 if alternar else 0.2)
		draw_circle(Vector2(direccion_giro * 34.0, 15.0), 12.0, col_guiño)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	var mundo = get_tree().current_scene
	if mundo and mundo.has_method("sumar_punto"):
		mundo.sumar_punto()
	queue_free()
