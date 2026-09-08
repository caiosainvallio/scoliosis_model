# Entrega da Task 04 — solver logístico flexível

Data: 2026-09-07

## Resultado

O solver próprio foi corrigido e verificado antes de qualquer reexecução da coorte. `glmnet` não está instalado no ambiente registrado e a task proíbe instalar dependências durante a revisão; por isso foi mantida a implementação autocontida, agora acompanhada por função objetivo explícita, condições de otimalidade e comparação independente com `optim`. A formulação segue a convenção de Friedman, Hastie e Tibshirani (`friedman2010_glmnet`, já presente em `references_prognostico.bib`).

No caso original do parecer (semente 71, `alpha=0`, `lambda=0,08`), a implementação anterior declarava convergência com objetivo 0,552148, gradiente máximo 0,105205 e diferença de coeficientes de aproximadamente 0,561 frente à referência. Após a correção:

| Quantidade | Solver corrigido | `optim` independente | Diferença |
|---|---:|---:|---:|
| Objetivo penalizado | 0,5193618 | 0,5193618 | < 1e-12 |
| Maior violação de gradiente/KKT | 1,27e-11 | 1,14e-08 | — |
| Maior diferença entre coeficientes | — | — | 5,03e-09 |

A tolerância de aceitação foi `1e-8` para o objetivo, `2e-5` para coeficientes em casos correlacionados e `1e-6` para KKT. A tolerância um pouco maior dos coeficientes correlacionados acomoda direções numericamente quase planas; nesses casos a diferença do objetivo permaneceu abaixo de `1,5e-12` e ambas as soluções satisfizeram gradiente/KKT.

## Convenção derivada e implementada

Para `eta_i = beta_0 + x_i^T beta`, com intercepto não penalizado e colunas de `x` padronizadas usando apenas o treino:

- logística: `L = n^-1 sum[log(1 + exp(eta_i)) - y_i eta_i] + lambda[(1-alpha)||beta||²/2 + alpha||beta||_1]`;
- gaussiana: `L = (2n)^-1 sum(y_i-eta_i)² +` a mesma penalidade;
- no IRLS, Hessiana e escore do subproblema usam `1/n`. Dividir por `sum(w_i)` mudava a razão entre perda e penalidade e foi removido;
- a atualização do intercepto é uma coordenada não penalizada dentro do subproblema ponderado;
- a volta à escala bruta usa `beta_raw = beta/scale` e `beta0_raw = beta0 - mean^T beta_raw`.

Para coeficientes não nulos, a condição verificada é `grad_j(loss) + lambda(1-alpha)beta_j + lambda alpha sign(beta_j)=0`. Para coeficientes zero, verifica-se `|grad_j(loss)| <= lambda alpha`. O gradiente do intercepto deve ser zero.

## Robustez, convergência e falhas

O ajuste logístico usa IRLS com descida por coordenadas no subproblema, `eta`/perda calculados de forma numericamente estável, piso de `1e-8` apenas nos pesos e busca linear que impede aumento do objetivo. `converged=TRUE` agora exige solução finita e KKT máximo menor ou igual a `1e-6`; mudança pequena de parâmetros ou objetivo, isoladamente, não basta.

Cada ajuste expõe `objective`, `kkt_max`, `intercept_gradient`, `zero_kkt_max` e `failure_reason`. Ajustes sem convergência retornam previsões `NA`; o tuning exige todos os folds finitos e convergidos para considerar uma configuração, e métricas com previsões inválidas permanecem `NA`. O caminho não usa como warm start uma solução que falhou.

Foram testados três seeds, três níveis de ridge, elastic net e lasso em três níveis de penalização, preditores fortemente correlacionados, coeficientes zero, intercepto, predições nas escalas padronizada/bruta, o caminho gaussiano compartilhado e uma não convergência deliberada. As 30 linhas do log passaram; 29 representam convergências válidas e uma representa falha esperada corretamente bloqueada.

## Escopo e passagem para a Task 05

Foram preservados a coorte, os modelos principais `lm`/`glm`, os resultados congelados e a definição clínica basal de `correcao_colete`. Esta task não executou a CV clínica nem substituiu os resultados flexíveis antigos.

A Task 05 deve executar `scripts/run_flexible_modeling.R`, que agora passa explicitamente os quatro destinos em `results/prognostico/revisao/`. Ela deve tratar `results/prognostico/aggregated/flexible_*` e `results/prognostico/reduced_objects/flexible_nested_internal.rds` como baseline obsoleto somente para comparação, reexecutar o componente flexível e verificar `converged`, `kkt_max`, `failure_reason` e métricas antes de integrar resultados. A presença de efeitos principais na matriz candidata continua sendo apenas hierarquia de construção, não restrição de coeficientes ativos.

## Evidências

- `R/11_flexible_modeling.R` — objetivo, KKT, solver e propagação de falhas;
- `tests/test_review_flexible_objective.R` — testes numéricos independentes;
- `tests/test_task09.R` — teste one-SE não tautológico e regressão do fluxo;
- `scripts/review_check_flexible_objective.R` — reprodução e matriz sintética;
- `results/prognostico/revisao/logs/solver_verificacao.csv` — 30 verificações auditáveis;
- `scripts/run_flexible_modeling.R` — destino explícito para a futura reexecução.

Limitação: a equivalência direta externa foi feita com `optim` para ridge, onde o objetivo é diferenciável. Elastic net/lasso foram avaliados pelas condições KKT completas, incluindo zeros, pois `glmnet` não está disponível. Isso verifica a solução do objetivo declarado, mas não mede o impacto na coorte; essa medição pertence à Task 05.
