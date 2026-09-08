# Execução da Task 06 — auditoria estrutural da CART

Data: 2026-09-08  
Diretório: `/Users/caiosainvallio/consultoria/scoliosis_model`

## Escopo e decisões preservadas

Foram lidos o índice/contrato, o parecer, a task, as entregas verificadas das Tasks 01 e 03, o código, testes, objetos e resumos congelados. A coorte (615; 317 eventos), os folds, os hiperparâmetros selecionados, os modelos principais e as três hipercorreções foram preservados. `correcao_colete` permaneceu definida como avaliação transversal basal de possível maleabilidade/corrigibilidade; não foi reaberta suspeita de vazamento temporal.

## Comandos e verificações

Todos os comandos shell foram prefixados com `rtk`.

| Comando/ação | Resultado |
|---|---|
| `rtk cat`/`sed`/`rg` nos contratos, entregas, código e logs | Dependências concluídas e escopo confirmado. |
| Consulta à documentação oficial de `rpart.object`, `labels.rpart` e `summary.rpart` | Ordem primário–concorrentes–substitutos e codificação de `csplit` confirmadas. |
| Inspeção de `cart_nested_internal.rds` | 50 folds/configurações e estruturas salvos; árvores não salvas. |
| `rtk Rscript --vanilla tests/test_review_cart_structure.R` | Passou: árvore conhecida, fator, `csplit`, ausência de cortes, concorrentes, substitutos, folhas, escopos, deduplicação por árvore e calibração. |
| `rtk Rscript --vanilla scripts/review_cart_structure.R` | Reajustou somente árvores com folds/configurações salvos; 313 primários = 313 nós internos; gerou CSVs da revisão. |
| `rtk Rscript --vanilla tests/run_tests.R` | Suíte integral passou; avisos esperados de separação em testes logísticos históricos. |

## Arquivos alterados ou produzidos

Código e testes:

- `R/10_cart_nested.R`;
- `scripts/review_cart_structure.R`;
- `tests/test_review_cart_structure.R`;
- `tests/run_tests.R`;
- `references_prognostico.bib` (fonte oficial da estrutura `rpart`).

Resultados:

- 16 arquivos `results/prognostico/revisao/aggregated/cart_*.csv`, incluindo o manifesto de hashes das 15 saídas analíticas;
- `results/prognostico/revisao/logs/cart_structure_rebuild.log`.

Evidências:

- `.plan/tasks-revisao/entregas/06_cart_estrutura.md`;
- `.plan/tasks-revisao/entregas/06_execucao.md`;
- novas linhas no `results/prognostico/revisao/logs/manifesto_inicial.csv`.

## Rastreabilidade e limitações

O hash da fonte permaneceu `f601adb42c299c2b0572f3e50ff26550b63a2f24dd7173f244a442b498965b71`; o do objeto CART congelado, `498ca47391ca4c5530bbf0c618577458d940c42c0ccffa6dcb7602c4fab0029d`. A reconstrução usou R 4.6.1 e `rpart` 4.1.27, versões também registradas no ambiente inicial/original, e reproduziu exatamente as 50 linhas de resumo estrutural.

O objeto congelado não continha os modelos completos; por isso, reconstrução determinística foi necessária. Nenhum tuning, bootstrap ou CV foi repetido. A falha do intercepto de calibração foi diagnosticada, mas não corrigida retroativamente, pois isso mudaria uma métrica fora do escopo estrutural; o denominador histórico de 49 foi mantido e explicado. Os CSVs de regras externas descrevem os conjuntos de treinamento de cada fold; não são regras de uma única árvore final. As regras aparentes da árvore ilustrativa estão separadas.

## Passagem

As Tasks 07, 12 e 13 devem consumir as saídas `cart_*` da revisão. O baseline em `results/prognostico/aggregated/` permanece congelado apenas para comparação. Nenhuma dependência anterior foi afetada e a próxima task não foi executada.
