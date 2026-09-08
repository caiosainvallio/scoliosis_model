# Task 06 — Corrigir a extração e a estabilidade estrutural da CART

- **Modelo recomendado:** sol (`gpt-5.6-sol`).
- **Complexidade:** Alta.
- **Justificativa do modelo:** A interpretação depende de distinguir cortes primários, concorrentes e substitutos e de contar corretamente nós e árvores.
- **Dependências:** [Task 01](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/01_inventario_e_rastreabilidade.md), [Task 03](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/03_bibliografia_e_fontes.md)
- **Status:** Concluída em 2026-09-08.

## Contexto e regras

Leia o [índice e contrato de execução](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/00_indice_execucao.md) e o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) antes de executar. A raiz do projeto é `/Users/caiosainvallio/consultoria/scoliosis_model`. Esta task pertence à revisão do relatório; a numeração é diferente da antiga pasta `.plan/tasks`.

A correção pelo colete é uma avaliação transversal da anamnese inicial, disponível como preditor basal e interpretada como possível marcador de maleabilidade/corrigibilidade imediata. Essa definição foi esclarecida pelo usuário e não deve ser reaberta como suspeita de vazamento temporal. Preserve a coorte e a especificação dos modelos principais; mantenha análises novas e saídas corrigidas rastreáveis.

## Objetivo

Produzir estatísticas confiáveis das regras efetivamente usadas pelas árvores.

## Entradas

- [R/10_cart_nested.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/10_cart_nested.R)
- [tests/test_task08.R](/Users/caiosainvallio/consultoria/scoliosis_model/tests/test_task08.R)
- [results/prognostico/reduced_objects/cart_nested_internal.rds](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/reduced_objects/cart_nested_internal.rds)
- [results/prognostico/aggregated/cart_cutpoint_summary.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/cart_cutpoint_summary.csv)
- [results/prognostico/aggregated/cart_variable_frequency_summary.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/cart_variable_frequency_summary.csv)

As entregas de tasks anteriores só estarão disponíveis após sua conclusão. Leia o resumo e as evidências das dependências antes de consumir suas saídas.

## Atividades

1. Consultar a documentação oficial da estrutura rpart. Auditar cart_structure_tables e percorrer cortes primários por nó respeitando ncompete e nsurrogate.
2. Extrair variável, nó, profundidade, ponto de corte ou conjunto de níveis, tamanho do nó e origem do ajuste. Separar cortes concorrentes/substitutos em saídas próprias caso sejam mantidos.
3. Corrigir scope='all_levels': hoje corresponde apenas a profundidades maiores que dois. Implementar escopos explícitos de raiz, profundidades 1–2, profundidades maiores e total de níveis.
4. Calcular frequência por árvore sem duplicar árvores que usam a mesma variável várias vezes. Separar estabilidade da variável de raiz da estabilidade do corte da raiz e dos cortes em outros níveis.
5. Regerar resumos a partir dos modelos salvos quando possível, sem retuning. Se os modelos necessários não existirem, documentar e reproduzir apenas a análise CART necessária.
6. Testar árvores conhecidas, fatores, ausência de splits e casos com concorrentes/substitutos. Verificar que números de cortes primários coincidem com nós internos e que frequências por árvore ficam entre 0 e 1.
7. Conferir folds com calibração inválida e seus motivos, incluindo a contagem de 49 interceptos válidos nas saídas anteriores. Registrar o tratamento adotado e os denominadores.
8. Entregar estrutura corrigida, regras das folhas e notas para a visualização, preservando parâmetros selecionados e desempenho que não forem afetados.

## Entregáveis

- `/Users/caiosainvallio/consultoria/scoliosis_model/R/10_cart_nested.R` com extração corrigida
- `/Users/caiosainvallio/consultoria/scoliosis_model/tests/test_review_cart_structure.R`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/cart_*.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/06_cart_estrutura.md`

Registre comandos, arquivos produzidos/alterados, verificações e limitações em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/06_execucao.md`. Quando houver decisão estatística nova, inclua justificativa e referência verificável e atualize o BibTeX, se aplicável.

## Critérios de conclusão

- [ ] Cortes primários não incluem concorrentes ou substitutos.
- [ ] Raiz, níveis profundos e todos os níveis têm semântica e denominadores corretos.
- [ ] Regras categóricas e contagens conferem com os objetos rpart.
- [ ] Mudanças são atribuíveis à correção da extração, sem ajuste oportunista das árvores.
- [ ] Resumo de execução e manifesto atualizados com as evidências desta task.

## Encerramento e passagem

Atualize o status deste arquivo somente após verificar os critérios. Informe o que mudou, como foi verificado, quais saídas devem ser consumidas e se há dependências afetadas. Registre pendências sem inventar informação ou tratar uma limitação não resolvida como aprovação. Não execute automaticamente a próxima task.
