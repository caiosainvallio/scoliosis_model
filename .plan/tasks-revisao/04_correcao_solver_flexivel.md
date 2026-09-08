# Task 04 — Corrigir e verificar o algoritmo logístico flexível

- **Modelo recomendado:** astra (`gpt-6-astra`).
- **Complexidade:** Muito alta.
- **Justificativa do modelo:** Envolve derivação do objetivo penalizado, otimização numérica e condições de otimalidade; um erro compromete toda a análise flexível logística.
- **Dependências:** [Task 01](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/01_inventario_e_rastreabilidade.md), [Task 03](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/03_bibliografia_e_fontes.md)
- **Status:** Concluída em 2026-09-07.

## Contexto e regras

Leia o [índice e contrato de execução](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/00_indice_execucao.md) e o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) antes de executar. A raiz do projeto é `/Users/caiosainvallio/consultoria/scoliosis_model`. Esta task pertence à revisão do relatório; a numeração é diferente da antiga pasta `.plan/tasks`.

A correção pelo colete é uma avaliação transversal da anamnese inicial, disponível como preditor basal e interpretada como possível marcador de maleabilidade/corrigibilidade imediata. Essa definição foi esclarecida pelo usuário e não deve ser reaberta como suspeita de vazamento temporal. Preserve a coorte e a especificação dos modelos principais; mantenha análises novas e saídas corrigidas rastreáveis.

## Objetivo

Garantir que a implementação flexível minimiza o objetivo declarado antes de executar novamente a coorte.

## Entradas

- [R/11_flexible_modeling.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/11_flexible_modeling.R)
- [scripts/review_check_flexible_objective.R](/Users/caiosainvallio/consultoria/scoliosis_model/scripts/review_check_flexible_objective.R)
- [tests/test_task09.R](/Users/caiosainvallio/consultoria/scoliosis_model/tests/test_task09.R)
- [.plan/tasks/09_modelagem_flexivel.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks/09_modelagem_flexivel.md)

As entregas de tasks anteriores só estarão disponíveis após sua conclusão. Leia o resumo e as evidências das dependências antes de consumir suas saídas.

## Atividades

1. Reproduzir o teste sintético do parecer: caso ridge, alpha=0, lambda=0,08, semente 71. Registrar a discrepância frente à otimização direta; não tomar converged=TRUE como evidência suficiente.
2. Derivar explicitamente a convenção de perda média, penalização, intercepto e padronização. Revisar a normalização por sum(weights) na etapa IRLS e sua compatibilidade com a penalização.
3. Preferir implementação estabelecida, como glmnet, se viável no ambiente; alternativamente corrigir a implementação própria com derivação documentada. Harmonizar transformações e lambda antes de comparar soluções.
4. Verificar ridge por gradiente e elastic net/lasso por condições KKT, incluindo coeficientes zero, intercepto e predições. Testar múltiplas sementes, níveis de penalização, preditores correlacionados e casos de não convergência.
5. Revisar critérios de convergência interna/externa, atualização do intercepto, limites numéricos e tratamento de falhas. Auditar efeitos no caminho contínuo quando houver código compartilhado.
6. Substituir testes tautológicos, incluindo condições terminadas em '|| TRUE', por verificações relevantes de seleção e correção numérica.
7. Disponibilizar funções e scripts com destino explícito das saídas da revisão. Não repetir ainda a CV clínica completa; entregar o procedimento verificado para a task 05.

## Entregáveis

- `/Users/caiosainvallio/consultoria/scoliosis_model/R/11_flexible_modeling.R` corrigido ou módulo equivalente integrado
- `/Users/caiosainvallio/consultoria/scoliosis_model/tests/test_review_flexible_objective.R`
- `/Users/caiosainvallio/consultoria/scoliosis_model/scripts/review_check_flexible_objective.R` atualizado com verificação da correção
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/logs/solver_verificacao.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/04_solver.md`

Registre comandos, arquivos produzidos/alterados, verificações e limitações em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/04_execucao.md`. Quando houver decisão estatística nova, inclua justificativa e referência verificável e atualize o BibTeX, se aplicável.

## Critérios de conclusão

- [ ] Teste original agora concorda com a referência dentro de tolerância justificada.
- [ ] Gradiente/KKT, objetivo e predições são verificados; convergência declarada isoladamente não basta.
- [ ] Falhas são registradas e não recebem métricas silenciosamente válidas.
- [ ] Escopo afetado e procedimento de reexecução estão documentados; lm/glm principais preservados.
- [ ] Resumo de execução e manifesto atualizados com as evidências desta task.

## Encerramento e passagem

Atualize o status deste arquivo somente após verificar os critérios. Informe o que mudou, como foi verificado, quais saídas devem ser consumidas e se há dependências afetadas. Registre pendências sem inventar informação ou tratar uma limitação não resolvida como aprovação. Não execute automaticamente a próxima task.
