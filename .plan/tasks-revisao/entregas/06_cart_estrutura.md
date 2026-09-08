# Entrega da Task 06 — estrutura e estabilidade da CART

Data: 2026-09-08

## Resultado

A extração estrutural foi corrigida sem retuning. O objeto reduzido congelado não continha as árvores, mas preservava os 50 folds externos, os hiperparâmetros escolhidos em cada fold e os resumos estruturais. Por isso, foram reajustadas somente as 50 árvores externas com os respectivos treinamentos e configurações salvas. Os resumos reconstruídos coincidiram exatamente com `cart_tree_summaries` do objeto congelado; AUC, Brier, log loss e calibração não foram recalculados nem substituídos.

A travessia agora segue a estrutura documentada do objeto `rpart`: cada nó interno em `frame` consome, em ordem, um corte primário, `ncompete` cortes concorrentes e `nsurrogate` substitutos de `model$splits`. Para fatores, `index` aponta para `csplit`, cujos códigos identificam níveis enviados à esquerda e à direita [@therneau2026_rpart_object].

## Conferência estrutural

| Quantidade nas 50 árvores externas | Resultado |
|---|---:|
| Nós internos | 313 |
| Cortes primários extraídos | 313 |
| Primários contínuos | 221 |
| Primários categóricos | 92 |
| Cortes concorrentes, em saída separada | 1.252 |
| Cortes substitutos, em saída separada | 898 |
| Folhas/regras completas | 363 |

O resumo antigo registrava 1.542 cortes numéricos porque percorria indiscriminadamente `model$splits`. O resumo corrigido contém 221 cortes numéricos primários. Essa diferença é integralmente atribuível à extração; não houve seleção oportunista ou mudança de árvore.

Cada linha de corte contém árvore, repetição, fold externo, origem do ajuste, nó, profundidade, tamanho do nó, variável, papel do corte, posição, melhoria/concordância, tipo, ponto de corte ou conjuntos de níveis e as regras esquerda/direita. As regras das folhas combinam os cortes primários do caminho completo e informam `n`, eventos, classe e proporção aparente no conjunto usado para ajustar aquela árvore.

## Escopos e estabilidade

Os escopos agora são explícitos e não se sobrepõem, salvo o total deliberado:

- `root`: profundidade 0;
- `depths_1_2`: profundidades 1 e 2, excluindo a raiz;
- `deeper_than_2`: profundidades acima de 2;
- `all_levels`: todos os nós internos, incluindo a raiz.

Para cada variável, `trees_with_variable` conta cada árvore no máximo uma vez em cada escopo. O denominador é sempre 50 árvores externas, inclusive árvores sem divisão; nesta execução não houve árvores sem divisão. Todas as frequências relativas ficaram entre 0 e 1.

Na raiz, `correcao_colete` ocorreu em 50/50 árvores. Essa é estabilidade da variável de raiz, não do limiar. Os limiares de raiz foram: 49,4186 em 46 árvores; 54,8589 em 2; 45,3463 em 1; e 49,3902 em 1. Em todos os níveis, as maiores frequências por árvore foram `correcao_colete` 50/50, `risser` 46/50, `imc` 23/50, `lenke` 22/50 e `cifose_toracica` 21/50. A interpretação clínica preservada é a de possível marcador basal de maleabilidade/corrigibilidade imediata; estabilidade da escolha não demonstra causalidade nem manutenção longitudinal.

## Árvore ilustrativa e notas para visualização

A configuração global já salva foi reajustada uma única vez na coorte completa, apenas para recuperar regras aparentes. Ela tem 6 cortes primários e 7 folhas; as regras estão em `cart_illustrative_leaf_rules.csv` e os cortes em `cart_illustrative_primary_splits.csv`.

Para a Task 07:

- usar exclusivamente os cortes primários e as regras ilustrativas; não incorporar concorrentes ou substitutos ao desenho;
- mostrar níveis categóricos por extenso e preservar exatamente o sentido esquerda/direita registrado;
- arredondar somente a exibição dos limiares, mantendo os valores completos nas tabelas auditáveis;
- mostrar por folha `n`, eventos e probabilidade aparente, indicando grupos pequenos;
- declarar que a árvore ilustrativa foi ajustada na coorte completa após seleção da configuração e não é uma validação externa daquela árvore;
- usar as 50 árvores externas somente para estabilidade estrutural e as previsões externas congeladas para desempenho.

## Calibração inválida

O resumo anterior tinha 49/50 interceptos de calibração válidos e 50/50 inclinações válidas. O único intercepto inválido foi repetição 3, fold 1. Nesse fold, 9 de 62 previsões eram exatamente zero e foram truncadas para `1e-15`; o `glm` com offset retornou coeficiente de magnitude implausível, acima do limite de 100 aplicado pelo código. Trata-se de falha numérica do ajuste original, não de prova de inexistência de um intercepto finito.

O tratamento foi preservado para rastreabilidade: o fold é excluído somente do resumo do intercepto, cujo denominador é 49; permanece nas demais métricas, cujos denominadores continuam 50. Nenhuma métrica foi alterada nesta task.

## Saídas para consumo

- `cart_primary_splits.csv`: fonte canônica dos cortes usados;
- `cart_competing_splits.csv` e `cart_surrogate_splits.csv`: diagnósticos separados, nunca misturados aos primários;
- `cart_variable_frequency_summary.csv`, `cart_cutpoint_summary.csv` e `cart_categorical_split_summary.csv`: estabilidade com denominadores explícitos;
- `cart_leaf_rules.csv`: regras das 50 árvores externas;
- `cart_illustrative_primary_splits.csv` e `cart_illustrative_leaf_rules.csv`: insumos da Task 07;
- `cart_calibration_validity_summary.csv` e `cart_calibration_invalid_folds.csv`: denominadores e motivo da falha;
- `cart_tree_summaries.csv`, `cart_node_size_summary.csv`, `cart_stability_summary.csv` e `cart_root_frequency.csv`: estrutura agregada.

Todos estão em `results/prognostico/revisao/aggregated/`. As Tasks 07, 12 e 13 devem usar estas saídas corrigidas e não os resumos estruturais congelados.

## Critérios de conclusão

| Critério | Evidência |
|---|---|
| Primários não incluem concorrentes/substitutos | 313 primários = 313 nós internos; papéis separados em três CSVs. |
| Escopos e denominadores corretos | Quatro escopos explícitos; deduplicação por árvore; denominador 50. |
| Regras categóricas e contagens conferem | Teste com fator/`csplit`; 92 primários categóricos; caminhos completos das folhas. |
| Mudança sem ajuste oportunista | Mesmos folds e hiperparâmetros; resumos estruturais reproduzidos exatamente; sem retuning. |
| Execução e manifesto atualizados | `06_execucao.md`, `cart_structure_rebuild.log` e manifesto da revisão. |

