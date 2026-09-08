# Entrega da Task 12 — figuras, legendas e blocos Quarto

Data: 2026-09-08. Todas as figuras novas usam azul, verde, laranja e roxo distinguíveis sem depender apenas da cor; PNG tem 1.800 × 1.200 px (180 dpi) e cada figura possui SVG equivalente. A convenção é `delta = maior Cobb aos seis meses − maior Cobb basal`, em graus.

## Figuras e interpretação permitida

| Arquivo-base | Estimador e avaliação identificados | Legenda autossuficiente |
|---|---|---|
| `linear_delta_distribution` | Descrição da coorte, n=615 | “Distribuição de delta (graus; n=615). As linhas em −5°, 0° e +5° são referências descritivas; −5° define melhora radiográfica de pelo menos 5°. Não é análise de progressão e o máximo final não permite confirmar a mesma região anatômica.” |
| `linear_observed_predicted` | Modelo linear congelado, avaliação aparente na coorte completa | “Delta observado versus previsto pelo modelo linear aparente (n=615). A linha pontilhada é a identidade e a contínua é a calibração no mesmo conjunto de ajuste; não representa validação externa.” |
| `linear_diagnostics` | Diagnósticos aparentes do modelo linear, n=615 | “Resíduos, Q–Q, influência e dispersão residual por quintil do valor ajustado para o modelo linear aparente (n=615). A suavização é diagnóstica; HC3 é a sensibilidade de inferência para heteroscedasticidade, não uma correção de previsão.” |
| `linear_coefficients_hc3` | Coeficientes aparentes; IC 95% t-HC3, 595 gl | “Coeficientes do modelo linear congelado em graus de delta, com IC 95% HC3 e distribuição t (595 graus de liberdade). São estimativas aparentes de associação; não são os coeficientes pós-shrinkage.” |
| `logistic_roc_calibration` | Modelo logístico congelado, ROC e calibração aparentes, n=615 | “ROC e calibração suave do modelo logístico aparente para melhora radiográfica de pelo menos 5° (n=615; 317 eventos e 298 não eventos). A diagonal é a identidade; pontos são décimos de probabilidade e a marcação inferior mostra a distribuição prevista. Não há bandas, pois não foi validado um método de banda para esta curva.” |
| `logistic_coefficients_shrunk` | Equação final pós-shrinkage; sem IC | “Odds ratios da equação logística final pós-shrinkage. Para variáveis contínuas, os contrastes são +10 unidades; para correção pelo colete, +10 pontos percentuais; para categorias, contraste com a referência. Não são apresentados IC porque IC aparentes para coeficientes pós-shrinkage não são compatíveis com o procedimento validado.” |
| `stability_repeated_predictions` | 5 × 10 CV interna; 5 previsões por participante | “Amplitude das cinco previsões externas internas por participante (n=615), da modelagem flexível: graus para delta e pontos percentuais para melhora. As cinco previsões por participante derivam de repetições da CV e não são pessoas independentes; o histograma é descritivo de estabilidade.” |
| `flexible_clinical_relations` | Ajustes globais exploratórios após avaliação externa interna | “Relações preditas pelos ajustes globais flexíveis exploratórios, na escala clínica, com demais covariáveis nos valores médios/modais da receita. Linhas verticais delimitam a faixa observada usada para nós das splines. Estes ajustes foram feitos após a CV para ilustração, não fornecem efeito causal, IC ou desempenho externo.” |
| `flexible_selection_stability` | Frequência de variáveis clínicas adicionais nos 50 ajustes externos | “Frequência de seleção de componentes clínicos adicionais nos 50 ajustes externos (5 repetições × 10 folds) da modelagem flexível. É estabilidade de seleção, não efeito clínico nem validação externa.” |
| `sensitivity_comparisons` | Média e amplitude em 5 repetições, mesmos testes de 615 por repetição | “RMSE linear (graus de delta) e Brier logístico das sensibilidades e referências simples, avaliados nos mesmos folds de teste completos (615 por repetição). Pontos são médias entre cinco repetições e barras são amplitudes entre partições, não IC; não ordenam estratégias como vencedoras.” |
| `cart_illustrative_tree`, `cart_stability` | Reuso sem alteração da Task 07 | Usar as legendas já entregues em `07_cart_visualizacao.md`: árvore ilustrativa aparente e estabilidade em 50 árvores dos treinamentos externos, respectivamente. |

## Blocos Quarto

```{=markdown}
![Distribuição de delta (graus; n=615). As linhas em −5°, 0° e +5° são referências descritivas; −5° define melhora radiográfica de pelo menos 5°. Não é análise de progressão e o máximo final não permite confirmar a mesma região anatômica.](results/prognostico/revisao/figures/linear_delta_distribution.png){fig-alt="Histograma de delta em graus com marcas em menos cinco, zero e mais cinco graus." width="100%"}

![Diagnósticos aparentes do modelo linear na coorte completa (n=615): resíduos, Q–Q, influência e dispersão por quintil. A suavização é diagnóstica e não é validação externa.](results/prognostico/revisao/figures/linear_diagnostics.png){fig-alt="Quatro painéis de diagnóstico do modelo linear." width="100%"}

![ROC e calibração aparente do modelo logístico para melhora radiográfica de pelo menos 5° (n=615; 317 eventos). A diagonal é a identidade; não há bandas porque não foi validado método de banda para esta curva.](results/prognostico/revisao/figures/logistic_roc_calibration.png){fig-alt="Curva ROC e curva de calibração aparente sem bandas." width="100%"}

![Amplitude das cinco previsões internas por participante da modelagem flexível (n=615): graus para delta e pontos percentuais para melhora. As cinco previsões por pessoa não são independentes.](results/prognostico/revisao/figures/stability_repeated_predictions.png){fig-alt="Histogramas de estabilidade de previsões lineares e logísticas." width="100%"}

![Relações previstas pelos ajustes globais flexíveis exploratórios após a validação interna, com demais covariáveis nos valores médios ou modais. Linhas verticais delimitam a faixa observada usada pelas splines; não são efeitos causais nem validação externa.](results/prognostico/revisao/figures/flexible_clinical_relations.png){fig-alt="Quatro curvas clínicas exploratórias para correção pelo colete e Cobb basal." width="100%"}
```

## Limitações preservadas

- A correção pelo colete permanece uma medida transversal basal de possível maleabilidade/corrigibilidade imediata; nenhuma figura a trata como vazamento temporal, efeito causal ou garantia de manutenção.
- Curvas e diagnósticos aparentes são assim identificados. Desempenho, estabilidade e sensibilidades são internos; nenhuma legenda declara validação externa.
- As amplitudes das cinco repetições e as barras de sensibilidade não são IC. Não foram criados IC aparentes para coeficientes pós-shrinkage nem bandas de calibração não sustentadas.
