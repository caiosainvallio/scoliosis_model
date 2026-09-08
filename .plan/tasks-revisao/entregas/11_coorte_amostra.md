# Entrega da Tarefa 11 — coorte e tamanho amostral

Data: 2026-09-08. A descrição usa exclusivamente agregados da fonte congelada e das saídas verificadas das Tasks 01–03. Nenhum identificador, linha individual, modelo novo ou imputação foi produzido.

## Coorte efetivamente analisada

O fluxo foi 621 registros lidos, 618 participantes após deduplicação explícita de três pares confirmados, e 615 participantes na análise por caso completo. Os três casos incompletos correspondem a 3/618 (0,485%) dos participantes deduplicados e tinham `Lenke` ausente; essa exclusão é exibida antes da descrição da coorte analítica. A coorte final teve 317 eventos de melhora radiográfica de pelo menos 5° e 298 não eventos.

`cohort_descriptive.csv` descreve todos os dez preditores e os desfechos/magnitudes usados: para variáveis numéricas, n, ausentes, média, DP, mediana, IIQ e amplitude; para fatores, n e proporção de cada nível. A idade média foi 13,18 anos (DP 1,69), IMC 19,22 kg/m² (2,92), maior Cobb basal 36,68° (5,60) e `delta` −4,66° (5,35; mediana −5; IIQ −8 a −1; amplitude −23 a 13). A correção pelo colete teve média de 47,06% (19,61; amplitude 3,70% a 142,42%), preservando as hipercorreções verdadeiras.

A magnitude basal é o máximo entre Cobb torácico proximal, torácico e lombar. Dez participantes da coorte final tiveram empate basal; todos os empates foram preservados e as regiões empatadas são concatenadas na derivação. Como só há a maior magnitude aos seis meses, `delta` compara máximos e não confirma a mesma região anatômica longitudinalmente.

## Ausência de dados e comparação agregada

`missing_before_after.csv` mantém, lado a lado, ausências após deduplicação e na coorte analítica. Há três `Lenke` ausentes entre 618 e nenhum ausente nas variáveis requeridas após caso completo. Outras medidas radiográficas não usadas diretamente no modelo podem permanecer ausentes — por exemplo Cobb torácico proximal — pois o máximo basal e os desfechos continuam derivados quando existe ao menos uma região disponível. A baixa fração de exclusões não é evidência de ausência de viés.

Incluídos e excluídos foram comparados apenas descritivamente em agregado em `cohort_included_excluded_aggregate.csv`, armazenado no diretório interno de logs. Não foram emitidas linhas individuais nem testes de hipótese para o grupo de três excluídos; esse tamanho não sustentaria uma comparação inferencial útil.

## Distribuição de delta e legenda para integração

As marcações descritivas para figura de `delta` são: 317/615 (51,5%) com `delta ≤ −5°`, 523/615 (85,0%) com `delta ≤ 0°` e 603/615 (98,0%) com `delta ≤ +5°`. Elas descrevem a distribuição contínua e o limiar secundário de melhora radiográfica; não constituem modelo ou análise de progressão.

Legenda sugerida: “Distribuição agregada da mudança entre a maior magnitude de Cobb aos seis meses e o maior Cobb basal (`delta`, graus; n=615). Linhas em −5°, 0° e +5° são referências descritivas; −5° define o desfecho secundário de melhora radiográfica de pelo menos 5°. O máximo basal preserva empates entre regiões, e a região do máximo final não está disponível.”

## Adequação amostral, condicional às premissas

Os modelos principais têm 19 parâmetros de preditores e um intercepto, com 615 participantes, 317 eventos, 298 não eventos, prevalência 0,515 e shrinkage desejado de 0,90. `sample_size_display.csv` separa parâmetros de variáveis e mostra todos os cenários pmsampsize aplicáveis aos modelos lineares/logísticos principais, excluindo a sensibilidade AUC para não misturar cenários.

Para `delta`, o cenário de R² ajustado recalculado requer n=312; R² esperados de 0,35, 0,30 e 0,25 requerem 350, 422 e 524 (todos abaixo de 615), enquanto R²=0,20 requer 676 (insuficiente). Para melhora radiográfica, o Cox–Snell aparente requer 392; 80% e 70% desse valor requerem 464 e 545, enquanto 60% e 50% requerem 654 e 805 (insuficientes). O cenário aparente da própria coorte é retrospectivo e otimista; mesmo os cenários conservadores dependem de R²/Cox–Snell, prevalência, 19 parâmetros e shrinkage especificados. Portanto, a amostra não é declarada universalmente “suficiente”.

O cálculo segue as formulações de amostra para predição contínua e binária de Riley et al. [@riley2019_continuous_sample_size; @riley2019_binary_sample_size; @riley2020_sample_size_framework]. Ele se aplica à especificação congelada linear/logística e não justifica a complexidade da modelagem flexível exploratória, que requer sua avaliação interna própria. Não houve nova decisão estatística nem alteração do BibTeX nesta task.

## Passagem

As Tasks 12, 13 e 15 devem consumir `cohort_descriptive.csv`, `missing_before_after.csv`, `sample_size_display.csv`, esta síntese e o log de execução. A Task 13 deve integrar a legenda e a redação condicional, mantendo a correção pelo colete como medida transversal basal de possível maleabilidade/corrigibilidade imediata, sem alegar efeito causal ou manutenção garantida. Permanecem pendentes informações de recrutamento, elegibilidade, perdas de seguimento e protocolo radiográfico; não foram inventadas.
