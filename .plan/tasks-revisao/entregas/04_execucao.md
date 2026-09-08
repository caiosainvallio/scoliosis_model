# Execução da Task 04 — correção do solver flexível

Data: 2026-09-07  
Diretório: `/Users/caiosainvallio/consultoria/scoliosis_model`

## Insumos e decisões preservadas

Foram lidos o índice/contrato, o parecer, a task antiga 09, as entregas verificadas das Tasks 01 e 03, o módulo flexível, o script sintético e os testes existentes. A coorte e os modelos principais não foram ajustados. A correção pelo colete permaneceu definida como medida transversal basal de corrigibilidade/maleabilidade imediata.

## Comandos e resultados

Todos os comandos shell foram prefixados com `rtk`.

| Comando/ação | Finalidade | Resultado |
|---|---|---|
| `rtk git status --short` | Conferir estado inicial | Árvore limpa no início da task. |
| `rtk cat` / `rtk sed` / `rtk rg` nos insumos | Ler dependências, localizar solver, convergência e teste tautológico | Erro de normalização por `sum(weights)` confirmado; `|| TRUE` localizado. |
| `rtk Rscript --vanilla -e 'cat(requireNamespace("glmnet", quietly=TRUE))'` | Avaliar implementação estabelecida disponível | `FALSE`; nenhuma dependência foi instalada. |
| `rtk Rscript --vanilla tests/test_review_flexible_objective.R` | Verificar referência, KKT, intercepto, escalas, predições e falha | Passou. |
| `rtk Rscript --vanilla scripts/review_check_flexible_objective.R` | Gerar evidência sintética independente | 30/30 cenários passaram; CSV gerado no destino da revisão. |
| `rtk Rscript --vanilla tests/run_tests.R` | Regressão de toda a suíte | Tasks antigas 05, 07, 08, 09 e 10 passaram, além do novo teste após sua inclusão na suíte. |
| `rtk git diff --check` | Conferir integridade textual do patch | Passou sem erros. |

Os avisos de `glm.fit` vistos em `test_task09.R` pertencem ao comparador congelado em dados sintéticos pequenos (separação/não convergência) e já eram emitidos pelo fluxo de teste; não vieram do solver corrigido. Os testes concluíram com código zero.

## Arquivos produzidos ou alterados

- alterado `R/11_flexible_modeling.R`;
- alterado `scripts/review_check_flexible_objective.R`;
- alterado `scripts/run_flexible_modeling.R`;
- criado `tests/test_review_flexible_objective.R`;
- alterado `tests/test_task09.R` para remover `|| TRUE`;
- alterado `tests/run_tests.R` para incluir o novo teste;
- criado `results/prognostico/revisao/logs/solver_verificacao.csv`;
- criados `.plan/tasks-revisao/entregas/04_solver.md` e `04_execucao.md`;
- atualizado o manifesto inicial com as saídas desta task;
- atualizado somente o status da Task 04 após todas as verificações.

Não foram alterados dados, QMD/HTML, resultados congelados, bibliografia, modelos principais ou status de outras tasks.

## Critérios de conclusão

- teste original concorda com `optim`: objetivo dentro de `1e-12`, coeficientes dentro de `5,1e-9` e KKT `1,27e-11`;
- gradiente/KKT, objetivo, intercepto, zeros e predições verificados em cenários adicionais;
- falha deliberada registrada como `maximum_iterations_or_kkt_not_met`, previsões e métricas bloqueadas com `NA`;
- destino futuro de saída explicitamente apontado para `results/prognostico/revisao/`;
- modelos principais e coorte preservados; reexecução clínica reservada à Task 05;
- suíte integral e manifesto verificados.

## Limitações e passagem

`glmnet` não estava disponível, portanto ridge foi comparado a `optim` e os casos não diferenciáveis foram verificados por KKT. A Task 05 deve consumir `04_solver.md`, o novo módulo e o log, executar a CV completa separadamente e substituir apenas as saídas flexíveis na árvore da revisão. Nenhuma conclusão clínica ou métrica logística da coorte foi atualizada nesta task.
