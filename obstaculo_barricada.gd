extends Area2D

var velocidad: float = 350.0
var tiempo_luz: float = 0.0

func _ready() -> void:
	add_to_group("enemigos")

func _process(delta: float) -> void:
	if get_tree().paused:
		return
		
	tiempo_luz += delta * 8.0
	position.y += (velocidad * 0.75) * delta
	queue_redraw()

func _draw() -> void:
	# Luces ámbar intermitentes de advertencia sobre las balizas
	var parpadeo = abs(sin(tiempo_luz))
	var col_luz = Color(1.0, 0.75, 0.1, 0.35 + (parpadeo * 0.45))
	var col_corona = Color(1.0, 0.9, 0.3, 0.2 + (parpadeo * 0.3))
	
	# Coordenadas relativas de las 2 balizas superiores de la barricada cenital
	var pos_izq = Vector2(-29.0, -19.5)
	var pos_der = Vector2(29.0, -19.5)
	
	draw_circle(pos_izq, 11.0 + (parpadeo * 4.0), col_corona)
	draw_circle(pos_izq, 5.0, col_luz)
	draw_circle(pos_der, 11.0 + (parpadeo * 4.0), col_corona)
	draw_circle(pos_der, 5.0, col_luz)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	var mundo = get_tree().current_scene
	if mundo and mundo.has_method("sumar_punto"):
		mundo.sumar_punto()
	queue_free()
