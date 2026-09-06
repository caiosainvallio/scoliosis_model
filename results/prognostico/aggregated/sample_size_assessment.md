Sugestão para o manuscrito

A coorte analítica compreendeu 615 participantes, após deduplicação explícita e exclusão de casos incompletos. O desfecho contínuo delta apresentou média de -4,655° (DP 5,353°), e o desfecho binário de melhora ocorreu em 317/615 participantes (prevalência 0,515). Os modelos linear e logístico tiveram especificação congelada com 19 parâmetros candidatos cada.
Para o modelo contínuo, o R² ajustado aparente recalculado foi 0,383 (R² aparente 0,403). Com shrinkage desejado de 0,900, o pmsampsize estimou n mínimo de 312 para a referência pelo R² ajustado; os cenários de R² esperado 0,35, 0,30, 0,25 e 0,20 exigiram, respectivamente, 350, 422, 524 e 676 participantes.
Para o modelo binário, o Cox–Snell aparente foi 0,379, seu máximo sob a prevalência observada foi 0,750 e o Nagelkerke aparente foi 0,505. Os n mínimos foram 392 para o Cox–Snell aparente e 464, 545, 654 e 805 para 80%, 70%, 60% e 50% desse valor, respectivamente.
Cada n mínimo foi comparado diretamente com os 615 participantes disponíveis: R² ajustado recalculado: n mínimo 312, margem 303, suficiente; R² esperado 0,35: n mínimo 350, margem 265, suficiente; R² esperado 0,30: n mínimo 422, margem 193, suficiente; R² esperado 0,25: n mínimo 524, margem 91, suficiente; R² esperado 0,20: n mínimo 676, margem -61, insuficiente; Cox–Snell aparente (100%): n mínimo 392, margem 223, suficiente; 80% do Cox–Snell aparente: n mínimo 464, margem 151, suficiente; 70% do Cox–Snell aparente: n mínimo 545, margem 70, suficiente; 60% do Cox–Snell aparente: n mínimo 654, margem -39, insuficiente; 50% do Cox–Snell aparente: n mínimo 805, margem -190, insuficiente; AUC aparente atual: n mínimo 392, margem 223, suficiente; AUC 0,82: n mínimo 481, margem 134, suficiente; AUC 0,78: n mínimo 647, margem -32, insuficiente.

Métodos

A avaliação foi executada com pmsampsize 1.1.3, usando a especificação congelada de 19 parâmetros candidatos, shrinkage desejado de 0,900 e os parâmetros recalculados da coorte analítica. Para o desfecho contínuo, foram avaliados o R² ajustado recalculado como referência e R² esperados de 0,35, 0,30, 0,25 e 0,20, com média e DP de delta recalculados. Para o desfecho binário, foram avaliados o Cox–Snell aparente como referência otimista e 80%, 70%, 60% e 50% desse valor, usando a prevalência recalculada.
Os cenários baseados em AUC foram mantidos exclusivamente como análise de sensibilidade. AUC aparente atual e AUC de 0,82 e 0,78 foram processadas com a mesma semente explícita, registrada nas tabelas e no log.

Resultados e limitações

A suficiência é condicional ao desempenho esperado e às demais premissas do pmsampsize; não foi selecionado retrospectivamente um cenário favorável. O R² e o Cox–Snell derivados do ajuste na própria coorte são aparentes e, portanto, otimistas. Os eventos por parâmetro são apresentados apenas como descrição complementar e não constituem a justificativa principal.
Este cálculo se aplica somente à especificação congelada de 19 parâmetros. Não justifica a complexidade de modelagem flexível exploratória, que requer avaliação própria e validação interna por reamostragem. A avaliação de tamanho amostral também não substitui a avaliação de desempenho, calibração, incerteza e transportabilidade.

Tabela resumida

| Modelo | Cenário | n mínimo | Margem para 615 | Suficiente |
|---|---|---:|---:|:---:|
| linear | R² ajustado recalculado | 312 | 303 | sim |
| linear | R² esperado 0,35 | 350 | 265 | sim |
| linear | R² esperado 0,30 | 422 | 193 | sim |
| linear | R² esperado 0,25 | 524 | 91 | sim |
| linear | R² esperado 0,20 | 676 | -61 | não |
| logistic | Cox–Snell aparente (100%) | 392 | 223 | sim |
| logistic | 80% do Cox–Snell aparente | 464 | 151 | sim |
| logistic | 70% do Cox–Snell aparente | 545 | 70 | sim |
| logistic | 60% do Cox–Snell aparente | 654 | -39 | não |
| logistic | 50% do Cox–Snell aparente | 805 | -190 | não |
| logistic | AUC aparente atual | 392 | 223 | sim |
| logistic | AUC 0,82 | 481 | 134 | sim |
| logistic | AUC 0,78 | 647 | -32 | não |
