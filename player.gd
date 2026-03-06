extends CharacterBody3D

# === VARIABLES DE MOVIMIENTO ===
@export var velocidad: float = 5.0
@export var fuerza_salto: float = 4.5
@export var friccion: float = 0.15

var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _espacio_previo: bool = false

# Referencias para animación (se asignan en _crear_personaje)
var _modelo: Node3D
var _pivot_pierna_izq: Node3D
var _pivot_pierna_der: Node3D
var _pivot_brazo_izq: Node3D
var _pivot_brazo_der: Node3D
var _tiempo_anim: float = 0.0


func _ready() -> void:
	print("=== PLAYER v3 - MAPA CON CASA Y ARBOLES ===")
	_crear_personaje()
	_crear_escena_prueba()


func _physics_process(delta: float) -> void:
	# --- Gravedad ---
	if not is_on_floor():
		velocity.y -= gravedad * delta

	# --- Salto ---
	var espacio_actual := Input.is_key_pressed(KEY_SPACE)
	if espacio_actual and not _espacio_previo and is_on_floor():
		velocity.y = fuerza_salto
	_espacio_previo = espacio_actual

	# --- Movimiento (WASD + Flechas) ---
	var entrada := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		entrada.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		entrada.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		entrada.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		entrada.y += 1.0
	entrada = entrada.normalized()

	var direccion := Vector3(entrada.x, 0.0, entrada.y)

	if direccion != Vector3.ZERO:
		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad
		# Girar el modelo hacia la dirección de movimiento
		if _modelo:
			_modelo.rotation.y = atan2(-direccion.x, -direccion.z)
	else:
		velocity.x = lerpf(velocity.x, 0.0, friccion)
		velocity.z = lerpf(velocity.z, 0.0, friccion)

	move_and_slide()

	# --- Animaciones ---
	_animar(delta, direccion != Vector3.ZERO)


func _animar(delta: float, en_movimiento: bool) -> void:
	if _pivot_pierna_izq == null:
		return

	if not is_on_floor():
		# --- Animación de salto ---
		if velocity.y > 0:
			# Subiendo: piernas recogidas, brazos arriba
			_pivot_pierna_izq.rotation.x = lerpf(_pivot_pierna_izq.rotation.x, 0.5, 0.15)
			_pivot_pierna_der.rotation.x = lerpf(_pivot_pierna_der.rotation.x, 0.5, 0.15)
			_pivot_brazo_izq.rotation.x = lerpf(_pivot_brazo_izq.rotation.x, -2.0, 0.15)
			_pivot_brazo_der.rotation.x = lerpf(_pivot_brazo_der.rotation.x, -2.0, 0.15)
		else:
			# Cayendo: piernas estiradas, brazos abiertos
			_pivot_pierna_izq.rotation.x = lerpf(_pivot_pierna_izq.rotation.x, -0.3, 0.1)
			_pivot_pierna_der.rotation.x = lerpf(_pivot_pierna_der.rotation.x, -0.3, 0.1)
			_pivot_brazo_izq.rotation.x = lerpf(_pivot_brazo_izq.rotation.x, -1.2, 0.1)
			_pivot_brazo_der.rotation.x = lerpf(_pivot_brazo_der.rotation.x, -1.2, 0.1)
	elif en_movimiento:
		# --- Animación de caminar ---
		_tiempo_anim += delta * 10.0
		var angulo := sin(_tiempo_anim) * 0.6

		_pivot_pierna_izq.rotation.x = angulo
		_pivot_pierna_der.rotation.x = -angulo
		_pivot_brazo_izq.rotation.x = -angulo * 0.8
		_pivot_brazo_der.rotation.x = angulo * 0.8
	else:
		# --- Volver a posición neutral ---
		_tiempo_anim = 0.0
		_pivot_pierna_izq.rotation.x = lerpf(_pivot_pierna_izq.rotation.x, 0.0, 0.2)
		_pivot_pierna_der.rotation.x = lerpf(_pivot_pierna_der.rotation.x, 0.0, 0.2)
		_pivot_brazo_izq.rotation.x = lerpf(_pivot_brazo_izq.rotation.x, 0.0, 0.2)
		_pivot_brazo_der.rotation.x = lerpf(_pivot_brazo_der.rotation.x, 0.0, 0.2)


# =====================================================================
# AUTO-GENERACIÓN (borrar cuando armes la escena real)
# =====================================================================

func _crear_personaje() -> void:
	if get_node_or_null("Colision"):
		return

	# Materiales reutilizables
	var mat_camiseta := StandardMaterial3D.new()
	mat_camiseta.albedo_color = Color(0.2, 0.35, 0.8)
	var mat_piel := StandardMaterial3D.new()
	mat_piel.albedo_color = Color(0.9, 0.72, 0.55)
	var mat_pantalon := StandardMaterial3D.new()
	mat_pantalon.albedo_color = Color(0.15, 0.15, 0.15)
	var mat_zapato := StandardMaterial3D.new()
	mat_zapato.albedo_color = Color(0.3, 0.15, 0.05)

	# --- Colisión ---
	var colision := CollisionShape3D.new()
	colision.name = "Colision"
	var forma := CapsuleShape3D.new()
	forma.radius = 0.35
	forma.height = 1.8
	colision.shape = forma
	colision.position.y = 0.9
	add_child(colision)

	# --- Modelo (contenedor que rota hacia la dirección de movimiento) ---
	_modelo = Node3D.new()
	_modelo.name = "Modelo"
	add_child(_modelo)

	# Torso
	var torso := MeshInstance3D.new()
	var torso_m := BoxMesh.new()
	torso_m.size = Vector3(0.6, 0.8, 0.3)
	torso_m.material = mat_camiseta
	torso.mesh = torso_m
	torso.position.y = 1.1
	_modelo.add_child(torso)

	# Cabeza
	var cabeza := MeshInstance3D.new()
	var cabeza_m := SphereMesh.new()
	cabeza_m.radius = 0.2
	cabeza_m.height = 0.4
	cabeza_m.material = mat_piel
	cabeza.mesh = cabeza_m
	cabeza.position.y = 1.7
	_modelo.add_child(cabeza)

	# --- Piernas con pivote en la cadera (para animación) ---
	# Pierna izquierda
	_pivot_pierna_izq = Node3D.new()
	_pivot_pierna_izq.position = Vector3(-0.15, 0.7, 0.0)
	_modelo.add_child(_pivot_pierna_izq)
	var pierna_izq := MeshInstance3D.new()
	var pierna_m := BoxMesh.new()
	pierna_m.size = Vector3(0.22, 0.7, 0.25)
	pierna_m.material = mat_pantalon
	pierna_izq.mesh = pierna_m
	pierna_izq.position.y = -0.35  # Offset hacia abajo desde el pivote
	_pivot_pierna_izq.add_child(pierna_izq)
	# Zapato izquierdo
	var zapato_izq := MeshInstance3D.new()
	var zapato_m := BoxMesh.new()
	zapato_m.size = Vector3(0.24, 0.12, 0.35)
	zapato_m.material = mat_zapato
	zapato_izq.mesh = zapato_m
	zapato_izq.position = Vector3(0.0, -0.7, 0.05)
	_pivot_pierna_izq.add_child(zapato_izq)

	# Pierna derecha
	_pivot_pierna_der = Node3D.new()
	_pivot_pierna_der.position = Vector3(0.15, 0.7, 0.0)
	_modelo.add_child(_pivot_pierna_der)
	var pierna_der := MeshInstance3D.new()
	pierna_der.mesh = pierna_m
	pierna_der.position.y = -0.35
	_pivot_pierna_der.add_child(pierna_der)
	var zapato_der := MeshInstance3D.new()
	zapato_der.mesh = zapato_m
	zapato_der.position = Vector3(0.0, -0.7, 0.05)
	_pivot_pierna_der.add_child(zapato_der)

	# --- Brazos con pivote en el hombro ---
	# Brazo izquierdo
	_pivot_brazo_izq = Node3D.new()
	_pivot_brazo_izq.position = Vector3(-0.4, 1.4, 0.0)
	_modelo.add_child(_pivot_brazo_izq)
	var brazo_izq := MeshInstance3D.new()
	var brazo_m := BoxMesh.new()
	brazo_m.size = Vector3(0.15, 0.55, 0.18)
	brazo_m.material = mat_camiseta
	brazo_izq.mesh = brazo_m
	brazo_izq.position.y = -0.3
	_pivot_brazo_izq.add_child(brazo_izq)
	# Mano izquierda
	var mano_izq := MeshInstance3D.new()
	var mano_m := SphereMesh.new()
	mano_m.radius = 0.08
	mano_m.height = 0.16
	mano_m.material = mat_piel
	mano_izq.mesh = mano_m
	mano_izq.position.y = -0.58
	_pivot_brazo_izq.add_child(mano_izq)

	# Brazo derecho
	_pivot_brazo_der = Node3D.new()
	_pivot_brazo_der.position = Vector3(0.4, 1.4, 0.0)
	_modelo.add_child(_pivot_brazo_der)
	var brazo_der := MeshInstance3D.new()
	brazo_der.mesh = brazo_m
	brazo_der.position.y = -0.3
	_pivot_brazo_der.add_child(brazo_der)
	var mano_der := MeshInstance3D.new()
	mano_der.mesh = mano_m
	mano_der.position.y = -0.58
	_pivot_brazo_der.add_child(mano_der)


func _crear_escena_prueba() -> void:
	var padre := get_parent()
	if padre == null or padre.get_node_or_null("Suelo"):
		return

	position.y = 1.0

	# --- Suelo (césped) ---
	var suelo := StaticBody3D.new()
	suelo.name = "Suelo"
	var col_suelo := CollisionShape3D.new()
	var forma_suelo := BoxShape3D.new()
	forma_suelo.size = Vector3(40.0, 0.2, 40.0)
	col_suelo.shape = forma_suelo
	suelo.add_child(col_suelo)
	var mesh_suelo := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(40.0, 0.2, 40.0)
	var mat_suelo := StandardMaterial3D.new()
	mat_suelo.albedo_color = Color(0.3, 0.6, 0.25)
	box.material = mat_suelo
	mesh_suelo.mesh = box
	suelo.add_child(mesh_suelo)
	padre.add_child(suelo)

	# --- Camino de tierra principal ---
	var mat_camino := StandardMaterial3D.new()
	mat_camino.albedo_color = Color(0.55, 0.4, 0.25)
	var camino := MeshInstance3D.new()
	var camino_m := BoxMesh.new()
	camino_m.size = Vector3(3.0, 0.02, 40.0)
	camino_m.material = mat_camino
	camino.mesh = camino_m
	camino.position.y = 0.11
	padre.add_child(camino)

	# Camino lateral (cruce)
	var camino2 := MeshInstance3D.new()
	var camino2_m := BoxMesh.new()
	camino2_m.size = Vector3(40.0, 0.02, 3.0)
	camino2_m.material = mat_camino
	camino2.mesh = camino2_m
	camino2.position.y = 0.11
	padre.add_child(camino2)

	# --- Casa (cerca del cruce) ---
	_crear_casa(padre, Vector3(7.0, 0.0, -6.0))

	# --- Árboles repartidos por el mapa ---
	var posiciones_arboles := [
		Vector3(-6.0, 0.0, -5.0), Vector3(-8.0, 0.0, 3.0),
		Vector3(7.0, 0.0, -14.0), Vector3(5.0, 0.0, 8.0),
		Vector3(-4.0, 0.0, -12.0), Vector3(12.0, 0.0, -3.0),
		Vector3(-10.0, 0.0, 8.0), Vector3(-6.0, 0.0, 12.0),
		Vector3(-12.0, 0.0, -9.0), Vector3(14.0, 0.0, 7.0),
		Vector3(-14.0, 0.0, -2.0), Vector3(10.0, 0.0, 13.0),
	]
	for pos in posiciones_arboles:
		_crear_arbol(padre, pos)

	# --- Rocas ---
	var mat_roca := StandardMaterial3D.new()
	mat_roca.albedo_color = Color(0.5, 0.5, 0.48)
	var posiciones_rocas := [
		Vector3(-3.0, 0.0, 4.0), Vector3(4.0, 0.0, -3.0),
		Vector3(-5.0, 0.0, -2.0), Vector3(11.0, 0.0, 2.0),
		Vector3(-9.0, 0.0, -7.0), Vector3(3.0, 0.0, 10.0),
	]
	for pos in posiciones_rocas:
		var roca := MeshInstance3D.new()
		var roca_m := SphereMesh.new()
		roca_m.radius = 0.25 + randf() * 0.2
		roca_m.height = roca_m.radius * 1.4
		roca_m.material = mat_roca
		roca.mesh = roca_m
		roca.position = Vector3(pos.x, 0.15, pos.z)
		roca.scale = Vector3(1.0, 0.6, 1.0)
		padre.add_child(roca)

	# --- Valla alrededor del mapa ---
	_crear_valla(padre)

	# --- Cámara ---
	var camara := Camera3D.new()
	camara.name = "Camara"
	camara.position = Vector3(0.0, 5.0, 8.0)
	camara.rotation.x = deg_to_rad(-28.0)
	add_child(camara)

	# --- Luz solar ---
	var luz := DirectionalLight3D.new()
	luz.name = "Luz"
	luz.rotation.x = deg_to_rad(-50.0)
	luz.rotation.y = deg_to_rad(-30.0)
	luz.shadow_enabled = true
	luz.light_energy = 1.2
	padre.add_child(luz)

	# --- Luz ambiente extra para que no quede oscuro ---
	var luz2 := DirectionalLight3D.new()
	luz2.rotation.x = deg_to_rad(-30.0)
	luz2.rotation.y = deg_to_rad(120.0)
	luz2.light_energy = 0.4
	padre.add_child(luz2)

	# --- Fondo cielo azul ---
	var env := WorldEnvironment.new()
	env.name = "Ambiente"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.45, 0.7, 0.95)
	env.environment = environment
	padre.add_child(env)


func _crear_arbol(padre: Node, pos: Vector3) -> void:
	var arbol := Node3D.new()
	arbol.position = pos

	# Tronco
	var tronco := MeshInstance3D.new()
	var tronco_m := CylinderMesh.new()
	tronco_m.top_radius = 0.12
	tronco_m.bottom_radius = 0.2
	tronco_m.height = 2.2
	var mat_tronco := StandardMaterial3D.new()
	mat_tronco.albedo_color = Color(0.4, 0.28, 0.12)
	tronco_m.material = mat_tronco
	tronco.mesh = tronco_m
	tronco.position.y = 1.1
	arbol.add_child(tronco)

	# Copa
	var copa := MeshInstance3D.new()
	var copa_m := SphereMesh.new()
	copa_m.radius = 1.0
	copa_m.height = 1.8
	var mat_copa := StandardMaterial3D.new()
	mat_copa.albedo_color = Color(0.18, 0.5, 0.15)
	copa_m.material = mat_copa
	copa.mesh = copa_m
	copa.position.y = 2.8
	arbol.add_child(copa)

	padre.add_child(arbol)


func _crear_casa(padre: Node, pos: Vector3) -> void:
	var casa := Node3D.new()
	casa.name = "Casa"
	casa.position = pos

	# Materiales
	var mat_pared := StandardMaterial3D.new()
	mat_pared.albedo_color = Color(0.85, 0.78, 0.65)
	var mat_techo := StandardMaterial3D.new()
	mat_techo.albedo_color = Color(0.6, 0.2, 0.15)
	var mat_puerta := StandardMaterial3D.new()
	mat_puerta.albedo_color = Color(0.35, 0.2, 0.1)
	var mat_ventana := StandardMaterial3D.new()
	mat_ventana.albedo_color = Color(0.5, 0.75, 0.9)
	var mat_chimenea := StandardMaterial3D.new()
	mat_chimenea.albedo_color = Color(0.45, 0.3, 0.25)

	# --- Paredes (cuerpo principal) ---
	var paredes := MeshInstance3D.new()
	var paredes_m := BoxMesh.new()
	paredes_m.size = Vector3(4.0, 2.5, 3.5)
	paredes_m.material = mat_pared
	paredes.mesh = paredes_m
	paredes.position.y = 1.25
	casa.add_child(paredes)

	# Colisión de la casa (para no atravesarla)
	var col_casa := StaticBody3D.new()
	col_casa.position = pos
	var col_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(4.0, 2.5, 3.5)
	col_shape.shape = box_shape
	col_shape.position.y = 1.25
	col_casa.add_child(col_shape)
	padre.add_child(col_casa)

	# --- Techo (prisma triangular con un box rotado) ---
	var techo := MeshInstance3D.new()
	var techo_m := BoxMesh.new()
	techo_m.size = Vector3(4.4, 0.15, 2.8)
	techo_m.material = mat_techo
	techo.mesh = techo_m
	techo.position = Vector3(-0.7, 2.8, 0.0)
	techo.rotation.z = deg_to_rad(25.0)
	casa.add_child(techo)

	var techo2 := MeshInstance3D.new()
	techo2.mesh = techo_m
	techo2.position = Vector3(0.7, 2.8, 0.0)
	techo2.rotation.z = deg_to_rad(-25.0)
	casa.add_child(techo2)

	# Cumbrera (parte superior del techo)
	var cumbrera := MeshInstance3D.new()
	var cumbrera_m := BoxMesh.new()
	cumbrera_m.size = Vector3(0.3, 0.15, 2.8)
	cumbrera_m.material = mat_techo
	cumbrera.mesh = cumbrera_m
	cumbrera.position.y = 3.1
	casa.add_child(cumbrera)

	# --- Puerta ---
	var puerta := MeshInstance3D.new()
	var puerta_m := BoxMesh.new()
	puerta_m.size = Vector3(0.7, 1.5, 0.05)
	puerta_m.material = mat_puerta
	puerta.mesh = puerta_m
	puerta.position = Vector3(0.0, 0.75, 1.76)
	casa.add_child(puerta)

	# --- Ventanas ---
	# Ventana izquierda
	var ventana1 := MeshInstance3D.new()
	var ventana_m := BoxMesh.new()
	ventana_m.size = Vector3(0.6, 0.6, 0.05)
	ventana_m.material = mat_ventana
	ventana1.mesh = ventana_m
	ventana1.position = Vector3(-1.2, 1.5, 1.76)
	casa.add_child(ventana1)

	# Ventana derecha
	var ventana2 := MeshInstance3D.new()
	ventana2.mesh = ventana_m
	ventana2.position = Vector3(1.2, 1.5, 1.76)
	casa.add_child(ventana2)

	# Ventana lateral
	var ventana3 := MeshInstance3D.new()
	ventana3.mesh = ventana_m
	ventana3.position = Vector3(2.01, 1.5, 0.0)
	ventana3.rotation.y = deg_to_rad(90.0)
	casa.add_child(ventana3)

	# --- Chimenea ---
	var chimenea := MeshInstance3D.new()
	var chimenea_m := BoxMesh.new()
	chimenea_m.size = Vector3(0.5, 1.2, 0.5)
	chimenea_m.material = mat_chimenea
	chimenea.mesh = chimenea_m
	chimenea.position = Vector3(-1.2, 3.2, 0.0)
	casa.add_child(chimenea)

	padre.add_child(casa)


func _crear_valla(padre: Node) -> void:
	var mat_valla := StandardMaterial3D.new()
	mat_valla.albedo_color = Color(0.5, 0.35, 0.18)
	var limite := 18.0

	# Crear postes y tablones en los 4 lados
	for lado in 4:
		for i in range(-18, 19, 2):
			var poste := MeshInstance3D.new()
			var poste_m := CylinderMesh.new()
			poste_m.top_radius = 0.05
			poste_m.bottom_radius = 0.06
			poste_m.height = 0.8
			poste_m.material = mat_valla
			poste.mesh = poste_m

			match lado:
				0: poste.position = Vector3(float(i), 0.4, -limite)
				1: poste.position = Vector3(float(i), 0.4, limite)
				2: poste.position = Vector3(-limite, 0.4, float(i))
				3: poste.position = Vector3(limite, 0.4, float(i))

			padre.add_child(poste)

	# Tablones horizontales (2 alturas, 4 lados)
	for altura in [0.25, 0.55]:
		for lado in 4:
			var tablon := MeshInstance3D.new()
			var tablon_m := BoxMesh.new()
			tablon_m.material = mat_valla

			match lado:
				0:
					tablon_m.size = Vector3(36.0, 0.08, 0.04)
					tablon.position = Vector3(0.0, altura, -limite)
				1:
					tablon_m.size = Vector3(36.0, 0.08, 0.04)
					tablon.position = Vector3(0.0, altura, limite)
				2:
					tablon_m.size = Vector3(0.04, 0.08, 36.0)
					tablon.position = Vector3(-limite, altura, 0.0)
				3:
					tablon_m.size = Vector3(0.04, 0.08, 36.0)
					tablon.position = Vector3(limite, altura, 0.0)

			tablon.mesh = tablon_m
			padre.add_child(tablon)
