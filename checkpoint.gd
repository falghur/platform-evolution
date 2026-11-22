
extends Area2D

# ==================================
# CONFIGURAÇÕES
# ==================================

@export var respawn_offset: Vector2 = Vector2(0, -10)

var activated: bool = false


# ==================================
# REFERÊNCIAS
# ==================================

@onready var visual: ColorRect = $ColorRect


# ==================================
# INICIALIZAÇÃO
# ==================================

func _ready() -> void:
	# Detecta corpos na camada 1
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(1, true)

	monitoring = true

	# Cor do checkpoint inativo
	visual.color = Color("#808080")

	# Conecta o sinal de entrada
	body_entered.connect(_on_body_entered)


# ==================================
# ATIVAÇÃO DO CHECKPOINT
# ==================================

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	var player: Player = body as Player

	# Salva a nova posição de respawn
	var new_position: Vector2 = (
		global_position + respawn_offset
	)

	player.activate_checkpoint(new_position)

	# Atualiza a aparência
	activated = true
	visual.color = Color("#22c55e")

	print("Checkpoint ativado!")
