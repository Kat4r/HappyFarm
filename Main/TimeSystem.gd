extends CanvasModulate

# Configurações de Tempo
const MINUTOS_POR_DIA = 1440 # 24h * 60m
const SEGUNDOS_REAIS_POR_DIA = 120.0 # Um dia no jogo dura 2 minutos reais (ajuste como quiser)

# Variáveis de Estado
var tempo_jogo: float = 0.0 # De 0.0 a 1.0 (0 = Começo do dia, 1 = Fim)
var dia_atual: int = 1
var hora_atual: int = 0
var minuto_atual: int = 0
var pausado: bool = false
var velocidade_tempo: float = 1.0

# Sinais
signal tempo_atualizado(dia, hora, minuto) # Enviaremos tudo junto para a UI

# Gradiente de Cores (O segredo visual!)
# Vamos definir as cores via código para facilitar, mas poderia ser um recurso GradientTexture
@export var cor_dia: Color = Color("ffffff") # Branco (Meio dia)
@export var cor_entardecer: Color = Color("ffcc99") # Laranja
@export var cor_noite: Color = Color("1e1e32") # Azul Escuro Profundo
@export var cor_madrugada: Color = Color("0d0d1a") # Quase preto

# Sinais para avisar o resto do jogo
signal mudou_dia(dia_novo)
signal mudou_hora(hora_nova)

func _process(delta):
	# Se estiver pausado, não avançamos o tempo!
	if pausado:
		return
		
	tempo_jogo += (delta * velocidade_tempo) / SEGUNDOS_REAIS_POR_DIA
	
	if tempo_jogo >= 1.0:
		tempo_jogo = 0.0
		dia_atual += 1
		# Aqui entrariam os pagamentos diários
	
	_calcular_relogio()
	_atualizar_visual()

func _calcular_relogio():
	var total_minutos = int(tempo_jogo * MINUTOS_POR_DIA)
	@warning_ignore("integer_division")
	var nova_hora = int(total_minutos / 60)
	var novo_minuto = total_minutos % 60
	
	if nova_hora != hora_atual or novo_minuto != minuto_atual:
		hora_atual = nova_hora
		minuto_atual = novo_minuto
		# Avisa a UI que o relógio mudou
		tempo_atualizado.emit(dia_atual, hora_atual, minuto_atual)

func _atualizar_visual():
	# Interpola as cores baseado no horário
	# Manhã (0h - 6h): Madrugada -> Entardecer (Amanhecer)
	# Dia (6h - 17h): Entardecer -> Dia
	# Tarde (17h - 19h): Dia -> Entardecer
	# Noite (19h - 24h): Entardecer -> Noite
	
	# Simplificação com Gradient seria ideal, mas vamos fazer um Lerp simples:
	# Vamos usar uma curva Senoidal para simular o sol subindo e descendo
	# 0.0 é meia noite, 0.5 é meio dia.
	
	var cor_alvo = cor_noite
	
	if hora_atual >= 5 and hora_atual < 8: # Amanhecendo
		var peso = float(minuto_atual + (hora_atual-5)*60) / 180.0
		cor_alvo = cor_madrugada.lerp(cor_dia, peso)
	elif hora_atual >= 8 and hora_atual < 17: # Dia Claro
		cor_alvo = cor_dia
	elif hora_atual >= 17 and hora_atual < 20: # Anoitecendo
		var peso = float(minuto_atual + (hora_atual-17)*60) / 180.0
		cor_alvo = cor_dia.lerp(cor_noite, peso)
	else: # Noite
		cor_alvo = cor_noite
		
	color = color.lerp(cor_alvo, 0.5 * get_process_delta_time())
	
	
func alternar_pausa():
	pausado = not pausado
	print("Tempo Pausado: ", pausado)
	return pausado

# Regra de Negócio: É horário de trabalho?
# Retorna TRUE se for proibido plantar (entre 20h e 06h)
func e_horario_proibido() -> bool:
	if hora_atual >= 20 or hora_atual < 6:
		return true
	return false
