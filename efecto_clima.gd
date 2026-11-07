extends Control

var tipo_clima: String = "despejado" # "lluvia", "niebla", "despejado"
var gotas_lluvia: Array = []
var nubes_niebla: Array = []
var tiempo_relampago: float = 0.0
var proximo_relampago: float = 5.0

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)
	inicializar_gotas()
	inicializar_niebla()

func inicializar_gotas() -> void:
	gotas_lluvia.clear()
	for i in range(80):
		gotas_lluvia.append({
			"pos": Vector2(randf_range(0, 650), randf_range(0, 1152)),
			"longitud": randf_range(20, 42),
			"velocidad": randf_range(1000, 1500),
			"grosor": randf_range(1.5, 2.5),
			"alpha": randf_range(0.45, 0.9)
		})

func inicializar_niebla() -> void:
	nubes_niebla.clear()
	for i in range(6):
		nubes_niebla.append({
			"pos": Vector2(randf_range(50, 600), randf_range(100, 1000)),
			"radio": randf_range(140, 240),
			"vel_x": randf_range(-20, 20),
			"alpha": randf_range(0.2, 0.35)
		})

func cambiar_clima(nuevo_clima: String) -> void:
	tipo_clima = nuevo_clima
	visible = (tipo_clima != "despejado")
	queue_redraw()

func _process(delta: float) -> void:
	if not visible or get_tree().paused:
		return

	var tamano_pantalla = get_viewport_rect().size
	if tamano_pantalla.x > 0:
		size = tamano_pantalla

	if tipo_clima == "lluvia":
		# Mover gotas de lluvia velozmente
		for gota in gotas_lluvia:
			gota["pos"].y += gota["velocidad"] * delta
			gota["pos"].x -= 120.0 * delta # inclinación por viento
			if gota["pos"].y > size.y + 40:
				gota["pos"].y = randf_range(-50, -10)
				gota["pos"].x = randf_range(0, size.x + 150)

		# Relámpago ocasional
		proximo_relampago -= delta
		if proximo_relampago <= 0:
			tiempo_relampago = 0.09
			proximo_relampago = randf_range(4.0, 7.5)
			
		if tiempo_relampago > 0:
			tiempo_relampago -= delta

	elif tipo_clima == "niebla":
		# Mover nubes suaves de niebla
		for nube in nubes_niebla:
			nube["pos"].x += nube["vel_x"] * delta
			if nube["pos"].x < -150:
				nube["pos"].x = size.x + 150
			elif nube["pos"].x > size.x + 150:
				nube["pos"].x = -150

	queue_redraw()

func _draw() -> void:
	var area = Rect2(Vector2.ZERO, size)

	if tipo_clima == "lluvia":
		# Tono general azulado de tormenta
		draw_rect(area, Color(0.04, 0.12, 0.28, 0.32))
		
		# Gotas de lluvia
		for gota in gotas_lluvia:
			var inicio = gota["pos"]
			var fin = inicio + Vector2(-8, gota["longitud"])
			var col = Color(0.68, 0.88, 1.0, gota["alpha"])
			draw_line(inicio, fin, col, gota["grosor"])

		# Destello de relámpago
		if tiempo_relampago > 0:
			draw_rect(area, Color(0.85, 0.95, 1.0, 0.38))

	elif tipo_clima == "niebla":
		# Tono de niebla densa general
		draw_rect(area, Color(0.82, 0.85, 0.92, 0.38))
		
		# Nubes suaves de niebla flotante
		for nube in nubes_niebla:
			var col = Color(0.92, 0.95, 1.0, nube["alpha"])
			draw_circle(nube["pos"], nube["radio"], col)
