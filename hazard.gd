
extends Area2D

# ==================================
# CONFIGURAÇÕES
# ==================================

@export var damage: int = 1


# ==================================
# INICIALIZAÇÃO
# ==================================

func _ready() -> void:
	# Detecta o Player na camada 1
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(1, true)

	monitoring = true

	body_entered.connect(_on_body_entered)


# ==================================
# CONTATO COM O JOGADOR
# ==================================

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	print("Jogador tocou uma armadilha!")

	# Agenda o dano após o processamento
	# atual de colisões.
	body.call_deferred(
		"trigger_hazard",
		damage
	)
