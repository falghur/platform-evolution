
extends CharacterBody2D
class_name Player

# ==================================
# ESTADOS DO PERSONAGEM
# ==================================

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL
}

var current_state: State = State.IDLE


# ==================================
# MOVIMENTAÇÃO
# ==================================

@export var speed: float = 220.0
@export var jump_velocity: float = -480.0

@export var gravity_up: float = 1000.0
@export var gravity_down: float = 1800.0

var facing_direction: float = 1.0


# ==================================
# VIDA
# ==================================

signal health_changed(current: int, maximum: int)

@export var max_health: int = 3
@export var invulnerability_seconds: float = 1.2

var current_health: int = 3
var is_invulnerable: bool = false
var invulnerability_remaining: float = 0.0


# ==================================
# CHECKPOINTS E QUEDAS
# ==================================

signal checkpoint_changed(new_position: Vector2)

@export var fall_limit_y: float = 650.0

var checkpoint_position: Vector2


# ==================================
# MOEDAS
# ==================================

signal coins_changed(total: int)

var coins: int = 0


# ==================================
# ATAQUE
# ==================================

signal attack_started

@export var attack_damage: int = 1
@export var attack_cooldown: float = 0.4

@export var attack_duration: float = 0.24
@export var attack_windup: float = 0.05
@export var attack_active_time: float = 0.12

var attack_cooldown_remaining: float = 0.0
var attack_time_remaining: float = 0.0

var enemies_hit: Array[int] = []


# ==================================
# KNOCKBACK
# ==================================

@export var knockback_speed: float = 260.0
@export var knockback_upward: float = 180.0
@export var knockback_duration: float = 0.2

var knockback_remaining: float = 0.0
var knockback_velocity_x: float = 0.0


# ==================================
# REFERÊNCIAS
# ==================================

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D

@onready var hurtbox: Area2D = $Hurtbox

@onready var hurtbox_shape: CollisionShape2D = (
	$Hurtbox/CollisionShape2D
)

@onready var attack_hitbox: Area2D = $AttackHitbox

@onready var attack_shape: CollisionShape2D = (
	$AttackHitbox/CollisionShape2D
)

var slash_effect: Line2D
var base_visual_scale: Vector2 = Vector2.ONE


# ==================================
# INICIALIZAÇÃO
# ==================================

func _ready() -> void:
	# O começo da fase é o primeiro checkpoint
	checkpoint_position = global_position

	current_health = max_health
	base_visual_scale = visual.scale

	visual.rotation = 0.0
	visual.modulate = Color.WHITE
	visual.play("idle")

	configure_combat_areas()
	create_slash_effect()


# ==================================
# CONFIGURAR ÁREAS DE COMBATE
# ==================================

func configure_combat_areas() -> void:
	# Hurtbox do jogador: camada 3
	hurtbox.position = Vector2.ZERO
	hurtbox.collision_layer = 0
	hurtbox.collision_mask = 0

	hurtbox.set_collision_layer_value(3, true)

	hurtbox.monitorable = true
	hurtbox.monitoring = false

	var hurt_rect := RectangleShape2D.new()
	hurt_rect.size = Vector2(20, 28)

	hurtbox_shape.shape = hurt_rect
	hurtbox_shape.position = Vector2(0, 10)
	hurtbox_shape.disabled = false

	# Hitbox do ataque: detecta camada 4
	attack_hitbox.collision_layer = 0
	attack_hitbox.collision_mask = 0

	attack_hitbox.set_collision_mask_value(4, true)

	attack_hitbox.monitoring = true
	attack_hitbox.monitorable = false

	var attack_rect := RectangleShape2D.new()
	attack_rect.size = Vector2(50, 36)

	attack_shape.shape = attack_rect
	attack_shape.position = Vector2.ZERO
	attack_shape.disabled = false

	update_attack_position()


# ==================================
# EFEITO VISUAL DO ATAQUE
# ==================================

func create_slash_effect() -> void:
	slash_effect = Line2D.new()
	slash_effect.name = "SlashEffect"

	slash_effect.points = PackedVector2Array([
		Vector2(10, -22),
		Vector2(26, -21),
		Vector2(40, -9),
		Vector2(42, 7),
		Vector2(31, 22)
	])

	slash_effect.width = 6.0

	slash_effect.default_color = Color(
		1.0, 0.85, 0.35, 1.0
	)

	slash_effect.z_index = 10
	slash_effect.visible = false

	add_child(slash_effect)


# ==================================
# ATUALIZAÇÃO FÍSICA
# ==================================

func _physics_process(delta: float) -> void:
	update_timers(delta)

	apply_gravity(delta)
	handle_jump()
	handle_movement()

	move_and_slide()

	# NOVO: verifica se caiu para fora do mapa
	if global_position.y > fall_limit_y:
		trigger_hazard(1)
		return

	update_state()
	update_attack_position()

	handle_attack()
	process_attack_hits()

	update_visual_feedback()
	update_attack_visual()


# ==================================
# TEMPORIZADORES
# ==================================

func update_timers(delta: float) -> void:
	attack_cooldown_remaining = maxf(
		0.0,
		attack_cooldown_remaining - delta
	)

	attack_time_remaining = maxf(
		0.0,
		attack_time_remaining - delta
	)

	knockback_remaining = maxf(
		0.0,
		knockback_remaining - delta
	)

	if is_invulnerable:
		invulnerability_remaining -= delta

		if invulnerability_remaining <= 0.0:
			invulnerability_remaining = 0.0
			is_invulnerable = false


# ==================================
# GRAVIDADE
# ==================================

func apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	if velocity.y < 0.0:
		velocity.y += gravity_up * delta
	else:
		velocity.y += gravity_down * delta


# ==================================
# PULO
# ==================================

func handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_velocity


# ==================================
# MOVIMENTO HORIZONTAL
# ==================================

func handle_movement() -> void:
	if knockback_remaining > 0.0:
		velocity.x = knockback_velocity_x
		return

	var direction: float = Input.get_axis(
		"move_left",
		"move_right"
	)

	velocity.x = direction * speed

	if direction > 0.0:
		facing_direction = 1.0
		visual.flip_h = false

	elif direction < 0.0:
		facing_direction = -1.0
		visual.flip_h = true


# ==================================
# ESTADOS DO PERSONAGEM
# ==================================

func update_state() -> void:
	var new_state: State = State.IDLE

	if not is_on_floor():
		if velocity.y < 0.0:
			new_state = State.JUMP
		else:
			new_state = State.FALL

	elif absf(velocity.x) > 1.0:
		new_state = State.RUN

	if new_state != current_state:
		current_state = new_state
		update_animation()


# ==================================
# ANIMAÇÕES
# ==================================

func update_animation() -> void:
	match current_state:
		State.IDLE:
			visual.play("idle")

		State.RUN:
			visual.play("run")

		State.JUMP:
			visual.play("jump")

		State.FALL:
			visual.play("fall")


# ==================================
# POSICIONAR HITBOX
# ==================================

func update_attack_position() -> void:
	attack_hitbox.position = Vector2(
		facing_direction * 33.0,
		10.0
	)


# ==================================
# INICIAR ATAQUE
# ==================================

func handle_attack() -> void:
	if not Input.is_action_just_pressed("attack"):
		return

	if attack_cooldown_remaining > 0.0:
		return

	attack_cooldown_remaining = attack_cooldown
	attack_time_remaining = attack_duration

	enemies_hit.clear()
	attack_started.emit()

	print("Ataque iniciado!")


# ==================================
# JANELA ATIVA DO ATAQUE
# ==================================

func is_attack_active() -> bool:
	if attack_time_remaining <= 0.0:
		return false

	var elapsed: float = (
		attack_duration - attack_time_remaining
	)

	if elapsed < attack_windup:
		return false

	if elapsed >= attack_windup + attack_active_time:
		return false

	return true


# ==================================
# DETECÇÃO DE ACERTOS
# ==================================

func process_attack_hits() -> void:
	if not is_attack_active():
		return

	for area: Area2D in attack_hitbox.get_overlapping_areas():
		if not area.is_in_group("enemies"):
			continue

		if area.is_queued_for_deletion():
			continue

		var relative_x: float = (
			area.global_position.x - global_position.x
		)

		if relative_x * facing_direction < -4.0:
			continue

		var enemy_id: int = area.get_instance_id()

		if enemies_hit.has(enemy_id):
			continue

		if area.has_method("take_damage"):
			enemies_hit.append(enemy_id)

			area.call(
				"take_damage",
				attack_damage
			)

			print("Golpe acertou: ", area.name)


# ==================================
# ANIMAÇÃO DO ATAQUE
# ==================================

func update_attack_visual() -> void:
	if attack_time_remaining <= 0.0:
		slash_effect.visible = false
		visual.scale = base_visual_scale
		return

	var progress: float = clampf(
		(attack_duration - attack_time_remaining)
		/ maxf(attack_duration, 0.01),
		0.0,
		1.0
	)

	var pulse: float = sin(progress * PI)

	visual.scale = Vector2(
		base_visual_scale.x * (1.0 + pulse * 0.15),
		base_visual_scale.y * (1.0 - pulse * 0.10)
	)

	slash_effect.visible = true

	slash_effect.position = Vector2(
		facing_direction * 13.0,
		10.0
	)

	slash_effect.scale = Vector2(
		facing_direction * (0.7 + progress * 0.3),
		0.7 + progress * 0.3
	)

	slash_effect.rotation = lerpf(
		-0.45,
		0.55,
		progress
	) * facing_direction

	slash_effect.modulate = Color(
		1.0,
		1.0,
		1.0,
		1.0 - progress
	)


# ==================================
# FEEDBACK VISUAL
# ==================================

func update_visual_feedback() -> void:
	if is_invulnerable:
		visual.modulate = Color(
			1.0, 0.4, 0.4
		)

	elif attack_time_remaining > 0.0:
		visual.modulate = Color(
			1.0, 0.95, 0.75
		)

	else:
		visual.modulate = Color.WHITE


# ==================================
# COLETA DE MOEDAS
# ==================================

func collect_coin(amount: int = 1) -> void:
	coins += amount
	coins_changed.emit(coins)


# ==================================
# RECEBIMENTO DE DANO
# ==================================

func take_damage(
	amount: int = 1,
	source_position: Vector2 = Vector2.ZERO
) -> void:
	if is_invulnerable:
		return

	if amount <= 0:
		return

	is_invulnerable = true
	invulnerability_remaining = invulnerability_seconds

	current_health = maxi(
		current_health - amount,
		0
	)

	health_changed.emit(
		current_health,
		max_health
	)

	print("Player recebeu dano! HP: ", current_health)

	if source_position != Vector2.ZERO:
		apply_knockback(source_position)

	if current_health <= 0:
		respawn()


# ==================================
# KNOCKBACK
# ==================================

func apply_knockback(source_position: Vector2) -> void:
	var push_direction: float = signf(
		global_position.x - source_position.x
	)

	if is_zero_approx(push_direction):
		push_direction = -facing_direction

	knockback_velocity_x = (
		push_direction * knockback_speed
	)

	knockback_remaining = knockback_duration

	velocity.y = minf(
		velocity.y,
		-knockback_upward
	)


# ==================================
# NOVO: ATIVAR CHECKPOINT
# ==================================

func activate_checkpoint(new_position: Vector2) -> void:
	if checkpoint_position.distance_to(new_position) < 1.0:
		return

	checkpoint_position = new_position

	checkpoint_changed.emit(checkpoint_position)

	print("Novo checkpoint: ", checkpoint_position)


# ==================================
# NOVO: RECEBER DANO DE ARMADILHA
# ==================================

func trigger_hazard(amount: int = 1) -> void:
	if amount <= 0:
		return

	# Mesmo invulnerável, não deixamos
	# o personagem preso na armadilha.
	if is_invulnerable:
		return_to_checkpoint()
		return

	is_invulnerable = true
	invulnerability_remaining = invulnerability_seconds

	# Perde vida
	current_health = maxi(
		current_health - amount,
		0
	)

	health_changed.emit(
		current_health,
		max_health
	)

	print("Armadilha! HP: ", current_health)

	# Se perdeu toda a vida, restaura o HP
	if current_health <= 0:
		respawn()
	else:
		return_to_checkpoint()


# ==================================
# NOVO: VOLTAR AO CHECKPOINT
# ==================================

func return_to_checkpoint() -> void:
	# Retorna ao último ponto salvo
	global_position = checkpoint_position

	# Cancela movimentações anteriores
	velocity = Vector2.ZERO

	knockback_remaining = 0.0
	knockback_velocity_x = 0.0

	# Cancela o ataque em andamento
	attack_time_remaining = 0.0
	attack_cooldown_remaining = 0.0

	enemies_hit.clear()

	# Restaura o visual
	visual.scale = base_visual_scale
	visual.rotation = 0.0

	if slash_effect != null:
		slash_effect.visible = false

	current_state = State.IDLE
	visual.play("idle")

	print("Retornou ao checkpoint!")


# ==================================
# REAPARECIMENTO APÓS MORTE
# ==================================

func respawn() -> void:
	print("Personagem derrotado!")

	# Restaura a vida
	current_health = max_health

	health_changed.emit(
		current_health,
		max_health
	)

	# Volta ao último checkpoint
	return_to_checkpoint()
