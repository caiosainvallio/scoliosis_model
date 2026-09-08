# Execução da Task 05 — reexecução flexível e hierarquia

Data: 2026-09-07  
Diretório: `/Users/caiosainvallio/consultoria/scoliosis_model`

## Insumos e decisões preservadas

Foram lidos o índice/contrato, o parecer atualizado, as Tasks 02–04 e suas entregas, o inventário/manifesto, `R/11_flexible_modeling.R`, `scripts/run_flexible_modeling.R`, os testes e o objeto flexível congelado anterior. A planilha fonte, a coorte, os modelos principais, as hipercorreções verdadeiras e os resultados congelados não foram alterados.

`correcao_colete` permaneceu definida como avaliação transversal na anamnese, disponível no momento basal e interpretada como possível marcador de corrigibilidade/maleabilidade imediata. Não foi tratada como vazamento temporal. Cobb basal permaneceu apenas na estratégia flexível exploratória e não foi promovido aos modelos principais.

## Comandos e verificações

Todos os comandos shell foram prefixados com `rtk`.

| Comando/ação | Finalidade | Resultado |
|---|---|---|
| `rtk cat`, `rtk sed`, `rtk rg`, `rtk find` | Ler contrato, dependências, parecer, código, saídas e manifesto | Escopo e decisões clínicas confirmados. |
| `rtk git status --short` | Conferir estado inicial | Árvore limpa antes da Task 05. |
| `rtk Rscript --vanilla -e 'parse(...)'` | Validar sintaxe do módulo e do executor | Passou. |
| `rtk Rscript --vanilla tests/test_task09.R` | Regressão rápida do fluxo flexível | Passou; avisos pertencem ao `glm` congelado em amostra sintética pequena. |
| `rtk Rscript --vanilla tests/test_review_flexible_objective.R` | Revalidar objetivo e KKT do solver | Passou. |
| `rtk Rscript --vanilla scripts/run_flexible_modeling.R` | Reexecutar 10 folds externos × 5 repetições × 5 folds internos | Concluiu duas vezes; métricas idênticas, 6.150 previsões, zero falhas externas. A segunda passagem acrescentou motivos de falha interna e expansão da matriz. |
| `rtk Rscript --vanilla tests/test_review_flexible_reexecution.R` | Auditar objetos e saídas da Task 05 | Passou. |
| `rtk Rscript --vanilla tests/run_tests.R` | Regressão integral | Todas as tasks testadas passaram. |
| `rtk git diff --check` | Integridade textual | Passou. |
| `rtk shasum -a 256 ...` | Confirmar preservação e identificar objetos novos | Fonte e objeto anterior mantiveram os hashes do inventário. |
| busca por `id`/`participant_index` nos CSV agregados | Privacidade | Nenhuma coluna individual foi publicada nos agregados. |

## Implementação

- `R/11_flexible_modeling.R`: métricas em todos os escopos; diferenças direcionais; resumo pareado por repetição; auditorias de hierarquia ativa, splines, expansão, reamostragem, observações pareadas e falhas; motivos de não convergência; persistência nos objetos/CSVs.
- `scripts/run_flexible_modeling.R`: leitura obrigatória do baseline anterior; comparação antes/depois nos mesmos índices; apêndice detalhado; log `.log`; saídas explícitas na árvore de revisão.
- `tests/test_review_flexible_reexecution.R`: verificações independentes de cobertura, disjunção, KKT, falhas, hierarquia, desenho, comparações e entregáveis.
- `tests/run_tests.R`: inclusão do novo teste.

Foram criados 22 arquivos `flexible_*.csv` em `results/prognostico/revisao/aggregated/`, dois objetos `flexible_*.rds`, um log `flexible_reexecution.log`, o apêndice metodológico atualizado e três figuras exploratórias. Previsões por participante permanecem somente no RDS interno reduzido, sem o identificador clínico original.

## Evidências dos critérios de conclusão

| Critério | Evidência |
|---|---|
| Nenhuma saída clínica revista usa o solver afetado | Todos os `flexible_*` da revisão foram regenerados após a correção; baseline anterior permaneceu fora da árvore de revisão e é lido apenas para comparação. |
| Mesmas observações e dependência identificada | `flexible_paired_prediction_audit.csv`: 6.150/6.150 linhas pareadas; `flexible_resampling_audit.csv`: cobertura 5 por participante e disjunção integral; resumos declaram que repetições não são independentes e DP não é IC. |
| Hierarquia descrita conforme verificação | `flexible_hierarchy_audit.csv` confirma efeitos principais candidatos; `flexible_active_hierarchy_audit.csv` registra 1.000 interações ativas, zero violações observadas e ausência de restrição formal. |
| Métricas, falhas e antes/depois rastreáveis | Tabelas externas, comparação congelada, impacto do solver, tuning, hiperparâmetros, KKT e `flexible_failure_audit.csv`; 160 falhas internas contínuas `kkt_not_met`, zero externas/globais. |
| Sem superioridade por pontos médios | Apêndice e `05_flexivel.md` limitam a interpretação e distinguem variabilidade de IC. |
| Resumo e manifesto atualizados | `05_flexivel.md`, este arquivo e novas linhas da Task 05 no `manifesto_inicial.csv`. |

## Integridade e limitações

O hash da fonte continuou `f601adb42c299c2b0572f3e50ff26550b63a2f24dd7173f244a442b498965b71`; o objeto anterior continuou `2758040208a178b246d184b54a679b1729b8f0a023d3799d4d88b145d3957a7e`. Nenhuma dependência foi instalada e nenhuma referência estatística nova foi necessária: a convenção do solver continua fundamentada em `friedman2010_glmnet`, já registrada na Task 04.

As cinco repetições reutilizam a mesma coorte e não produzem cinco estudos independentes. A análise não fornece validação externa nem teste/IC formal de superioridade. Ridge tornou todos os coeficientes numericamente ativos nos ajustes selecionados; a ausência observada de violação forte não converte o procedimento em restrição hierárquica. As 160 falhas internas contínuas foram excluídas da elegibilidade da configuração e não alcançaram os ajustes externos selecionados.

## Passagem

As Tasks 12 e 13 devem consumir somente as saídas `flexible_*` em `results/prognostico/revisao/`, usando `05_flexivel.md` e o apêndice para interpretação. Não devem consumir as métricas logísticas flexíveis congeladas como resultados corrigidos. Nenhuma outra task foi executada ou teve seu status alterado.
