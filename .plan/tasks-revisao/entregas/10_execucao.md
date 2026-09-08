# Execução da Task 10 — sensibilidades e comparadores

Data: 2026-09-08  
Diretório: `/Users/caiosainvallio/consultoria/scoliosis_model`

## Escopo e decisões preservadas

Foram lidos o índice/contrato, o parecer, a task, as dependências 02, 03, 08 e 09, o manifesto, os módulos e as saídas congeladas de sensibilidade. A coorte permaneceu em 615 participantes, com 317 eventos e 298 não eventos; os dez preditores, 19 parâmetros preditores mais intercepto e os modelos principais foram preservados. `correcao_colete` continuou definida como avaliação transversal basal de possível maleabilidade/corrigibilidade imediata. Os três casos confirmados acima de 100% permaneceram na análise principal.

## Implementação

- `R/14_review_sensitivity.R`: folds comuns, exclusões restritas ao treino, comparadores treino-only, métricas/calibração pareadas, parametrizações com Cobb basal, incerteza descritiva de estratos e auditoria.
- `scripts/run_review_sensitivity.R`: executor isolado na árvore `revisao`, seed `20260909`, asserções, logs, hashes e objeto reduzido.
- `tests/test_review_cobb_reparameterization.R`: teste sintético independente da identidade de coeficientes/previsões e da dependência do comparador somente do treino.
- `tests/run_tests.R`: inclusão do novo teste na suíte integral.

Nenhum pacote novo foi instalado e nenhuma referência nova foi necessária: a decisão de validação interna e a interpretação de calibração usam fontes primárias já verificadas na Task 03.

## Comandos e verificações

| Comando/ação | Resultado |
|---|---|
| `rtk Rscript --vanilla tests/test_review_cobb_reparameterization.R` | Identidade algébrica e comparador treino-only aprovados em dados sintéticos. |
| `rtk Rscript --vanilla scripts/run_review_sensitivity.R` | 50 folds concluídos; todos os testes completos comuns; equivalência Cobb abaixo de `1e-10`; manifesto e log produzidos. |
| `rtk Rscript --vanilla tests/run_tests.R` | Suíte integral aprovada, incluindo Tasks 05, 07, 08, 09, solver flexível, CART, inferência, validação e sensibilidades. Warnings esperados dos testes legados/flexíveis permanecem documentados por seus módulos. |
| Conferência de CSVs e RDS | 615 previsões por repetição/cenário; comparadores estimados no treino; teste nunca usado para ajuste ou exclusão; hashes SHA-256 registrados. |
| `rtk git diff --check` e inspeção do diff/status | Sem erro de whitespace; mudanças limitadas ao escopo da Task 10, manifesto central, suíte e status desta task. |

## Evidências dos critérios

| Critério | Evidência |
|---|---|
| Mesma avaliação e escala | `sensitivity_resampling_audit.csv`, `sensitivity_resampling_metrics_*.csv` e `baseline_comparisons.csv`: 615 previsões por repetição; RMSE/MAE em graus de delta e Brier/log loss em probabilidade. |
| Equivalência com Cobb basal | `sensitivity_cobb_reparameterization.csv`: matrizes idênticas; diferenças máximas `1,39e-13` em previsão e `1,59e-13` em coeficientes convertidos. |
| Principal não alterada | n=615, hipercorreções presentes e `main_cohort_changed: FALSE` no log; exclusões ocorrem apenas no treino dos cenários. |
| Robustez quantitativa sem seleção | `sensitivity_scenario_conclusions.csv` e `10_sensibilidades.md`: métricas aparentes, coorte completa e folds comuns são identificados separadamente. |
| Resumo e manifesto | Este arquivo, `10_sensibilidades.md`, `sensitivity_output_manifest.csv` e novas entradas no manifesto central. |

## Arquivos produzidos ou alterados

Código/testes: `R/14_review_sensitivity.R`, `scripts/run_review_sensitivity.R`, `tests/test_review_cobb_reparameterization.R` e `tests/run_tests.R`.

Resultados: 19 CSVs públicos `sensitivity_*`/`baseline_comparisons.csv` em `results/prognostico/revisao/aggregated/`, `results/prognostico/revisao/logs/sensitivity_task10.log` e `results/prognostico/revisao/reduced_objects/sensitivity_review_reduced.rds`. Evidências: `10_sensibilidades.md` e este arquivo.

## Limitações e passagem

Onze de 50 ajustes logísticos após exclusão de influentes tiveram aviso de probabilidades ajustadas numericamente extremas; convergiram e tiveram coeficientes finitos, mas sua calibração e log loss pioraram. As cinco repetições não são amostras independentes e sua amplitude não é IC. Não houve validação externa. A região anatômica da curva máxima aos seis meses não está disponível, impedindo confirmar que o delta compara a mesma curva.

As Tasks 12, 13 e 15 devem usar somente as saídas da revisão, relatar o ganho pequeno do Cobb basal sem seleção por R², mostrar os comparadores como referências treino-only e manter as exclusões como sensibilidades. Nenhuma dependência anterior foi afetada e a Task 11 não foi iniciada.
