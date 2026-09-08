# Entrega da Task 05 — reexecução flexível e hierarquia

Data: 2026-09-07

## Resultado

A análise flexível exploratória foi reexecutada integralmente com o solver corrigido da Task 04. A coorte permaneceu com 615 participantes e 317 eventos; `correcao_colete` permaneceu uma medida transversal basal de corrigibilidade/maleabilidade imediata. Os resultados congelados e o objeto flexível anterior foram preservados para comparação.

Foram reconstruídos deterministicamente os mesmos 10 folds externos em 5 repetições e os 5 folds internos. Cada participante apareceu uma vez no teste por repetição. Todos os conjuntos treino/teste externos e treino/validação internos foram disjuntos, e os índices coincidiram com os do objeto anterior. O pré-processamento — medianas, modos, níveis, centros, escalas, limites e nós das splines — foi estimado somente no treino aplicável.

## Especificação e seleção

A matriz candidata teve 48 colunas: 6 componentes lineares, 18 componentes de spline natural (3 graus de liberdade para cada uma das 6 variáveis numéricas), 14 dummies e 10 interações. Cobb basal está incluído nesta análise exploratória. Os nós internos do ajuste global ilustrativo e seus limites estão registrados em `flexible_spline_specification.csv`; esse ajuste posterior à avaliação externa não fornece desempenho validado.

A grade foi mantida: alpha em 0, 0,25, 0,50, 0,75 e 1; quatro frações de lambda entre 1 e 0,001. A regra one-SE minimizou RMSE contínuo ou log loss logístico e desempatou por maior fração de lambda, menor alpha e menor `config_id`. Os 100 ajustes externos selecionaram ridge (`alpha=0`); 99 selecionaram fração 0,01 e um selecionou 0,001. Lambda absoluto, lambda máximo, limiar one-SE, objetivo e KKT estão disponíveis por ajuste.

Houve 160 falhas `kkt_not_met` entre 5.000 avaliações internas contínuas e nenhuma entre as 5.000 logísticas. Configurações incompletas foram inelegíveis. Nenhum dos 100 ajustes externos selecionados ou dos dois ajustes globais falhou. O maior KKT externo foi `9,99e-09`, abaixo da tolerância de `1e-6`.

## Desempenho e comparação pareada

As métricas agregadas sobre as 3.075 previsões externas por família foram:

| Família | Métrica | Flexível corrigido | Congelado nos mesmos folds |
|---|---:|---:|---:|
| Contínua | R² | 0,3826 | 0,3560 |
| Contínua | RMSE | 4,2022° | 4,2919° |
| Contínua | MAE | 3,3386° | 3,4102° |
| Contínua | Intercepto de calibração | 0,6874° | −0,2802° |
| Contínua | Inclinação de calibração | 1,1454 | 0,9386 |
| Logística | AUC | 0,8499 | 0,8431 |
| Logística | Brier | 0,1576 | 0,1618 |
| Logística | Log loss | 0,4792 | 0,4942 |
| Logística | Intercepto de calibração | −0,0047 | −0,0071 |
| Logística | Inclinação de calibração | 1,1109 | 0,8438 |

Na comparação por repetição, flexível menos congelado, as diferenças médias foram −0,0897° em RMSE, −0,0716° em MAE, +0,0065 em AUC, −0,0042 em Brier e −0,0151 em log loss. Para calibração logística, as diferenças foram +0,0024 no intercepto e +0,2671 na inclinação; a direção deve ser julgada por proximidade aos alvos 0 e 1, não pelo sinal isolado.

Esses pontos médios favorecem modestamente a estratégia flexível nas métricas de erro/discriminação e aproximam a inclinação logística de 1, mas não constituem demonstração formal de superioridade. As cinco repetições reutilizam as mesmas pessoas; o desvio-padrão entre repetições mede variabilidade de reamostragem e não é intervalo de confiança. O ganho também não pode ser atribuído apenas a splines, porque a estratégia acrescenta Cobb basal, interações e penalização.

A variabilidade individual entre as cinco previsões teve amplitude mediana de 0,499° no contínuo e 0,0494 na probabilidade logística; os percentis 97,5% das amplitudes foram 1,613° e 0,1346, respectivamente. Esses valores descrevem estabilidade entre partições, não erro residual ou intervalo de predição.

## Impacto do solver

O objeto anterior e o corrigido usaram índices e observações externas idênticos. Na comparação por repetição, corrigido menos anterior, a AUC logística mudou +0,00019, o Brier −0,00112, o log loss −0,00382 e a inclinação de calibração −0,12782, aproximando-se de 1. A mudança absoluta média nas probabilidades foi 0,02375 e a máxima 0,12922. A família contínua foi numericamente idêntica, com diferença média de RMSE zero e alterações de previsões apenas na ordem de `1e-14`.

A conclusão substantiva não mudou: a modelagem flexível permanece exploratória, sem validação externa e sem evidência formal de superioridade. Nenhuma saída clínica da árvore de revisão usa o solver logístico anterior.

## Hierarquia

Os efeitos principais correspondentes estavam presentes na matriz candidata em todas as interações. Não foi imposta restrição formal de hierarquia forte. Como a regra one-SE selecionou ridge em todos os ajustes externos, os 1.000 coeficientes de interação auditados estavam numericamente ativos e seus efeitos principais também; assim, não houve violação observada de hierarquia forte nesses ajustes. Isso é uma propriedade observada das soluções obtidas, não uma garantia do algoritmo. Nenhum cenário hierarquicamente restrito novo foi criado.

## Saídas para consumo

- Task 12: `flexible_external_metrics.csv`, `flexible_external_metric_distribution.csv`, `flexible_prediction_stability.csv`, `flexible_selection_frequency.csv`, `flexible_coefficient_stability.csv`, `flexible_spline_specification.csv`, `flexible_design_expansion.csv` e as três figuras flexíveis na árvore de revisão.
- Task 13: este resumo e `flexible_methodological_appendix.md`, além de `flexible_frozen_comparison_summary.csv`, `flexible_solver_before_after_metrics.csv`, `flexible_failure_audit.csv` e as auditorias de hierarquia/reamostragem.
- Auditoria/reprodução: `flexible_nested_internal.rds`, `flexible_solver_before_after.rds` e `flexible_reexecution.log`.

Limitações: a análise é interna e repetida; não há IC de superioridade, validação externa ou restrição formal de hierarquia. Os coeficientes penalizados de bases spline não são efeitos clínicos isolados. As falhas internas contínuas tornam as configurações correspondentes inelegíveis e estão explicitamente registradas; não afetaram os ajustes externos selecionados.
