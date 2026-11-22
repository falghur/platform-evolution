
extends Area2D

# ==================================
# CONFIGURAÇÕES DA MOEDA
# ==================================

@export var value: int = 1


# ==================================
# INICIALIZAÇÃO
# ==================================

func _ready() -> void:
	body_entered.connect(_on_body_entered)


# ==================================
# DETECÇÃO DA COLETA
# ==================================

func _on_body_entered(body: Node2D) -> void:
	# Verifica se a moeda já será removida
	if is_queued_for_deletion():
		return

	# Verifica se o corpo é um personagem
	# e possui a função de coletar moedas
	if body is CharacterBody2D and body.has_method("collect_coin"):

		# Entrega os pontos ao personagem
		body.call("collect_coin", value)

		# Remove a moeda do cenário
		queue_free()
