# Task 10 — Sensibilidades, Cobb basal e comparadores simples

- **Modelo recomendado:** sol (`gpt-5.6-sol`).
- **Complexidade:** Alta.
- **Justificativa do modelo:** Requer comparações estatísticas justas e interpretação de cenários de exclusão e reparametrização do desfecho.
- **Dependências:** [Task 02](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/02_definicoes_clinicas_e_racional.md), [Task 03](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/03_bibliografia_e_fontes.md), [Task 08](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/08_pressupostos_e_inferencia_robusta.md), [Task 09](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/09_validacao_incerteza_e_shrinkage.md)
- **Status:** Concluída em 2026-09-08.

## Contexto e regras

Leia o [índice e contrato de execução](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/00_indice_execucao.md) e o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) antes de executar. A raiz do projeto é `/Users/caiosainvallio/consultoria/scoliosis_model`. Esta task pertence à revisão do relatório; a numeração é diferente da antiga pasta `.plan/tasks`.

A correção pelo colete é uma avaliação transversal da anamnese inicial, disponível como preditor basal e interpretada como possível marcador de maleabilidade/corrigibilidade imediata. Essa definição foi esclarecida pelo usuário e não deve ser reaberta como suspeita de vazamento temporal. Preserve a coorte e a especificação dos modelos principais; mantenha análises novas e saídas corrigidas rastreáveis.

## Objetivo

Mostrar quais conclusões resistem às sensibilidades e qual ganho prognóstico existe frente a referências simples.

## Entradas

- [R/12_sensitivity_analysis.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/12_sensitivity_analysis.R)
- [scripts/run_sensitivity_analysis.R](/Users/caiosainvallio/consultoria/scoliosis_model/scripts/run_sensitivity_analysis.R)
- [results/prognostico/aggregated/sensitivity_discussion.md](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/sensitivity_discussion.md)
- [results/prognostico/aggregated/sensitivity_scenario_metrics.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/sensitivity_scenario_metrics.csv)
- [results/prognostico/aggregated/sensitivity_cobb_target_metrics.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/sensitivity_cobb_target_metrics.csv)

As entregas de tasks anteriores só estarão disponíveis após sua conclusão. Leia o resumo e as evidências das dependências antes de consumir suas saídas.

## Atividades

1. Consolidar sensibilidades já executadas para influência, hipercorreções e alvo alternativo; reutilizar saídas válidas e identificar o conjunto de ajuste e de avaliação em cada linha.
2. Preservar as hipercorreções confirmadas e todas as observações da análise principal. Cook, leverage e resíduos são sinais de investigação; não são critérios para construir uma nova coorte principal.
3. Quantificar mudanças de coeficientes, métricas e previsões, incluindo avaliação na mesma coorte completa. Explicar a melhora aparente obtida quando se retiram justamente os casos de maior erro.
4. Implementar sensibilidade com delta ~ X e delta ~ Cobb basal + X; conferir a equivalência linear da segunda com Cobb final ~ Cobb basal + X ao reconverter para delta. Usar os mesmos desenhos e observações.
5. Avaliar os cenários em reamostragem comparável e com pré-processamento no treino. Comparar erros em graus e calibração na mesma escala, sem selecionar alvo por R² de desfechos distintos.
6. Incluir comparadores de média de delta e prevalência de melhora, estimados apenas no treinamento; calcular diferença de desempenho e contexto clínico. Evitar comparar baseline aparente com modelo validado como se fosse uma comparação pareada.
7. Integrar descrição de estratos já existente, com n e incerteza; não introduzir busca de subgrupos ou interações pós-dados. Informar a limitação anatômica decorrente de máximos de curvas diferentes.
8. Entregar tabela cenário/motivação/n/conjunto de avaliação/mudança/conclusão, identificando complementos decorrentes desta revisão.

## Entregáveis

- Scripts/módulos de sensibilidade com resultados separados da análise congelada
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/sensitivity_*.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/baseline_comparisons.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/tests/test_review_cobb_reparameterization.R`
- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/10_sensibilidades.md`

Registre comandos, arquivos produzidos/alterados, verificações e limitações em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/10_execucao.md`. Quando houver decisão estatística nova, inclua justificativa e referência verificável e atualize o BibTeX, se aplicável.

## Critérios de conclusão

- [ ] Comparadores e modelos usam o mesmo conjunto de avaliação e a mesma escala de erro.
- [ ] Equivalência das formulações com Cobb basal foi verificada numericamente.
- [ ] Nenhuma exclusão de sensibilidade alterou a coorte principal.
- [ ] Conclusões de robustez têm números e não confundem desempenho na subamostra selecionada com generalização.
- [ ] Resumo de execução e manifesto atualizados com as evidências desta task.

## Encerramento e passagem

Atualize o status deste arquivo somente após verificar os critérios. Informe o que mudou, como foi verificado, quais saídas devem ser consumidas e se há dependências afetadas. Registre pendências sem inventar informação ou tratar uma limitação não resolvida como aprovação. Não execute automaticamente a próxima task.

