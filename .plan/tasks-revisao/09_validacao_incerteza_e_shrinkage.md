# Task 09 — Avaliação interna, incerteza e equações após shrinkage

- **Modelo recomendado:** astra (`gpt-6-astra`).
- **Complexidade:** Muito alta.
- **Justificativa do modelo:** A definição do alvo da validação, a dependência da reamostragem e a cobertura dos intervalos exigem raciocínio estatístico avançado.
- **Dependências:** [Task 03](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/03_bibliografia_e_fontes.md), [Task 08](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/08_pressupostos_e_inferencia_robusta.md)
- **Status:** Pendente.

## Contexto e regras

Leia o [índice e contrato de execução](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/00_indice_execucao.md) e o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) antes de executar. A raiz do projeto é `/Users/caiosainvallio/consultoria/scoliosis_model`. Esta task pertence à revisão do relatório; a numeração é diferente da antiga pasta `.plan/tasks`.

A correção pelo colete é uma avaliação transversal da anamnese inicial, disponível como preditor basal e interpretada como possível marcador de maleabilidade/corrigibilidade imediata. Essa definição foi esclarecida pelo usuário e não deve ser reaberta como suspeita de vazamento temporal. Preserve a coorte e a especificação dos modelos principais; mantenha análises novas e saídas corrigidas rastreáveis.

## Objetivo

Assegurar que desempenho, incerteza e intervalos publicados correspondem exatamente ao procedimento e ao modelo que foram avaliados.

## Entradas

- [R/03_metrics_calibration.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/03_metrics_calibration.R)
- [R/04_bootstrap_stability.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/04_bootstrap_stability.R)
- [R/08_internal_validation.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/08_internal_validation.R)
- [R/09_shrinkage_equations.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/09_shrinkage_equations.R)
- [scripts/run_internal_validation.R](/Users/caiosainvallio/consultoria/scoliosis_model/scripts/run_internal_validation.R)
- [results/prognostico/aggregated/frozen_bootstrap_optimism_summary.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/frozen_bootstrap_optimism_summary.csv)
- [results/prognostico/aggregated/frozen_shrinkage_summary.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/frozen_shrinkage_summary.csv)

As entregas de tasks anteriores só estarão disponíveis após sua conclusão. Leia o resumo e as evidências das dependências antes de consumir suas saídas.

## Atividades

1. Auditar o bootstrap existente, suas unidades, fórmulas de otimismo e direções de métricas. Corrigir contagem de falhas por réplica/modelo, separando-a de falhas por métrica.
2. Documentar três objetos: ajuste aparente, desempenho corrigido da especificação fixa e equação pós-shrinkage. Preservar a distinção entre avaliação interna e externa.
3. Definir e justificar um procedimento de IC para as métricas principais corrigidas, com fonte metodológica adequada. Não usar os quantis do otimismo ou das métricas entre folds como substitutos automáticos. Registrar o procedimento antes da execução e aplicar a reamostragem necessária.
4. Avaliar o procedimento completo de shrinkage quando apresentar desempenho da equação final: estimar o fator e recalibrar intercepto dentro do treinamento de cada avaliação, sem estimá-los no conjunto de teste. Identificar de modo separado qualquer avaliação adicional por CV/nova reamostragem.
5. Revisar os IC da média e intervalos individuais construídos com sigma e informação do ajuste original. Implementar método justificável, explicitando heteroscedasticidade e incerteza do fator estimado; avaliar cobertura e largura em observações não usadas no ajuste. Registrar a limitação da cobertura interna.
6. Manter a amplitude bootstrap de previsões como medida de estabilidade; distinguir de IC de desempenho, IC da média e intervalo de predição individual. Não atribuir ao índice do projeto uma definição de literatura diferente.
7. Documentar intercepto e slope de calibração, tipos de IC, falhas, sementes, custo computacional observado e denominadores. Não recalcular o bootstrap antigo apenas para gerar uma tabela já existente.
8. Se um intervalo não puder ser estimado validamente com as informações disponíveis, deixar o resultado explicitamente indisponível com motivo científico; não inventar precisão. Essa limitação deve passar à auditoria final, sem alegação de validação completa desse intervalo.

## Entregáveis

- Módulos R e scripts necessários à avaliação adicional, com destino explícito na revisão
- `/Users/caiosainvallio/consultoria/scoliosis_model/tests/test_review_validation.R`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/validation_*.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/prediction_intervals_*.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/logs/validation_*.log`
- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/09_validacao_incerteza.md`

Registre comandos, arquivos produzidos/alterados, verificações e limitações em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/09_execucao.md`. Quando houver decisão estatística nova, inclua justificativa e referência verificável e atualize o BibTeX, se aplicável.

## Critérios de conclusão

- [ ] Cada métrica e intervalo informa o modelo, procedimento, unidade e alvo correspondente.
- [ ] Não existe reutilização do conjunto de teste para estimar shrinkage ou calibrar intercepto.
- [ ] Falhas são contadas sem duplicação e intervalos têm método e evidência de cobertura apropriados.
- [ ] Precisão não demonstrada aparece como limitação, nunca como intervalo final validado.
- [ ] Resumo de execução e manifesto atualizados com as evidências desta task.

## Encerramento e passagem

Atualize o status deste arquivo somente após verificar os critérios. Informe o que mudou, como foi verificado, quais saídas devem ser consumidas e se há dependências afetadas. Registre pendências sem inventar informação ou tratar uma limitação não resolvida como aprovação. Não execute automaticamente a próxima task.

