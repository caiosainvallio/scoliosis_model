# Execução da Task 08 — pressupostos e inferência robusta

Data: 2026-09-08  
Diretório: `/Users/caiosainvallio/consultoria/scoliosis_model`

## Escopo e insumos

Foram lidos o índice/contrato, o parecer atualizado, a task, as entregas verificadas das Tasks 02 e 03, o manifesto inicial, `R/07_frozen_models.R`, `R/12_sensitivity_analysis.R`, os testes e os resultados congelados de coeficientes, heteroscedasticidade e colinearidade. A coorte, fórmulas, preditores, hipercorreções e decisões clínicas foram preservados.

## Comandos e verificações

Todos os comandos shell foram prefixados com `rtk`.

| Comando/ação | Resultado |
|---|---|
| `rtk cat` / `sed` / `rg` / `find` | Contrato, dependências, código, resultados e manifesto auditados. |
| Verificação de pacotes R | `readxl`, `car`, `lmtest`, `sandwich` e `quadprog` disponíveis; nenhuma instalação foi feita. |
| Consulta das fontes primárias de Albert–Anderson e MacKinnon–White | Metadados e DOI `10.1093/biomet/71.1.1` (separação) e `10.1016/0304-4076(85)90158-7` (HC3) conferidos nas páginas dos periódicos. |
| `rtk Rscript --vanilla tests/test_review_inference.R` | Passou: IC t contra `confint.lm`, HC3 contra fórmula matricial independente, três padrões de separação sintéticos, identidade da coorte e invariância pontual. |
| `rtk Rscript --vanilla scripts/run_review_inference.R` | Produziu as saídas da revisão; 615/317/298, posto 20/20, coeficientes preservados, BP p=0,01054 e ausência de separação completa/quase-completa. |
| `rtk Rscript --vanilla tests/run_tests.R` | Suíte integral passou. Houve os dez avisos logísticos esperados nos testes históricos sintéticos; nenhuma falha. |

## Arquivos alterados ou produzidos

Código, executor, testes e referência:

- `R/07_frozen_models.R`;
- `scripts/run_review_inference.R`;
- `tests/test_review_inference.R`;
- `tests/run_tests.R`;
- `references_prognostico.bib` (entradas `albert1984_logistic_separation` e `mackinnon1985_hc3`).

Resultados e logs:

- 18 CSVs analíticos em `results/prognostico/revisao/aggregated/`, incluindo as duas tabelas de coeficientes e os `diagnostics_*.csv`;
- `results/prognostico/revisao/aggregated/diagnostics_output_manifest.csv` com hashes de 19 artefatos analíticos/internos;
- `results/prognostico/revisao/logs/diagnostics_influence_task10_internal.csv`;
- `results/prognostico/revisao/logs/review_inference.log`;
- `results/prognostico/revisao/reduced_objects/diagnostics_plot_data.rds`;
- `.plan/tasks-revisao/entregas/08_pressupostos.md` e este registro.

## Critérios de conclusão

| Critério | Evidência |
|---|---|
| IC e testes coerentes | Teste contra `confint.lm`; tabelas registram covariância, distribuição, gl e nível. |
| Coeficientes e coorte preservados | 615/317/298; diferença pontual máxima `4,66e-15`; fórmula e matriz 20/20. |
| Heteroscedasticidade interpretada e quantificada | BP, R² auxiliar, padrão por quintis e comparação HC3/clássica. |
| Sem aprovação por p>0,05 ou convergência | Matriz pressuposto/evidência/ação/limite e separação formal multivariável. |
| Resumo e manifesto atualizados | `08_pressupostos.md`, este arquivo, `diagnostics_output_manifest.csv` e novas entradas no manifesto central. |

## Limitações e passagem

HC3 corrige a covariância dos coeficientes, não não linearidade, dependência, calibração ou intervalos individuais. Não há variáveis de centro/avaliador para avaliar agrupamento. Os IDs influentes permanecem somente em log interno; nenhum caso foi removido. A Task 10 deve executar as sensibilidades de influência e hipercorreção; a Task 12 deve construir os gráficos a partir dos dados preparados; a Task 13 deve integrar a interpretação e as referências. Nenhuma task subsequente foi executada automaticamente.
