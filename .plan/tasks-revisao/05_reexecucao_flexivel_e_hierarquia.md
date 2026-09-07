# Task 05 — Reexecutar a análise flexível e esclarecer a hierarquia

- **Modelo recomendado:** sol (`gpt-5.6-sol`).
- **Complexidade:** Alta.
- **Justificativa do modelo:** Coordena uma análise aninhada extensa, a avaliação de seleção e comparações com incerteza e interpretações limitadas.
- **Dependências:** [Task 02](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/02_definicoes_clinicas_e_racional.md), [Task 03](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/03_bibliografia_e_fontes.md), [Task 04](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/04_correcao_solver_flexivel.md)
- **Status:** Pendente.

## Contexto e regras

Leia o [índice e contrato de execução](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/00_indice_execucao.md) e o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) antes de executar. A raiz do projeto é `/Users/caiosainvallio/consultoria/scoliosis_model`. Esta task pertence à revisão do relatório; a numeração é diferente da antiga pasta `.plan/tasks`.

A correção pelo colete é uma avaliação transversal da anamnese inicial, disponível como preditor basal e interpretada como possível marcador de maleabilidade/corrigibilidade imediata. Essa definição foi esclarecida pelo usuário e não deve ser reaberta como suspeita de vazamento temporal. Preserve a coorte e a especificação dos modelos principais; mantenha análises novas e saídas corrigidas rastreáveis.

## Objetivo

Gerar resultados flexíveis válidos e um apêndice que descreva exatamente o procedimento executado.

## Entradas

- [R/11_flexible_modeling.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/11_flexible_modeling.R)
- [scripts/run_flexible_modeling.R](/Users/caiosainvallio/consultoria/scoliosis_model/scripts/run_flexible_modeling.R)
- [results/prognostico/aggregated/flexible_methodological_appendix.md](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/flexible_methodological_appendix.md)
- [.plan/tasks-revisao/entregas/04_solver.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/04_solver.md)

As entregas de tasks anteriores só estarão disponíveis após sua conclusão. Leia o resumo e as evidências das dependências antes de consumir suas saídas.

## Atividades

1. Preservar os resultados anteriores para comparação. Reutilizar identificadores de reamostragem disponíveis ou reconstruí-los de modo determinístico; verificar treino/teste disjuntos e pré-processamento apenas no treino.
2. Executar novamente a parte logística corrigida e quaisquer saídas afetadas; reexecutar a família contínua somente se a mudança atingir seu código ou seus insumos. Manter dez folds externos, cinco repetições e cinco folds internos, salvo correção documentada indispensável.
3. Relatar alpha, lambda, nós/graus de liberdade das splines, expansão de variáveis, Cobb basal, interações, critérios one-SE, desempates e falhas. Não afinar a grade retrospectivamente apenas para obter melhores métricas.
4. Auditar hierarquia nos coeficientes ativos. Se não houver restrição formal, corrigir o relato para presença dos efeitos principais na matriz candidata; não confundir essa propriedade com hierarquia forte. Tratar eventual restrição nova como cenário distinto.
5. Comparar estratégias flexível e congelada nos mesmos folds; apresentar diferenças direcionais de RMSE, MAE, AUC, Brier e log loss, calibração e estabilidade. Separar variabilidade entre folds de IC.
6. Quantificar impacto antes/depois da correção do solver e registrar se as conclusões mudam. Não atribuir diferença de desempenho apenas a splines quando também há preditores adicionais e penalização.
7. Entregar os dados agregados para as figuras da task 12 e a redação da task 13.

## Entregáveis

- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/flexible_*.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/reduced_objects/flexible_*.rds`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/logs/flexible_*.log`
- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/05_flexivel.md`

Registre comandos, arquivos produzidos/alterados, verificações e limitações em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/05_execucao.md`. Quando houver decisão estatística nova, inclua justificativa e referência verificável e atualize o BibTeX, se aplicável.

## Critérios de conclusão

- [ ] Nenhuma saída clínica revista utiliza o solver anterior afetado.
- [ ] Comparações usam as mesmas observações de teste e identificam a dependência das repetições.
- [ ] Hierarquia é descrita conforme o que foi verificado.
- [ ] Métricas, falhas e diferenças antes/depois são rastreáveis e não há conclusão de superioridade baseada apenas em pontos médios.
- [ ] Resumo de execução e manifesto atualizados com as evidências desta task.

## Encerramento e passagem

Atualize o status deste arquivo somente após verificar os critérios. Informe o que mudou, como foi verificado, quais saídas devem ser consumidas e se há dependências afetadas. Registre pendências sem inventar informação ou tratar uma limitação não resolvida como aprovação. Não execute automaticamente a próxima task.

