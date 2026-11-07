extends Node

## AdministradorAnuncios - Gestor Centralizado de Publicidad AdMob
## Controla la inicialización de Google Mobile Ads (Poing Studios Plugin),
## la carga en segundo plano, la pausa del juego mientras se muestra el anuncio nativo,
## y la reanudación segura SOLO tras cerrar el anuncio oficial de Google.

signal intersticial_cerrado()
signal recompensa_obtenida(recompensa: String, cantidad: int)
signal anuncio_fallido(tipo: String, error: String)

# ==============================================================================
# IDENTIFICADORES DE UNIDADES DE ANUNCIO DE PRUEBA (TEST IDs)
# ==============================================================================
# IDs Oficiales de Prueba de Google AdMob para Android:
const ID_APP_OPEN_TEST     := "ca-app-pub-3940256099942544/9257395921"
const ID_INTERSTITIAL_TEST := "ca-app-pub-3940256099942544/1033173712"
const ID_REWARDED_TEST     := "ca-app-pub-3940256099942544/5224354917"

# IDs Oficiales de Prueba de Google AdMob para iOS:
const ID_APP_OPEN_IOS_TEST     := "ca-app-pub-3940256099942544/5575463023"
const ID_INTERSTITIAL_IOS_TEST := "ca-app-pub-3940256099942544/4411468910"
const ID_REWARDED_IOS_TEST     := "ca-app-pub-3940256099942544/1712485313"

# ==============================================================================
# CONFIGURACIÓN DE PRODUCCIÓN DE GOOGLE ADMOB
# ==============================================================================
# App ID oficial de AdMob (con tilde ~)
@export var app_id_admob: String = "ca-app-pub-9480054276272697~2618913069"

# IDs de Bloques de Anuncios de Producción (con barra /):
@export var id_app_open_produccion: String = "ca-app-pub-9480054276272697/3799171366"
@export var id_interstitial_produccion: String = "ca-app-pub-9480054276272697/8964654552"
@export var id_rewarded_produccion: String = "ca-app-pub-9480054276272697/2315485723"
@export var usar_anuncios_de_prueba: bool = false
@export var mostrar_app_open_en_editor: bool = false

# ==============================================================================
# CONFIGURACIÓN Y ESTADO
# ==============================================================================
@export var tiempo_minimo_entre_intersticiales: float = 40.0
@export var tiempo_minimo_entre_app_open: float = 60.0
var _ultimo_tiempo_intersticial: float = -999.0
var _ultimo_tiempo_app_open: float = -999.0

# Referencias internas de AdMob
var _app_open_ad: AppOpenAd = null
var _interstitial_ad: InterstitialAd = null
var _rewarded_ad: RewardedAd = null
var _reward_listener: OnUserEarnedRewardListener = null

var _cargando_app_open: bool = false
var _cargando_intersticial: bool = false
var _cargando_rewarded: bool = false
var _app_open_load_time: int = 0

# Callbacks diferidos
var _callback_intersticial_fin: Callable = Callable()
var _callback_recompensa_activa: Callable = Callable()
var _callback_cerrado_activo: Callable = Callable()
var _recompensa_ganada_pendiente: bool = false

# Control de ciclo de vida
var _anuncio_inicio_mostrado: bool = false
var _esperando_anuncio_inicio: bool = false
var _anuncio_en_pantalla: bool = false
var _inicializado: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_verificar_e_inicializar_admob()


func _notification(what: int) -> void:
	# Manejar reanudación de la app para App Open Ad según políticas de Google
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_intentar_mostrar_app_open_al_reanudar()


func _verificar_e_inicializar_admob() -> void:
	var os_name := OS.get_name()
	print("[AdMob] Iniciando AdMob en: %s" % os_name)
	
	var on_init_listener := OnInitializationCompleteListener.new()
	on_init_listener.on_initialization_complete = _al_completar_inicializacion
	
	var request_config := RequestConfiguration.new()
	request_config.tag_for_child_directed_treatment = RequestConfiguration.TagForChildDirectedTreatment.FALSE
	request_config.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_G
	
	MobileAds.set_request_configuration(request_config)
	MobileAds.initialize(on_init_listener)


func _al_completar_inicializacion(_status: InitializationStatus) -> void:
	_inicializado = true
	print("[AdMob] Inicialización completada con éxito. Precargando anuncios (App Open, Intersticial, Recompensado)...")
	cargar_app_open()
	cargar_intersticial()
	cargar_rewarded()


# ==============================================================================
# GESTIÓN DE PAUSA Y AUDIO MIENTRAS SE MUESTRA UN ANUNCIO NATIVO
# ==============================================================================
var _estaba_pausado_antes_del_anuncio: bool = false

func _pausar_para_anuncio() -> void:
	_anuncio_en_pantalla = true
	_estaba_pausado_antes_del_anuncio = get_tree().paused
	get_tree().paused = true
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)


func _reanudar_tras_anuncio() -> void:
	_anuncio_en_pantalla = false
	if not _estaba_pausado_antes_del_anuncio:
		get_tree().paused = false
	if DatosNiveles:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), DatosNiveles.audio_silenciado)
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


# ==============================================================================
# VALIDACIÓN DE POLÍTICAS DE GOOGLE ADMOB
# ==============================================================================
func _puede_mostrar_app_open() -> bool:
	# Política de Google: NO mostrar anuncios de apertura sobre gameplay activo
	var mundo = get_tree().current_scene
	if mundo:
		if "juego_activo" in mundo and mundo.juego_activo:
			if "juego_pausado" in mundo and not mundo.juego_pausado:
				return false
	return true


# ==============================================================================
# ANUNCIOS DE CARGA DE APLICACIÓN (APP OPEN ADS)
# ==============================================================================
func _obtener_id_app_open() -> String:
	if not usar_anuncios_de_prueba and id_app_open_produccion != "":
		return id_app_open_produccion
	return ID_APP_OPEN_TEST if OS.get_name() == "Android" else ID_APP_OPEN_IOS_TEST


func cargar_app_open() -> void:
	if _app_open_ad != null or _cargando_app_open:
		return
		
	_cargando_app_open = true
	var unit_id := _obtener_id_app_open()
	print("[AdMob] Solicitando carga de App Open Ad con ID: ", unit_id)
	
	var load_callback := AppOpenAdLoadCallback.new()
	load_callback.on_ad_loaded = func(ad: AppOpenAd) -> void:
		_app_open_ad = ad
		_cargando_app_open = false
		_app_open_load_time = int(Time.get_unix_time_from_system())
		print("[AdMob] App Open Ad cargado exitosamente en memoria.")
		
		var content_callback := FullScreenContentCallback.new()
		content_callback.on_ad_showed_full_screen_content = func() -> void:
			print("[AdMob] App Open Ad en pantalla. Pausando juego y silenciando audio.")
			_pausar_para_anuncio()
			
		content_callback.on_ad_dismissed_full_screen_content = func() -> void:
			print("[AdMob] App Open Ad cerrado por el usuario. Reanudando juego...")
			_reanudar_tras_anuncio()
			_destruir_app_open()
			cargar_app_open()
			
		content_callback.on_ad_failed_to_show_full_screen_content = func(err: AdError) -> void:
			print("[AdMob] Error al mostrar App Open Ad: ", err.message)
			_reanudar_tras_anuncio()
			_destruir_app_open()
			cargar_app_open()
			
		_app_open_ad.full_screen_content_callback = content_callback
		
		# Si se estaba esperando para la apertura inicial de la app:
		if _esperando_anuncio_inicio and not _anuncio_inicio_mostrado:
			_esperando_anuncio_inicio = false
			if _puede_mostrar_app_open():
				_anuncio_inicio_mostrado = true
				mostrar_app_open()
		
	load_callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		print("[AdMob] Falló la carga de App Open Ad: ", error.message)
		_cargando_app_open = false
		anuncio_fallido.emit("app_open", error.message)

	AppOpenAdLoader.new().load(unit_id, AdRequest.new(), load_callback)


func solicitar_anuncio_apertura_app() -> void:
	if _anuncio_inicio_mostrado:
		return
		
	# En el editor de Godot o en escritorio (Windows/Mac/Linux), omitir el App Open Ad inicial
	# para permitir al desarrollador probar el juego de inmediato sin interrupciones.
	# En dispositivos móviles reales (Android / iOS) se ejecutará normalmente.
	if not mostrar_app_open_en_editor and (OS.has_feature("editor") or (OS.get_name() != "Android" and OS.get_name() != "iOS")):
		print("[AdMob] Omitiendo App Open Ad de inicio en entorno de editor/PC.")
		_anuncio_inicio_mostrado = true
		return
		
	if _app_open_ad != null and not _es_app_open_expirado():
		_anuncio_inicio_mostrado = true
		mostrar_app_open()
	else:
		_esperando_anuncio_inicio = true
		if not _cargando_app_open:
			cargar_app_open()


func _intentar_mostrar_app_open_al_reanudar() -> void:
	if not _inicializado or _anuncio_en_pantalla:
		return
	if not mostrar_app_open_en_editor and (OS.has_feature("editor") or (OS.get_name() != "Android" and OS.get_name() != "iOS")):
		return
	var tiempo_actual = Time.get_ticks_msec() / 1000.0
	if (tiempo_actual - _ultimo_tiempo_app_open) < tiempo_minimo_entre_app_open:
		return
	if not _puede_mostrar_app_open():
		return
	if _app_open_ad != null and not _es_app_open_expirado():
		mostrar_app_open()


func mostrar_app_open() -> bool:
	if _app_open_ad != null:
		if _es_app_open_expirado():
			print("[AdMob] App Open Ad expirado (>4 horas). Destruyendo y recargando...")
			_destruir_app_open()
			cargar_app_open()
			return false
			
		var tiempo_actual = Time.get_ticks_msec() / 1000.0
		_ultimo_tiempo_app_open = tiempo_actual
		print("[AdMob] Mostrando App Open Ad oficial de Google AdMob...")
		_app_open_ad.show()
		return true
	else:
		print("[AdMob] App Open Ad no estaba listo en memoria. Solicitando carga...")
		cargar_app_open()
		return false


func _es_app_open_expirado() -> bool:
	if _app_open_load_time == 0:
		return true
	var ahora := int(Time.get_unix_time_from_system())
	return (ahora - _app_open_load_time) >= (4 * 3600)


func _destruir_app_open() -> void:
	if _app_open_ad:
		_app_open_ad.destroy()
		_app_open_ad = null
		_app_open_load_time = 0


# ==============================================================================
# GESTIÓN DE ANUNCIOS INTERSTICIALES (PANTALLA COMPLETA NATIVA)
# ==============================================================================
func _obtener_id_intersticial() -> String:
	if not usar_anuncios_de_prueba and id_interstitial_produccion != "":
		return id_interstitial_produccion
	return ID_INTERSTITIAL_TEST if OS.get_name() == "Android" else ID_INTERSTITIAL_IOS_TEST


func cargar_intersticial() -> void:
	if _interstitial_ad != null or _cargando_intersticial:
		return
		
	_cargando_intersticial = true
	var unit_id := _obtener_id_intersticial()
	
	var load_callback := InterstitialAdLoadCallback.new()
	load_callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial_ad = ad
		_cargando_intersticial = false
		print("[AdMob] Intersticial cargado con éxito en memoria.")
		
		var content_callback := FullScreenContentCallback.new()
		content_callback.on_ad_showed_full_screen_content = func() -> void:
			print("[AdMob] Intersticial en pantalla. Pausando juego.")
			_pausar_para_anuncio()
			
		content_callback.on_ad_dismissed_full_screen_content = func() -> void:
			print("[AdMob] Intersticial cerrado. Reanudando juego...")
			_reanudar_tras_anuncio()
			_destruir_intersticial()
			intersticial_cerrado.emit()
			
			if _callback_intersticial_fin.is_valid():
				var cb = _callback_intersticial_fin
				_callback_intersticial_fin = Callable()
				cb.call()
				
			cargar_intersticial()
			
		content_callback.on_ad_failed_to_show_full_screen_content = func(err: AdError) -> void:
			print("[AdMob] Error al mostrar intersticial: ", err.message)
			_reanudar_tras_anuncio()
			_destruir_intersticial()
			anuncio_fallido.emit("interstitial", err.message)
			
			if _callback_intersticial_fin.is_valid():
				var cb = _callback_intersticial_fin
				_callback_intersticial_fin = Callable()
				cb.call()
				
			cargar_intersticial()
			
		_interstitial_ad.full_screen_content_callback = content_callback
		
	load_callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		print("[AdMob] Falló la carga del intersticial: ", error.message)
		_cargando_intersticial = false
		anuncio_fallido.emit("interstitial", error.message)

	InterstitialAdLoader.new().load(unit_id, AdRequest.new(), load_callback)


func mostrar_intersticial(on_terminado: Callable = Callable(), forzar: bool = false) -> bool:
	_callback_intersticial_fin = on_terminado
	var tiempo_actual = Time.get_ticks_msec() / 1000.0
	
	if not forzar and (tiempo_actual - _ultimo_tiempo_intersticial) < tiempo_minimo_entre_intersticiales:
		print("[AdMob] Intersticial omitido por cooldown.")
		if _callback_intersticial_fin.is_valid():
			var cb = _callback_intersticial_fin
			_callback_intersticial_fin = Callable()
			cb.call()
		return false
		
	if _interstitial_ad != null:
		print("[AdMob] Mostrando Intersticial oficial de Google AdMob...")
		_ultimo_tiempo_intersticial = tiempo_actual
		_interstitial_ad.show()
		return true
	else:
		# Regla de oro AdMob: NUNCA congelar la pantalla del jugador esperando la red
		print("[AdMob] No hay Intersticial listo en este momento. Continuando flujo normal y precargando...")
		cargar_intersticial()
		if _callback_intersticial_fin.is_valid():
			var cb = _callback_intersticial_fin
			_callback_intersticial_fin = Callable()
			cb.call()
		return false


func _destruir_intersticial() -> void:
	if _interstitial_ad:
		_interstitial_ad.destroy()
		_interstitial_ad = null


# ==============================================================================
# GESTIÓN DE ANUNCIOS RECOMPENSADOS (VER ANUNCIO PARA CONTINUAR)
# ==============================================================================
func _obtener_id_rewarded() -> String:
	if not usar_anuncios_de_prueba and id_rewarded_produccion != "":
		return id_rewarded_produccion
	return ID_REWARDED_TEST if OS.get_name() == "Android" else ID_REWARDED_IOS_TEST


func cargar_rewarded() -> void:
	if _rewarded_ad != null or _cargando_rewarded:
		return
		
	_cargando_rewarded = true
	var unit_id := _obtener_id_rewarded()
	
	var load_callback := RewardedAdLoadCallback.new()
	load_callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded_ad = ad
		_cargando_rewarded = false
		print("[AdMob] Anuncio Recompensado cargado y listo en memoria.")
		
		var content_callback := FullScreenContentCallback.new()
		content_callback.on_ad_showed_full_screen_content = func() -> void:
			print("[AdMob] Anuncio recompensado en pantalla. Pausando juego y silenciando audio.")
			_pausar_para_anuncio()
			
		content_callback.on_ad_dismissed_full_screen_content = func() -> void:
			print("[AdMob] Anuncio recompensado cerrado.")
			_reanudar_tras_anuncio()
			
			if _recompensa_ganada_pendiente:
				_recompensa_ganada_pendiente = false
				print("[AdMob] Recompensa confirmada. Continuando partida...")
				if _callback_recompensa_activa.is_valid():
					var cb_rec = _callback_recompensa_activa
					_callback_recompensa_activa = Callable()
					cb_rec.call()
			else:
				print("[AdMob] El jugador cerró el anuncio sin completar la visualización.")
				if _callback_cerrado_activo.is_valid():
					var cb_close = _callback_cerrado_activo
					_callback_cerrado_activo = Callable()
					cb_close.call()
					
			_destruir_rewarded()
			_reward_listener = null
			cargar_rewarded()
			
		content_callback.on_ad_failed_to_show_full_screen_content = func(err: AdError) -> void:
			print("[AdMob] Error al mostrar recompensado: ", err.message)
			_reanudar_tras_anuncio()
			_destruir_rewarded()
			_reward_listener = null
			anuncio_fallido.emit("rewarded", err.message)
			_recompensa_ganada_pendiente = false
			if _callback_cerrado_activo.is_valid():
				var cb_close = _callback_cerrado_activo
				_callback_cerrado_activo = Callable()
				cb_close.call()
			cargar_rewarded()
			
		_rewarded_ad.full_screen_content_callback = content_callback
		
	load_callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		print("[AdMob] Falló la carga del recompensado: ", error.message)
		_cargando_rewarded = false
		anuncio_fallido.emit("rewarded", error.message)

	RewardedAdLoader.new().load(unit_id, AdRequest.new(), load_callback)


func esta_recompensado_listo() -> bool:
	return _rewarded_ad != null


func mostrar_recompensa_monedas(on_recompensa_ganada: Callable, on_cerrado: Callable = Callable()) -> bool:
	return mostrar_recompensa_revivir(on_recompensa_ganada, on_cerrado)


func mostrar_recompensa_revivir(on_recompensa_ganada: Callable, on_cerrado: Callable = Callable()) -> bool:
	_callback_recompensa_activa = on_recompensa_ganada
	_callback_cerrado_activo = on_cerrado
	_recompensa_ganada_pendiente = false
	
	if _rewarded_ad != null:
		# Retener el listener como variable de instancia para evitar que sea liberado por el Garbage Collector
		_reward_listener = OnUserEarnedRewardListener.new()
		_reward_listener.on_user_earned_reward = func(item: RewardedItem) -> void:
			print("[AdMob] ¡Recompensa acreditada por Google AdMob! (%d %s)" % [item.amount, item.type])
			_recompensa_ganada_pendiente = true
			recompensa_obtenida.emit(item.type, item.amount)
				
		_rewarded_ad.show(_reward_listener)
		return true
	else:
		print("[AdMob] No había anuncio recompensado cargado. Solicitando carga...")
		cargar_rewarded()
		return false


func _destruir_rewarded() -> void:
	if _rewarded_ad:
		_rewarded_ad.destroy()
		_rewarded_ad = null
