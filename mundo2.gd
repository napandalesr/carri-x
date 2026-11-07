extends Node2D

const URL_POLITICA_PRIVACIDAD: String = "https://soporte-carrilx.github.io/politica_de_privacidad.html"

@export var enemigos_scenes: Array[PackedScene] = [
	preload("res://enemigo.tscn"),
	preload("res://enemigos/enemigoVolqueta/enemigo_volqueta.tscn"),
	preload("res://enemigos/enemigoMoto/enemigo_moto.tscn"),
	preload("res://enemigos/enemigoAceite/enemigo_aceite.tscn"),
	preload("res://enemigo_policia.tscn"),
	preload("res://obstaculo_barricada.tscn"),
	preload("res://enemigo_fantasma.tscn")
]

@export var items_scenes: Array[PackedScene] = [
	preload("res://items/item_moneda.tscn"),
	preload("res://items/item_escudo.tscn"),
	preload("res://items/item_reloj.tscn")
]

@onready var jugador = get_node_or_null("Jugador")
@onready var timer = get_node_or_null("Timer")
@onready var parallax_background = get_node_or_null("ParallaxBackground")
@onready var sprite_fondo = get_node_or_null("ParallaxBackground/ParallaxLayer/Sprite2D")

@onready var hud = get_node_or_null("HUD")
@onready var puntaje_label = get_node_or_null("HUD/PuntajeLabel")
@onready var record_label = get_node_or_null("HUD/RecordLabel")
@onready var contenedor_vidas = get_node_or_null("HUD/ContenedorVidas")

@onready var menu_inicio = get_node_or_null("HUD/MenuInicio")
@onready var boton_jugar = get_node_or_null("HUD/MenuInicio/BotonJugar")

@onready var menu_game_over = get_node_or_null("HUD/MenuGameOver")
@onready var boton_reiniciar = get_node_or_null("HUD/MenuGameOver/BotonReiniciar")

@onready var menu_transicion = get_node_or_null("HUD/MenuTransicion")
@onready var boton_siguiente_nivel = get_node_or_null("HUD/MenuTransicion/BotonSiguienteNivel")

@onready var musica_fondo = get_node_or_null("MusicaFondo")

var puntos: int = 0
var vidas: int = 3
var velocidad_enemigos: float = 400.0
var velocidad_fondo: float = 0.0
var juego_activo: bool = false
var en_transicion: bool = false
var juego_pausado: bool = false

# --- VIBRACIÓN DE CÁMARA & RALENTIZACIÓN ---
var duracion_vibracion: float = 0.0
var fuerza_vibracion: float = 12.0
var ralentizado: bool = false
var tiempo_ralentizado: float = 0.0
var tiempo_spawn_base: float = 1.10
var escena_corazon: PackedScene = preload("res://items/item_corazon.tscn")
var corazon_spawneado_en_nivel: bool = false
var spawns_desde_ultima_barricada: int = 15
var spawns_desde_ultimo_aceite: int = 15
var spawns_desde_ultimo_fantasma: int = 15

# --- Nodos Creados Dinámicamente para la Interfaz Avanzada ---
var boton_pausa_hud: TextureButton
var boton_habilidad_hud: TextureButton
var label_monedas_hud: Label
var monedas_recolectadas_partida: int = 0

var menu_pausa: Control
var menu_ajustes: Control
var menu_guia: Control
var menu_niveles: Control
var menu_garaje: Control
var menu_opciones_jugar: Control
var menu_modal_transicion: Control
var menu_victoria_campana: Control

var box_pausa: VBoxContainer
var box_ajustes: VBoxContainer
var box_guia: VBoxContainer
var box_niveles: VBoxContainer
var box_garaje: VBoxContainer
var box_opciones_jugar: VBoxContainer
var box_modal_transicion: VBoxContainer
var box_victoria_campana: VBoxContainer

# Referencias directas para actualización instantánea bilingüe
var boton_menu_garaje: TextureButton
var boton_menu_niveles: TextureButton
var boton_menu_ajustes: TextureButton
var boton_menu_guia: TextureButton
var btn_menu_go: TextureButton
var btn_menu_trans: TextureButton
var lbl_reinicio: Label
var btn_continuar_pausa: TextureButton
var btn_ajustes_pausa: TextureButton
var btn_salir_pausa: TextureButton
var boton_desplegable_idioma: PanelContainer
var icono_bandera_actual: TextureRect
var flecha_desplegable_idioma: Label
var panel_desplegable_idioma: PanelContainer
var check_idioma_es: Label
var check_idioma_en: Label
var btn_toggle_audio: TextureButton
var btn_toggle_musica: TextureButton
var btn_cerrar_ajustes: TextureButton
var btn_cerrar_guia: TextureButton
var btn_continuar_partida: TextureButton
var btn_nueva_partida: TextureButton
var btn_cancelar_jugar: TextureButton
var lbl_vic_desc: Label
var btn_ir_infinito: TextureButton
var btn_salir_vic: TextureButton

var titulo_pausa: Label
var titulo_ajustes: Label
var titulo_guia: Label
var titulo_niveles: Label
var titulo_garaje: Label
var titulo_transicion: Label
var titulo_opciones_jugar: Label
var titulo_victoria: Label

var label_audio_estado: Label
var label_musica_estado: Label
var label_pausa_info: Label
var label_transicion_info: Label
var label_opciones_jugar_info: Label
var btn_continuar_juego_lbl: Label
var label_clima_hud: Label
var overlay_clima: Control
var barra_meta_hud: ProgressBar
var audio_victoria_player: AudioStreamPlayer
var audio_item_player: AudioStreamPlayer
var boton_revivir_ad: TextureButton
var revividas_en_esta_partida: int = 0
var tiempo_visible_clima: float = 0.0

var label_modo_control: Label
var label_desc_control: Label
var btn_cambiar_control: TextureButton
var banner_tutorial_carril: PanelContainer

func obtener_carriles() -> Array:
	var info_nivel = DatosNiveles.NIVELES.get(DatosNiveles.nivel_actual, DatosNiveles.NIVELES[1])
	return info_nivel["carriles"]

func actualizar_fondo_nivel() -> void:
	var info_nivel = DatosNiveles.NIVELES.get(DatosNiveles.nivel_actual, DatosNiveles.NIVELES[1])
	if sprite_fondo and "fondo" in info_nivel:
		var ruta_fondo: String = info_nivel["fondo"]
		if ResourceLoader.exists(ruta_fondo):
			var nueva_textura: Texture2D = load(ruta_fondo)
			sprite_fondo.texture = nueva_textura
			
			var tamano_pantalla = get_viewport_rect().size
			var tamano_textura = nueva_textura.get_size()
			if tamano_textura.x > 0 and tamano_textura.y > 0:
				sprite_fondo.scale = Vector2(
					tamano_pantalla.x / tamano_textura.x,
					tamano_pantalla.y / tamano_textura.y
				)
			if sprite_fondo.centered:
				sprite_fondo.position = tamano_pantalla / 2.0
			else:
				sprite_fondo.position = Vector2.ZERO
	actualizar_clima(DatosNiveles.nivel_actual)

func crear_boton_arcade(texto: String, pos: Vector2 = Vector2.ZERO, tamano: Vector2 = Vector2(408, 90), tamano_fuente: int = 24) -> TextureButton:
	var btn = TextureButton.new()
	var tex = load("res://fondoBotonJugar.png")
	btn.texture_normal = tex
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	btn.custom_minimum_size = tamano
	if pos != Vector2.ZERO:
		btn.set_position(pos)
		btn.set_size(tamano)
	
	var lbl = Label.new()
	lbl.name = "Label"
	lbl.text = texto
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", tamano_fuente)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.2, 0.05, 0.95))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	btn.add_child(lbl)
	
	return btn

func actualizar_texto_boton(btn: TextureButton, texto: String) -> void:
	if is_instance_valid(btn):
		var lbl = btn.get_node_or_null("Label")
		if lbl:
			lbl.text = texto

func _ready() -> void:
	DisplayServer.screen_set_orientation(1)
	construir_interfaz_avanzada()
	aplicar_configuracion_audio()
	cerrar_modales()
	
	if has_node("/root/AdministradorAnuncios"):
		AdministradorAnuncios.solicitar_anuncio_apertura_app()
	
	if menu_inicio:
		menu_inicio.visible = true
	if menu_game_over:
		menu_game_over.visible = false
	if menu_transicion:
		menu_transicion.visible = false
	if puntaje_label:
		puntaje_label.visible = false
	if record_label:
		record_label.visible = false
	if contenedor_vidas:
		contenedor_vidas.visible = false
	if boton_pausa_hud:
		boton_pausa_hud.visible = false
		
	if timer:
		timer.stop()
	actualizar_fondo_nivel()
	
	if boton_jugar:
		boton_jugar.pressed.connect(_on_boton_jugar_pressed)
	if boton_reiniciar:
		boton_reiniciar.pressed.connect(_on_boton_reiniciar_pressed)
		boton_reiniciar.set_position(Vector2(100, 455))
		boton_reiniciar.set_size(Vector2(448, 85))
		if menu_game_over:
			lbl_reinicio = menu_game_over.get_node_or_null("Label")
			if lbl_reinicio:
				lbl_reinicio.set_position(Vector2(100, 455))
				lbl_reinicio.set_size(Vector2(448, 85))
				lbl_reinicio.text = DatosNiveles.t("BTN_REINTENTAR")
				lbl_reinicio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl_reinicio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				lbl_reinicio.add_theme_font_size_override("font_size", 22)
	
	if menu_game_over:
		boton_revivir_ad = crear_boton_arcade(DatosNiveles.t("BTN_REVIVIR_AD"), Vector2(100, 350), Vector2(448, 85), 20)
		boton_revivir_ad.pressed.connect(_on_boton_revivir_ad_pressed)
		menu_game_over.add_child(boton_revivir_ad)
		
	if boton_siguiente_nivel:
		boton_siguiente_nivel.pressed.connect(_on_boton_siguiente_nivel_pressed)

	# Capturador de capturas/fotos activo con teclas F12, F2 o P (incluso con el juego pausado)
	if hud:
		var nodo_captura = Node.new()
		nodo_captura.name = "CapturadorGlobalTeclas"
		nodo_captura.process_mode = Node.PROCESS_MODE_ALWAYS
		var script_captura = GDScript.new()
		script_captura.source_code = "@tool\nextends Node\nsignal tecla_presionada\nfunc _input(event: InputEvent) -> void:\n\tif event is InputEventKey and event.pressed and not event.echo:\n\t\tif event.keycode == KEY_F12 or event.keycode == KEY_P or event.keycode == KEY_F2:\n\t\t\ttecla_presionada.emit()\n"
		script_captura.reload()
		nodo_captura.set_script(script_captura)
		hud.add_child(nodo_captura)
		nodo_captura.tecla_presionada.connect(func():
			tomar_captura(menu_pausa != null and menu_pausa.visible)
		)

	actualizar_idioma_interfaz()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F12 or event.keycode == KEY_P or event.keycode == KEY_F2:
			tomar_captura(menu_pausa != null and menu_pausa.visible)

	# Cerrar el menú desplegable de idioma si se hace clic fuera de él
	if panel_desplegable_idioma and panel_desplegable_idioma.visible:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var pos = event.position
			if boton_desplegable_idioma and panel_desplegable_idioma:
				if not boton_desplegable_idioma.get_global_rect().has_point(pos) and not panel_desplegable_idioma.get_global_rect().has_point(pos):
					panel_desplegable_idioma.visible = false
					if flecha_desplegable_idioma:
						flecha_desplegable_idioma.text = "▼"

# --- DETECCIÓN DE SALIDA O PÉRDIDA DE FOCO (PAUSA AUTOMÁTICA) ---
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if juego_activo and not juego_pausado and not en_transicion:
			pausar_juego()

func _process(delta: float) -> void:
	if juego_pausado:
		return

	# Vibración de Cámara
	if duracion_vibracion > 0:
		duracion_vibracion -= delta
		position = Vector2(
			randf_range(-fuerza_vibracion, fuerza_vibracion),
			randf_range(-fuerza_vibracion, fuerza_vibracion)
		)
	else:
		position = Vector2.ZERO

	# Ralentización (Reloj)
	if ralentizado:
		tiempo_ralentizado -= delta
		if tiempo_ralentizado <= 0:
			ralentizado = false
			if timer:
				timer.wait_time = tiempo_spawn_base

	var vel_actual_fondo = velocidad_fondo * (0.6 if ralentizado else 1.0)
	if juego_activo and parallax_background and vel_actual_fondo > 0:
		parallax_background.scroll_offset.y += vel_actual_fondo * delta

	# Temporizador para ocultar el texto de clima tras 5 segundos
	if tiempo_visible_clima > 0.0:
		tiempo_visible_clima -= delta
		if tiempo_visible_clima <= 0.0 and label_clima_hud:
			label_clima_hud.visible = false



# --- CONSTRUCCIÓN DINÁMICA DE MENÚS Y HUD REDISEÑADO ---
func construir_interfaz_avanzada() -> void:
	if not hud:
		return

	# Permitir que el HUD siga activo cuando el árbol del juego se pausa
	hud.process_mode = Node.PROCESS_MODE_ALWAYS

	# 1. Botón de Pausa Elegante en la Esquina Superior Izquierda (Sin tapar la puntuación)
	boton_pausa_hud = crear_boton_arcade(DatosNiveles.t("BTN_PAUSA"), Vector2(20, 15), Vector2(110, 48))
	boton_pausa_hud.z_index = 100
	boton_pausa_hud.pressed.connect(pausar_juego)
	hud.add_child(boton_pausa_hud)

	# Ubicación limpia para PuntajeLabel y ContenedorVidas en la barra superior
	if puntaje_label:
		puntaje_label.set_position(Vector2(145, 18))
		puntaje_label.z_index = 100
	if contenedor_vidas:
		contenedor_vidas.set_position(Vector2(410, 15))
		contenedor_vidas.custom_minimum_size = Vector2(210, 44)
		contenedor_vidas.set_size(Vector2(210, 44))
		contenedor_vidas.alignment = BoxContainer.ALIGNMENT_END
		contenedor_vidas.z_index = 100

	label_clima_hud = Label.new()
	label_clima_hud.set_position(Vector2(450, 68))
	label_clima_hud.add_theme_font_size_override("font_size", 15)
	label_clima_hud.modulate = Color(1.0, 0.95, 0.6)
	label_clima_hud.z_index = 100
	label_clima_hud.visible = false
	hud.add_child(label_clima_hud)

	# 2. Contador Exclusivo de Monedas en el HUD (Claro, visible y sin barras confusas)
	label_monedas_hud = Label.new()
	label_monedas_hud.set_position(Vector2(145, 48))
	label_monedas_hud.add_theme_font_size_override("font_size", 16)
	label_monedas_hud.modulate = Color(1.0, 0.85, 0.2)
	label_monedas_hud.z_index = 100
	label_monedas_hud.visible = false
	hud.add_child(label_monedas_hud)

	# 3. Botón Flotante de Habilidad Activa (Móvil / Táctil)
	boton_habilidad_hud = crear_boton_arcade("⚡", Vector2(510, 1080), Vector2(100, 100), 28)
	boton_habilidad_hud.z_index = 100
	boton_habilidad_hud.visible = false
	boton_habilidad_hud.pressed.connect(func():
		if jugador and jugador.has_method("activar_habilidad_especial"):
			jugador.activar_habilidad_especial()
	)
	hud.add_child(boton_habilidad_hud)

	overlay_clima = Control.new()
	overlay_clima.set_script(preload("res://efecto_clima.gd"))
	overlay_clima.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_clima.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_clima.z_index = 50
	add_child(overlay_clima)

	audio_victoria_player = AudioStreamPlayer.new()
	if ResourceLoader.exists("res://sonidos/victoria.wav"):
		audio_victoria_player.stream = load("res://sonidos/victoria.wav")
	add_child(audio_victoria_player)

	audio_item_player = AudioStreamPlayer.new()
	add_child(audio_item_player)

	# Agregar Botones en el Menú Inicio con alineación limpia
	if menu_inicio:
		crear_selector_idioma_desplegable()

		boton_menu_garaje = crear_boton_arcade(DatosNiveles.t("BTN_GARAJE"), Vector2(120, 465), Vector2(408, 90))
		boton_menu_garaje.pressed.connect(abrir_menu_garaje)
		menu_inicio.add_child(boton_menu_garaje)

		boton_menu_niveles = crear_boton_arcade(DatosNiveles.t("BTN_NIVELES"), Vector2(120, 565), Vector2(408, 90))
		boton_menu_niveles.pressed.connect(abrir_menu_niveles)
		menu_inicio.add_child(boton_menu_niveles)

		boton_menu_ajustes = crear_boton_arcade(DatosNiveles.t("BTN_AJUSTES"), Vector2(120, 665), Vector2(408, 90))
		boton_menu_ajustes.pressed.connect(abrir_menu_ajustes)
		menu_inicio.add_child(boton_menu_ajustes)

		boton_menu_guia = crear_boton_arcade(DatosNiveles.t("BTN_GUIA"), Vector2(120, 765), Vector2(408, 90))
		boton_menu_guia.pressed.connect(abrir_menu_guia)
		menu_inicio.add_child(boton_menu_guia)

	# Agregar Botón Volver al Menú en Pantalla de Game Over
	if menu_game_over:
		btn_menu_go = crear_boton_arcade(DatosNiveles.t("BTN_MENU_PRINCIPAL"), Vector2(100, 560), Vector2(448, 85), 22)
		btn_menu_go.pressed.connect(volver_al_menu_principal)
		menu_game_over.add_child(btn_menu_go)

	# Agregar Botón Volver al Menú en Pantalla de Nivel Completado
	if menu_transicion:
		btn_menu_trans = crear_boton_arcade(DatosNiveles.t("BTN_MENU_PRINCIPAL"), Vector2(120, 770), Vector2(408, 95))
		btn_menu_trans.pressed.connect(volver_al_menu_principal)
		menu_transicion.add_child(btn_menu_trans)

	# 2. Menú de Pausa
	var res_pausa = crear_panel_modal(DatosNiveles.t("TITULO_PAUSA"))
	menu_pausa = res_pausa["control"]
	box_pausa = res_pausa["vbox"]
	titulo_pausa = res_pausa["titulo"]
	
	label_pausa_info = Label.new()
	label_pausa_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_pausa_info.add_theme_font_size_override("font_size", 20)
	label_pausa_info.modulate = Color(1.0, 0.9, 0.4)
	box_pausa.add_child(label_pausa_info)

	btn_continuar_pausa = crear_boton_arcade(DatosNiveles.t("BTN_CONTINUAR"), Vector2.ZERO, Vector2(380, 70))
	btn_continuar_pausa.pressed.connect(despausar_juego)
	box_pausa.add_child(btn_continuar_pausa)
	
	btn_ajustes_pausa = crear_boton_arcade(DatosNiveles.t("BTN_AJUSTES_PAUSA"), Vector2.ZERO, Vector2(380, 70))
	btn_ajustes_pausa.pressed.connect(abrir_menu_ajustes)
	box_pausa.add_child(btn_ajustes_pausa)
	
	btn_salir_pausa = crear_boton_arcade(DatosNiveles.t("BTN_MENU_PRINCIPAL"), Vector2.ZERO, Vector2(380, 70))
	btn_salir_pausa.pressed.connect(volver_al_menu_principal)
	box_pausa.add_child(btn_salir_pausa)

	# 3. Menú de Opciones y Controles
	var res_ajustes = crear_panel_modal(DatosNiveles.t("TITULO_AJUSTES"))
	menu_ajustes = res_ajustes["control"]
	box_ajustes = res_ajustes["vbox"]
	titulo_ajustes = res_ajustes["titulo"]
	
	label_modo_control = Label.new()
	label_modo_control.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_modo_control.add_theme_font_size_override("font_size", 18)
	label_modo_control.modulate = Color(1.0, 0.9, 0.3)
	box_ajustes.add_child(label_modo_control)
	
	label_desc_control = Label.new()
	label_desc_control.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_desc_control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_desc_control.custom_minimum_size = Vector2(400, 48)
	label_desc_control.add_theme_font_size_override("font_size", 13)
	label_desc_control.modulate = Color(0.85, 0.92, 1.0)
	box_ajustes.add_child(label_desc_control)
	
	btn_cambiar_control = crear_boton_arcade(DatosNiveles.t("BTN_CAMBIAR_CONTROL"), Vector2.ZERO, Vector2(380, 58), 19)
	btn_cambiar_control.pressed.connect(toggle_modo_control)
	box_ajustes.add_child(btn_cambiar_control)
	
	var sep_audio = HSeparator.new()
	sep_audio.modulate = Color(0.3, 0.5, 0.7, 0.5)
	box_ajustes.add_child(sep_audio)
	
	label_audio_estado = Label.new()
	label_audio_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_audio_estado.add_theme_font_size_override("font_size", 16)
	box_ajustes.add_child(label_audio_estado)
	
	btn_toggle_audio = crear_boton_arcade(DatosNiveles.t("BTN_SILENCIAR_TODO"), Vector2.ZERO, Vector2(380, 54), 19)
	btn_toggle_audio.pressed.connect(toggle_audio_completo)
	box_ajustes.add_child(btn_toggle_audio)
	
	label_musica_estado = Label.new()
	label_musica_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_musica_estado.add_theme_font_size_override("font_size", 16)
	box_ajustes.add_child(label_musica_estado)
	
	btn_toggle_musica = crear_boton_arcade(DatosNiveles.t("BTN_SILENCIAR_MUSICA"), Vector2.ZERO, Vector2(380, 54), 19)
	btn_toggle_musica.pressed.connect(toggle_musica_fondo)
	box_ajustes.add_child(btn_toggle_musica)
	
	btn_cerrar_ajustes = crear_boton_arcade(DatosNiveles.t("BTN_VOLVER"), Vector2.ZERO, Vector2(380, 58), 20)
	btn_cerrar_ajustes.pressed.connect(cerrar_modales)
	box_ajustes.add_child(btn_cerrar_ajustes)

	# 4. Menú Guía de Elementos (Tutorial)
	var res_guia = crear_panel_modal(DatosNiveles.t("TITULO_GUIA"))
	menu_guia = res_guia["control"]
	box_guia = res_guia["vbox"]
	titulo_guia = res_guia["titulo"]
	reconstruir_menu_guia()

	# 5. Menú Garaje de Vehículos
	var res_garaje = crear_panel_modal(DatosNiveles.t("TITULO_GARAJE"))
	menu_garaje = res_garaje["control"]
	box_garaje = res_garaje["vbox"]
	titulo_garaje = res_garaje["titulo"]

	# 6. Menú Selector de Niveles (Vista Informativa)
	var res_niveles = crear_panel_modal(DatosNiveles.t("TITULO_NIVELES"))
	menu_niveles = res_niveles["control"]
	box_niveles = res_niveles["vbox"]
	titulo_niveles = res_niveles["titulo"]

	# 7. Menú Modal de Nivel Completado
	var res_trans = crear_panel_modal(DatosNiveles.t("TITULO_TRANSICION"))
	menu_modal_transicion = res_trans["control"]
	box_modal_transicion = res_trans["vbox"]
	titulo_transicion = res_trans["titulo"]
	construir_pantalla_transicion(1)

	# 8. Menú Modal de Opciones al Presionar JUGAR
	var res_jugar_opc = crear_panel_modal(DatosNiveles.t("TITULO_OPCIONES_JUGAR"))
	menu_opciones_jugar = res_jugar_opc["control"]
	box_opciones_jugar = res_jugar_opc["vbox"]
	titulo_opciones_jugar = res_jugar_opc["titulo"]

	label_opciones_jugar_info = Label.new()
	label_opciones_jugar_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_opciones_jugar_info.add_theme_font_size_override("font_size", 18)
	label_opciones_jugar_info.modulate = Color(1.0, 0.9, 0.4)
	label_opciones_jugar_info.autowrap_mode = TextServer.AUTOWRAP_WORD
	box_opciones_jugar.add_child(label_opciones_jugar_info)

	btn_continuar_partida = crear_boton_arcade(DatosNiveles.t("BTN_CONTINUAR_NIVEL", [DatosNiveles.nivel_actual]), Vector2.ZERO, Vector2(380, 70))
	if btn_continuar_partida.get_child_count() > 0:
		btn_continuar_juego_lbl = btn_continuar_partida.get_child(0) as Label
	btn_continuar_partida.pressed.connect(continuar_partida_guardada)
	box_opciones_jugar.add_child(btn_continuar_partida)

	btn_nueva_partida = crear_boton_arcade(DatosNiveles.t("BTN_NUEVA_PARTIDA"), Vector2.ZERO, Vector2(380, 70))
	btn_nueva_partida.pressed.connect(empezar_nueva_partida)
	box_opciones_jugar.add_child(btn_nueva_partida)

	btn_cancelar_jugar = crear_boton_arcade(DatosNiveles.t("BTN_VOLVER"), Vector2.ZERO, Vector2(380, 70))
	btn_cancelar_jugar.pressed.connect(cerrar_modales)
	box_opciones_jugar.add_child(btn_cancelar_jugar)

	# 9. Menú Modal de Gran Victoria de Fin de Campaña (Nivel 30)
	var res_vic = crear_panel_modal(DatosNiveles.t("TITULO_VICTORIA"))
	menu_victoria_campana = res_vic["control"]
	box_victoria_campana = res_vic["vbox"]
	titulo_victoria = res_vic["titulo"]

	lbl_vic_desc = Label.new()
	lbl_vic_desc.text = DatosNiveles.t("DESC_VICTORIA")
	lbl_vic_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_vic_desc.add_theme_font_size_override("font_size", 16)
	lbl_vic_desc.modulate = Color(1.0, 0.95, 0.4)
	lbl_vic_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	box_victoria_campana.add_child(lbl_vic_desc)

	btn_ir_infinito = crear_boton_arcade(DatosNiveles.t("BTN_MODO_INFINITO"), Vector2.ZERO, Vector2(380, 70))
	btn_ir_infinito.pressed.connect(_on_boton_siguiente_nivel_pressed)
	box_victoria_campana.add_child(btn_ir_infinito)

	btn_salir_vic = crear_boton_arcade(DatosNiveles.t("BTN_MENU_PRINCIPAL"), Vector2.ZERO, Vector2(380, 70))
	btn_salir_vic.pressed.connect(volver_al_menu_principal)
	box_victoria_campana.add_child(btn_salir_vic)

func crear_panel_modal(titulo_texto: String) -> Dictionary:
	var ctrl = Control.new()
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.visible = false
	
	var bg_dim = ColorRect.new()
	bg_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_dim.color = Color(0, 0, 0, 0.75)
	ctrl.add_child(bg_dim)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 520)
	
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.06, 0.08, 0.14, 0.96)
	st.corner_radius_top_left = 16
	st.corner_radius_top_right = 16
	st.corner_radius_bottom_left = 16
	st.corner_radius_bottom_right = 16
	st.border_width_left = 2
	st.border_width_top = 2
	st.border_width_right = 2
	st.border_width_bottom = 2
	st.border_color = Color(0.2, 0.6, 0.9, 0.8)
	st.content_margin_left = 16
	st.content_margin_right = 16
	st.content_margin_top = 16
	st.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", st)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 10)
	
	var title = Label.new()
	title.name = "TituloModal"
	title.text = titulo_texto
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color(0.4, 0.85, 1.0)
	vbox.add_child(title)
	
	panel.add_child(vbox)
	center.add_child(panel)
	
	if hud:
		hud.add_child(ctrl)
	
	return {"control": ctrl, "vbox": vbox, "titulo": title}

func reconstruir_menu_guia() -> void:
	if not box_guia:
		return
		
	# Limpiar elementos dinámicos previos preservando el título en index 0
	for child in box_guia.get_children():
		if child != box_guia.get_child(0):
			child.queue_free()
			
	var scroll_guia = ScrollContainer.new()
	scroll_guia.custom_minimum_size = Vector2(420, 340)
	habilitar_scroll_tactil_suave(scroll_guia)
	var vbox_items = VBoxContainer.new()
	vbox_items.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox_items.add_theme_constant_override("separation", 10)
	
	var leyenda_datos = [
		{"icono": "🎛️", "nombre": DatosNiveles.t("GUIA_BOTONES_TIT"), "desc": DatosNiveles.t("GUIA_BOTONES_DESC")},
		{"icono": "👆", "nombre": DatosNiveles.t("GUIA_CARRILES_TIT"), "desc": DatosNiveles.t("GUIA_CARRILES_DESC")},
		{"icono": "🪙", "nombre": DatosNiveles.t("GUIA_MONEDA_TIT"), "desc": DatosNiveles.t("GUIA_MONEDA_DESC")},
		{"icono": "❤️", "nombre": DatosNiveles.t("GUIA_CORAZON_TIT"), "desc": DatosNiveles.t("GUIA_CORAZON_DESC")},
		{"icono": "🛡️", "nombre": DatosNiveles.t("GUIA_ESCUDO_TIT"), "desc": DatosNiveles.t("GUIA_ESCUDO_DESC")},
		{"icono": "⏳", "nombre": DatosNiveles.t("GUIA_RELOJ_TIT"), "desc": DatosNiveles.t("GUIA_RELOJ_DESC")},
		{"icono": "🚗", "nombre": DatosNiveles.t("GUIA_AUTO_TIT"), "desc": DatosNiveles.t("GUIA_AUTO_DESC")},
		{"icono": "🏍️", "nombre": DatosNiveles.t("GUIA_MOTO_TIT"), "desc": DatosNiveles.t("GUIA_MOTO_DESC")},
		{"icono": "🚚", "nombre": DatosNiveles.t("GUIA_VOLQUETA_TIT"), "desc": DatosNiveles.t("GUIA_VOLQUETA_DESC")},
		{"icono": "🛢️", "nombre": DatosNiveles.t("GUIA_ACEITE_TIT"), "desc": DatosNiveles.t("GUIA_ACEITE_DESC")},
		{"icono": "🚓", "nombre": DatosNiveles.t("GUIA_POLICIA_TIT"), "desc": DatosNiveles.t("GUIA_POLICIA_DESC")},
		{"icono": "🚧", "nombre": DatosNiveles.t("GUIA_BARRICADA_TIT"), "desc": DatosNiveles.t("GUIA_BARRICADA_DESC")}
	]
	
	for elem in leyenda_datos:
		var panel_item = PanelContainer.new()
		var st_i = StyleBoxFlat.new()
		st_i.bg_color = Color(0.12, 0.15, 0.22, 0.9)
		st_i.corner_radius_top_left = 8
		st_i.corner_radius_bottom_right = 8
		st_i.content_margin_left = 8
		st_i.content_margin_right = 8
		st_i.content_margin_top = 8
		st_i.content_margin_bottom = 8
		panel_item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel_item.add_theme_stylebox_override("panel", st_i)
		
		var hb = HBoxContainer.new()
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lbl_ico = Label.new()
		lbl_ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl_ico.text = elem["icono"]
		lbl_ico.add_theme_font_size_override("font_size", 28)
		hb.add_child(lbl_ico)
		
		var vb_txt = VBoxContainer.new()
		vb_txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lbl_nom = Label.new()
		lbl_nom.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl_nom.text = elem["nombre"]
		lbl_nom.add_theme_font_size_override("font_size", 18)
		lbl_nom.modulate = Color(1, 0.9, 0.3)
		vb_txt.add_child(lbl_nom)
		
		var lbl_des = Label.new()
		lbl_des.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl_des.text = elem["desc"]
		lbl_des.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl_des.custom_minimum_size = Vector2(330, 0)
		lbl_des.add_theme_font_size_override("font_size", 14)
		vb_txt.add_child(lbl_des)
		
		hb.add_child(vb_txt)
		panel_item.add_child(hb)
		vbox_items.add_child(panel_item)
		
	scroll_guia.add_child(vbox_items)
	box_guia.add_child(scroll_guia)
	
	btn_cerrar_guia = crear_boton_arcade(DatosNiveles.t("BTN_VOLVER"), Vector2.ZERO, Vector2(380, 70))
	btn_cerrar_guia.pressed.connect(cerrar_modales)
	box_guia.add_child(btn_cerrar_guia)

func crear_selector_idioma_desplegable() -> void:
	if not menu_inicio:
		return

	# 1. Botón Principal (Select cerrado) en la esquina superior izquierda
	boton_desplegable_idioma = PanelContainer.new()
	boton_desplegable_idioma.name = "BotonSelectIdioma"
	boton_desplegable_idioma.set_position(Vector2(26, 26))
	boton_desplegable_idioma.z_index = 85
	
	var st_btn = StyleBoxFlat.new()
	st_btn.bg_color = Color(0.06, 0.10, 0.20, 0.92)
	st_btn.corner_radius_top_left = 12
	st_btn.corner_radius_top_right = 12
	st_btn.corner_radius_bottom_left = 12
	st_btn.corner_radius_bottom_right = 12
	st_btn.border_width_left = 2
	st_btn.border_width_top = 2
	st_btn.border_width_right = 2
	st_btn.border_width_bottom = 2
	st_btn.border_color = Color(0.3, 0.65, 0.95, 0.8)
	st_btn.content_margin_left = 10
	st_btn.content_margin_right = 10
	st_btn.content_margin_top = 6
	st_btn.content_margin_bottom = 6
	boton_desplegable_idioma.add_theme_stylebox_override("panel", st_btn)

	var hbox_btn = HBoxContainer.new()
	hbox_btn.add_theme_constant_override("separation", 8)
	hbox_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	icono_bandera_actual = TextureRect.new()
	icono_bandera_actual.custom_minimum_size = Vector2(36, 24)
	icono_bandera_actual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono_bandera_actual.stretch_mode = TextureRect.STRETCH_SCALE
	icono_bandera_actual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox_btn.add_child(icono_bandera_actual)

	flecha_desplegable_idioma = Label.new()
	flecha_desplegable_idioma.text = "▼"
	flecha_desplegable_idioma.add_theme_font_size_override("font_size", 12)
	flecha_desplegable_idioma.modulate = Color(0.4, 0.85, 1.0)
	flecha_desplegable_idioma.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox_btn.add_child(flecha_desplegable_idioma)

	boton_desplegable_idioma.add_child(hbox_btn)
	boton_desplegable_idioma.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	boton_desplegable_idioma.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			toggle_menu_desplegable_idioma()
	)
	menu_inicio.add_child(boton_desplegable_idioma)

	# 2. Menú Desplegable (Opciones estilo Select HTML)
	panel_desplegable_idioma = PanelContainer.new()
	panel_desplegable_idioma.name = "DesplegableOpcionesIdioma"
	panel_desplegable_idioma.set_position(Vector2(26, 72))
	panel_desplegable_idioma.z_index = 95
	panel_desplegable_idioma.visible = false

	var st_drop = StyleBoxFlat.new()
	st_drop.bg_color = Color(0.04, 0.07, 0.16, 0.97)
	st_drop.corner_radius_top_left = 12
	st_drop.corner_radius_top_right = 12
	st_drop.corner_radius_bottom_left = 12
	st_drop.corner_radius_bottom_right = 12
	st_drop.border_width_left = 2
	st_drop.border_width_top = 2
	st_drop.border_width_right = 2
	st_drop.border_width_bottom = 2
	st_drop.border_color = Color(0.3, 0.65, 0.95, 0.9)
	st_drop.content_margin_left = 8
	st_drop.content_margin_right = 8
	st_drop.content_margin_top = 8
	st_drop.content_margin_bottom = 8
	panel_desplegable_idioma.add_theme_stylebox_override("panel", st_drop)

	var vbox_drop = VBoxContainer.new()
	vbox_drop.add_theme_constant_override("separation", 6)

	# Fila 1: Español (🇪🇸)
	var fila_es = PanelContainer.new()
	var st_fila_es = StyleBoxFlat.new()
	st_fila_es.bg_color = Color(0.12, 0.18, 0.32, 0.65)
	st_fila_es.corner_radius_top_left = 8
	st_fila_es.corner_radius_top_right = 8
	st_fila_es.corner_radius_bottom_left = 8
	st_fila_es.corner_radius_bottom_right = 8
	st_fila_es.content_margin_left = 8
	st_fila_es.content_margin_right = 8
	st_fila_es.content_margin_top = 6
	st_fila_es.content_margin_bottom = 6
	fila_es.add_theme_stylebox_override("panel", st_fila_es)
	fila_es.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var hb_es = HBoxContainer.new()
	hb_es.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb_es.add_theme_constant_override("separation", 8)
	
	var ico_es = TextureRect.new()
	ico_es.texture = load("res://bandera_es.svg")
	ico_es.custom_minimum_size = Vector2(32, 22)
	ico_es.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico_es.stretch_mode = TextureRect.STRETCH_SCALE
	ico_es.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb_es.add_child(ico_es)

	var lbl_es = Label.new()
	lbl_es.text = "Español"
	lbl_es.add_theme_font_size_override("font_size", 14)
	lbl_es.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb_es.add_child(lbl_es)

	check_idioma_es = Label.new()
	check_idioma_es.text = " ✓"
	check_idioma_es.add_theme_font_size_override("font_size", 14)
	check_idioma_es.modulate = Color(0.2, 1.0, 0.4)
	check_idioma_es.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb_es.add_child(check_idioma_es)

	fila_es.add_child(hb_es)
	fila_es.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			seleccionar_idioma_desplegable("es")
	)
	vbox_drop.add_child(fila_es)

	# Fila 2: English (🇺🇸)
	var fila_en = PanelContainer.new()
	var st_fila_en = StyleBoxFlat.new()
	st_fila_en.bg_color = Color(0.12, 0.18, 0.32, 0.65)
	st_fila_en.corner_radius_top_left = 8
	st_fila_en.corner_radius_top_right = 8
	st_fila_en.corner_radius_bottom_left = 8
	st_fila_en.corner_radius_bottom_right = 8
	st_fila_en.content_margin_left = 8
	st_fila_en.content_margin_right = 8
	st_fila_en.content_margin_top = 6
	st_fila_en.content_margin_bottom = 6
	fila_en.add_theme_stylebox_override("panel", st_fila_en)
	fila_en.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var hb_en = HBoxContainer.new()
	hb_en.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb_en.add_theme_constant_override("separation", 8)
	
	var ico_en = TextureRect.new()
	ico_en.texture = load("res://bandera_us.svg")
	ico_en.custom_minimum_size = Vector2(32, 22)
	ico_en.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico_en.stretch_mode = TextureRect.STRETCH_SCALE
	ico_en.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb_en.add_child(ico_en)

	var lbl_en = Label.new()
	lbl_en.text = "English"
	lbl_en.add_theme_font_size_override("font_size", 14)
	lbl_en.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb_en.add_child(lbl_en)

	check_idioma_en = Label.new()
	check_idioma_en.text = " ✓"
	check_idioma_en.add_theme_font_size_override("font_size", 14)
	check_idioma_en.modulate = Color(0.2, 1.0, 0.4)
	check_idioma_en.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb_en.add_child(check_idioma_en)

	fila_en.add_child(hb_en)
	fila_en.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			seleccionar_idioma_desplegable("en")
	)
	vbox_drop.add_child(fila_en)

	panel_desplegable_idioma.add_child(vbox_drop)
	menu_inicio.add_child(panel_desplegable_idioma)
	actualizar_estado_visual_desplegable_idioma()

func toggle_menu_desplegable_idioma() -> void:
	if not panel_desplegable_idioma:
		return
	panel_desplegable_idioma.visible = not panel_desplegable_idioma.visible
	if flecha_desplegable_idioma:
		flecha_desplegable_idioma.text = "▲" if panel_desplegable_idioma.visible else "▼"
	reproducir_sonido_item("res://sonidos/cambioCarril.wav")

func seleccionar_idioma_desplegable(nuevo_idioma: String) -> void:
	if panel_desplegable_idioma:
		panel_desplegable_idioma.visible = false
	if flecha_desplegable_idioma:
		flecha_desplegable_idioma.text = "▼"
	
	if DatosNiveles.idioma != nuevo_idioma:
		DatosNiveles.idioma = nuevo_idioma
		DatosNiveles.guardar_progreso()
		actualizar_idioma_interfaz()
		reproducir_sonido_item("res://sonidos/moneda.wav")
	else:
		reproducir_sonido_item("res://sonidos/cambioCarril.wav")

func actualizar_estado_visual_desplegable_idioma() -> void:
	var es_espanol = (DatosNiveles.idioma == "es")
	if icono_bandera_actual:
		icono_bandera_actual.texture = load("res://bandera_es.svg" if es_espanol else "res://bandera_us.svg")
	if check_idioma_es:
		check_idioma_es.visible = es_espanol
	if check_idioma_en:
		check_idioma_en.visible = not es_espanol

func actualizar_idioma_interfaz() -> void:
	# 1. Menú Inicio
	var lbl_jugar = menu_inicio.get_node_or_null("Label") if menu_inicio else null
	if not lbl_jugar and boton_jugar:
		lbl_jugar = boton_jugar.get_node_or_null("Label")
	if lbl_jugar:
		lbl_jugar.text = DatosNiveles.t("BTN_JUGAR")
	actualizar_texto_boton(boton_menu_garaje, DatosNiveles.t("BTN_GARAJE"))
	actualizar_texto_boton(boton_menu_niveles, DatosNiveles.t("BTN_NIVELES"))
	actualizar_texto_boton(boton_menu_ajustes, DatosNiveles.t("BTN_AJUSTES"))
	actualizar_texto_boton(boton_menu_guia, DatosNiveles.t("BTN_GUIA"))

	# 2. HUD
	actualizar_texto_boton(boton_pausa_hud, DatosNiveles.t("BTN_PAUSA"))
	actualizar_hud()
	if banner_tutorial_carril and banner_tutorial_carril.get_child_count() > 0:
		var lbl_tut = banner_tutorial_carril.get_child(0) as Label
		if lbl_tut:
			lbl_tut.text = DatosNiveles.t("TUTORIAL_CARRILES")

	# 3. Menú de Pausa
	if titulo_pausa:
		titulo_pausa.text = DatosNiveles.t("TITULO_PAUSA")
	if label_pausa_info:
		var texto_nivel = DatosNiveles.t("HUD_INFINITO") if DatosNiveles.nivel_actual == 31 else str(DatosNiveles.nivel_actual)
		label_pausa_info.text = DatosNiveles.t("PAUSA_INFO", [puntos, texto_nivel])
	actualizar_texto_boton(btn_continuar_pausa, DatosNiveles.t("BTN_CONTINUAR"))
	actualizar_texto_boton(btn_ajustes_pausa, DatosNiveles.t("BTN_AJUSTES_PAUSA"))
	actualizar_texto_boton(btn_salir_pausa, DatosNiveles.t("BTN_MENU_PRINCIPAL"))

	# 4. Menú de Ajustes
	if titulo_ajustes:
		titulo_ajustes.text = DatosNiveles.t("TITULO_AJUSTES")
	actualizar_labels_control()
	actualizar_texto_boton(btn_cambiar_control, DatosNiveles.t("BTN_CAMBIAR_CONTROL"))
	actualizar_labels_audio()
	actualizar_texto_boton(btn_cerrar_ajustes, DatosNiveles.t("BTN_VOLVER"))

	# Actualizar selector desplegable de idioma en Menú Inicio
	actualizar_estado_visual_desplegable_idioma()

	# 5. Menú Game Over
	if lbl_reinicio:
		lbl_reinicio.text = DatosNiveles.t("BTN_REINTENTAR")
	actualizar_texto_boton(boton_revivir_ad, DatosNiveles.t("BTN_REVIVIR_AD"))
	actualizar_texto_boton(btn_menu_go, DatosNiveles.t("BTN_MENU_PRINCIPAL"))
	actualizar_texto_boton(btn_menu_trans, DatosNiveles.t("BTN_MENU_PRINCIPAL"))

	# 6. Menú Opciones al Jugar
	if titulo_opciones_jugar:
		titulo_opciones_jugar.text = DatosNiveles.t("TITULO_OPCIONES_JUGAR")
	if label_opciones_jugar_info:
		label_opciones_jugar_info.text = DatosNiveles.t("INFO_CHECKPOINT", [DatosNiveles.nivel_actual, DatosNiveles.nivel_maximo_desbloqueado])
	actualizar_texto_boton(btn_continuar_partida, DatosNiveles.t("BTN_CONTINUAR_NIVEL", [DatosNiveles.nivel_actual]))
	actualizar_texto_boton(btn_nueva_partida, DatosNiveles.t("BTN_NUEVA_PARTIDA"))
	actualizar_texto_boton(btn_cancelar_jugar, DatosNiveles.t("BTN_VOLVER"))

	# 7. Menú Victoria de Campaña
	if titulo_victoria:
		titulo_victoria.text = DatosNiveles.t("TITULO_VICTORIA")
	if lbl_vic_desc:
		lbl_vic_desc.text = DatosNiveles.t("DESC_VICTORIA")
	actualizar_texto_boton(btn_ir_infinito, DatosNiveles.t("BTN_MODO_INFINITO"))
	actualizar_texto_boton(btn_salir_vic, DatosNiveles.t("BTN_MENU_PRINCIPAL"))

	# 8. Modales Dinámicos
	if titulo_guia:
		titulo_guia.text = DatosNiveles.t("TITULO_GUIA")
	if titulo_niveles:
		titulo_niveles.text = DatosNiveles.t("TITULO_NIVELES")
	if titulo_garaje:
		titulo_garaje.text = DatosNiveles.t("TITULO_GARAJE")
	if titulo_transicion:
		titulo_transicion.text = DatosNiveles.t("TITULO_TRANSICION")

	reconstruir_menu_guia()

	if menu_niveles and menu_niveles.visible:
		abrir_menu_niveles()
	if menu_garaje and menu_garaje.visible:
		abrir_menu_garaje()
	if menu_modal_transicion and menu_modal_transicion.visible:
		construir_pantalla_transicion(DatosNiveles.nivel_actual - 1)

func habilitar_scroll_tactil_suave(scroll: ScrollContainer) -> void:
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 4
	
	var arrastre = {"activo": false, "ultimo_y": 0.0}
	
	scroll.gui_input.connect(func(event: InputEvent):
		if event is InputEventScreenTouch:
			if event.is_pressed():
				arrastre["activo"] = true
				arrastre["ultimo_y"] = event.position.y
			else:
				arrastre["activo"] = false
		elif event is InputEventScreenDrag:
			scroll.scroll_vertical -= int(event.relative.y * 1.15)
		elif event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.is_pressed():
					arrastre["activo"] = true
					arrastre["ultimo_y"] = event.position.y
				else:
					arrastre["activo"] = false
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				scroll.scroll_vertical -= 40
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				scroll.scroll_vertical += 40
		elif event is InputEventMouseMotion:
			if arrastre["activo"]:
				scroll.scroll_vertical -= int(event.relative.y * 1.15)
	)

# --- LÓGICA DE CONTROL DE PAUSA ---
func pausar_juego() -> void:
	if not juego_activo or en_transicion:
		return
	juego_pausado = true
	get_tree().paused = true
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	if musica_fondo:
		musica_fondo.stream_paused = true
	if label_pausa_info:
		var texto_nivel = DatosNiveles.t("HUD_INFINITO") if DatosNiveles.nivel_actual == 31 else str(DatosNiveles.nivel_actual)
		label_pausa_info.text = DatosNiveles.t("PAUSA_INFO", [puntos, texto_nivel])
	if menu_pausa:
		menu_pausa.visible = true

func despausar_juego() -> void:
	juego_pausado = false
	get_tree().paused = false
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), DatosNiveles.audio_silenciado)
	if musica_fondo and not DatosNiveles.musica_silenciada and not DatosNiveles.audio_silenciado:
		musica_fondo.stream_paused = false
	cerrar_modales()

func cerrar_modales() -> void:
	if panel_desplegable_idioma:
		panel_desplegable_idioma.visible = false
	if flecha_desplegable_idioma:
		flecha_desplegable_idioma.text = "▼"
	if menu_pausa:
		menu_pausa.visible = false
	if menu_ajustes:
		menu_ajustes.visible = false
	if menu_guia:
		menu_guia.visible = false
	if menu_niveles:
		menu_niveles.visible = false
	if menu_garaje:
		menu_garaje.visible = false
	if menu_modal_transicion:
		menu_modal_transicion.visible = false
	if menu_victoria_campana:
		menu_victoria_campana.visible = false
	if menu_opciones_jugar:
		menu_opciones_jugar.visible = false

func abrir_opciones_jugar() -> void:
	cerrar_modales()
	if label_opciones_jugar_info:
		label_opciones_jugar_info.text = DatosNiveles.t("INFO_CHECKPOINT", [DatosNiveles.nivel_actual, DatosNiveles.nivel_maximo_desbloqueado])
	actualizar_texto_boton(btn_continuar_partida, DatosNiveles.t("BTN_CONTINUAR_NIVEL", [DatosNiveles.nivel_actual]))
	if menu_opciones_jugar:
		menu_opciones_jugar.visible = true

func continuar_partida_guardada() -> void:
	cerrar_modales()
	vidas = 3
	revividas_en_esta_partida = 0
	preparar_nivel()

func empezar_nueva_partida() -> void:
	cerrar_modales()
	vidas = 3
	DatosNiveles.nivel_actual = 1
	revividas_en_esta_partida = 0
	preparar_nivel()

func volver_al_menu_principal() -> void:
	if DatosNiveles.nivel_actual != 31:
		var checkpoint = obtener_nivel_checkpoint(DatosNiveles.nivel_actual)
		DatosNiveles.nivel_actual = checkpoint
		DatosNiveles.guardar_progreso()
	juego_pausado = false
	juego_activo = false
	revividas_en_esta_partida = 0
	get_tree().paused = false
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), DatosNiveles.audio_silenciado)
	if timer:
		timer.stop()
		timer.paused = false
	cerrar_modales()
	
	get_tree().call_group("enemigos", "queue_free")
	get_tree().call_group("items", "queue_free")
	get_tree().call_group("aceite", "queue_free")
	
	if musica_fondo:
		musica_fondo.stop()
		
	if menu_inicio:
		menu_inicio.visible = true
	if banner_tutorial_carril:
		banner_tutorial_carril.visible = false
	if menu_game_over:
		menu_game_over.visible = false
	if menu_transicion:
		menu_transicion.visible = false
	if puntaje_label:
		puntaje_label.visible = false
	if record_label:
		record_label.visible = false
	if contenedor_vidas:
		contenedor_vidas.visible = false
	if boton_pausa_hud:
		boton_pausa_hud.visible = false
	if boton_habilidad_hud:
		boton_habilidad_hud.visible = false
	if label_monedas_hud:
		label_monedas_hud.visible = false
	tiempo_visible_clima = 0.0
	if label_clima_hud:
		label_clima_hud.visible = false
	if overlay_clima and overlay_clima.has_method("cambiar_clima"):
		overlay_clima.cambiar_clima("despejado")

# --- VISTA INFORMATIVA DE PROGRESO DE NIVELES ---
func abrir_menu_niveles() -> void:
	if not box_niveles:
		return
		
	for child in box_niveles.get_children():
		if child != box_niveles.get_child(0):
			child.queue_free()
			
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 340)
	habilitar_scroll_tactil_suave(scroll)
	
	var vbox_cards = VBoxContainer.new()
	vbox_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox_cards.add_theme_constant_override("separation", 8)
	
	for n in range(1, 31):
		var info_nivel = DatosNiveles.NIVELES.get(n, {})
		var desbloqueado = n <= DatosNiveles.nivel_maximo_desbloqueado
		var es_actual = n == DatosNiveles.nivel_maximo_desbloqueado
		
		var card = PanelContainer.new()
		var st_card = StyleBoxFlat.new()
		st_card.corner_radius_top_left = 8
		st_card.corner_radius_top_right = 8
		st_card.corner_radius_bottom_left = 8
		st_card.corner_radius_bottom_right = 8
		st_card.content_margin_left = 10
		st_card.content_margin_right = 10
		st_card.content_margin_top = 8
		st_card.content_margin_bottom = 8
		
		if desbloqueado:
			st_card.bg_color = Color(0.12, 0.22, 0.16, 0.95) if es_actual else Color(0.1, 0.14, 0.2, 0.9)
			st_card.border_width_left = 2
			st_card.border_width_top = 2
			st_card.border_width_right = 2
			st_card.border_width_bottom = 2
			st_card.border_color = Color(0.3, 0.8, 0.4) if es_actual else Color(0.2, 0.4, 0.6)
		else:
			st_card.bg_color = Color(0.08, 0.08, 0.1, 0.6)
			
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_theme_stylebox_override("panel", st_card)
		
		var hb = HBoxContainer.new()
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var lbl_num = Label.new()
		lbl_num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl_num.text = DatosNiveles.t("NIVEL_NUM", [n])
		lbl_num.add_theme_font_size_override("font_size", 16)
		lbl_num.modulate = Color(1.0, 0.9, 0.4) if desbloqueado else Color(0.5, 0.5, 0.5)
		lbl_num.custom_minimum_size = Vector2(90, 0)
		hb.add_child(lbl_num)
		
		var lbl_meta = Label.new()
		lbl_meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var meta = info_nivel.get("meta_puntos", 0)
		lbl_meta.text = DatosNiveles.t("META_PTS", [meta])
		lbl_meta.add_theme_font_size_override("font_size", 15)
		lbl_meta.modulate = Color(0.8, 0.9, 1.0) if desbloqueado else Color(0.4, 0.4, 0.4)
		lbl_meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(lbl_meta)
		
		var lbl_estado = Label.new()
		lbl_estado.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if es_actual:
			lbl_estado.text = DatosNiveles.t("ESTADO_EN_PROGRESO")
			lbl_estado.modulate = Color(0.4, 1.0, 0.4)
		elif desbloqueado:
			lbl_estado.text = DatosNiveles.t("ESTADO_COMPLETADO")
			lbl_estado.modulate = Color(1.0, 0.85, 0.2)
		else:
			lbl_estado.text = DatosNiveles.t("ESTADO_BLOQUEADO")
			lbl_estado.modulate = Color(0.5, 0.5, 0.5)
			
		lbl_estado.add_theme_font_size_override("font_size", 13)
		hb.add_child(lbl_estado)
		
		card.add_child(hb)
		vbox_cards.add_child(card)
		
	scroll.add_child(vbox_cards)
	box_niveles.add_child(scroll)
	
	var btn_volver = crear_boton_arcade(DatosNiveles.t("BTN_VOLVER"), Vector2.ZERO, Vector2(380, 70))
	btn_volver.pressed.connect(cerrar_modales)
	box_niveles.add_child(btn_volver)
	
	if menu_niveles:
		menu_niveles.visible = true

func seleccionar_nivel_y_jugar(num_nivel: int) -> void:
	DatosNiveles.nivel_actual = num_nivel
	cerrar_modales()
	revividas_en_esta_partida = 0
	preparar_nivel()

# --- GARAJE DE VEHÍCULOS Y BILLETERA ---
func abrir_menu_garaje() -> void:
	if not box_garaje:
		return
		
	for child in box_garaje.get_children():
		if child != box_garaje.get_child(0):
			child.queue_free()
			
	# 1. Cabecera de la Billetera (Saldo de Monedas en tiempo real)
	var panel_billetera = PanelContainer.new()
	var st_bill = StyleBoxFlat.new()
	st_bill.bg_color = Color(0.08, 0.12, 0.18, 0.95)
	st_bill.border_width_bottom = 2
	st_bill.border_color = Color(1.0, 0.85, 0.2)
	st_bill.corner_radius_top_left = 8
	st_bill.corner_radius_top_right = 8
	st_bill.corner_radius_bottom_left = 8
	st_bill.corner_radius_bottom_right = 8
	st_bill.content_margin_top = 8
	st_bill.content_margin_bottom = 8
	st_bill.content_margin_left = 12
	st_bill.content_margin_right = 12
	panel_billetera.add_theme_stylebox_override("panel", st_bill)
	
	var hb_bill = HBoxContainer.new()
	hb_bill.alignment = BoxContainer.ALIGNMENT_CENTER
	hb_bill.add_theme_constant_override("separation", 15)
	
	var lbl_saldo = Label.new()
	lbl_saldo.text = DatosNiveles.t("BILLETERA_SALDO", [DatosNiveles.monedas])
	lbl_saldo.add_theme_font_size_override("font_size", 18)
	lbl_saldo.modulate = Color(1.0, 0.9, 0.3)
	hb_bill.add_child(lbl_saldo)
	panel_billetera.add_child(hb_bill)
	box_garaje.add_child(panel_billetera)

	# 2. Botón de Recompensa Voluntaria AdMob (+20 Monedas Gratis) con verificación previa
	var btn_ad_monedas = crear_boton_arcade(DatosNiveles.t("BTN_AD_MONEDAS"), Vector2.ZERO, Vector2(380, 52), 17)
	btn_ad_monedas.pressed.connect(func():
		var ad_mgr = get_node_or_null("/root/AdministradorAnuncios")
		if ad_mgr:
			if ad_mgr.has_method("esta_recompensado_listo") and ad_mgr.esta_recompensado_listo():
				ad_mgr.mostrar_recompensa_monedas(
					func():
						DatosNiveles.agregar_monedas(20)
						reproducir_sonido_item("res://sonidos/moneda.wav")
						abrir_menu_garaje(),
					func():
						abrir_menu_garaje()
				)
			else:
				var lbl_b = btn_ad_monedas.get_node_or_null("Label")
				if lbl_b:
					lbl_b.text = DatosNiveles.t("AD_ESPERE")
				if ad_mgr.has_method("cargar_rewarded"):
					ad_mgr.cargar_rewarded()
				var t = get_tree().create_timer(2.5)
				t.timeout.connect(func():
					if is_instance_valid(btn_ad_monedas):
						var lb = btn_ad_monedas.get_node_or_null("Label")
						if lb:
							lb.text = DatosNiveles.t("BTN_AD_MONEDAS")
				)
	)
	box_garaje.add_child(btn_ad_monedas)
	
	# 3. Lista con Scroll de Autos y Habilidades
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 310)
	habilitar_scroll_tactil_suave(scroll)
	
	var vbox_autos = VBoxContainer.new()
	vbox_autos.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox_autos.add_theme_constant_override("separation", 10)
	
	var lista_claves = [
		"res://jugador.png",
		"res://auto_rojo.svg",
		"res://auto_amarillo.svg",
		"res://auto_policia.svg",
		"res://auto_cyber.svg",
		"res://auto_f1.svg"
	]
	
	for ruta in lista_claves:
		if not ruta in DatosNiveles.AUTOS_INFO:
			continue
		var info = DatosNiveles.AUTOS_INFO[ruta]
		var costo: int = info["costo"]
		var desbloqueado: bool = DatosNiveles.esta_auto_desbloqueado(ruta)
		var es_seleccionado: bool = (DatosNiveles.auto_seleccionado == ruta)
		
		var card = PanelContainer.new()
		var st = StyleBoxFlat.new()
		st.corner_radius_top_left = 10
		st.corner_radius_top_right = 10
		st.corner_radius_bottom_left = 10
		st.corner_radius_bottom_right = 10
		st.content_margin_left = 10
		st.content_margin_right = 10
		st.content_margin_top = 8
		st.content_margin_bottom = 8
		
		if es_seleccionado:
			st.bg_color = Color(0.1, 0.28, 0.4, 0.95)
			st.border_width_left = 2
			st.border_width_top = 2
			st.border_width_right = 2
			st.border_width_bottom = 2
			st.border_color = Color(0.3, 0.9, 1.0)
		elif desbloqueado:
			st.bg_color = Color(0.1, 0.15, 0.22, 0.9)
			st.border_width_left = 1
			st.border_width_top = 1
			st.border_width_right = 1
			st.border_width_bottom = 1
			st.border_color = Color(0.3, 0.55, 0.75)
		else:
			st.bg_color = Color(0.08, 0.09, 0.12, 0.75)
			st.border_width_left = 1
			st.border_width_top = 1
			st.border_width_right = 1
			st.border_width_bottom = 1
			st.border_color = Color(0.35, 0.35, 0.4)
			
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		card.add_theme_stylebox_override("panel", st)
		
		var hb = HBoxContainer.new()
		hb.mouse_filter = Control.MOUSE_FILTER_PASS
		hb.add_theme_constant_override("separation", 10)
		
		if ResourceLoader.exists(ruta):
			var tr = TextureRect.new()
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tr.texture = load(ruta)
			tr.custom_minimum_size = Vector2(50, 83)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hb.add_child(tr)
			
		var vb = VBoxContainer.new()
		vb.mouse_filter = Control.MOUSE_FILTER_PASS
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var lbl_nom = Label.new()
		lbl_nom.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl_nom.text = DatosNiveles.obtener_nombre_auto(ruta)
		lbl_nom.add_theme_font_size_override("font_size", 15)
		lbl_nom.modulate = Color(1.0, 0.9, 0.4) if desbloqueado else Color(0.65, 0.65, 0.65)
		vb.add_child(lbl_nom)
		
		var lbl_desc = Label.new()
		lbl_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl_desc.text = DatosNiveles.obtener_desc_auto(ruta)
		lbl_desc.add_theme_font_size_override("font_size", 12)
		lbl_desc.modulate = Color(0.85, 0.85, 0.85) if desbloqueado else Color(0.6, 0.6, 0.6)
		lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl_desc.custom_minimum_size = Vector2(185, 0)
		vb.add_child(lbl_desc)
		
		hb.add_child(vb)
		
		if es_seleccionado:
			var lbl_sel = Label.new()
			lbl_sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lbl_sel.text = DatosNiveles.t("EQUIPADO")
			lbl_sel.add_theme_font_size_override("font_size", 13)
			lbl_sel.modulate = Color(0.3, 1.0, 0.5)
			hb.add_child(lbl_sel)
		elif desbloqueado:
			var btn_usar = crear_boton_arcade(DatosNiveles.t("BTN_USAR"), Vector2.ZERO, Vector2(85, 42), 16)
			btn_usar.pressed.connect(func(): seleccionar_auto_garaje(ruta))
			hb.add_child(btn_usar)
		else:
			# Auto no comprado: mostrar botón de compra o faltante
			if DatosNiveles.monedas >= costo:
				var btn_comprar = crear_boton_arcade(str(costo) + " 🪙", Vector2.ZERO, Vector2(95, 44), 15)
				btn_comprar.pressed.connect(func():
					if DatosNiveles.comprar_auto(ruta):
						reproducir_sonido_item("res://sonidos/moneda.wav")
						seleccionar_auto_garaje(ruta)
				)
				hb.add_child(btn_comprar)
			else:
				var vb_bloq = VBoxContainer.new()
				vb_bloq.alignment = BoxContainer.ALIGNMENT_CENTER
				var lbl_costo = Label.new()
				lbl_costo.text = str(costo) + " 🪙"
				lbl_costo.add_theme_font_size_override("font_size", 14)
				lbl_costo.modulate = Color(1.0, 0.8, 0.3)
				vb_bloq.add_child(lbl_costo)
				var lbl_falta = Label.new()
				lbl_falta.text = DatosNiveles.t("FALTAN_MONEDAS", [costo - DatosNiveles.monedas])
				lbl_falta.add_theme_font_size_override("font_size", 11)
				lbl_falta.modulate = Color(0.85, 0.4, 0.4)
				vb_bloq.add_child(lbl_falta)
				hb.add_child(vb_bloq)
			
		card.add_child(hb)
		vbox_autos.add_child(card)
		
	scroll.add_child(vbox_autos)
	box_garaje.add_child(scroll)
	
	var btn_volver = crear_boton_arcade(DatosNiveles.t("BTN_VOLVER"), Vector2.ZERO, Vector2(380, 60))
	btn_volver.pressed.connect(func():
		if en_transicion:
			if menu_garaje:
				menu_garaje.visible = false
			construir_pantalla_transicion(DatosNiveles.nivel_actual - 1)
			if menu_modal_transicion:
				menu_modal_transicion.visible = true
		else:
			cerrar_modales()
	)
	box_garaje.add_child(btn_volver)
	
	if menu_garaje:
		menu_garaje.visible = true

func seleccionar_auto_garaje(ruta_auto: String) -> void:
	DatosNiveles.auto_seleccionado = ruta_auto
	DatosNiveles.guardar_progreso()
	if jugador and jugador.has_method("actualizar_textura_auto"):
		jugador.actualizar_textura_auto()
	abrir_menu_garaje()

# --- EVENTOS CLIMÁTICOS ---
func actualizar_clima(num_nivel: int) -> void:
	if not overlay_clima or not label_clima_hud:
		return
		
	if num_nivel in [4, 8, 12, 15, 18, 22, 25]:
		# Lluvia
		label_clima_hud.text = DatosNiveles.t("CLIMA_LLUVIA")
		label_clima_hud.modulate = Color(0.4, 0.75, 1.0)
		if overlay_clima.has_method("cambiar_clima"):
			overlay_clima.cambiar_clima("lluvia" if juego_activo else "despejado")
	elif num_nivel in [6, 11, 16, 20, 24]:
		# Niebla
		label_clima_hud.text = DatosNiveles.t("CLIMA_NIEBLA")
		label_clima_hud.modulate = Color(0.85, 0.85, 0.9)
		if overlay_clima.has_method("cambiar_clima"):
			overlay_clima.cambiar_clima("niebla" if juego_activo else "despejado")
	else:
		# Despejado
		label_clima_hud.text = DatosNiveles.t("CLIMA_DESPEJADO")
		label_clima_hud.modulate = Color(1.0, 0.9, 0.5)
		if overlay_clima.has_method("cambiar_clima"):
			overlay_clima.cambiar_clima("despejado")
	
	label_clima_hud.visible = false

# --- CONTROL DE AUDIO Y OPCIONES ---
func abrir_menu_ajustes() -> void:
	actualizar_labels_audio()
	actualizar_labels_control()
	if menu_ajustes:
		menu_ajustes.visible = true

func toggle_modo_control() -> void:
	if DatosNiveles.modo_control == "botones":
		DatosNiveles.modo_control = "carriles"
	else:
		DatosNiveles.modo_control = "botones"
	DatosNiveles.guardar_progreso()
	if jugador and jugador.has_method("actualizar_modo_control"):
		jugador.actualizar_modo_control()
	actualizar_labels_control()

func actualizar_labels_control() -> void:
	if label_modo_control:
		if DatosNiveles.modo_control == "carriles":
			label_modo_control.text = DatosNiveles.t("MODO_CARRILES")
		else:
			label_modo_control.text = DatosNiveles.t("MODO_BOTONES")
	if label_desc_control:
		if DatosNiveles.modo_control == "carriles":
			label_desc_control.text = DatosNiveles.t("DESC_MODO_CARRILES")
		else:
			label_desc_control.text = DatosNiveles.t("DESC_MODO_BOTONES")

func mostrar_guia_control_carriles() -> void:
	if DatosNiveles.modo_control != "carriles":
		if banner_tutorial_carril:
			banner_tutorial_carril.visible = false
		return

	if not banner_tutorial_carril and hud:
		banner_tutorial_carril = PanelContainer.new()
		banner_tutorial_carril.set_position(Vector2(64, 820))
		banner_tutorial_carril.custom_minimum_size = Vector2(520, 60)
		banner_tutorial_carril.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner_tutorial_carril.z_index = 80
		
		var st = StyleBoxFlat.new()
		st.bg_color = Color(0.06, 0.1, 0.18, 0.9)
		st.corner_radius_top_left = 12
		st.corner_radius_top_right = 12
		st.corner_radius_bottom_left = 12
		st.corner_radius_bottom_right = 12
		st.border_width_left = 2
		st.border_width_top = 2
		st.border_width_right = 2
		st.border_width_bottom = 2
		st.border_color = Color(0.3, 0.8, 1.0, 0.8)
		st.content_margin_left = 12
		st.content_margin_right = 12
		st.content_margin_top = 8
		st.content_margin_bottom = 8
		banner_tutorial_carril.add_theme_stylebox_override("panel", st)
		
		var lbl = Label.new()
		lbl.text = DatosNiveles.t("TUTORIAL_CARRILES")
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.modulate = Color(1.0, 0.95, 0.5)
		banner_tutorial_carril.add_child(lbl)
		hud.add_child(banner_tutorial_carril)

	if banner_tutorial_carril:
		banner_tutorial_carril.modulate.a = 1.0
		banner_tutorial_carril.visible = true
		var tween = create_tween()
		tween.tween_interval(3.0)
		tween.tween_property(banner_tutorial_carril, "modulate:a", 0.0, 0.8)
		tween.tween_callback(func(): banner_tutorial_carril.visible = false)

func abrir_menu_guia() -> void:
	cerrar_modales()
	reconstruir_menu_guia()
	if menu_guia:
		menu_guia.visible = true

func toggle_audio_completo() -> void:
	DatosNiveles.audio_silenciado = not DatosNiveles.audio_silenciado
	DatosNiveles.guardar_progreso()
	aplicar_configuracion_audio()

func toggle_musica_fondo() -> void:
	DatosNiveles.musica_silenciada = not DatosNiveles.musica_silenciada
	DatosNiveles.guardar_progreso()
	aplicar_configuracion_audio()

func aplicar_configuracion_audio() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), DatosNiveles.audio_silenciado)
	if musica_fondo:
		musica_fondo.stream_paused = DatosNiveles.musica_silenciada or DatosNiveles.audio_silenciado
	actualizar_labels_audio()

func actualizar_labels_audio() -> void:
	if label_audio_estado:
		var estado_gen = DatosNiveles.t("ESTADO_SILENCIADO") if DatosNiveles.audio_silenciado else DatosNiveles.t("ESTADO_ACTIVO")
		label_audio_estado.text = DatosNiveles.t("AUDIO_ESTADO", [estado_gen])
	if label_musica_estado:
		var estado_mus = DatosNiveles.t("ESTADO_SILENCIADA") if DatosNiveles.musica_silenciada else DatosNiveles.t("ESTADO_ACTIVA")
		label_musica_estado.text = DatosNiveles.t("MUSICA_ESTADO", [estado_mus])
	if btn_toggle_audio:
		actualizar_texto_boton(btn_toggle_audio, DatosNiveles.t("BTN_ACTIVAR_TODO") if DatosNiveles.audio_silenciado else DatosNiveles.t("BTN_SILENCIAR_TODO"))
	if btn_toggle_musica:
		actualizar_texto_boton(btn_toggle_musica, DatosNiveles.t("BTN_ACTIVAR_MUSICA") if DatosNiveles.musica_silenciada else DatosNiveles.t("BTN_SILENCIAR_MUSICA"))

# --- CICLO PRINCIPAL DE JUEGO ---
func iniciar_juego() -> void:
	vidas = 3
	DatosNiveles.nivel_actual = 1
	revividas_en_esta_partida = 0
	preparar_nivel()

func preparar_nivel() -> void:
	en_transicion = false
	juego_pausado = false
	get_tree().paused = false
	puntos = 0
	ralentizado = false
	tiempo_ralentizado = 0.0
	tiempo_visible_clima = 5.0
	
	var info_nivel = DatosNiveles.NIVELES.get(DatosNiveles.nivel_actual, DatosNiveles.NIVELES[1])
	velocidad_enemigos = info_nivel["velocidad_inicial"]
	velocidad_fondo = 300.0
	
	actualizar_fondo_nivel()
	
	monedas_recolectadas_partida = 0
	if jugador and jugador.has_method("resetear_posicion"):
		jugador.resetear_posicion()
		if not jugador.habilidad_activada.is_connected(_al_habilidad_activada):
			jugador.habilidad_activada.connect(_al_habilidad_activada)
		if not jugador.habilidad_cooldown.is_connected(_al_habilidad_cooldown):
			jugador.habilidad_cooldown.connect(_al_habilidad_cooldown)
		if not jugador.habilidad_lista.is_connected(_al_habilidad_lista):
			jugador.habilidad_lista.connect(_al_habilidad_lista)
		
	if musica_fondo and not musica_fondo.playing and not DatosNiveles.musica_silenciada:
		musica_fondo.play()
	
	juego_activo = true
	actualizar_hud()
	
	if menu_inicio:
		menu_inicio.visible = false
	if menu_game_over:
		menu_game_over.visible = false
	if menu_transicion:
		menu_transicion.visible = false
	cerrar_modales()
	
	corazon_spawneado_en_nivel = false
	spawns_desde_ultima_barricada = 15
	spawns_desde_ultimo_aceite = 15
	spawns_desde_ultimo_fantasma = 15
	tiempo_spawn_base = calcular_tiempo_spawn(puntos)
	if timer:
		timer.wait_time = tiempo_spawn_base
		timer.start()

func reproducir_sonido_item(ruta_audio: String) -> void:
	if audio_item_player and ResourceLoader.exists(ruta_audio) and not DatosNiveles.audio_silenciado:
		audio_item_player.stream = load(ruta_audio)
		audio_item_player.play()

func recolectar_moneda() -> void:
	monedas_recolectadas_partida += 1
	DatosNiveles.agregar_monedas(1)
	actualizar_hud_monedas()

func actualizar_hud_monedas() -> void:
	if label_monedas_hud:
		label_monedas_hud.text = DatosNiveles.t("HUD_MONEDAS", [DatosNiveles.monedas, monedas_recolectadas_partida])
		label_monedas_hud.visible = juego_activo

func configurar_boton_habilidad_hud() -> void:
	if not boton_habilidad_hud:
		return
	var tipo = DatosNiveles.obtener_habilidad_auto(DatosNiveles.auto_seleccionado)
	if tipo == "ninguna" or tipo == "inmune_aceite":
		boton_habilidad_hud.visible = false
		return
		
	boton_habilidad_hud.visible = juego_activo
	var icono = "⚡"
	match tipo:
		"escudo_embestida": icono = "🛡️"
		"disparo": icono = "🎯"
		"iman": icono = "🧲"
		"todas": icono = "👑"
		
	var lbl = boton_habilidad_hud.get_node_or_null("Label")
	if lbl:
		lbl.text = icono
	boton_habilidad_hud.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _al_habilidad_activada(tipo: String, duracion: float) -> void:
	if boton_habilidad_hud:
		var lbl = boton_habilidad_hud.get_node_or_null("Label")
		if lbl:
			lbl.text = DatosNiveles.t("HABILIDAD_ACTIVA")
		boton_habilidad_hud.modulate = Color(1.0, 0.9, 0.2)

func _al_habilidad_cooldown(restante: float, total: float) -> void:
	if boton_habilidad_hud:
		var lbl = boton_habilidad_hud.get_node_or_null("Label")
		if lbl:
			lbl.text = "%.1fs" % restante
		boton_habilidad_hud.modulate = Color(0.6, 0.6, 0.6, 0.7)

func _al_habilidad_lista() -> void:
	if boton_habilidad_hud:
		configurar_boton_habilidad_hud()
		reproducir_sonido_item("res://sonidos/escudo.wav")
		var tw = create_tween()
		tw.tween_property(boton_habilidad_hud, "scale", Vector2(1.15, 1.15), 0.12)
		tw.tween_property(boton_habilidad_hud, "scale", Vector2(1.0, 1.0), 0.12)

func mostrar_texto_flotante(texto: String, pos: Vector2, col: Color = Color.WHITE) -> void:
	var lbl = Label.new()
	lbl.text = texto
	lbl.set_position(pos)
	lbl.modulate = col
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.z_index = 150
	add_child(lbl)
	var tw = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(lbl, "position:y", pos.y - 60.0, 0.7)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.tween_callback(lbl.queue_free)

# --- SISTEMA DE CAPTURAS DE PANTALLA (FOTOS PARA GOOGLE PLAY) ---
func obtener_directorio_capturas() -> String:
	var dir_base = "res://capturas"
	if OS.has_feature("standalone") and not OS.has_feature("editor"):
		dir_base = "user://capturas"
	var dir_global = ProjectSettings.globalize_path(dir_base)
	if not DirAccess.dir_exists_absolute(dir_global):
		DirAccess.make_dir_recursive_absolute(dir_global)
	return dir_base

func tomar_captura(ocultar_pausa: bool = false) -> void:
	# Si se llama desde el menú de pausa, ocultamos temporalmente el modal para capturar la acción limpia
	if ocultar_pausa and menu_pausa and menu_pausa.visible:
		menu_pausa.visible = false
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
	else:
		await RenderingServer.frame_post_draw

	var img = get_viewport().get_texture().get_image()

	if ocultar_pausa and menu_pausa:
		menu_pausa.visible = true

	if not img:
		print("❌ [CAPTURAS] No se pudo obtener la imagen del Viewport.")
		return

	# Asegurar cumplimiento estricto con Google Play (Relación 9:16 y Mínimo 1080x1920 px)
	if img.get_width() != 1080 or img.get_height() != 1920:
		img.resize(1080, 1920, Image.INTERPOLATE_LANCZOS)

	var dir_base = obtener_directorio_capturas()
	var fecha_hora = Time.get_datetime_string_from_system().replace(":", "-")
	var nombre_archivo = "carril_x_" + fecha_hora + ".png"
	var ruta_absoluta = ProjectSettings.globalize_path(dir_base) + "/" + nombre_archivo

	var err = img.save_png(ruta_absoluta)
	if err == OK:
		print("📸 [CAPTURAS] ¡Foto guardada con éxito!: ", ruta_absoluta)
		mostrar_texto_flotante("📸 " + DatosNiveles.t("FOTO_GUARDADA"), Vector2(210, 180), Color(0.2, 1.0, 0.4))
		reproducir_sonido_item("res://sonidos/moneda.wav")

		# Efecto visual de flash blanco sutil de cámara
		if hud:
			var flash = ColorRect.new()
			flash.set_size(get_viewport_rect().size)
			flash.color = Color(1.0, 1.0, 1.0, 0.45)
			flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			flash.z_index = 200
			hud.add_child(flash)
			var tw = create_tween()
			tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(flash, "color:a", 0.0, 0.22)
			tw.tween_callback(flash.queue_free)
	else:
		print("❌ [CAPTURAS] Error al guardar captura: ", err)

func actualizar_hud() -> void:
	actualizar_clima(DatosNiveles.nivel_actual)
	actualizar_hud_monedas()
	configurar_boton_habilidad_hud()
	if boton_pausa_hud:
		boton_pausa_hud.visible = juego_activo
		
	var info_nivel = DatosNiveles.NIVELES.get(DatosNiveles.nivel_actual, DatosNiveles.NIVELES[1])
	var meta = info_nivel.get("meta_puntos", -1)

	if puntaje_label:
		if DatosNiveles.nivel_actual == 31:
			puntaje_label.text = DatosNiveles.t("HUD_PUNTOS") + ": " + str(puntos) + "  |  " + DatosNiveles.t("HUD_NIVEL") + ": " + DatosNiveles.t("HUD_INFINITO")
		else:
			puntaje_label.text = DatosNiveles.t("HUD_PUNTOS") + ": " + str(puntos) + " / " + str(meta) + "  |  " + DatosNiveles.t("HUD_NIVEL") + ": " + str(DatosNiveles.nivel_actual)
		puntaje_label.add_theme_font_size_override("font_size", 20)
		puntaje_label.visible = juego_activo

	if record_label:
		if DatosNiveles.nivel_actual == 31 and juego_activo:
			record_label.text = DatosNiveles.t("HUD_RECORD") + ": " + str(DatosNiveles.record_puntos)
			record_label.visible = true
		else:
			record_label.visible = false
	
	if contenedor_vidas:
		contenedor_vidas.visible = juego_activo
		var lista_corazones = contenedor_vidas.get_children()
		for i in range(lista_corazones.size()):
			lista_corazones[i].visible = i < vidas

func obtener_factor_ralentizacion() -> float:
	return 0.6 if ralentizado else 1.0

func activar_vibracion(duracion: float = 0.2, fuerza: float = 12.0) -> void:
	duracion_vibracion = duracion
	fuerza_vibracion = fuerza

func activar_ralentizacion(duracion: float = 4.5, _factor: float = 0.6) -> void:
	ralentizado = true
	tiempo_ralentizado = duracion
	if timer:
		timer.wait_time = tiempo_spawn_base * 1.6

func restar_vida() -> void:
	if not juego_activo or en_transicion:
		return
		
	activar_vibracion(0.3, 15.0)
	vidas -= 1
	actualizar_hud()
	
	get_tree().call_group("enemigos", "queue_free")
	get_tree().call_group("items", "queue_free")
	get_tree().call_group("aceite", "queue_free")
	
	if vidas <= 0:
		game_over()
	else:
		if jugador and jugador.has_method("resetear_posicion"):
			jugador.resetear_posicion()

func obtener_nivel_checkpoint(num_nivel: int) -> int:
	if num_nivel >= 30:
		return 30
	elif num_nivel >= 25:
		return 25
	elif num_nivel >= 20:
		return 20
	elif num_nivel >= 15:
		return 15
	elif num_nivel >= 10:
		return 10
	elif num_nivel >= 5:
		return 5
	else:
		return 1

func sumar_vida() -> void:
	if vidas < 5:
		vidas += 1
		actualizar_hud()
		reproducir_sonido_item("res://sonidos/corazon.wav")

func game_over() -> void:
	juego_activo = false
	juego_pausado = false
	get_tree().paused = false
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), DatosNiveles.audio_silenciado)
	velocidad_fondo = 0.0
	if timer:
		timer.stop()
	
	if musica_fondo:
		musica_fondo.stop()
		
	get_tree().call_group("enemigos", "queue_free")
	get_tree().call_group("items", "queue_free")
	get_tree().call_group("aceite", "queue_free")
	
	if DatosNiveles.nivel_actual == 31:
		DatosNiveles.actualizar_record(puntos)
		
	if boton_pausa_hud:
		boton_pausa_hud.visible = false
	if boton_habilidad_hud:
		boton_habilidad_hud.visible = false
	if menu_game_over:
		if lbl_reinicio:
			lbl_reinicio.text = DatosNiveles.t("BTN_REINTENTAR")
		actualizar_texto_boton(boton_revivir_ad, DatosNiveles.t("BTN_REVIVIR_AD"))
		actualizar_texto_boton(btn_menu_go, DatosNiveles.t("BTN_MENU_PRINCIPAL"))
		if boton_revivir_ad:
			boton_revivir_ad.visible = (revividas_en_esta_partida < 1)
		menu_game_over.visible = true

func sumar_punto() -> void:
	if not juego_activo or en_transicion:
		return
		
	puntos += 1
	evaluar_progreso_puntos()

func sumar_puntos_extra(cantidad: int) -> void:
	if not juego_activo or en_transicion:
		return
		
	puntos += cantidad
	evaluar_progreso_puntos()

func calcular_tiempo_spawn(pts: int) -> float:
	var info_nivel = DatosNiveles.NIVELES.get(DatosNiveles.nivel_actual, DatosNiveles.NIVELES[1])
	var num_carriles = info_nivel.get("carriles", []).size()
	
	if num_carriles <= 2:
		# Pistas de 2 carriles (Nivel 1 y Nivel 2) - Punto medio ágil y justo:
		if DatosNiveles.nivel_actual == 1:
			# Nivel 1 (Meta 60): 0 pts -> 1.35s | 30 pts -> 1.10s | 60 pts -> 0.90s
			if pts <= 0:
				return 1.35
			elif pts <= 30:
				return 1.35 - (float(pts) / 30.0) * 0.25
			elif pts <= 60:
				return 1.10 - (float(pts - 30) / 30.0) * 0.20
			else:
				return 0.90
		else:
			# Nivel 2 (Meta 65): 0 pts -> 1.25s | 30 pts -> 1.00s | 65 pts -> 0.80s
			if pts <= 0:
				return 1.25
			elif pts <= 30:
				return 1.25 - (float(pts) / 30.0) * 0.25
			elif pts <= 65:
				return 1.00 - (float(pts - 30) / 35.0) * 0.20
			else:
				return 0.80
	else:
		# Pistas de 3 a 6 carriles (Nivel 3 en adelante):
		# Curva deportiva estándar con múltiples carriles abiertos para esquivar
		if pts <= 0:
			return 1.10
		elif pts <= 30:
			# De 1.10s (0 pts) a 0.85s (30 pts)
			return 1.10 - (float(pts) / 30.0) * 0.25
		elif pts <= 60:
			# De 0.85s (30 pts) a 0.60s (60 pts)
			return 0.85 - (float(pts - 30) / 30.0) * 0.25
		elif pts <= 100:
			# De 0.60s (60 pts) a 0.38s (100 pts)
			return 0.60 - (float(pts - 60) / 40.0) * 0.22
		else:
			return 0.38

func evaluar_progreso_puntos() -> void:
	var info_nivel = DatosNiveles.NIVELES.get(DatosNiveles.nivel_actual, DatosNiveles.NIVELES[1])
	
	if DatosNiveles.nivel_actual == 31:
		DatosNiveles.actualizar_record(puntos)
	elif info_nivel["meta_puntos"] > 0 and puntos >= info_nivel["meta_puntos"]:
		paso_siguiente_nivel()
		return

	actualizar_hud()
		
	var limite_velocidad = 1200.0 if DatosNiveles.nivel_actual == 31 else 880.0
	if velocidad_enemigos < limite_velocidad:
		velocidad_enemigos += 6.0
		velocidad_fondo += 4.5
		
	tiempo_spawn_base = calcular_tiempo_spawn(puntos)
	if timer:
		timer.wait_time = tiempo_spawn_base * (1.6 if ralentizado else 1.0)

func paso_siguiente_nivel() -> void:
	en_transicion = true
	if timer:
		timer.stop()
	velocidad_fondo = 0.0
	get_tree().call_group("enemigos", "queue_free")
	get_tree().call_group("items", "queue_free")
	get_tree().call_group("aceite", "queue_free")

	if audio_victoria_player and audio_victoria_player.stream and not DatosNiveles.audio_silenciado:
		audio_victoria_player.play()
	
	# Bono de monedas garantizado por superar cada nivel (+10 monedas a la billetera)
	DatosNiveles.agregar_monedas(10)

	var nivel_superado = DatosNiveles.nivel_actual
	DatosNiveles.nivel_actual += 1
	if DatosNiveles.nivel_actual > DatosNiveles.nivel_maximo_desbloqueado:
		DatosNiveles.nivel_maximo_desbloqueado = DatosNiveles.nivel_actual
	DatosNiveles.guardar_progreso()
	
	if boton_pausa_hud:
		boton_pausa_hud.visible = false
		
	cerrar_modales()
	if has_node("/root/AdministradorAnuncios"):
		AdministradorAnuncios.mostrar_intersticial(Callable(self, "_al_terminar_anuncio_victoria"), true)
	else:
		_al_terminar_anuncio_victoria()

func _al_terminar_anuncio_victoria() -> void:
	var nivel_superado = DatosNiveles.nivel_actual - 1
	if nivel_superado == 30:
		if menu_victoria_campana:
			menu_victoria_campana.visible = true
	else:
		construir_pantalla_transicion(nivel_superado)
		if menu_modal_transicion:
			menu_modal_transicion.visible = true

func construir_pantalla_transicion(nivel_superado: int) -> void:
	if not box_modal_transicion:
		return

	# Limpiar elementos dinámicos previos preservando el título en index 0
	for child in box_modal_transicion.get_children():
		if child != box_modal_transicion.get_child(0):
			child.queue_free()

	var lbl_titulo = box_modal_transicion.get_child(0) as Label
	if lbl_titulo:
		lbl_titulo.text = DatosNiveles.t("NIVEL_SUPERADO", [nivel_superado])
		lbl_titulo.modulate = Color(0.4, 0.85, 1.0)

	var nuevo_auto = DatosNiveles.obtener_siguiente_auto_comprable()

	if not nuevo_auto.is_empty():
		# Presentar tarjeta destacada con mejoras del auto nuevo que ya se puede costear
		var panel_oferta = PanelContainer.new()
		panel_oferta.custom_minimum_size = Vector2(400, 185)

		var st = StyleBoxFlat.new()
		st.bg_color = Color(0.08, 0.12, 0.22, 0.98)
		st.corner_radius_top_left = 14
		st.corner_radius_top_right = 14
		st.corner_radius_bottom_left = 14
		st.corner_radius_bottom_right = 14
		st.border_width_left = 2
		st.border_width_top = 2
		st.border_width_right = 2
		st.border_width_bottom = 2
		st.border_color = Color(1.0, 0.84, 0.0, 0.95)
		st.content_margin_left = 14
		st.content_margin_right = 14
		st.content_margin_top = 10
		st.content_margin_bottom = 10
		panel_oferta.add_theme_stylebox_override("panel", st)

		var vb_oferta = VBoxContainer.new()
		vb_oferta.add_theme_constant_override("separation", 8)

		var lbl_tag = Label.new()
		lbl_tag.text = DatosNiveles.t("TAG_NUEVO_AUTO")
		lbl_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_tag.add_theme_font_size_override("font_size", 18)
		lbl_tag.modulate = Color(1.0, 0.9, 0.2)
		vb_oferta.add_child(lbl_tag)

		var hb = HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)

		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(65, 95)
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var ruta_auto: String = nuevo_auto.get("ruta", "")
		if ResourceLoader.exists(ruta_auto):
			tex_rect.texture = load(ruta_auto)
		hb.add_child(tex_rect)

		var vb_detalles = VBoxContainer.new()
		vb_detalles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb_detalles.add_theme_constant_override("separation", 3)

		var lbl_nombre = Label.new()
		lbl_nombre.text = nuevo_auto.get("nombre", "Auto Deportivo")
		lbl_nombre.add_theme_font_size_override("font_size", 18)
		lbl_nombre.modulate = Color(1.0, 1.0, 1.0)
		vb_detalles.add_child(lbl_nombre)

		var lbl_precio = Label.new()
		lbl_precio.text = DatosNiveles.t("PRECIO_AUTO", [nuevo_auto.get("costo", 0), DatosNiveles.monedas])
		lbl_precio.add_theme_font_size_override("font_size", 15)
		lbl_precio.modulate = Color(0.35, 0.9, 1.0)
		vb_detalles.add_child(lbl_precio)

		var lbl_mejora = Label.new()
		lbl_mejora.text = "⭐ " + nuevo_auto.get("desc", "")
		lbl_mejora.add_theme_font_size_override("font_size", 13)
		lbl_mejora.modulate = Color(0.9, 0.95, 0.75)
		lbl_mejora.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb_detalles.add_child(lbl_mejora)

		hb.add_child(vb_detalles)
		vb_oferta.add_child(hb)
		panel_oferta.add_child(vb_oferta)
		box_modal_transicion.add_child(panel_oferta)

		var btn_garaje = crear_boton_arcade(DatosNiveles.t("BTN_IR_GARAJE"), Vector2.ZERO, Vector2(380, 68), 19)
		btn_garaje.pressed.connect(abrir_menu_garaje)
		box_modal_transicion.add_child(btn_garaje)
	else:
		var lbl_resumen = Label.new()
		lbl_resumen.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_resumen.add_theme_font_size_override("font_size", 17)
		lbl_resumen.modulate = Color(0.9, 1.0, 0.9)
		lbl_resumen.text = DatosNiveles.t("RESUMEN_NIVEL", [nivel_superado, DatosNiveles.monedas])
		box_modal_transicion.add_child(lbl_resumen)

		var btn_garaje_opc = crear_boton_arcade(DatosNiveles.t("BTN_GARAJE"), Vector2.ZERO, Vector2(380, 60), 18)
		btn_garaje_opc.pressed.connect(abrir_menu_garaje)
		box_modal_transicion.add_child(btn_garaje_opc)

	var btn_sig_nivel = crear_boton_arcade(DatosNiveles.t("BTN_SIGUIENTE_NIVEL"), Vector2.ZERO, Vector2(380, 68), 20)
	btn_sig_nivel.pressed.connect(_on_boton_siguiente_nivel_pressed)
	box_modal_transicion.add_child(btn_sig_nivel)

	var btn_menu_trans_modal = crear_boton_arcade(DatosNiveles.t("BTN_MENU_PRINCIPAL"), Vector2.ZERO, Vector2(380, 56), 18)
	btn_menu_trans_modal.pressed.connect(volver_al_menu_principal)
	box_modal_transicion.add_child(btn_menu_trans_modal)

func _on_boton_siguiente_nivel_pressed() -> void:
	cerrar_modales()
	preparar_nivel()

func _on_boton_revivir_ad_pressed() -> void:
	if has_node("/root/AdministradorAnuncios"):
		var exito = AdministradorAnuncios.mostrar_recompensa_revivir(
			Callable(self, "_al_otorgar_recompensa_revivir")
		)
		if not exito:
			print("[AdMob] Anuncio no listo en este momento.")
			if boton_revivir_ad:
				var lbl = boton_revivir_ad.get_node_or_null("Label")
				if lbl:
					lbl.text = DatosNiveles.t("AD_ESPERE")
					lbl.add_theme_font_size_override("font_size", 17)
					get_tree().create_timer(2.5).timeout.connect(func():
						if lbl and is_instance_valid(lbl):
							lbl.text = DatosNiveles.t("BTN_REVIVIR_AD")
							lbl.add_theme_font_size_override("font_size", 20)
					)
	else:
		_al_otorgar_recompensa_revivir()

func _al_otorgar_recompensa_revivir() -> void:
	revividas_en_esta_partida += 1
	if menu_game_over:
		menu_game_over.visible = false
	
	vidas = 2
	juego_activo = true
	juego_pausado = false
	en_transicion = false
	get_tree().paused = false
	
	# Restaurar velocidad dinámica del nivel y tráfico acumulado
	var info_nivel = DatosNiveles.NIVELES.get(DatosNiveles.nivel_actual, DatosNiveles.NIVELES[1])
	velocidad_fondo = 300.0 + min(puntos * 4.5, 350.0)
	velocidad_enemigos = info_nivel.get("velocidad_inicial", 400.0) + min(puntos * 6.0, 450.0)
	tiempo_spawn_base = calcular_tiempo_spawn(puntos)
	
	actualizar_hud()
	
	if boton_pausa_hud:
		boton_pausa_hud.visible = true
	if timer:
		timer.wait_time = tiempo_spawn_base * (1.6 if ralentizado else 1.0)
		timer.start()
		
	# Aplicar audio respetando estrictamente si el usuario tenía la música silenciada
	aplicar_configuracion_audio()
	if musica_fondo:
		if not DatosNiveles.musica_silenciada and not DatosNiveles.audio_silenciado:
			if not musica_fondo.playing:
				musica_fondo.play()
			else:
				musica_fondo.stream_paused = false
		else:
			musica_fondo.stop()
			musica_fondo.stream_paused = true
		
	if jugador:
		jugador.resetear_posicion()
		if jugador.has_method("activar_escudo"):
			jugador.activar_escudo(3.5) # Otorgar 3.5 segundos de escudo protector al revivir

func _on_timer_timeout() -> void:
	if not juego_activo or en_transicion or juego_pausado:
		return
		
	var info_nivel = DatosNiveles.NIVELES.get(DatosNiveles.nivel_actual, DatosNiveles.NIVELES[1])
	var indices_permitidos: Array = info_nivel["enemigos"]
	
	if indices_permitidos.is_empty():
		return

	var carriles = obtener_carriles()
	var carril_azar: int = randi() % carriles.size()

	# En pistas de 2 carriles (Nivel 1 y 2), evitar únicamente el solapamiento simultáneo:
	# Si en el otro carril ya hay un obstáculo saliendo en la parte superior (y < 240 px),
	# alinear en el mismo carril para no generar una pared pegada.
	if carriles.size() <= 2:
		var otro_carril = 1 - carril_azar
		var x_otro_carril = carriles[otro_carril]
		var obstaculos = get_tree().get_nodes_in_group("enemigos") + get_tree().get_nodes_in_group("aceite")
		for obs in obstaculos:
			if is_instance_valid(obs) and abs(obs.position.x - x_otro_carril) < 40.0:
				if obs.position.y > -150.0 and obs.position.y < 240.0:
					carril_azar = otro_carril
					break

	var meta_puntos_actual: int = info_nivel.get("meta_puntos", 0)
	var mitad_cumplida: bool = (meta_puntos_actual > 0 and puntos >= (meta_puntos_actual / 2)) or (meta_puntos_actual <= 0 and puntos >= 25)
	# En los Niveles 1 y 2 no se envían vidas adicionales (corazones)
	var permite_corazon_en_nivel: bool = DatosNiveles.nivel_actual > 2
	var debe_spawnear_corazon_garantizado: bool = permite_corazon_en_nivel and not corazon_spawneado_en_nivel and vidas < 5 and mitad_cumplida

	# Si se alcanzó el 50% de la meta, GARANTIZAR el spawn del corazón de inmediato
	if debe_spawnear_corazon_garantizado:
		corazon_spawneado_en_nivel = true
		var nuevo_corazon = escena_corazon.instantiate()
		nuevo_corazon.position = Vector2(carriles[carril_azar], -100.0)
		if "velocidad" in nuevo_corazon:
			nuevo_corazon.velocidad = velocidad_fondo
		add_child(nuevo_corazon)
		return

	# Probabilidad de aparición de ítems (24%) con prioridad balanceada a monedas
	var es_item = randf() < 0.24 and not items_scenes.is_empty()

	if es_item:
		var r_item = randf()
		var item_escena: PackedScene
		if r_item < 0.65:
			item_escena = items_scenes[0] # Moneda (65% de probabilidad)
		elif r_item < 0.82:
			item_escena = items_scenes[1] # Escudo (17%)
		else:
			item_escena = items_scenes[2] # Reloj (18%)

		var nuevo_item = item_escena.instantiate()
		nuevo_item.position = Vector2(carriles[carril_azar], -100.0)
		if "velocidad" in nuevo_item:
			nuevo_item.velocidad = velocidad_fondo
		add_child(nuevo_item)
	else:
		var indice_azar: int = indices_permitidos.pick_random()

		# Control de formación del Auto Fantasma / Espejismos (índice 6)
		if indice_azar == 6:
			# Solo permitir si han pasado al menos 12 obstáculos y con 35% de probabilidad
			if spawns_desde_ultimo_fantasma >= 12 and randf() < 0.35:
				spawns_desde_ultimo_fantasma = 0
				spawnear_formacion_fantasma(carriles)
				return
			else:
				var alternativos_fantasma = []
				for idx in indices_permitidos:
					if idx != 6 and idx != 5 and idx != 3:
						alternativos_fantasma.append(idx)
				indice_azar = alternativos_fantasma.pick_random() if not alternativos_fantasma.is_empty() else 0
				spawns_desde_ultimo_fantasma += 1
		else:
			spawns_desde_ultimo_fantasma += 1

		# Control de rareza sorpresa para la Barricada de Obras (índice 5)
		if indice_azar == 5:
			# Solo permitir si han pasado al menos 14 vehículos normales y con baja probabilidad (20%)
			if spawns_desde_ultima_barricada >= 14 and randf() < 0.20:
				spawns_desde_ultima_barricada = 0
			else:
				var alternativos = []
				for idx in indices_permitidos:
					if idx != 5 and idx != 3 and idx != 6:
						alternativos.append(idx)
				indice_azar = alternativos.pick_random() if not alternativos.is_empty() else 0
				spawns_desde_ultima_barricada += 1

		# Control de frecuencia del Aceite (índice 3)
		if DatosNiveles.nivel_actual in [8, 9, 10]:
			# NIVELES 8, 9 Y 10: OLEADA CRÍTICA DE ACEITE MULTI-CARRIL (Incentivo clave Deportivo Rojo)
			# Aparece frecuentemente (cada 1 o 2 obstáculos con 75% de probabilidad) cubriendo múltiples carriles a la vez
			if spawns_desde_ultimo_aceite >= 1 and randf() < 0.75:
				spawns_desde_ultimo_aceite = 0
				spawnear_oleada_aceite(carriles)
				return
			elif indice_azar == 3:
				spawns_desde_ultimo_aceite = 0
				spawnear_oleada_aceite(carriles)
				return
			else:
				spawns_desde_ultimo_aceite += 1
		elif indice_azar == 3:
			# En otros niveles con aceite: exigir al menos 3 vehículos limpios y 35% de probabilidad
			var min_spawns_aceite = 3
			var prob_aceite = 0.35
			if spawns_desde_ultimo_aceite >= min_spawns_aceite and randf() < prob_aceite:
				spawns_desde_ultimo_aceite = 0
			else:
				var alternativos_aceite = []
				for idx in indices_permitidos:
					if idx != 3 and idx != 5 and idx != 6:
						alternativos_aceite.append(idx)
				indice_azar = alternativos_aceite.pick_random() if not alternativos_aceite.is_empty() else 0
				spawns_desde_ultimo_aceite += 1
		else:
			spawns_desde_ultimo_aceite += 1

		if indice_azar != 5 and indice_azar != 6:
			spawns_desde_ultima_barricada += 1

		var escena_elegida: PackedScene = enemigos_scenes[indice_azar]
		var nuevo_enemigo = escena_elegida.instantiate()
			
		if "velocidad" in nuevo_enemigo:
			nuevo_enemigo.velocidad = velocidad_enemigos
			
		nuevo_enemigo.position = Vector2(carriles[carril_azar], -100.0)
		add_child(nuevo_enemigo)

func spawnear_formacion_fantasma(carriles: Array) -> void:
	if carriles.is_empty() or enemigos_scenes.size() <= 6:
		return
	var escena_fantasma = enemigos_scenes[6]
	var carril_solido = randi() % carriles.size()
	
	for i in range(carriles.size()):
		var nuevo_fantasma = escena_fantasma.instantiate()
		if "velocidad" in nuevo_fantasma:
			nuevo_fantasma.velocidad = velocidad_enemigos
		if "es_espejismo" in nuevo_fantasma:
			nuevo_fantasma.es_espejismo = (i != carril_solido)
		nuevo_fantasma.position = Vector2(carriles[i], -100.0)
		add_child(nuevo_fantasma)

func spawnear_oleada_aceite(carriles: Array) -> void:
	if carriles.is_empty() or enemigos_scenes.size() <= 3:
		return
	var escena_aceite = enemigos_scenes[3]
	var indices_carriles = range(carriles.size())
	indices_carriles.shuffle()
	
	# Cubrir 2 carriles simultáneos (igual que en Nivel 8), dejando 2 carriles transitables para maniobrar
	var cantidad_charcos = 2
	cantidad_charcos = mini(cantidad_charcos, carriles.size() - 1)
	
	for i in range(cantidad_charcos):
		var idx_carril = indices_carriles[i]
		var nuevo_aceite = escena_aceite.instantiate()
		if "velocidad" in nuevo_aceite:
			nuevo_aceite.velocidad = velocidad_fondo
		var offset_y = randf_range(-130.0, -90.0)
		nuevo_aceite.position = Vector2(carriles[idx_carril], offset_y)
		add_child(nuevo_aceite)
		
	# En el carril restante o limpio, lanzar con alta probabilidad un vehículo rival
	# Esto crea la trampa mortal: ¡o te metes al charco de aceite o chocas con el vehículo!
	if randf() < 0.65 and indices_carriles.size() > cantidad_charcos:
		var carril_vehiculo = indices_carriles[cantidad_charcos]
		var idx_enemigo = [0, 1, 2].pick_random()
		var escena_rival = enemigos_scenes[idx_enemigo]
		var rival = escena_rival.instantiate()
		if "velocidad" in rival:
			rival.velocidad = velocidad_enemigos
		rival.position = Vector2(carriles[carril_vehiculo], -140.0)
		add_child(rival)

func _on_boton_jugar_pressed() -> void:
	if has_node("/root/AdministradorAnuncios") and AdministradorAnuncios._anuncio_en_pantalla:
		return
	if DatosNiveles.nivel_actual > 1 or DatosNiveles.nivel_maximo_desbloqueado > 1:
		abrir_opciones_jugar()
	else:
		empezar_nueva_partida()

func _on_boton_reiniciar_pressed() -> void:
	cerrar_modales()
	if menu_game_over:
		menu_game_over.visible = false
	if DatosNiveles.nivel_actual != 31:
		var checkpoint = obtener_nivel_checkpoint(DatosNiveles.nivel_actual)
		DatosNiveles.nivel_actual = checkpoint
		DatosNiveles.guardar_progreso()
	vidas = 3
	revividas_en_esta_partida = 0
	preparar_nivel()
