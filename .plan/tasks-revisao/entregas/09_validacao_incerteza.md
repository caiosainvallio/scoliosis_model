# Protocolo e entrega da Task 09 — validação, incerteza e shrinkage

Data do protocolo: 2026-09-08, antes da execução da reamostragem adicional.

## Objetos e alvos pré-especificados

1. **Ajuste aparente:** modelo `lm` para `delta` e modelo `glm(binomial)` para `delta_cat`, ajustados nos 615 participantes com a fórmula principal fixa (dez preditores, 19 parâmetros preditores e intercepto). Descreve ajuste na coorte de desenvolvimento, não desempenho futuro.
2. **Desempenho corrigido da especificação fixa:** estimador de Harrell já calculado com 2.000 réplicas, cada uma reajustando exatamente a fórmula principal. O alvo é o desempenho esperado do processo de ajuste dessa especificação numa amostra da mesma população e do mesmo tamanho; continua sendo avaliação interna.
3. **Equação pós-shrinkage:** coeficientes não interceptais multiplicados pela inclinação de calibração corrigida (limitada a `[0,1]`) e intercepto recalibrado na coorte de treinamento. É a equação destinada a futura validação externa, não uma equação externamente validada.
4. **Avaliação adicional do procedimento completo:** validação cruzada repetida e estratificada. Em cada fold externo, o fator é estimado por bootstrap somente no treinamento externo, o modelo é reduzido e o intercepto é recalibrado somente nesse treinamento; o fold de teste permanece intocado. O alvo é o processo completo de construir a equação pós-shrinkage.

`correcao_colete` permanece uma avaliação transversal basal de possível maleabilidade/corrigibilidade imediata. Coorte, desfechos, fórmulas, hipercorreções e modelos principais não serão alterados.

## IC de desempenho pré-especificado

Para as métricas corrigidas será usado o **IC bootstrap com deslocamento de localização** de Noma et al. (2021): calcula-se o IC percentil da distribuição bootstrap da métrica aparente e deslocam-se os dois limites pela mesma correção de otimismo aplicada à estimativa pontual. Assim, os limites não são quantis do otimismo e não são IC de folds. Serão usadas as 2.000 réplicas congeladas já verificadas, sem repetir o bootstrap apenas para recriar informação existente.

O método, estimativa, nível, número de tentativas, número válido, unidade, direção e alvo serão registrados por linha. As métricas principais são R², RMSE e MAE para o modelo contínuo; AUC, Brier e log loss para o binário. Interceptos e slopes de calibração serão apresentados com o mesmo método, mas separados das métricas principais.

Referência: Noma H, Shinozaki T, Iba K, Teramukai S, Furukawa TA. *Statistics in Medicine*. 2021;40(26):5691–5701. DOI `10.1002/sim.9148`.

## Intervalos de previsão pré-especificados

Os intervalos clássicos atualmente produzidos por `predict.shrunk_linear_model()` serão classificados como aproximações históricas não validadas: usam sigma e a matriz de informação do ajuste aparente, assumem homoscedasticidade e omitem a incerteza do fator.

O intervalo individual adicional será avaliado por **conformal separado normalizado** dentro de folds externos. Cada treinamento externo será dividido, de modo determinístico e sem acessar seu teste, em treino próprio e calibração. O treino próprio estimará modelo, shrinkage, intercepto e uma função de escala positiva dos resíduos; a calibração obterá o quantil conformal finito de `|y - pred| / escala`. A cobertura e largura serão medidas apenas no teste externo. A normalização permite largura dependente do valor ajustado e a calibração separada incorpora, nos resíduos de calibração, o erro do processo completo estimado no treino próprio. A repetição externa mede a cobertura interna do procedimento, não prova cobertura em outro centro ou população.

O IC da média condicional da equação final será publicado como **indisponível**: a fórmula histórica não incorpora heteroscedasticidade nem a incerteza do fator, e a avaliação conformal proposta é para observações individuais, não para a média. Também não serão publicados intervalos individuais para os 615 participantes como se estivessem externamente calibrados; serão publicados somente cobertura/largura agregadas da avaliação interna e o motivo da indisponibilidade do intervalo final.

Referência conformal: Lei J, G'Sell M, Rinaldo A, Tibshirani RJ, Wasserman L. *Journal of the American Statistical Association*. 2018;113(523):1094–1111. DOI `10.1080/01621459.2017.1307116`.

## Configuração computacional registrada

- IC de desempenho: 2.000 réplicas congeladas, seed raiz `20260906`.
- Avaliação completa do shrinkage: 5 repetições de 10 folds externos; 200 réplicas internas por fold; seed raiz `20260909`.
- Cobertura conformal: os mesmos 50 folds externos; 80% do treinamento externo para treino próprio, 20% para calibração; 200 réplicas internas por fold; nível nominal 95%; seed raiz `20260910`.
- Falha será contada uma vez por réplica/modelo. Indisponibilidade por métrica será uma contagem separada.

Os resultados, critérios finais, custo observado e limitações serão acrescentados a este arquivo somente depois da execução.

## Resultados executados

### IC do desempenho corrigido da especificação fixa

As 2.000 réplicas congeladas foram consumidas sem refazer o bootstrap antigo. Todas foram válidas nos dois modelos. O IC deslocado de 95% produziu:

| Modelo | Métrica (unidade) | Corrigida | IC 95% deslocado |
|---|---|---:|---:|
| Linear | R² (proporção) | 0,3637 | 0,3218 a 0,4410 |
| Linear | RMSE (graus de delta) | 4,2763 | 3,9267 a 4,4730 |
| Linear | MAE (graus de delta) | 3,3944 | 3,1028 a 3,5559 |
| Logístico | AUC (probabilidade de ordenação) | 0,8483 | 0,8291 a 0,8839 |
| Logístico | Brier (erro quadrático de probabilidade) | 0,1600 | 0,1363 a 0,1707 |
| Logístico | Log loss (escore logarítmico) | 0,4892 | 0,4297 a 0,5143 |

O erro médio, os interceptos de calibração e as inclinações de calibração mantêm suas estimativas corrigidas, mas seus IC por deslocamento ficaram explicitamente indisponíveis. Em cada amostra bootstrap, essas estatísticas aparentes são fixadas por construção em 0 ou 1 quando calculadas sobre o mesmo ajuste; deslocar seus quantis geraria intervalos espuriamente degenerados. `validation_performance_ci.csv` registra `NA`, método e motivo por linha.

### Procedimento completo pós-shrinkage

Foram concluídos 50 folds externos internos (5 repetições × 10 folds), com 200 bootstraps internos por modelo e fold. Todos os 20.000 ajustes internos foram válidos. O fator e o intercepto foram sempre estimados no treinamento; nenhuma linha de teste foi usada nesses passos.

| Modelo | Métrica | Média nas 5 repetições | Amplitude entre repetições |
|---|---|---:|---:|
| Linear | R² | 0,3546 | 0,3479 a 0,3597 |
| Linear | RMSE (graus) | 4,2965 | 4,2797 a 4,3187 |
| Linear | MAE (graus) | 3,4030 | 3,3849 a 3,4208 |
| Linear | Intercepto de calibração (graus) | -0,1024 | -0,1775 a -0,0701 |
| Linear | Slope de calibração | 0,9790 | 0,9677 a 0,9860 |
| Logístico | AUC | 0,8452 | 0,8433 a 0,8465 |
| Logístico | Brier | 0,1604 | 0,1595 a 0,1617 |
| Logístico | Log loss | 0,4870 | 0,4849 a 0,4899 |
| Logístico | Calibração no intercepto (log-odds) | 0,0072 | -0,0009 a 0,0167 |
| Logístico | Slope de calibração | 0,9930 | 0,9823 a 1,0043 |

As amplitudes entre cinco repetições são descrições da dependência da partição, **não IC**. Os fatores dentro dos folds variaram de 0,9458 a 0,9622 no linear e de 0,8528 a 0,8810 no logístico. A equação nos dados completos preserva os fatores 0,958050 (linear) e 0,883549 (logístico), com interceptos recalibrados -0,047748 e -2,857062, respectivamente.

### Intervalos individuais

A avaliação conformal utilizou 50 folds, com treino próprio, calibração e teste mutuamente separados. Em cada repetição, cada um dos 615 participantes apareceu exatamente uma vez no teste; o denominador total de 3.075 previsões representa cinco previsões repetidas por participante, não 3.075 indivíduos independentes.

- Cobertura nominal: 95%.
- Cobertura interna combinada: 94,86%.
- Cobertura por repetição: 94,31% a 95,61%.
- Largura média combinada: 17,44° de delta.
- Largura média por repetição: 17,15° a 17,75°.

Essa cobertura é interna, depende de permutabilidade na população representada e não garante cobertura externa. O IC da média e o intervalo individual da equação final ajustada nos 615 participantes continuam indisponíveis pelos motivos pré-especificados. A amplitude bootstrap histórica de previsões permanece uma medida de estabilidade individual e não foi renomeada como IC de desempenho, IC da média ou intervalo de predição.

## Saídas para consumo

- `validation_performance_ci.csv`: estimativas e IC de desempenho, com alvo, unidade, método, direção, denominadores e indisponibilidades;
- `validation_failure_audit.csv`: falhas por réplica/modelo separadas de indisponibilidade por métrica;
- `validation_objects.csv`, `validation_final_shrinkage_summary.csv`, `validation_final_shrinkage_coefficients.csv` e `validation_final_equations.txt`: distinção e reprodução dos três objetos;
- `validation_shrinkage_procedure_audit.csv`, `validation_shrinkage_metrics_by_repeat.csv` e `validation_shrinkage_metrics_summary.csv`: avaliação adicional do procedimento completo;
- `prediction_intervals_coverage_by_fold.csv`, `prediction_intervals_coverage_by_repeat.csv` e `prediction_intervals_availability.csv`: cobertura, largura, denominadores e limites;
- `validation_output_manifest.csv`, `validation_task09.log` e `validation_review_reduced.rds`: hashes, custo, sementes e objeto interno reduzido.

Todas as saídas ficam sob `results/prognostico/revisao/`. Não houve validação externa nem alteração da coorte, da especificação principal ou das decisões clínicas.
