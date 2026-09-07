# Task 07 — Redesenhar a árvore CART e a tabela de folhas

- **Modelo recomendado:** terra (`gpt-5.6-terra`).
- **Complexidade:** Moderada.
- **Justificativa do modelo:** Visualização R com especificação clara e dados estruturais já auditados.
- **Dependências:** [Task 02](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/02_definicoes_clinicas_e_racional.md), [Task 06](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/06_auditoria_estrutural_cart.md)
- **Status:** Pendente.

## Contexto e regras

Leia o [índice e contrato de execução](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/00_indice_execucao.md) e o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) antes de executar. A raiz do projeto é `/Users/caiosainvallio/consultoria/scoliosis_model`. Esta task pertence à revisão do relatório; a numeração é diferente da antiga pasta `.plan/tasks`.

A correção pelo colete é uma avaliação transversal da anamnese inicial, disponível como preditor basal e interpretada como possível marcador de maleabilidade/corrigibilidade imediata. Essa definição foi esclarecida pelo usuário e não deve ser reaberta como suspeita de vazamento temporal. Preserve a coorte e a especificação dos modelos principais; mantenha análises novas e saídas corrigidas rastreáveis.

## Objetivo

Recuperar a legibilidade da árvore histórica usando a árvore correta da análise atual.

## Entradas

- [analisys.qmd](/Users/caiosainvallio/consultoria/scoliosis_model/analisys.qmd)
- [R/10_cart_nested.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/10_cart_nested.R)
- [results/prognostico/figures/cart_illustrative_tree.png](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/figures/cart_illustrative_tree.png)
- [results/prognostico/aggregated/cart_illustrative_configuration.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/cart_illustrative_configuration.csv)
- [.plan/tasks-revisao/entregas/06_cart_estrutura.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/06_cart_estrutura.md)

As entregas de tasks anteriores só estarão disponíveis após sua conclusão. Leia o resumo e as evidências das dependências antes de consumir suas saídas.

## Atividades

1. Usar o objeto ilustrativo selecionado na coorte completa; não reutilizar a árvore ajustada no relatório antigo nem escolher uma árvore apenas por aparência.
2. Construir figura com rpart.plot ou alternativa R equivalente: caixas legíveis, ramos sim/não, nomes em português, níveis de fatores por extenso, probabilidade de melhora, eventos e n.
3. Preservar cortes computacionais e indicar arredondamentos apenas de apresentação. Conferir a ordem de classes; eliminar rótulos como risser=acde e sobreposições.
4. Produzir tabela com folha, caminho completo, n, eventos, proporção aparente e identificação de grupos pequenos. Regras devem permitir reproduzir a atribuição às folhas.
5. Produzir figura agregada de frequência da raiz/variáveis e distribuição de cortes primários usando somente os resumos corrigidos da task 06.
6. Exportar PNG em alta resolução e ao menos um formato vetorial SVG/PDF. Inspecionar visualmente em largura de publicação e no formato destinado ao HTML.
7. Escrever legendas que distingam árvore ilustrativa ajustada na coorte completa de desempenho do procedimento em CV aninhada; entregar blocos Quarto para integração.

## Entregáveis

- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/figures/cart_illustrative_tree.png` e versão vetorial
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/figures/cart_stability.png` e versão vetorial
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/cart_leaves.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/07_cart_visualizacao.md`

Registre comandos, arquivos produzidos/alterados, verificações e limitações em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/07_execucao.md`. Quando houver decisão estatística nova, inclua justificativa e referência verificável e atualize o BibTeX, se aplicável.

## Critérios de conclusão

- [ ] Todos os rótulos são legíveis sem códigos de níveis ou sobreposição.
- [ ] Soma de n e eventos das folhas coincide com a coorte usada na árvore.
- [ ] Probabilidades exibidas correspondem à classe melhora.
- [ ] Legendas deixam explícito o caráter aparente das proporções das folhas; exportações foram abertas e inspecionadas.
- [ ] Resumo de execução e manifesto atualizados com as evidências desta task.

## Encerramento e passagem

Atualize o status deste arquivo somente após verificar os critérios. Informe o que mudou, como foi verificado, quais saídas devem ser consumidas e se há dependências afetadas. Registre pendências sem inventar informação ou tratar uma limitação não resolvida como aprovação. Não execute automaticamente a próxima task.

