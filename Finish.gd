
extends Area2D
class_name LevelFinish

# ==================================
# SINAIS
# ==================================

signal level_reached


# ==================================
# CONTROLE
# ==================================

var activated: bool = false


# ==================================
# INICIALIZAÇÃO
# ==================================

func _ready() -> void:
	# A chegada detecta o corpo do Player
	# que está na camada física 1.
	collision_layer = 0
	collision_mask = 0

	set_collision_mask_value(1, true)

	monitoring = true

	# Conecta o sinal de contato
	body_entered.connect(_on_body_entered)


# ==================================
# DETECÇÃO DO JOGADOR
# ==================================

func _on_body_entered(body: Node2D) -> void:
	# Evita ativar a chegada duas vezes
	if activated:
		return

	# Somente o Player conclui a fase
	if not body is Player:
		return

	activated = true

	print("Linha de chegada alcançada!")

	# Avisa que a fase foi concluída
	level_reached.emit()
