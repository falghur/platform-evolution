
extends Area2D

# ==================================
# ESTADOS DO INIMIGO
# ==================================

enum EnemyState {
	PATROL,
	CHASE,
	ATTACK
}

var current_state: EnemyState = EnemyState.PATROL


# ==================================
# MOVIMENTAÇÃO
# ==================================

@export var patrol_speed: float = 70.0
@export var chase_speed: float = 150.0

@export var patrol_distance: float = 100.0
@export var detection_distance: float = 300.0
@export var vertical_detection: float = 120.0

var start_x: float = 0.0
var direction: float = 1.0


# ==================================
# VIDA
# ==================================

@export var max_health: int = 2

var current_health: int = 2
var is_dead: bool = false


# ==================================
# DANO
# ==================================

@export var damage: int = 1


# ==================================
# EFEITOS
# ==================================

var hit_flash_remaining: float = 0.0
var death_timer: float = 0.0


# ==================================
# REFERÊNCIAS
# ==================================

@onready var player: Player = (
	get_parent().get_node_or_null("player") as Player
)

@onready var visual: ColorRect = $ColorRect

@onready var hurtbox_shape: CollisionShape2D = (
	$CollisionShape2D
)

@onready var contact_hitbox: Area2D = $ContactHitbox

@onready var contact_shape: CollisionShape2D = (
	$ContactHitbox/CollisionShape2D
)


# ==================================
# INICIALIZAÇÃO
# ==================================

func _ready() -> void:
	start_x = global_position.x
	current_health = maxi(max_health, 1)

	add_to_group("enemies")

	configure_combat_areas()

	if player == null:
		push_error("Player não encontrado!")
		return

	print("Inimigo preparado! HP: ", current_health)


# ==================================
# CONFIGURAR ÁREAS FÍSICAS
# ==================================

func configure_combat_areas() -> void:
	# O próprio Enemy será sua Hurtbox
	# Camada 4: inimigos

	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(4, true)

	monitorable = true
	monitoring = false

	var hurt_rect := RectangleShape2D.new()
	hurt_rect.size = Vector2(28, 28)

	hurtbox_shape.shape = hurt_rect
	hurtbox_shape.position = Vector2.ZERO
	hurtbox_shape.disabled = false

	# ContactHitbox detecta a Hurtbox
	# do jogador, que está na camada 3.

	contact_hitbox.position = Vector2.ZERO
	contact_hitbox.collision_layer = 0
	contact_hitbox.collision_mask = 0
	contact_hitbox.set_collision_mask_value(3, true)

	contact_hitbox.monitoring = true
	contact_hitbox.monitorable = false

	var contact_rect := RectangleShape2D.new()
	contact_rect.size = Vector2(32, 34)

	contact_shape.shape = contact_rect
	contact_shape.position = Vector2.ZERO
	contact_shape.disabled = false


# ==================================
# ATUALIZAÇÃO FÍSICA
# ==================================

func _physics_process(delta: float) -> void:
	if is_dead:
		update_death(delta)
		return

	update_hit_feedback(delta)

	if player == null:
		patrol(delta)
		return

	update_ai_state()

	match current_state:
		EnemyState.PATROL:
			patrol(delta)

		EnemyState.CHASE:
			chase_player(delta)

		EnemyState.ATTACK:
			attack_player()


# ==================================
# VERIFICAR CONTATO FÍSICO
# ==================================

func is_touching_player() -> bool:
	return contact_hitbox.overlaps_area(
		player.hurtbox
	)


# ==================================
# MÁQUINA DE ESTADOS
# ==================================

func update_ai_state() -> void:
	# Contato físico tem prioridade
	if is_touching_player():
		current_state = EnemyState.ATTACK
		return

	var distance_x: float = absf(
		player.global_position.x - global_position.x
	)

	var distance_y: float = absf(
		player.global_position.y - global_position.y
	)

	if (
		distance_x <= detection_distance
		and distance_y <= vertical_detection
	):
		current_state = EnemyState.CHASE
	else:
		current_state = EnemyState.PATROL


# ==================================
# PATRULHA
# ==================================

func patrol(delta: float) -> void:
	global_position.x += (
		direction * patrol_speed * delta
	)

	if global_position.x >= start_x + patrol_distance:
		global_position.x = start_x + patrol_distance
		direction = -1.0

	elif global_position.x <= start_x - patrol_distance:
		global_position.x = start_x - patrol_distance
		direction = 1.0


# ==================================
# PERSEGUIÇÃO
# ==================================

func chase_player(delta: float) -> void:
	var difference: float = (
		player.global_position.x - global_position.x
	)

	if absf(difference) <= 4.0:
		return

	direction = signf(difference)

	var step: float = minf(
		chase_speed * delta,
		absf(difference)
	)

	global_position.x += direction * step


# ==================================
# ATAQUE DO INIMIGO
# ==================================

func attack_player() -> void:
	if player.is_invulnerable:
		return

	if not is_touching_player():
		return

	player.take_damage(
		damage,
		global_position
	)


# ==================================
# RECEBER DANO
# ==================================

func take_damage(amount: int = 1) -> void:
	if is_dead:
		return

	if amount <= 0:
		return

	current_health = maxi(
		current_health - amount,
		0
	)

	hit_flash_remaining = 0.15

	print("Inimigo recebeu dano! HP: ", current_health)

	if current_health <= 0:
		die()


# ==================================
# FEEDBACK VISUAL
# ==================================

func update_hit_feedback(delta: float) -> void:
	if hit_flash_remaining > 0.0:
		hit_flash_remaining -= delta

		visual.modulate = Color(
			1.0, 1.0, 1.0, 0.35
		)
	else:
		visual.modulate = Color.WHITE


# ==================================
# MORTE
# ==================================

func die() -> void:
	if is_dead:
		return

	is_dead = true
	death_timer = 0.25

	# Impede novos golpes durante a morte
	remove_from_group("enemies")

	print("Inimigo derrotado!")


# ==================================
# DESAPARECIMENTO
# ==================================

func update_death(delta: float) -> void:
	death_timer -= delta

	var opacity: float = clampf(
		death_timer / 0.25,
		0.0,
		1.0
	)

	visual.modulate = Color(
		1.0,
		1.0,
		1.0,
		opacity
	)

	if death_timer <= 0.0:
		queue_free()
