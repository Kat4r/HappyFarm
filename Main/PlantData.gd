class_name PlantData
extends Resource

# Informações básicas
@export var id_nome: String = "planta_generica"
@export var nome_exibicao: String = "Planta Genérica"
@export var preco_compra: int = 10
@export var preco_venda: int = 15

# Tempo total para crescer (em segundos/ticks)
@export var tempo_crescimento_total: int = 10

# Configuração visual
# Array de coordenadas do Atlas (no Tileset) para cada estágio visual
# Ex: [Semente, Broto, Médio, Maduro]
@export var estagios_visuais: Array[Vector2i] 

# Retorna a coordenada do atlas baseada na porcentagem de crescimento
func get_atlas_coord_por_estagio(progresso_atual: int) -> Vector2i:
	if estagios_visuais.is_empty():
		return Vector2i(0,0)
	
	# Calcula qual estágio mostrar baseado no tempo decorrido
	# Se já passou do tempo total, retorna o último estágio (maduro)
	if progresso_atual >= tempo_crescimento_total:
		return estagios_visuais[-1]
		
	# Matemática para distribuir os estágios ao longo do tempo
	var estagio_idx = int(float(progresso_atual) / tempo_crescimento_total * (estagios_visuais.size() - 1))
	return estagios_visuais[estagio_idx]

func esta_pronta(progresso_atual: int) -> bool:
	return progresso_atual >= tempo_crescimento_total
