extends Node

const RUTA_GUARDADO: String = "user://progreso.save"

const NIVELES: Dictionary = {
	# --- TIER 1: TRÁFICO URBANO Y MURO DE ACEITE (Niveles 1 al 10) ---
	1: { "carriles": [192.0, 456.0], "velocidad_inicial": 320.0, "meta_puntos": 45, "fondo": "res://carreteras/carretera1.svg", "enemigos": [0] },
	2: { "carriles": [192.0, 456.0], "velocidad_inicial": 340.0, "meta_puntos": 50, "fondo": "res://carreteras/carretera1.svg", "enemigos": [0, 2] },
	3: { "carriles": [148.0, 324.0, 500.0], "velocidad_inicial": 360.0, "meta_puntos": 55, "fondo": "res://carreteras/carretera2.svg", "enemigos": [0, 2] },
	4: { "carriles": [148.0, 324.0, 500.0], "velocidad_inicial": 380.0, "meta_puntos": 60, "fondo": "res://carreteras/carretera2.svg", "enemigos": [0, 1, 2] },
	5: { "carriles": [148.0, 324.0, 500.0], "velocidad_inicial": 400.0, "meta_puntos": 65, "fondo": "res://carreteras/carretera2.svg", "enemigos": [0, 1, 2] },
	6: { "carriles": [117.0, 255.0, 393.0, 531.0], "velocidad_inicial": 420.0, "meta_puntos": 70, "fondo": "res://carreteras/carretera3.svg", "enemigos": [0, 1, 2] },
	7: { "carriles": [117.0, 255.0, 393.0, 531.0], "velocidad_inicial": 440.0, "meta_puntos": 75, "fondo": "res://carreteras/carretera3.svg", "enemigos": [0, 1, 2, 3] },
	8: { "carriles": [117.0, 255.0, 393.0, 531.0], "velocidad_inicial": 465.0, "meta_puntos": 85, "fondo": "res://carreteras/carretera3.svg", "enemigos": [0, 1, 2, 3] },
	9: { "carriles": [117.0, 255.0, 393.0, 531.0], "velocidad_inicial": 490.0, "meta_puntos": 95, "fondo": "res://carreteras/carretera3.svg", "enemigos": [0, 1, 2, 3] },
	10: { "carriles": [117.0, 255.0, 393.0, 531.0], "velocidad_inicial": 515.0, "meta_puntos": 110, "fondo": "res://carreteras/carretera3.svg", "enemigos": [0, 1, 2, 3] },

	# --- TIER 2: LA AUTOPISTA FANTASMA Y ESPEJISMOS HOLOGRÁFICOS (Niveles 11 al 20) ---
	11: { "carriles": [117.0, 255.0, 393.0, 531.0], "velocidad_inicial": 535.0, "meta_puntos": 115, "fondo": "res://carreteras/carretera3.svg", "enemigos": [0, 1, 2, 6] },
	12: { "carriles": [117.0, 255.0, 393.0, 531.0], "velocidad_inicial": 555.0, "meta_puntos": 120, "fondo": "res://carreteras/carretera3.svg", "enemigos": [0, 1, 2, 5, 6] },
	13: { "carriles": [95.2, 209.6, 324.0, 438.4, 552.8], "velocidad_inicial": 575.0, "meta_puntos": 125, "fondo": "res://carreteras/carretera4.svg", "enemigos": [0, 1, 2, 6] },
	14: { "carriles": [95.2, 209.6, 324.0, 438.4, 552.8], "velocidad_inicial": 595.0, "meta_puntos": 130, "fondo": "res://carreteras/carretera4.svg", "enemigos": [0, 1, 2, 3, 6] },
	15: { "carriles": [95.2, 209.6, 324.0, 438.4, 552.8], "velocidad_inicial": 615.0, "meta_puntos": 140, "fondo": "res://carreteras/carretera4.svg", "enemigos": [0, 1, 2, 5, 6] },
	16: { "carriles": [95.2, 209.6, 324.0, 438.4, 552.8], "velocidad_inicial": 635.0, "meta_puntos": 145, "fondo": "res://carreteras/carretera4.svg", "enemigos": [0, 1, 2, 4, 6] },
	17: { "carriles": [95.2, 209.6, 324.0, 438.4, 552.8], "velocidad_inicial": 655.0, "meta_puntos": 150, "fondo": "res://carreteras/carretera4.svg", "enemigos": [0, 1, 2, 4, 5, 6] },
	18: { "carriles": [95.2, 209.6, 324.0, 438.4, 552.8], "velocidad_inicial": 675.0, "meta_puntos": 160, "fondo": "res://carreteras/carretera4.svg", "enemigos": [0, 1, 2, 3, 5, 6] },
	19: { "carriles": [95.2, 209.6, 324.0, 438.4, 552.8], "velocidad_inicial": 695.0, "meta_puntos": 170, "fondo": "res://carreteras/carretera4.svg", "enemigos": [0, 1, 2, 4, 5, 6] },
	20: { "carriles": [95.2, 209.6, 324.0, 438.4, 552.8], "velocidad_inicial": 715.0, "meta_puntos": 180, "fondo": "res://carreteras/carretera4.svg", "enemigos": [0, 1, 2, 3, 4, 5, 6] },

	# --- TIER 3: MEGAPISTA CIBERNÉTICA Y CAZADORES NOCTURNOS (Niveles 21 al 30) ---
	21: { "carriles": [79.0, 177.0, 275.0, 373.0, 471.0, 569.0], "velocidad_inicial": 735.0, "meta_puntos": 190, "fondo": "res://carreteras/carretera5.svg", "enemigos": [0, 1, 2, 4, 5, 6] },
	22: { "carriles": [79.0, 177.0, 275.0, 373.0, 471.0, 569.0], "velocidad_inicial": 750.0, "meta_puntos": 200, "fondo": "res://carreteras/carretera5.svg", "enemigos": [0, 1, 2, 3, 4, 5, 6] },
	23: { "carriles": [79.0, 177.0, 275.0, 373.0, 471.0, 569.0], "velocidad_inicial": 765.0, "meta_puntos": 215, "fondo": "res://carreteras/carretera5.svg", "enemigos": [0, 1, 2, 4, 5, 6] },
	24: { "carriles": [79.0, 177.0, 275.0, 373.0, 471.0, 569.0], "velocidad_inicial": 780.0, "meta_puntos": 230, "fondo": "res://carreteras/carretera5.svg", "enemigos": [0, 1, 2, 3, 4, 5, 6] },
	25: { "carriles": [79.0, 177.0, 275.0, 373.0, 471.0, 569.0], "velocidad_inicial": 800.0, "meta_puntos": 245, "fondo": "res://carreteras/carretera5.svg", "enemigos": [0, 1, 2, 3, 4, 5, 6] },
	26: { "carriles": [79.0, 177.0, 275.0, 373.0, 471.0, 569.0], "velocidad_inicial": 815.0, "meta_puntos": 260, "fondo": "res://carreteras/carretera5.svg", "enemigos": [0, 1, 2, 3, 4, 5, 6] },
	27: { "carriles": [79.0, 177.0, 275.0, 373.0, 471.0, 569.0], "velocidad_inicial": 830.0, "meta_puntos": 275, "fondo": "res://carreteras/carretera5.svg", "enemigos": [0, 1, 2, 3, 4, 5, 6] },
	28: { "carriles": [79.0, 177.0, 275.0, 373.0, 471.0, 569.0], "velocidad_inicial": 845.0, "meta_puntos": 290, "fondo": "res://carreteras/carretera5.svg", "enemigos": [0, 1, 2, 3, 4, 5, 6] },
	29: { "carriles": [79.0, 177.0, 275.0, 373.0, 471.0, 569.0], "velocidad_inicial": 860.0, "meta_puntos": 310, "fondo": "res://carreteras/carretera5.svg", "enemigos": [0, 1, 2, 3, 4, 5, 6] },
	30: { "carriles": [79.0, 177.0, 275.0, 373.0, 471.0, 569.0], "velocidad_inicial": 880.0, "meta_puntos": 330, "fondo": "res://carreteras/carretera5.svg", "enemigos": [0, 1, 2, 3, 4, 5, 6] },

	# --- MODO INFINITO (Nivel 31) ---
	31: {
		"carriles": [79.0, 177.0, 275.0, 373.0, 471.0, 569.0],
		"velocidad_inicial": 900.0,
		"meta_puntos": -1,
		"fondo": "res://carreteras/carretera5.svg",
		"enemigos": [0, 1, 2, 3, 4, 5, 6]
	}
}

var nivel_actual: int = 1
var nivel_maximo_desbloqueado: int = 1
var record_puntos: int = 0
var audio_silenciado: bool = false
var musica_silenciada: bool = false
var auto_seleccionado: String = "res://jugador.png"
var modo_control: String = "botones" # "botones" o "carriles"
var monedas: int = 0
var autos_desbloqueados: Array = ["res://jugador.png"]
var idioma: String = "es" # "es" (Español) o "en" (English)

const AUTOS_INFO: Dictionary = {
	"res://jugador.png": {
		"nombre": "Auto Clásico Azul",
		"nombre_es": "Auto Clásico Azul",
		"nombre_en": "Classic Blue Car",
		"costo": 0,
		"habilidad_tipo": "ninguna",
		"desc": "Vehículo estándar equilibrado. Agilidad urbana clásica.",
		"desc_es": "Vehículo estándar equilibrado. Agilidad urbana clásica.",
		"desc_en": "Standard balanced vehicle. Classic urban agility."
	},
	"res://auto_rojo.svg": {
		"nombre": "Auto Deportivo Rojo",
		"nombre_es": "Auto Deportivo Rojo",
		"nombre_en": "Red Sports Car",
		"costo": 280,
		"habilidad_tipo": "inmune_aceite",
		"desc": "Llantas especiales con tacos de tracción amarillos: 100% inmune a derrapes por charcos de aceite.",
		"desc_es": "Llantas especiales con tacos de tracción amarillos: 100% inmune a derrapes por charcos de aceite.",
		"desc_en": "Special tires with yellow traction studs: 100% immune to slipping on oil puddles."
	},
	"res://auto_amarillo.svg": {
		"nombre": "Superdeportivo GT",
		"nombre_es": "Superdeportivo GT",
		"nombre_en": "GT Supercar",
		"costo": 500,
		"habilidad_tipo": "escudo_embestida",
		"desc": "Escudo de 4s (recarga 6s): Al chocar a un enemigo, lo empuja a otro carril y suma +2 pts.",
		"desc_es": "Escudo de 4s (recarga 6s): Al chocar a un enemigo, lo empuja a otro carril y suma +2 pts.",
		"desc_en": "4s shield (6s cooldown): When ramming an enemy, pushes it to another lane and adds +2 pts."
	},
	"res://auto_policia.svg": {
		"nombre": "Patrulla Interceptor",
		"nombre_es": "Patrulla Interceptor",
		"nombre_en": "Police Interceptor",
		"costo": 1200,
		"habilidad_tipo": "disparo",
		"desc": "Torreta de asalto frontal: Dispara proyectiles que destruyen rivales y suma +2 pts.",
		"desc_es": "Torreta de asalto frontal: Dispara proyectiles que destruyen rivales y suma +2 pts.",
		"desc_en": "Front assault turret: Shoots projectiles that destroy rivals and adds +2 pts."
	},
	"res://auto_cyber.svg": {
		"nombre": "Auto Cyberpunk Neón",
		"nombre_es": "Auto Cyberpunk Neón",
		"nombre_en": "Neon Cyberpunk Car",
		"costo": 2200,
		"habilidad_tipo": "iman",
		"desc": "Imán de 4s (recarga 6s): Atrae todas las monedas y escudos hacia ti.",
		"desc_es": "Imán de 4s (recarga 6s): Atrae todas las monedas y escudos hacia ti.",
		"desc_en": "4s magnet (6s cooldown): Attracts all coins and shields toward you."
	},
	"res://auto_f1.svg": {
		"nombre": "Bólido Leyenda F1",
		"nombre_es": "Bólido Leyenda F1",
		"nombre_en": "Legend F1 Racer",
		"costo": 4500,
		"habilidad_tipo": "todas",
		"desc": "El Rey de la Pista: Inmune a aceite + Escudo embestidor + Disparos + Imán.",
		"desc_es": "El Rey de la Pista: Inmune a aceite + Escudo embestidor + Disparos + Imán.",
		"desc_en": "The King of the Track: Immune to oil + Ramming shield + Blasters + Magnet."
	}
}

const TRADUCCIONES: Dictionary = {
	"es": {
		"BTN_VOLVER": "VOLVER",
		"BTN_MENU_PRINCIPAL": "MENÚ PRINCIPAL",
		"BTN_PAUSA": "PAUSA",
		"BTN_CONTINUAR": "CONTINUAR",
		"BTN_JUGAR": "JUGAR",
		"BTN_REINTENTAR": "REINTENTAR NIVEL",
		"BTN_USAR": "USAR",
		"EQUIPADO": "EQUIPADO ✓",
		"FALTAN_MONEDAS": "Faltan %d",

		"BTN_GARAJE": "GARAJE DE VEHÍCULOS",
		"BTN_NIVELES": "PROGRESO DE NIVELES",
		"BTN_AJUSTES": "OPCIONES Y CONTROLES",
		"BTN_GUIA": "GUÍA DE ELEMENTOS",

		"HUD_PUNTOS": "PUNTOS",
		"HUD_NIVEL": "NIVEL",
		"HUD_INFINITO": "INFINITO",
		"HUD_RECORD": "RÉCORD",
		"HUD_MONEDAS": "🪙 MONEDAS: %d (+%d)",
		"CLIMA_LLUVIA": "CLIMA: 🌧️ Lluvia",
		"CLIMA_NIEBLA": "CLIMA: 🌫️ Niebla",
		"CLIMA_DESPEJADO": "CLIMA: ☀️ Despejado",
		"HABILIDAD_ACTIVA": "ACTIVO!",
		"TUTORIAL_CARRILES": "👆 Toca directamente el carril al que quieres ir",

		"TITULO_PAUSA": "JUEGO EN PAUSA",
		"PAUSA_INFO": "Puntaje: %d  |  Nivel: %s",
		"BTN_AJUSTES_PAUSA": "AJUSTES Y CONTROLES",
		"FOTO_GUARDADA": "¡Foto guardada!",

		"TITULO_AJUSTES": "OPCIONES Y CONTROLES",
		"MODO_CARRILES": "🎮 MODO: TOCAR CARRILES",
		"MODO_BOTONES": "🎮 MODO: BOTONES EN PANTALLA",
		"DESC_MODO_CARRILES": "👆 Toca directamente el carril al que deseas ir o desliza. El auto maniobrará suavemente hacia allí sin saltar.",
		"DESC_MODO_BOTONES": "🎛️ Usa las flechas táctiles en pantalla para cambiar de carril.",
		"BTN_CAMBIAR_CONTROL": "CAMBIAR MODO DE CONTROL",
		"AUDIO_ESTADO": "Audio General: %s",
		"MUSICA_ESTADO": "Música de Fondo: %s",
		"ESTADO_ACTIVO": "ACTIVO",
		"ESTADO_ACTIVA": "ACTIVA",
		"ESTADO_SILENCIADO": "SILENCIADO",
		"ESTADO_SILENCIADA": "SILENCIADA",
		"BTN_SILENCIAR_TODO": "SILENCIAR TODO",
		"BTN_ACTIVAR_TODO": "ACTIVAR AUDIO",
		"BTN_SILENCIAR_MUSICA": "SILENCIAR MÚSICA",
		"BTN_ACTIVAR_MUSICA": "ACTIVAR MÚSICA",

		"BTN_REVIVIR_AD": "VER ANUNCIO (+2 VIDAS)",
		"AD_ESPERE": "Espere un momento e intente de nuevo",

		"TITULO_OPCIONES_JUGAR": "OPCIONES DE JUEGO",
		"INFO_CHECKPOINT": "Punto de control: Nivel %d.\nRécord alcanzado: Nivel %d.",
		"BTN_CONTINUAR_NIVEL": "CONTINUAR (NIVEL %d)",
		"BTN_NUEVA_PARTIDA": "EMPEZAR DE NUEVO",

		"TITULO_NIVELES": "PROGRESO DE NIVELES",
		"NIVEL_NUM": "NIVEL %d",
		"META_PTS": "Meta: %d pts",
		"ESTADO_EN_PROGRESO": "EN PROGRESO 🚩",
		"ESTADO_COMPLETADO": "COMPLETADO ⭐",
		"ESTADO_BLOQUEADO": "BLOQUEADO 🔒",

		"TITULO_GARAJE": "GARAJE DE VEHÍCULOS",
		"BILLETERA_SALDO": "🪙 BILLETERA: %d MONEDAS",
		"BTN_AD_MONEDAS": "📺 +20 MONEDAS GRATIS",

		"TITULO_TRANSICION": "¡NIVEL COMPLETADO!",
		"NIVEL_SUPERADO": "¡NIVEL %d SUPERADO!",
		"TAG_NUEVO_AUTO": "¡NUEVO VEHÍCULO DISPONIBLE!",
		"PRECIO_AUTO": "🪙 Precio: %d (Tienes: %d 🪙)",
		"BTN_IR_GARAJE": "IR AL GARAJE Y EQUIPAR",
		"RESUMEN_NIVEL": "¡Has completado el Nivel %d con éxito!\n\n🪙 Bono por Nivel: +10 Monedas\nBilletera Total: %d Monedas",
		"BTN_SIGUIENTE_NIVEL": "SIGUIENTE NIVEL",

		"TITULO_VICTORIA": "🏆 ¡CAMPEÓN DE LA PISTA!",
		"DESC_VICTORIA": "¡FELICITACIONES!\nHas superado con éxito los 30 Niveles de Campaña y demostrado reflejos legendarios.\n\n🏎️ DESBLOQUEADO: Bólido Leyenda F1 Dorado\n♾️ DESBLOQUEADO: Modo Infinito (Nivel 31)",
		"BTN_MODO_INFINITO": "MODO INFINITO ♾️",

		"TITULO_GUIA": "GUÍA DE ELEMENTOS",
		"GUIA_BOTONES_TIT": "Control: Botones",
		"GUIA_BOTONES_DESC": "Flechas en pantalla para moverte paso a paso carril por carril.",
		"GUIA_CARRILES_TIT": "Control: Tocar Carriles",
		"GUIA_CARRILES_DESC": "Toca directamente el carril al que quieres ir o desliza. El auto maniobra con suavidad sin saltar.",
		"GUIA_MONEDA_TIT": "Moneda de Oro",
		"GUIA_MONEDA_DESC": "Suma +3 puntos bonus de inmediato al recogerla.",
		"GUIA_CORAZON_TIT": "Corazón Extra",
		"GUIA_CORAZON_DESC": "Suma +1 vida extra (máximo 5 vidas). Aparece al alcanzar el 50% del nivel.",
		"GUIA_ESCUDO_TIT": "Escudo de Energía",
		"GUIA_ESCUDO_DESC": "Protege tu auto durante 7s o hasta absorber 1 choque.",
		"GUIA_RELOJ_TIT": "Reloj Ralentizador",
		"GUIA_RELOJ_DESC": "Reduce la velocidad del tráfico y fondo un 40% durante 4.5s.",
		"GUIA_AUTO_TIT": "Auto Convencional",
		"GUIA_AUTO_DESC": "Vehículo estándar. Esquívate de su carril para evitar chocar.",
		"GUIA_MOTO_TIT": "Moto Deportiva",
		"GUIA_MOTO_DESC": "Vehículo rápido. Desciende un 35% más veloz que los autos.",
		"GUIA_VOLQUETA_TIT": "Volqueta Pesada",
		"GUIA_VOLQUETA_DESC": "Camión largo y lento. Ocupa más espacio vertical al rebasar.",
		"GUIA_ACEITE_TIT": "Mancha de Aceite",
		"GUIA_ACEITE_DESC": "¡No resta vidas! Pero al pisarla tu auto se deslizará sin control.",
		"GUIA_POLICIA_TIT": "Patrulla de Policía (Nivel 16+)",
		"GUIA_POLICIA_DESC": "Vehículo veloz con sirena. ¡Atención! Se inclina previamente para avisar y cambia de carril en persecución.",
		"GUIA_BARRICADA_TIT": "Barricada de Obras (Nivel 12+)",
		"GUIA_BARRICADA_DESC": "Bloqueo pesado de carril en obras con balizas ámbar y conos. ¡Evita chocar contra ella!"
	},
	"en": {
		"BTN_VOLVER": "BACK",
		"BTN_MENU_PRINCIPAL": "MAIN MENU",
		"BTN_PAUSA": "PAUSE",
		"BTN_CONTINUAR": "CONTINUE",
		"BTN_JUGAR": "PLAY",
		"BTN_REINTENTAR": "RETRY LEVEL",
		"BTN_USAR": "USE",
		"EQUIPADO": "EQUIPPED ✓",
		"FALTAN_MONEDAS": "%d needed",

		"BTN_GARAJE": "VEHICLE GARAGE",
		"BTN_NIVELES": "LEVEL PROGRESS",
		"BTN_AJUSTES": "SETTINGS & CONTROLS",
		"BTN_GUIA": "ELEMENTS GUIDE",

		"HUD_PUNTOS": "SCORE",
		"HUD_NIVEL": "LEVEL",
		"HUD_INFINITO": "INFINITE",
		"HUD_RECORD": "RECORD",
		"HUD_MONEDAS": "🪙 COINS: %d (+%d)",
		"CLIMA_LLUVIA": "WEATHER: 🌧️ Rain",
		"CLIMA_NIEBLA": "WEATHER: 🌫️ Fog",
		"CLIMA_DESPEJADO": "WEATHER: ☀️ Clear",
		"HABILIDAD_ACTIVA": "ACTIVE!",
		"TUTORIAL_CARRILES": "👆 Tap directly on the lane you want to move to",

		"TITULO_PAUSA": "GAME PAUSED",
		"PAUSA_INFO": "Score: %d  |  Level: %s",
		"BTN_AJUSTES_PAUSA": "SETTINGS & CONTROLS",
		"FOTO_GUARDADA": "Screenshot saved!",

		"TITULO_AJUSTES": "SETTINGS & CONTROLS",
		"MODO_CARRILES": "🎮 MODE: TAP LANES",
		"MODO_BOTONES": "🎮 MODE: ON-SCREEN BUTTONS",
		"DESC_MODO_CARRILES": "👆 Tap directly on the lane you want or swipe. The car steers smoothly without jumping.",
		"DESC_MODO_BOTONES": "🎛️ Use on-screen touch arrows to switch lanes.",
		"BTN_CAMBIAR_CONTROL": "CHANGE CONTROL MODE",
		"AUDIO_ESTADO": "Master Audio: %s",
		"MUSICA_ESTADO": "Background Music: %s",
		"ESTADO_ACTIVO": "ON",
		"ESTADO_ACTIVA": "ON",
		"ESTADO_SILENCIADO": "MUTED",
		"ESTADO_SILENCIADA": "MUTED",
		"BTN_SILENCIAR_TODO": "MUTE ALL",
		"BTN_ACTIVAR_TODO": "UNMUTE AUDIO",
		"BTN_SILENCIAR_MUSICA": "MUTE MUSIC",
		"BTN_ACTIVAR_MUSICA": "UNMUTE MUSIC",

		"BTN_REVIVIR_AD": "WATCH AD (+2 LIVES)",
		"AD_ESPERE": "Please wait a moment and try again",

		"TITULO_OPCIONES_JUGAR": "GAME OPTIONS",
		"INFO_CHECKPOINT": "Checkpoint: Level %d.\nRecord reached: Level %d.",
		"BTN_CONTINUAR_NIVEL": "CONTINUE (LEVEL %d)",
		"BTN_NUEVA_PARTIDA": "START NEW GAME",

		"TITULO_NIVELES": "LEVEL PROGRESS",
		"NIVEL_NUM": "LEVEL %d",
		"META_PTS": "Target: %d pts",
		"ESTADO_EN_PROGRESO": "IN PROGRESS 🚩",
		"ESTADO_COMPLETADO": "COMPLETED ⭐",
		"ESTADO_BLOQUEADO": "LOCKED 🔒",

		"TITULO_GARAJE": "VEHICLE GARAGE",
		"BILLETERA_SALDO": "🪙 WALLET: %d COINS",
		"BTN_AD_MONEDAS": "📺 +20 FREE COINS",

		"TITULO_TRANSICION": "LEVEL COMPLETED!",
		"NIVEL_SUPERADO": "LEVEL %d COMPLETED!",
		"TAG_NUEVO_AUTO": "NEW VEHICLE AVAILABLE!",
		"PRECIO_AUTO": "🪙 Price: %d (You have: %d 🪙)",
		"BTN_IR_GARAJE": "GO TO GARAGE & EQUIP",
		"RESUMEN_NIVEL": "You completed Level %d successfully!\n\n🪙 Level Bonus: +10 Coins\nTotal Wallet: %d Coins",
		"BTN_SIGUIENTE_NIVEL": "NEXT LEVEL",

		"TITULO_VICTORIA": "🏆 TRACK CHAMPION!",
		"DESC_VICTORIA": "CONGRATULATIONS!\nYou have successfully completed all 30 Campaign Levels and demonstrated legendary reflexes.\n\n🏎️ UNLOCKED: Golden Legend F1 Racer\n♾️ UNLOCKED: Infinite Mode (Level 31)",
		"BTN_MODO_INFINITO": "INFINITE MODE ♾️",

		"TITULO_GUIA": "ELEMENTS GUIDE",
		"GUIA_BOTONES_TIT": "Control: Buttons",
		"GUIA_BOTONES_DESC": "On-screen arrows to steer step by step lane by lane.",
		"GUIA_CARRILES_TIT": "Control: Tap Lanes",
		"GUIA_CARRILES_DESC": "Tap directly on the lane you want or swipe. The car maneuvers smoothly without jumping.",
		"GUIA_MONEDA_TIT": "Gold Coin",
		"GUIA_MONEDA_DESC": "Adds +3 bonus points immediately upon collection.",
		"GUIA_CORAZON_TIT": "Extra Heart",
		"GUIA_CORAZON_DESC": "Adds +1 extra life (max 5 lives). Appears at 50% of the level.",
		"GUIA_ESCUDO_TIT": "Energy Shield",
		"GUIA_ESCUDO_DESC": "Protects your car for 7s or until absorbing 1 crash.",
		"GUIA_RELOJ_TIT": "Slowdown Clock",
		"GUIA_RELOJ_DESC": "Reduces traffic and road speed by 40% for 4.5s.",
		"GUIA_AUTO_TIT": "Standard Car",
		"GUIA_AUTO_DESC": "Standard vehicle. Dodge its lane to avoid crashing.",
		"GUIA_MOTO_TIT": "Sport Motorcycle",
		"GUIA_MOTO_DESC": "Fast vehicle. Moves down 35% faster than cars.",
		"GUIA_VOLQUETA_TIT": "Heavy Dump Truck",
		"GUIA_VOLQUETA_DESC": "Long and slow truck. Occupies more vertical room when overtaking.",
		"GUIA_ACEITE_TIT": "Oil Slick",
		"GUIA_ACEITE_DESC": "Does not cost lives! But driving over it makes your car slide out of control.",
		"GUIA_POLICIA_TIT": "Police Patrol (Level 16+)",
		"GUIA_POLICIA_DESC": "Fast vehicle with siren. Warning: Tilts ahead of time to signal, then changes lanes in pursuit.",
		"GUIA_BARRICADA_TIT": "Roadblock (Level 12+)",
		"GUIA_BARRICADA_DESC": "Heavy construction barricade with amber lights and cones. Avoid crashing into it!"
	}
}

func _ready() -> void:
	cargar_progreso()

func t(clave: String, args: Array = []) -> String:
	var dic = TRADUCCIONES.get(idioma, TRADUCCIONES["es"])
	var plantilla: String = dic.get(clave, "")
	if plantilla.is_empty():
		plantilla = TRADUCCIONES["es"].get(clave, clave)
	if args.is_empty():
		return plantilla
	else:
		return plantilla % args

func cambiar_idioma() -> void:
	if idioma == "es":
		idioma = "en"
	else:
		idioma = "es"
	guardar_progreso()

func obtener_nombre_auto(id_auto: String) -> String:
	if id_auto in AUTOS_INFO:
		var campo = "nombre_" + idioma
		if campo in AUTOS_INFO[id_auto]:
			return AUTOS_INFO[id_auto][campo]
		return AUTOS_INFO[id_auto].get("nombre", "")
	return ""

func obtener_desc_auto(id_auto: String) -> String:
	if id_auto in AUTOS_INFO:
		var campo = "desc_" + idioma
		if campo in AUTOS_INFO[id_auto]:
			return AUTOS_INFO[id_auto][campo]
		return AUTOS_INFO[id_auto].get("desc", "")
	return ""

func guardar_progreso() -> void:
	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo:
		var datos = {
			"nivel_actual": nivel_actual,
			"nivel_maximo_desbloqueado": nivel_maximo_desbloqueado,
			"record_puntos": record_puntos,
			"audio_silenciado": audio_silenciado,
			"musica_silenciada": musica_silenciada,
			"auto_seleccionado": auto_seleccionado,
			"modo_control": modo_control,
			"monedas": monedas,
			"autos_desbloqueados": autos_desbloqueados,
			"idioma": idioma
		}
		var json_cadena = JSON.stringify(datos)
		archivo.store_line(json_cadena)
		archivo.close()

func cargar_progreso() -> void:
	if not FileAccess.file_exists(RUTA_GUARDADO):
		if not autos_desbloqueados.has("res://jugador.png"):
			autos_desbloqueados.append("res://jugador.png")
		return
		
	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if archivo:
		var json_texto = archivo.get_as_text()
		archivo.close()
		
		var json = JSON.new()
		var resultado_parse = json.parse(json_texto)
		if resultado_parse == OK:
			var datos = json.get_data()
			nivel_actual = int(datos.get("nivel_actual", 1))
			nivel_maximo_desbloqueado = int(datos.get("nivel_maximo_desbloqueado", 1))
			record_puntos = int(datos.get("record_puntos", 0))
			audio_silenciado = bool(datos.get("audio_silenciado", false))
			musica_silenciada = bool(datos.get("musica_silenciada", false))
			auto_seleccionado = str(datos.get("auto_seleccionado", "res://jugador.png"))
			modo_control = str(datos.get("modo_control", "botones"))
			monedas = int(datos.get("monedas", 0))
			idioma = str(datos.get("idioma", "es"))
			if idioma != "es" and idioma != "en":
				idioma = "es"
			
			var autos_guardados = datos.get("autos_desbloqueados", ["res://jugador.png"])
			if autos_guardados is Array:
				autos_desbloqueados = autos_guardados
			if not autos_desbloqueados.has("res://jugador.png"):
				autos_desbloqueados.append("res://jugador.png")

func actualizar_record(nuevos_puntos: int) -> bool:
	if nuevos_puntos > record_puntos:
		record_puntos = nuevos_puntos
		guardar_progreso()
		return true
	return false

func agregar_monedas(cantidad: int) -> void:
	if cantidad > 0:
		monedas += cantidad
		guardar_progreso()

func gastar_monedas(cantidad: int) -> bool:
	if cantidad <= monedas:
		monedas -= cantidad
		guardar_progreso()
		return true
	return false

func esta_auto_desbloqueado(id_auto: String) -> bool:
	return id_auto in autos_desbloqueados

func comprar_auto(id_auto: String) -> bool:
	if esta_auto_desbloqueado(id_auto):
		return true
	if id_auto in AUTOS_INFO:
		var costo: int = AUTOS_INFO[id_auto]["costo"]
		if gastar_monedas(costo):
			autos_desbloqueados.append(id_auto)
			guardar_progreso()
			return true
	return false

func obtener_habilidad_auto(id_auto: String) -> String:
	if id_auto in AUTOS_INFO:
		return AUTOS_INFO[id_auto].get("habilidad_tipo", "ninguna")
	return "ninguna"

func obtener_siguiente_auto_comprable() -> Dictionary:
	var orden_autos = [
		"res://auto_rojo.svg",
		"res://auto_amarillo.svg",
		"res://auto_policia.svg",
		"res://auto_cyber.svg",
		"res://auto_f1.svg"
	]
	for ruta in orden_autos:
		if not esta_auto_desbloqueado(ruta):
			var info = AUTOS_INFO.get(ruta, {})
			if not info.is_empty() and monedas >= info.get("costo", 999999):
				var res = info.duplicate()
				res["ruta"] = ruta
				res["nombre"] = obtener_nombre_auto(ruta)
				res["desc"] = obtener_desc_auto(ruta)
				return res
	return {}
