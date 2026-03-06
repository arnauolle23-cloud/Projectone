extends CharacterBody3D

# === VARIABLES DE MOVIMIENTO ===
# Velocidad de desplazamiento del jugador (unidades por segundo)
@export var velocidad: float = 5.0
# Fuerza del salto (impulso vertical instantáneo)
@export var fuerza_salto: float = 4.5
# Factor de suavizado para frenar/acelerar (0 = sin freno, 1 = freno instantáneo)
@export var friccion: float = 0.15

# Tomamos la gravedad de la configuración del proyecto para ser consistentes con el motor.
var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	# Auto-genera todo lo necesario para probar sin crear nodos a mano.
	# >>> BORRAR este _ready() cuando armes la escena real en el editor. <<<
	_configurar_inputs()
	_crear_cuerpo()
	_crear_escena_prueba()


func _physics_process(delta: float) -> void:
	# --- Gravedad ---
	if not is_on_floor():
		velocity.y -= gravedad * delta

	# --- Salto (solo si está en el suelo) ---
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = fuerza_salto

	# --- Dirección de movimiento (ejes X y Z) ---
	# Input.get_vector() devuelve un Vector2 normalizado.
	# Se conecta directamente a un joystick virtual sin cambiar nada.
	var entrada: Vector2 = Input.get_vector(
		"mover_izquierda", "mover_derecha",
		"mover_adelante", "mover_atras"
	)

	# Debug: si ves valores distintos de (0,0) al pulsar WASD, el input funciona.
	if entrada != Vector2.ZERO:
		print("Input detectado: ", entrada)

	# Convertimos el Vector2 de entrada a dirección 3D.
	var direccion: Vector3 = Vector3(entrada.x, 0.0, entrada.y)

	# --- Aplicar velocidad horizontal ---
	if direccion != Vector3.ZERO:
		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad
	else:
		# Sin input: frenamos suavemente con interpolación lineal.
		velocity.x = lerpf(velocity.x, 0.0, friccion)
		velocity.z = lerpf(velocity.z, 0.0, friccion)

	# move_and_slide() aplica velocidad, gestiona colisiones
	# y actualiza is_on_floor() automáticamente.
	move_and_slide()


# =====================================================================
# AUTO-GENERACIÓN DE ESCENA DE PRUEBA
# Todo lo de abajo crea nodos por código para que NO tengas que
# armar nada a mano en el editor. Cuando la escena real esté lista,
# borra desde aquí hasta el final del archivo.
# =====================================================================

func _configurar_inputs() -> void:
	# Registra las acciones de input por código (equivale a Input Map).
	_agregar_accion("mover_izquierda", KEY_A)
	_agregar_accion("mover_derecha",   KEY_D)
	_agregar_accion("mover_adelante",  KEY_W)
	_agregar_accion("mover_atras",     KEY_S)
	_agregar_accion("saltar",          KEY_SPACE)


func _agregar_accion(nombre: String, tecla: Key) -> void:
	# Borrar si ya existe para asegurar que tenga la tecla correcta.
	if InputMap.has_action(nombre):
		InputMap.erase_action(nombre)
	InputMap.add_action(nombre)
	var evento := InputEventKey.new()
	evento.keycode = tecla
	evento.physical_keycode = tecla
	InputMap.action_add_event(nombre, evento)


func _crear_cuerpo() -> void:
	# Si ya existen hijos (escena armada en el editor), no duplicar.
	if get_node_or_null("CollisionShape3D"):
		return

	# Colisión: cápsula que envuelve al jugador.
	var colision := CollisionShape3D.new()
	colision.name = "CollisionShape3D"
	colision.shape = CapsuleShape3D.new()  # radio 0.5, alto 2.0 por defecto
	add_child(colision)

	# Malla visual: cápsula azul para identificar al jugador.
	var malla := MeshInstance3D.new()
	malla.name = "MeshInstance3D"
	var capsula := CapsuleMesh.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.4, 0.8)
	capsula.material = material
	malla.mesh = capsula
	add_child(malla)


func _crear_escena_prueba() -> void:
	var padre := get_parent()
	if padre == null or padre.get_node_or_null("Suelo"):
		return  # Ya se creó o no hay padre.

	# Posicionar al jugador por encima del suelo.
	position.y = 1.5

	# --- Suelo verde (20×20) ---
	var suelo := StaticBody3D.new()
	suelo.name = "Suelo"

	var col_suelo := CollisionShape3D.new()
	var forma_suelo := BoxShape3D.new()
	forma_suelo.size = Vector3(20.0, 0.2, 20.0)
	col_suelo.shape = forma_suelo
	suelo.add_child(col_suelo)

	var mesh_suelo := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(20.0, 0.2, 20.0)
	var mat_suelo := StandardMaterial3D.new()
	mat_suelo.albedo_color = Color(0.3, 0.6, 0.3)
	box.material = mat_suelo
	mesh_suelo.mesh = box
	suelo.add_child(mesh_suelo)

	padre.add_child(suelo)

	# --- Cámara que sigue al jugador (hija de este nodo) ---
	var camara := Camera3D.new()
	camara.name = "Camara"
	camara.position = Vector3(0.0, 4.0, 7.0)
	camara.rotation.x = deg_to_rad(-25.0)
	add_child(camara)

	# --- Luz direccional ---
	var luz := DirectionalLight3D.new()
	luz.name = "Luz"
	luz.rotation.x = deg_to_rad(-45.0)
	padre.add_child(luz)
