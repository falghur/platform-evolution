
extends Node2D

# ==================================
# CONFIGURAÇÕES DA FASE
# ==================================

@export var level_number: int = 1

@export_file("*.tscn")
var next_level_scene: String = ""


# ==================================
# CONTROLE
# ==================================

var is_level_finished: bool = false


# ==================================
# REFERÊNCIAS DO JOGADOR E HUD
# ==================================

@onready var player: Player = (
	get_node_or_null("player") as Player
)

@onready var coin_label: Label = (
	get_node_or_null("HUD/CoinLabel") as Label
)

@onready var health_label: Label = (
	get_node_or_null("HUD/HealthLabel") as Label
)


# ==================================
# LINHA DE CHEGADA
# ==================================

@onready var finish: LevelFinish = (
	get_node_or_null("Finish") as LevelFinish
)


# ==================================
# INTERFACE DE VITÓRIA
# ==================================

@onready var victory_panel: PanelContainer = (
	get_node_or_null("HUD/VictoryPanel")
	as PanelContainer
)

@onready var victory_label: Label = (
	get_node_or_null(
		"HUD/VictoryPanel/VBoxContainer/VictoryLabel"
	) as Label
)

@onready var next_button: Button = (
	get_node_or_null(
		"HUD/VictoryPanel/VBoxContainer/NextButton"
	) as Button
)

@onready var retry_button: Button = (
	get_node_or_null(
		"HUD/VictoryPanel/VBoxContainer/RetryButton"
	) as Button
)


# ==================================
# INICIALIZAÇÃO
# ==================================

func _ready() -> void:
	get_tree().paused = false

	# Verifica referências existentes
	if player == null:
		push_error("Nó 'player' não encontrado!")
		return

	if coin_label == null:
		push_error("HUD/CoinLabel não encontrado!")
		return

	if health_label == null:
		push_error("HUD/HealthLabel não encontrado!")
		return

	if finish == null:
		push_error("Nó 'Finish' não encontrado!")
		return

	if (
		victory_panel == null
		or victory_label == null
		or next_button == null
		or retry_button == null
	):
		push_error(
			"Interface VictoryPanel incompleta!"
		)
		return

	# ----------------------------------
	# Configuração do painel
	# ----------------------------------

	# Permite usar os botões com o
	# restante do jogo pausado.
	victory_panel.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	victory_panel.custom_minimum_size = (
		Vector2(360, 200)
	)

	victory_panel.reset_size()

	# Centraliza o painel na tela
	victory_panel.position = (
		get_viewport_rect().size
		- victory_panel.size
	) / 2.0

	victory_panel.hide()

	# ----------------------------------
	# Conectar sinais
	# ----------------------------------

	player.coins_changed.connect(
		_on_coins_changed
	)

	player.health_changed.connect(
		_on_health_changed
	)

	finish.level_reached.connect(
		_on_finish_reached
	)

	next_button.pressed.connect(
		_on_next_pressed
	)

	retry_button.pressed.connect(
		_on_retry_pressed
	)

	# ----------------------------------
	# Configurar os botões
	# ----------------------------------

	var has_next_level: bool = (
		not next_level_scene.strip_edges().is_empty()
	)

	next_button.visible = has_next_level

	next_button.text = "Próxima fase"
	retry_button.text = "Rejogar"

	# ----------------------------------
	# Inicializar HUD
	# ----------------------------------

	update_coin_counter(player.coins)

	update_health_counter(
		player.current_health,
		player.max_health
	)

	print("Fase ", level_number, " iniciada!")


# ==================================
# EVENTOS DE MOEDAS
# ==================================

func _on_coins_changed(total: int) -> void:
	update_coin_counter(total)


# ==================================
# EVENTOS DE VIDA
# ==================================

func _on_health_changed(
	current: int,
	maximum: int
) -> void:
	update_health_counter(
		current,
		maximum
	)


# ==================================
# ATUALIZAR MOEDAS
# ==================================

func update_coin_counter(total: int) -> void:
	coin_label.text = "Moedas: %d" % total


# ==================================
# ATUALIZAR VIDA
# ==================================

func update_health_counter(
	current: int,
	maximum: int
) -> void:
	health_label.text = (
		"Vida: %d / %d" % [current, maximum]
	)


# ==================================
# FINALIZAÇÃO DA FASE
# ==================================

func _on_finish_reached() -> void:
	if is_level_finished:
		return

	is_level_finished = true

	print("Fase ", level_number, " concluída!")

	# Prepara o texto de vitória
	victory_label.text = (
		"Fase %d concluída!\nMoedas: %d"
		% [level_number, player.coins]
	)

	# Exibe a interface
	victory_panel.show()

	# Pausa o jogo
	get_tree().paused = true


# ==================================
# PRÓXIMA FASE
# ==================================

func _on_next_pressed() -> void:
	if next_level_scene.strip_edges().is_empty():
		return

	# Retoma o jogo antes da troca de cena
	get_tree().paused = false

	var result: Error = (
		get_tree().change_scene_to_file(
			next_level_scene
		)
	)

	if result != OK:
		push_error(
			"Falha ao carregar: " + next_level_scene
		)


# ==================================
# REJOGAR A FASE
# ==================================

func _on_retry_pressed() -> void:
	get_tree().paused = false

	var result: Error = (
		get_tree().reload_current_scene()
	)

	if result != OK:
		push_error(
			"Não foi possível reiniciar a fase!"
		)
