# Entrega da Task 10 — sensibilidades, Cobb basal e comparadores

Data: 2026-09-08  
Escopo: complementos de robustez separados da análise congelada, sem excluir participantes da coorte principal e sem alterar as fórmulas principais.

## Protocolo e comparabilidade

As comparações adicionais foram executadas nos mesmos 5 × 10 folds estratificados e com a mesma seed `20260909` da avaliação da Task 09. Em cada fold, modelos, sinais de influência, média de delta e prevalência de melhora foram estimados somente no treinamento. Todas as alternativas foram avaliadas no mesmo fold de teste completo; cada repetição reúne exatamente 615 previsões. A codificação dos fatores é a especificação fixa anterior aos dados e não há transformação estimada na coorte completa.

As amplitudes entre cinco repetições descrevem dependência das partições e não são intervalos de confiança. A avaliação é interna e não demonstra transportabilidade. A reamostragem comparável segue a finalidade de validação interna descrita por `steyerberg2001_bootstrap`; calibração é interpretada segundo `vancalster2019_calibration`.

## Resultados comparáveis

| Cenário | Conjunto de ajuste | Conjunto de avaliação | Resultado principal | Conclusão |
|---|---|---|---:|---|
| Principal | 553–555 por fold | Mesmos testes completos; n=615/repetição | RMSE 4,3008°; Brier 0,16047 | Referência pareada interna |
| Influência excluída | Linear: 499–509; logístico: 457–479 por fold | Mesmos testes completos; n=615/repetição | RMSE +0,0696°; Brier +0,01707 versus principal | A melhora aparente na subamostra selecionada não generalizou aos casos mantidos no teste |
| Hipercorreções excluídas | 550–553 por fold | Mesmos testes completos; n=615/repetição | RMSE +0,00186°; Brier +0,00000004 | Impacto global desprezível; os três casos permanecem na principal |
| Delta condicionado ao Cobb basal | 553–555 por fold | Mesmos testes completos; n=615/repetição | RMSE 4,2322°; −0,0686° versus principal | Pequeno ganho interno; não redefine o desfecho nem a especificação principal |
| Média de delta do treino | 553–555 por fold | Mesmos testes completos; n=615/repetição | RMSE 5,3518° | O principal reduziu RMSE em 1,0510° |
| Prevalência do treino | 553–555 por fold | Mesmos testes completos; n=615/repetição | Brier 0,24976 | O principal reduziu Brier em 0,08929 |

Para o modelo principal, as amplitudes entre repetições foram RMSE 4,2830–4,3233° e Brier 0,15954–0,16187. Para a alternativa com Cobb basal, o RMSE variou de 4,2174 a 4,2598°. Não foi usado R² para escolher entre desfechos distintos; todas as comparações acima estão na escala original de delta ou de probabilidade indicada.

Onze dos 50 ajustes logísticos após exclusão de influentes emitiram aviso de probabilidades ajustadas numericamente 0 ou 1. Os ajustes convergiram e produziram coeficientes finitos, mas o aviso, o log loss médio pior (0,76695 contra 0,48957) e a inclinação de calibração muito menor (0,302 contra 0,863) reforçam que a exclusão diagnóstica não é uma estratégia de desenvolvimento defensável.

## Por que a melhora na subamostra é aparente

Na análise histórica consolidada, excluir os 99 casos sinalizados pelo modelo logístico e avaliar o reajuste nos 516 restantes elevou a AUC aparente de 0,8674 para 0,9710 e reduziu o log loss de 0,4548 para 0,2204. Quando o mesmo reajuste foi aplicado à coorte completa de 615, a AUC foi 0,8642 e o log loss 0,6417. A avaliação em folds confirma o padrão sem usar o teste para decidir exclusões: AUC média 0,8364, Brier 0,17754 e log loss 0,76695, todos piores que o principal. Retirar justamente observações de grande resíduo seleciona uma população mais fácil; não demonstra ganho prognóstico.

As mudanças aparentes de coeficientes e previsões estão quantificadas termo a termo. Como mudanças relativas explodem para coeficientes próximos de zero, a interpretação deve priorizar a diferença absoluta e a mudança das previsões. Na retirada das hipercorreções, a diferença absoluta média de previsão foi 0,06295° no linear e 0,0000017 na probabilidade; os máximos foram 0,5504° e 0,0000062. Nos cenários de influência, as diferenças foram maiores, coerentes com sua natureza diagnóstica, sem alterar o modelo principal.

## Cobb basal e equivalência algébrica

Foram ajustados, com os mesmos desenhos e observações em cada fold:

1. `delta ~ Cobb_basal + X`;
2. `Cobb_final ~ Cobb_basal + X`, reconvertendo a previsão por `delta_previsto = Cobb_final_previsto - Cobb_basal`.

As matrizes de desenho foram idênticas nos 50 folds. Após acrescentar 1 ao coeficiente de Cobb basal da primeira parametrização, a maior diferença absoluta entre coeficientes foi `1,59e-13`; a maior diferença entre previsões reconvertidas foi `1,39e-13`, abaixo da tolerância pré-definida de `1e-10`. A equivalência é numérica e algébrica para mínimos quadrados com Cobb basal incluído; não torna o R² do Cobb final comparável ao R² de delta como regra de seleção de alvo.

## Estratos e limite anatômico

A descrição existente foi integrada para faixas de previsão, sexo, Lenke, Risser, flexibilidade e escoliômetro, sempre com n, eventos/não eventos e intervalos descritivos de 95% para média de delta e prevalência (Wilson). Estratos com n<20 permanecem marcados como pequenos. Não foram procuradas interações, cortes ou subgrupos pós-dados, e os intervalos não sustentam alegações de heterogeneidade.

A fonte identifica a região da maior curva somente no basal e fornece aos seis meses apenas a magnitude máxima. Assim, não é possível saber se os máximos basal e final pertencem à mesma curva anatômica; esta limitação permanece explícita e impede interpretação de delta como mudança garantida da mesma curva.

## Saídas para consumo

- `sensitivity_scenario_conclusions.csv`: tabela cenário/motivação/n/avaliação/mudança/conclusão;
- `sensitivity_resampling_metrics_by_repeat.csv`, `sensitivity_resampling_metrics_summary.csv` e `sensitivity_resampling_audit.csv`: avaliação pareada, warnings e separação treino–teste;
- `baseline_comparisons.csv`: ganhos contra média e prevalência estimadas no treino;
- `sensitivity_cobb_reparameterization.csv`: verificação numérica das formulações;
- `sensitivity_cobb_target_apparent_*.csv`: consolidação rastreável do alvo alternativo histórico, claramente marcado como aparente e em sua escala própria;
- `sensitivity_apparent_and_full_cohort_*.csv`, `sensitivity_coefficient_changes.csv` e `sensitivity_prediction_changes.csv`: consolidação das análises aparentes e na coorte completa;
- `sensitivity_strata_descriptive.csv` e `sensitivity_anatomical_region_summary.csv`: descrição com incerteza e limite anatômico;
- `sensitivity_output_manifest.csv`, `sensitivity_task10.log` e `sensitivity_review_reduced.rds`: hashes, execução e objeto interno reduzido.

As Tasks 12, 13 e 15 devem consumir as saídas em `results/prognostico/revisao/`, manter a coorte principal de 615 e distinguir avaliação interna de validação externa.
