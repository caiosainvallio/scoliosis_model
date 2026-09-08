# Execução da Task 09 — validação, incerteza e shrinkage

Data: 2026-09-08  
Diretório: `/Users/caiosainvallio/consultoria/scoliosis_model`

## Escopo e decisões preservadas

Foram lidos o índice/contrato, o parecer, a task, os resumos e evidências das Tasks 03 e 08, o manifesto, os módulos R, executores, testes e resultados congelados relevantes. A coorte permaneceu com 615 participantes (317 eventos e 298 não eventos), dez preditores, 19 parâmetros preditores e intercepto. `correcao_colete` permaneceu uma avaliação transversal basal de possível maleabilidade/corrigibilidade imediata. Nenhuma hipercorreção foi excluída e nenhum resultado congelado foi sobrescrito.

O procedimento estatístico foi registrado em `09_validacao_incerteza.md` antes da reamostragem adicional. Foram acrescentadas as referências primárias `noma2021_optimism_ci` e `lei2018_conformal_regression` ao BibTeX, com metadados conferidos nas páginas do PubMed/editor.

## Implementação

- `R/04_bootstrap_stability.R`: `consolidate_optimism()` agora registra `n_failed_replicas` uma vez por réplica/modelo e `n_metric_unavailable` separadamente. A antiga coluna ambígua por métrica foi removida do novo contrato.
- `R/09_shrinkage_equations.R`: solicitações aos intervalos clássicos legados agora emitem aviso explícito de que assumem homoscedasticidade, reutilizam sigma/informação do ajuste aparente e omitem incerteza do fator.
- `R/13_review_validation.R`: implementa IC deslocado, auditoria de falhas, folds estratificados, bootstrap interno, avaliação completa do shrinkage, escala heteroscedástica, conformal separado e tabela de indisponibilidade.
- `scripts/run_review_validation.R`: executor isolado com destino exclusivo na revisão, seeds, testes de contrato, logs, manifesto e objeto reduzido.
- `tests/test_review_validation.R`: referências sintéticas independentes para o deslocamento, contagem de falhas, separação treino/teste, fatores e intervalos conformais.
- `tests/run_tests.R`: inclui o novo teste.

## Comandos e verificações

Todos os comandos shell foram prefixados com `rtk`.

| Comando/ação | Resultado |
|---|---|
| `rtk cat`, `sed`, `rg`, `head`, `git status/diff` | Contrato, dependências, código, outputs e alterações auditados. |
| Consulta PubMed/editor para Noma et al. e Lei et al. | DOI, autores, periódico, volume, fascículo e páginas conferidos. |
| `rtk Rscript --vanilla tests/test_review_validation.R` | Passou antes e depois da execução analítica. |
| `rtk Rscript --vanilla scripts/run_review_validation.R` | Duas execuções completas passaram; a final levou 259,8 s. Coorte/hash conferidos; todos os 20.000 ajustes internos da avaliação completa foram válidos. |
| `rtk Rscript --vanilla tests/run_tests.R` | Suíte integral passou. Os dez avisos logísticos sintéticos históricos permaneceram esperados; os dois novos avisos do teste histórico de intervalo documentam a limitação legada. |
| Conferência de CSVs e manifesto | Seis IC principais finitos; cinco IC de estatísticas degeneradas como `NA` motivado; 50 folds sem reutilização de teste; cobertura/largura finitas; hashes registrados. |

## Resultados essenciais

- IC 95% corrigidos: R² 0,3637 (0,3218–0,4410), RMSE 4,2763° (3,9267–4,4730), MAE 3,3944° (3,1028–3,5559), AUC 0,8483 (0,8291–0,8839), Brier 0,1600 (0,1363–0,1707) e log loss 0,4892 (0,4297–0,5143).
- Avaliação completa pós-shrinkage, médias de cinco repetições: RMSE 4,2965°, R² 0,3546, AUC 0,8452, slopes 0,9790 (linear) e 0,9930 (logístico). As amplitudes entre repetições não são IC.
- Cobertura conformal interna combinada 94,86%, largura média 17,44°; cada repetição tem denominador 615 e o agregado 3.075 previsões repetidas.
- 0/2.000 réplicas congeladas falharam em cada modelo; 0 métricas indisponíveis entre réplicas válidas. Falhas e métricas são contadas em níveis separados.

## Arquivos produzidos ou alterados

Código e teste: `R/04_bootstrap_stability.R`, `R/09_shrinkage_equations.R`, `R/13_review_validation.R`, `scripts/run_review_validation.R`, `tests/test_review_validation.R`, `tests/run_tests.R` e `references_prognostico.bib`.

Resultados: 13 arquivos públicos `validation_*`/`prediction_intervals_*` em `results/prognostico/revisao/aggregated/`, `results/prognostico/revisao/logs/validation_task09.log`, `results/prognostico/revisao/reduced_objects/validation_review_reduced.rds` e o manifesto de hashes `validation_output_manifest.csv`.

Evidências: `.plan/tasks-revisao/entregas/09_validacao_incerteza.md` e este arquivo.

## Critérios e limitações

| Critério | Evidência |
|---|---|
| Modelo, procedimento, unidade e alvo por métrica/intervalo | `validation_performance_ci.csv`, métricas de shrinkage e tabelas de disponibilidade. |
| Teste não reutilizado para shrinkage/intercepto | 50/50 linhas da auditoria registram `FALSE`; teste sintético verifica disjunção. |
| Falhas sem duplicação e intervalos com cobertura | Auditoria por réplica/modelo; IC de Noma para métricas principais; cobertura conformal somente em teste externo interno não usado. |
| Precisão não demonstrada como limite | Cinco IC de calibração/erro médio e os dois intervalos da equação final estão `unavailable` com motivo científico. |
| Resumo e manifesto | `09_validacao_incerteza.md`, este arquivo, `validation_output_manifest.csv` e manifesto central. |

A cobertura conformal é interna e marginal sob permutabilidade; não demonstra transportabilidade, cobertura condicional exata ou validade externa. A função de escala permite largura heteroscedástica, mas não modela toda possível estrutura de variância. A calibração separada incorpora o erro do modelo/fator estimado no treino próprio para aquela avaliação, sem fornecer um IC isolado do fator. Não resta conjunto independente para calibrar honestamente intervalos da equação ajustada em todos os 615 casos. Essas limitações devem seguir para as Tasks 13 e 15.

## Passagem

As Tasks 10, 12, 13 e 15 devem consumir somente as saídas da árvore `revisao`, respeitando `evaluation`, `target`, `interval_status` e `prediction_intervals_availability.csv`. A Task 13 deve substituir qualquer apresentação dos intervalos lineares congelados por sua indisponibilidade e pela cobertura interna agregada; deve manter a amplitude bootstrap como estabilidade. Nenhuma dependência anterior foi afetada e nenhuma task subsequente foi iniciada.
