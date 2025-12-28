extends CanvasLayer

@onready var label_relogio = $LabelRelogio
@onready var btn_pausa = $BtnPausa
# Precisamos achar o TimeSystem. Como ele está no Main, podemos exportar ou buscar:
@export var sistema_tempo: Node # Arraste o nó 'CicloDiaNoite' para cá no Inspetor
@onready var moldura_pausa = $MolduraPausa


func _ready():
	# Conecta o sinal do relógio para atualizar o texto
	if sistema_tempo:
		moldura_pausa.visible = false
		sistema_tempo.tempo_atualizado.connect(_atualizar_texto_relogio)
		
		# Conecta o botão de pausa
		btn_pausa.pressed.connect(func():
			var esta_pausado = sistema_tempo.alternar_pausa()
			moldura_pausa.visible = esta_pausado
			 
			if esta_pausado:
				label_relogio.text = "TEMPO PAUSADO" # Opcional: Alternar entre a hora e o texto
				btn_pausa.text = "RETOMAR TEMPO"
				label_relogio.modulate = Color(1, 0, 0) # Fica vermelho quando pausa
			else:
				btn_pausa.text = "PAUSAR TEMPO"
				label_relogio.modulate = Color(1, 1, 1)
		)

# Dica: Vamos mover a lógica visual para uma função separada para não repetir código
func _alternar_pausa_visual():
	var esta_pausado = sistema_tempo.alternar_pausa()
	moldura_pausa.visible = esta_pausado
	
	if esta_pausado:
		label_relogio.text = "TEMPO PAUSADO"
		btn_pausa.text = "RETOMAR TEMPO"
		label_relogio.modulate = Color(1, 0, 0)
	else:
		# Força o relógio a mostrar a hora atual imediatamente ao despausar
		_atualizar_texto_relogio(sistema_tempo.dia_atual, sistema_tempo.hora_atual, sistema_tempo.minuto_atual)
		btn_pausa.text = "PAUSAR TEMPO"
		label_relogio.modulate = Color(1, 1, 1)


func _atualizar_texto_relogio(dia, hora, minuto):
	# Formata para ficar bonito (ex: 08:05 em vez de 8:5)
	var str_hora = "%02d" % hora
	var str_minuto = "%02d" % minuto
	label_relogio.text = "Dia " + str(dia) + " - " + str_hora + ":" + str_minuto
	
func _input(event):
	# event.is_echo() verifica se a tecla está apenas sendo segurada
	if event.is_action_pressed("ui_accept", false) or (event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_SPACE):
		if sistema_tempo:
			_alternar_pausa_visual()
