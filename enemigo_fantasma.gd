extends Area2D

var velocidad: float = 400.0
var es_espejismo: bool = false
var tiempo_flicker: float = 0.0
var x_base: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("enemigos")
	x_base = position.x
	
	if es_espejismo:
		add_to_group("espejismos")
		modulate = Color(0.25, 0.95, 1.0, 0.52)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func _process(delta: float) -> void:
	if get_tree().paused:
		return
		
	var mundo = get_tree().current_scene
	var mult = mundo.obtener_factor_ralentizacion() if mundo and mundo.has_method("obtener_factor_ralentizacion") else 1.0
	position.y += (velocidad * mult) * delta
	
	if es_espejismo:
		tiempo_flicker += delta * 14.0
		var alfa = 0.44 + sin(tiempo_flicker) * 0.16
		modulate.a = alfa
		position.x = x_base + sin(tiempo_flicker * 2.3) * 1.8

func disolver_espejismo() -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.3, 0.4), 0.15)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(queue_free)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if not es_espejismo:
		var mundo = get_tree().current_scene
		if mundo and mundo.has_method("sumar_punto"):
			mundo.sumar_punto()
	queue_free()

func _on_area_entered(_area: Area2D) -> void:
	pass
