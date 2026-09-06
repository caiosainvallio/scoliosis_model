# Parecer estatístico sobre os modelos prognósticos de resposta radiográfica

## Conclusão executiva

A base é **quantitativamente plausível para o desenvolvimento preliminar** dos modelos de regressão linear e logística especificados, mas os resultados fornecidos **ainda não permitem afirmar que houve validação interna**. O estudo pode ser reenquadrado como desenvolvimento de modelos prognósticos somente após completar a avaliação interna por reamostragem, revisar a forma funcional de preditores contínuos e definir com precisão o momento e a finalidade clínica da previsão.

O modelo linear é defensável como principal por preservar o desfecho contínuo. O modelo logístico é defensável como secundário e apresenta desempenho aparente promissor. A CART deve permanecer exploratória: o arquivo diagnóstico não contém seus resultados de desempenho, calibração, hiperparâmetros finais ou estabilidade, e o pipeline anteriormente descrito reutiliza os mesmos folds para tuning e avaliação, produzindo uma estimativa otimista.

Assim, a redação atualmente justificável é: **“desenvolvimento de modelos prognósticos com avaliação interna planejada”**. A expressão **“desenvolvimento e validação interna”** só deve constar dos resultados e conclusões depois que o bootstrap completo tiver sido executado e relatado.

## 1. Base disponível e complexidade

- Base total: 621 participantes.
- Casos completos nos modelos: 618 (99,5%); perda de apenas 3 participantes (0,48%), todos por ausência em Lenke.
- Modelo linear: 19 parâmetros preditores e 598 graus de liberdade residuais.
- Modelo logístico: 318 eventos de melhora e 300 não eventos; prevalência de 51,5%; 19 parâmetros, equivalendo a 16,7 eventos e 15,8 participantes do menor grupo por parâmetro.
- Matrizes de desenho de ambos os modelos com posto completo; nenhum coeficiente não estimável.
- Ausência de separação no modelo logístico e nenhuma estimativa extrema pelo critério diagnóstico utilizado.
- Sem categorias raras entre os dados efetivamente analisados; a menor categoria observada é Lenke 1 (n=37). Nenhuma combinação entre categoria e desfecho apresentou menos de cinco eventos ou não eventos.
- Colinearidade baixa a moderada: VIF ajustados por termo aproximadamente entre 1,1 e 2,45.

Esses números são tranquilizadores e afastam a preocupação inicial de inviabilidade evidente por escassez extrema de dados. Contudo, razões como “eventos por parâmetro” são apenas triagem. O tamanho mínimo deve ser formalmente calculado com critérios contemporâneos que considerem número de parâmetros candidatos, prevalência e desempenho esperado, não apenas a regra de dez eventos por variável.

## 2. Modelo linear principal

### Desempenho aparente

- R²: 0,400.
- R² ajustado: 0,381.
- RMSE: 4,15°.
- MAE: 3,30°.

O modelo explica cerca de 40% da variação observada na mudança do Cobb dentro da amostra de desenvolvimento. O erro absoluto médio de 3,3° é relevante quando comparado ao limiar clínico de 5°: previsões individuais próximas desse limiar terão incerteza material. O relatório final deveria, além do erro médio, fornecer **intervalos de predição individuais**, que serão mais amplos que RMSE ou MAE.

Os principais sinais do modelo são coerentes com a codificação em que valores mais negativos de `delta` representam maior melhora:

- maior correção no colete: maior melhora prevista (β=-0,123 grau por ponto percentual; IC95% -0,141 a -0,105);
- Lenke 3, 4 e 6, comparados a Lenke 1: menor melhora prevista;
- Risser 1 a 3, comparados a Risser 0: maior melhora prevista;
- rigidez: aproximadamente 0,91° menos melhora que flexibilidade;
- padrão torácico-lombar do escoliômetro: aproximadamente 2,70° menos melhora que a referência normal.

Essas associações são aparentes e não corrigidas por otimismo. Não se deve selecionar ou excluir variáveis com base nesses p-valores.

### Calibração e forma funcional

O intercepto de calibração igual a zero e a inclinação igual a um foram calculados sobre os mesmos dados usados para ajustar uma regressão linear com intercepto. São resultados essencialmente esperados por construção e **não demonstram calibração interna válida**.

O gráfico observado versus previsto sugere alguma curvatura nas extremidades. Os gráficos marginais também sugerem possível não linearidade para idade, IMC e, sobretudo, correção no colete. Essas figuras não avaliam a forma funcional condicionalmente aos demais preditores; recomenda-se comparar termos lineares com splines cúbicos restritos pré-especificados, respeitando o orçamento de graus de liberdade, e incluir essa decisão no procedimento de reamostragem.

### Mudança do Cobb versus Cobb aos seis meses

O modelo alternativo para Cobb aos seis meses ajustado pelo Cobb basal obteve R² aparente de 0,717 e R² ajustado de 0,707, contra 0,400 e 0,381 no modelo de mudança. Entretanto, RMSE e MAE foram quase idênticos (4,08° e 3,28° versus 4,15° e 3,30°) e os alvos não são idênticos; portanto, o maior R² não escolhe automaticamente o modelo alternativo.

A correlação entre Cobb basal e mudança foi praticamente nula (-0,023), enquanto Cobb basal e Cobb final se correlacionaram em 0,716. Isso reduz, nesta base, a preocupação de que a mudança seja dominada por acoplamento matemático com o basal, mas não elimina regressão à média nem erro de mensuração.

Se o uso pretendido é comunicar “quantos graus a paciente deverá melhorar”, o modelo de mudança é clinicamente direto. Se o uso é prever o estado radiográfico futuro, o Cobb aos seis meses ajustado pelo basal é mais natural. Recomenda-se manter um como principal conforme o uso clínico declarado e o outro como análise de sensibilidade, sem escolher retrospectivamente pelo melhor desempenho aparente.

## 3. Modelo logístico secundário

### Desempenho aparente

- AUC: 0,867 (IC95% aparente 0,839–0,895).
- Brier score: 0,148.
- Log loss: 0,457.
- Probabilidades previstas entre 0,0068 e 0,99999.

A discriminação aparente é boa. O Brier também é melhor que o valor de referência de um modelo que prevê apenas a prevalência, aproximadamente 0,250 nesta amostra balanceada. Entretanto, essas métricas foram calculadas nos próprios participantes usados para estimar os 20 coeficientes, logo são otimistas.

A probabilidade máxima quase igual a 1 merece atenção, embora não tenha sido detectada separação e não existam coeficientes extremos. Após bootstrap, uma inclinação de calibração inferior a um indicaria previsões excessivamente extremas e poderia justificar shrinkage ou penalização.

### Calibração

Intercepto igual a zero e slope igual a um são novamente resultados aparentes esperados quando o preditor linear do próprio modelo é recalibrado na amostra de desenvolvimento. O gráfico por decis mostra desvios locais, especialmente nas faixas de probabilidade aproximadas de 0,13 a 0,34, mas agrupamento em decis é instável e não deve ser a análise principal.

Na avaliação final, usar curva suave de calibração, calibration-in-the-large, slope e, idealmente, medidas de erro absoluto de calibração, todos aparentes e corrigidos por otimismo. A AUC não substitui calibração.

### Interpretação e finalidade

O desfecho binário perde informação e cria uma descontinuidade artificial em 5°. Por isso, ele deve permanecer secundário. Sensibilidade, especificidade e acurácia só são úteis se houver um limiar de decisão clínica previamente definido. Se o modelo pretende orientar uma decisão, acrescentar análise de utilidade clínica por curva de decisão; caso contrário, não é obrigatório.

## 4. CART

O ZIP não inclui métricas, árvore final, hiperparâmetros escolhidos, matriz de confusão, estabilidade dos pontos de corte ou resultados de reamostragem da CART. Portanto, **não é possível emitir um julgamento empírico sobre seu desempenho com estes arquivos**.

Pelo código previamente descrito, o mesmo conjunto de folds foi usado para selecionar hiperparâmetros e depois estimar o desempenho do workflow final. Essa reutilização introduz viés de seleção. Para estimar honestamente o desempenho do algoritmo completo, utilizar validação cruzada aninhada (tuning nos folds internos e avaliação nos externos) ou bootstrap de todo o pipeline.

Mesmo com isso, árvores únicas são instáveis. A análise deve relatar:

- frequência da variável na raiz e nos primeiros splits;
- distribuição dos pontos de corte;
- frequência de árvores sem divisão;
- tamanho dos nós terminais;
- AUC/Brier e calibração fora da amostra;
- estabilidade das previsões individuais.

Recomendação: manter a CART como ferramenta exploratória geradora de hipóteses, sem chamá-la de terceiro modelo clínico e sem competir com as regressões pelo desempenho observado.

## 5. Limitações e pontos que exigem auditoria

1.  **Validação interna ausente.** Todos os valores fornecidos são aparentes. Não há R², RMSE, MAE, AUC, Brier ou calibração corrigidos por otimismo.
2.  **Tamanho amostral ainda não calculado formalmente.** A razão observada é confortável como triagem, mas o cálculo de Riley exige desempenho antecipado, não o desempenho aparente escolhido após ver os dados.
3.  **Correção no colete.** É o preditor dominante e varia de 3,7% a 142,4%. Valores acima de 100% podem ser clinicamente possíveis conforme a fórmula e sobremodelagem da curva, mas devem ser auditados. Também é necessário confirmar que a variável está disponível no momento zero de uso. Se depender de radiografia após colocação do colete, o modelo é de predição condicional pós-ajuste, não de prognóstico puramente basal.
4.  **Não linearidade.** As especificações lineares dos preditores contínuos ainda não foram adequadamente validadas.
5.  **Influência.** Foram sinalizados 41 casos pelo limiar de Cook no modelo linear e 50 no logístico; os máximos absolutos de Cook são baixos (0,020 e 0,015), sugerindo que o elevado número decorre do limiar sensível 4/n. Há dois resíduos padronizados extremos no linear (máximo absoluto 4,44). Recomenda-se análise de sensibilidade, sem exclusão automática.
6.  **Representatividade.** A amostra é 89,5% feminina. Isso pode refletir a população clínica, mas limita a precisão e a transportabilidade das previsões para meninos (n=65), mesmo que sexo tenha coeficiente estimável.
7.  **Mensuração do desfecho.** Um ponto de corte de 5° pode se aproximar da variabilidade de mensuração do Cobb. A justificativa clínica e a padronização/leitura radiográfica devem ser explicitadas.
8.  **Dados ausentes.** A perda de 0,48% é pequena; análise por casos completos é pragmática e provavelmente pouco impactante, mas os três casos e a razão da ausência devem ser descritos.
9.  **Generalização.** Desenvolvimento em uma única base não demonstra validade externa. Centro, período de recrutamento, protocolo do colete/S4D e critérios de seleção devem ser descritos para definir a população-alvo.

## 6. Plano metodológico recomendado

1.  Definir população-alvo, momento zero, horizonte de seis meses e uso clínico pretendido.
2.  Congelar previamente os 19 parâmetros e as codificações; evitar stepwise e seleção por p-valor.
3.  Auditar a variável de correção no colete e valores extremos; verificar unidades, fórmula e disponibilidade temporal.
4.  Fazer cálculo formal de tamanho amostral para os desfechos contínuo e binário com `pmsampsize`, usando estimativas externas ou conservadoras de R², e não apenas o R² aparente.
5.  Revisar formas funcionais com parcimônia. Se escolhas forem guiadas pelos dados, repeti-las integralmente em cada reamostragem.
6.  Executar pelo menos 1.000–2.000 amostras bootstrap. Em cada amostra: refazer todo o pré-processamento e desenvolvimento, medir desempenho na amostra bootstrap e na base original, calcular otimismo e corrigi-lo.
7.  Modelo linear: relatar R², RMSE, MAE, intercepto e slope de calibração, curva suave, intervalos de predição e versões corrigidas por otimismo.
8.  Modelo logístico: relatar AUC, Brier, log loss, intercepto e slope de calibração, curva suave e versões corrigidas por otimismo. Considerar shrinkage uniforme ou ridge se o bootstrap mostrar sobreajuste.
9.  Apresentar equações completas, interceptos, coeficientes, unidades, níveis de referência e tratamento dos valores ausentes. Evitar arredondamento excessivo.
10. Avaliar a CART em procedimento aninhado e mantê-la explicitamente exploratória.
11. Planejar validação externa futura antes de qualquer recomendação de uso clínico.
12. Relatar o estudo conforme TRIPOD+AI e fazer uma autoavaliação de risco de viés pelo PROBAST/PROBAST+AI aplicável.

## Parecer final

**Viabilidade:** favorável, mas condicional, para os modelos linear e logístico. A amostra e a distribuição do desfecho são muito melhores do que inicialmente se poderia temer: 618 casos completos, 19 parâmetros, desfecho binário equilibrado, matrizes de posto completo, ausência de separação e pouca colinearidade. Não há fundamento, pelos números atuais, para rejeitar de saída o enquadramento como desenvolvimento de modelos prognósticos.

**Estado atual:** incompleto para alegar validação interna. O desempenho promissor — R² 0,40 e RMSE 4,15° no linear; AUC 0,867 e Brier 0,148 no logístico — é somente aparente. A calibração aparente 0/1 não acrescenta evidência. O ponto decisivo será quanto esses números se deterioram após bootstrap e qual será a inclinação de calibração corrigida.

**Hierarquia recomendada:** modelo linear da mudança como principal, desde que corresponda ao uso clínico; modelo logístico como secundário; CART apenas exploratória. O modelo de Cobb final ajustado pelo basal deve ser análise de sensibilidade ou alternativa de alvo, não vencedor automático pelo R² aparente.

**Formulação editorial recomendada:** “desenvolvimento e avaliação interna por bootstrap de modelos prognósticos”, evitando chamar o modelo de “validado” como propriedade definitiva e deixando explícita a necessidade de validação externa.

## Referências metodológicas essenciais

- Collins GS et al. TRIPOD+AI statement: updated guidance for reporting clinical prediction models that use regression or machine learning methods. *BMJ*. 2024;385:e078378. <https://www.bmj.com/content/385/bmj-2023-078378>
- Riley RD et al. Calculating the sample size required for developing a clinical prediction model. *BMJ*. 2020;368:m441. <https://www.bmj.com/content/368/bmj.m441>
- Riley RD, Collins GS et al. Developing clinical prediction models: a step-by-step guide. *BMJ*. 2024;386:e078276. <https://www.bmj.com/content/386/bmj-2023-078276>
- Collins GS et al. Transparent reporting of a multivariable prediction model for individual prognosis or diagnosis (TRIPOD). *BMJ*. 2015;350:g7594. <https://doi.org/10.1136/bmj.g7594>
- Varma S, Simon R. Bias in error estimation when using cross-validation for model selection. *BMC Bioinformatics*. 2006;7:91. <https://pubmed.ncbi.nlm.nih.gov/16504092/>
