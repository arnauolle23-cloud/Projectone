extends CharacterBody3D

# === VARIABLES DE MOVIMIENTO ===
@export var velocidad: float = 5.0
@export var fuerza_salto: float = 4.5
@export var friccion: float = 0.15

var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _espacio_previo: bool = false


func _ready() -> void:
	_crear_personaje()
	_crear_escena_prueba()


func _physics_process(delta: float) -> void:
	# --- Gravedad ---
	if not is_on_floor():
		velocity.y -= gravedad * delta

	# --- Salto (detectar pulsación única de Espacio) ---
	var espacio_actual := Input.is_key_pressed(KEY_SPACE)
	if espacio_actual and not _espacio_previo and is_on_floor():
		velocity.y = fuerza_salto
	_espacio_previo = espacio_actual

	# --- Movimiento con detección directa de teclas ---
	# Cuando añadas joystick virtual, reemplaza este bloque por Input.get_vector().
	var entrada := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		entrada.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		entrada.x += 1.0
	if Input.is_key_pressed(KEY_W):
		entrada.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		entrada.y += 1.0
	entrada = entrada.normalized()

	var direccion := Vector3(entrada.x, 0.0, entrada.y)

	if direccion != Vector3.ZERO:
		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad
	else:
		velocity.x = lerpf(velocity.x, 0.0, friccion)
		velocity.z = lerpf(velocity.z, 0.0, friccion)

	move_and_slide()


# =====================================================================
# AUTO-GENERACIÓN (borrar cuando armes la escena real en el editor)
# =====================================================================

func _crear_personaje() -> void:
	if get_node_or_null("Colision"):
		return

	# --- Colisión: cápsula que cubre todo el cuerpo ---
	var colision := CollisionShape3D.new()
	colision.name = "Colision"
	var forma := CapsuleShape3D.new()
	forma.radius = 0.35
	forma.height = 1.8
	colision.shape = forma
	colision.position.y = 0.9
	add_child(colision)

	# --- Cuerpo (torso) ---
	var torso := MeshInstance3D.new()
	var torso_mesh := BoxMesh.new()
	torso_mesh.size = Vector3(0.6, 0.8, 0.3)
	var mat_torso := StandardMaterial3D.new()
	mat_torso.albedo_color = Color(0.2, 0.35, 0.8)  # Azul (camiseta)
	torso_mesh.material = mat_torso
	torso.mesh = torso_mesh
	torso.position.y = 1.1
	add_child(torso)

	# --- Cabeza ---
	var cabeza := MeshInstance3D.new()
	var cabeza_mesh := SphereMesh.new()
	cabeza_mesh.radius = 0.2
	cabeza_mesh.height = 0.4
	var mat_piel := StandardMaterial3D.new()
	mat_piel.albedo_color = Color(0.9, 0.72, 0.55)  # Color piel
	cabeza_mesh.material = mat_piel
	cabeza.mesh = cabeza_mesh
	cabeza.position.y = 1.7
	add_child(cabeza)

	# --- Pierna izquierda ---
	var pierna_izq := MeshInstance3D.new()
	var pierna_mesh := BoxMesh.new()
	pierna_mesh.size = Vector3(0.22, 0.7, 0.25)
	var mat_pantalon := StandardMaterial3D.new()
	mat_pantalon.albedo_color = Color(0.15, 0.15, 0.15)  # Gris oscuro
	pierna_mesh.material = mat_pantalon
	pierna_izq.mesh = pierna_mesh
	pierna_izq.position = Vector3(-0.15, 0.35, 0.0)
	add_child(pierna_izq)

	# --- Pierna derecha ---
	var pierna_der := MeshInstance3D.new()
	pierna_der.mesh = pierna_mesh  # Reutilizamos la misma malla
	pierna_der.position = Vector3(0.15, 0.35, 0.0)
	add_child(pierna_der)

	# --- Brazo izquierdo ---
	var brazo_izq := MeshInstance3D.new()
	var brazo_mesh := BoxMesh.new()
	brazo_mesh.size = Vector3(0.15, 0.6, 0.2)
	brazo_mesh.material = mat_torso  # Mismo color que el torso
	brazo_izq.mesh = brazo_mesh
	brazo_izq.position = Vector3(-0.4, 1.05, 0.0)
	add_child(brazo_izq)

	# --- Brazo derecho ---
	var brazo_der := MeshInstance3D.new()
	brazo_der.mesh = brazo_mesh
	brazo_der.position = Vector3(0.4, 1.05, 0.0)
	add_child(brazo_der)


func _crear_escena_prueba() -> void:
	var padre := get_parent()
	if padre == null or padre.get_node_or_null("Suelo"):
		return

	position.y = 1.0

	# --- Suelo ---
	var suelo := StaticBody3D.new()
	suelo.name = "Suelo"

	var col_suelo := CollisionShape3D.new()
	var forma_suelo := BoxShape3D.new()
	forma_suelo.size = Vector3(30.0, 0.2, 30.0)
	col_suelo.shape = forma_suelo
	suelo.add_child(col_suelo)

	var mesh_suelo := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(30.0, 0.2, 30.0)
	var mat_suelo := StandardMaterial3D.new()
	mat_suelo.albedo_color = Color(0.35, 0.65, 0.3)
	box.material = mat_suelo
	mesh_suelo.mesh = box
	suelo.add_child(mesh_suelo)

	padre.add_child(suelo)

	# --- Cámara (sigue al jugador) ---
	var camara := Camera3D.new()
	camara.name = "Camara"
	camara.position = Vector3(0.0, 4.0, 7.0)
	camara.rotation.x = deg_to_rad(-25.0)
	add_child(camara)

	# --- Luz ---
	var luz := DirectionalLight3D.new()
	luz.name = "Luz"
	luz.rotation.x = deg_to_rad(-45.0)
	luz.rotation.y = deg_to_rad(-30.0)
	luz.shadow_enabled = true
	padre.add_child(luz)

	# --- Luz ambiente para que no quede tan oscuro ---
	var env := WorldEnvironment.new()
	env.name = "Ambiente"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.5, 0.7, 0.9)  # Cielo azul claro
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	env.environment = environment
	padre.add_child(env)
