# Entrega da Task 08 — pressupostos, diagnósticos e inferência robusta

Data: 2026-09-08  
Escopo: auditoria dos modelos principais congelados, correção da convenção inferencial linear e sensibilidades diagnósticas, sem alterar a coorte nem a especificação.

## Decisões preservadas

A coorte permaneceu com 615 participantes, 317 eventos e 298 não eventos; a matriz dos dois modelos permaneceu com 20 colunas (intercepto e 19 parâmetros preditores) e posto 20. Os coeficientes pontuais reproduziram o baseline com diferença absoluta máxima de `4,66e-15`, atribuível à representação numérica. Nenhum caso foi excluído e nenhuma fórmula principal foi alterada.

`correcao_colete` foi preservada como avaliação transversal basal de possível maleabilidade/corrigibilidade imediata. As três hipercorreções verdadeiras continuam na análise principal; sua influência permanece uma sensibilidade da Task 10.

## Convenções inferenciais

A inconsistência em `wald_coefficient_table()` foi corrigida. Para objetos `lm`, estimativas, erros-padrão, testes e IC de 95% agora usam a mesma inferência clássica baseada em t com 595 graus de liberdade. Para o modelo logístico, a convenção continua sendo Wald normal assintótica, explicitada nas colunas da saída.

Como sensibilidade à heteroscedasticidade, a matriz HC3 foi calculada com `sandwich::vcovHC(type = "HC3")`; testes e IC de 95% usam t com os mesmos 595 graus de liberdade. Essa escolha é deliberadamente conservadora e coerente dentro da tabela. HC3 altera somente a incerteza dos coeficientes: não altera coeficientes pontuais, forma funcional, calibração, dependência nem cobertura de intervalos de predição individuais. A matriz robusta é fundamentada por `white1980_robust_covariance`, e a modificação HC3 por `mackinnon1985_hc3`, no BibTeX.

Os erros-padrão HC3 variaram de 0,928 a 1,154 vezes os clássicos. A única mudança de travessia do zero ocorreu para `cifose_toracica`: IC clássico t `[-0,07029; 0,000049]`, p=0,05032; IC HC3 `[-0,06922; -0,001023]`, p=0,04353. Essa proximidade do limiar reforça que a interpretação não deve depender de uma dicotomia de p=0,05.

## Pressuposto, evidência, interpretação, ação e limite

| Pressuposto | Evidência observada | Interpretação | Ação | Limitação |
|---|---|---|---|---|
| Independência | 615 IDs únicos; duplicatas conhecidas removidas antes do ajuste | Uma linha por participante sustenta a unidade analítica | Explicitar o desenho; não aplicar autocorrelação à ordem arbitrária dos pacientes | Centro, avaliador e outras estruturas de agrupamento não existem na fonte e não podem ser avaliados |
| Média condicional linear | LOWESS de resíduos versus ajustado e resíduos componentes dos cinco termos numéricos preparado | Diagnóstico gráfico, sem teste binário de aprovação | Task 12 deve apresentar a forma e confrontá-la com a análise flexível | A suavização é exploratória e não mede desempenho externo |
| Linearidade no logit | LOWESS de resíduos componentes na escala do preditor linear preparado | Convergência não aprova a forma do logit | Integrar gráficos e calibração, mantendo o logit principal congelado | Extremos de probabilidade e desfecho binário limitam a leitura local |
| Variância constante | BP=36,004; 19 gl; p=0,01054; R² auxiliar=0,05854; razão máxima/mínima dos DP residuais por quintil=1,265 | Evidência contra homoscedasticidade, com associação auxiliar modesta e padrão não monotônico entre quintis | Relatar inferência clássica e HC3; mostrar o padrão gráfico | HC3 não corrige a média nem intervalos individuais |
| Caudas dos resíduos | 27 resíduos padronizados com módulo >2 e 2 com módulo >3; assimetria=-0,400; excesso de curtose=0,681 | Há caudas a inspecionar; não se exige normalidade das covariáveis | Usar Q–Q, resumo de caudas, influência e HC3 em conjunto | O gráfico não demonstra normalidade exata nem cobertura externa |
| Colinearidade | Posto 20/20; GVIF ajustado entre 1,047 e 1,381; maior índice de condição padronizado=5,723 | Desenho estimável e sem sinal numérico forte de redundância nesta codificação | Relatar GVIF, graus de liberdade, transformação e índices completos | Nenhum limiar isolado prova validade; índices dependem de escala/codificação |
| Influência | 55 observações sinalizadas no linear e 99 no logístico por pelo menos um critério; critérios se sobrepõem | Sinais para investigação, não regras de exclusão | IDs internos e critérios foram preparados para a Task 10 | A análise sem casos ainda será executada pela Task 10 e não redefine a coorte |
| Separação logística | Programação quadrática: sem separação completa ou quase-completa; `glm` convergiu, coeficientes finitos, zero células fatoriais com desfecho único; menor categoria n=37 | O diagnóstico formal cobre o desenho multivariável; os demais sinais são complementares | Relatar método, convergência, estimabilidade e categorias raras em conjunto | Não garante forma funcional, calibração, precisão ou estabilidade |

A tabela legível por máquina correspondente é `diagnostics_assumption_evidence.csv`. Nenhum pressuposto recebeu aprovação global baseada apenas em p>0,05, convergência ou coeficientes finitos.

## Separação logística

Foi implementado um teste de viabilidade por programação quadrática baseado nas condições geométricas de Albert e Anderson (`albert1984_logistic_separation`, DOI `10.1093/biomet/71.1.1`). Para o desenho assinado, a separação completa procura uma direção com todas as margens estritamente positivas; a quase-completa procura margens não negativas e ao menos uma positiva. Os testes sintéticos reproduzem separação completa, quase-completa e sobreposição conhecidas. Na coorte não foi detectada separação completa ou quase-completa.

## Saídas para consumo

- `coefficients_linear_classic_corrected.csv`: inferência clássica linear coerente em t;
- `coefficients_linear_hc3.csv`: sensibilidade HC3 com os mesmos coeficientes pontuais;
- `diagnostics_inference_comparison.csv`: comparação termo a termo;
- `diagnostics_assumption_evidence.csv` e demais `diagnostics_*.csv`: evidências auditáveis;
- `diagnostics_plot_data.rds`: dados reduzidos para as figuras da Task 12;
- `diagnostics_influence_task10_internal.csv`: dados individuais restritos aos logs internos para as sensibilidades da Task 10;
- `diagnostics_output_manifest.csv`: hashes e consumidores de todas as saídas analíticas desta task.

As Tasks 09, 10, 12, 13 e 15 devem consumir as saídas na árvore `results/prognostico/revisao/`. Os resultados originais em `results/prognostico/aggregated/` permanecem baseline congelado e não foram sobrescritos.

## Limites

Os diagnósticos são internos e não substituem validação externa. A independência entre centros/avaliadores não é verificável porque essas variáveis não estão disponíveis. A suavização é descritiva. A inferência de coeficientes é aparente, e a análise de influência sem casos cabe à Task 10. Nenhum teste de normalidade de covariáveis, Shapiro–Wilk ou autocorrelação em ordem arbitrária foi reinstalado.
