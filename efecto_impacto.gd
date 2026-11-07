extends Node2D

var tiempo: float = 0.0
var duracion: float = 0.25
var color_destello: Color = Color(1.0, 0.65, 0.2, 1.0)

func _ready() -> void:
	z_index = 50

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	tiempo += delta
	queue_redraw()
	if tiempo >= duracion:
		queue_free()

func _draw() -> void:
	var prog = tiempo / duracion
	var radio = lerpf(12.0, 70.0, prog)
	var alpha = 1.0 - prog
	
	# Anillo expansivo de impacto
	draw_arc(Vector2.ZERO, radio, 0.0, TAU, 32, Color(color_destello.r, color_destello.g, color_destello.b, alpha), 4.0)
	draw_circle(Vector2.ZERO, radio * 0.45, Color(1.0, 1.0, 0.8, alpha * 0.6))
	
	# Rayos / Chispas radiantes
	for i in range(8):
		var angulo = i * (TAU / 8.0)
		var dir = Vector2(cos(angulo), sin(angulo))
		var p1 = dir * (radio * 0.4)
		var p2 = dir * (radio * 1.25)
		draw_line(p1, p2, Color(1.0, 0.9, 0.3, alpha), 3.0)
