
extends Node

# ==================================
# RECURSOS DE ÁUDIO
# ==================================

@export var attack_sound: AudioStream
@export var coin_sound: AudioStream
@export var hurt_sound: AudioStream


# ==================================
# REFERÊNCIAS
# ==================================

@onready var player: Player = (
	get_parent().get_node_or_null("player") as Player
)

var attack_audio: AudioStreamPlayer
var coin_audio: AudioStreamPlayer
var hurt_audio: AudioStreamPlayer


# ==================================
# CONTROLE DE EVENTOS
# ==================================

var previous_health: int = 0
var previous_coins: int = 0


# ==================================
# INICIALIZAÇÃO
# ==================================

func _ready() -> void:
	if player == null:
		push_error(
			"AudioController: Player não encontrado!"
		)
		return

	# Cria os três reprodutores
	attack_audio = create_audio_player(
		attack_sound, -8.0
	)

	coin_audio = create_audio_player(
		coin_sound, -6.0
	)

	hurt_audio = create_audio_player(
		hurt_sound, -8.0
	)

	# Guarda os valores iniciais
	previous_health = player.current_health
	previous_coins = player.coins

	# Conecta os sinais do jogador
	player.attack_started.connect(
		_on_attack_started
	)

	player.coins_changed.connect(
		_on_coins_changed
	)

	player.health_changed.connect(
		_on_health_changed
	)

	print("Sistema de áudio iniciado!")


# ==================================
# CRIAR REPRODUTOR
# ==================================

func create_audio_player(
	audio_stream: AudioStream,
	volume: float
) -> AudioStreamPlayer:

	var audio := AudioStreamPlayer.new()

	audio.stream = audio_stream
	audio.volume_db = volume

	add_child(audio)

	if audio_stream == null:
		push_warning(
			"Existe um som não configurado!"
		)

	return audio


# ==================================
# EVENTO DE ATAQUE
# ==================================

func _on_attack_started() -> void:
	play_sound(attack_audio)


# ==================================
# EVENTO DE MOEDA
# ==================================

func _on_coins_changed(total: int) -> void:
	# Toca somente se o total aumentou
	if total > previous_coins:
		play_sound(coin_audio)

	previous_coins = total


# ==================================
# EVENTO DE DANO
# ==================================

func _on_health_changed(
	current: int,
	_maximum: int
) -> void:

	# Toca somente se a vida diminuiu
	if current < previous_health:
		play_sound(hurt_audio)

	previous_health = current


# ==================================
# REPRODUZIR SOM
# ==================================

func play_sound(audio: AudioStreamPlayer) -> void:
	if audio == null:
		return

	if audio.stream == null:
		return

	# Reinicia o efeito para reproduzi-lo
	# desde o começo quando acionado.
	audio.stop()
	audio.play()
