# Apêndice metodológico — modelagem flexível exploratória corrigida

## Escopo e desenho

A reexecução preservou a coorte de 615 participantes (317 eventos) e a definição basal de `correcao_colete` como avaliação transversal de corrigibilidade imediata. Os modelos flexíveis são exploratórios e não substituem os modelos principais congelados.

Foram usados 10 folds externos, 5 repetições e 5 folds internos, com semente 20261714. Cada participante integra o teste exatamente uma vez por repetição. As repetições reutilizam as mesmas pessoas; por isso o desvio-padrão entre repetições descreve variabilidade de reamostragem e não é intervalo de confiança.

Todos os índices foram reconstruídos deterministicamente e coincidiram com o objeto anterior. Treino/teste externos e treino/validação internos foram auditados como disjuntos. Medianas, modos, centros, escalas, níveis fatoriais, limites e nós de spline foram estimados apenas no treino aplicável; o teste externo não participou do tuning.

## Especificação candidata e seleção

A matriz candidata contém seis variáveis numéricas (`idade`, `imc`, `cifose_toracica`, `lordose_lombar`, `correcao_colete` e Cobb basal), cada uma com componente linear e spline natural de 3 graus de liberdade; cinco fatores codificados por dummies; e três famílias de interação (`correcao_colete × flexibilidade`, `correcao_colete × Lenke` e `idade × Risser`). O ajuste externo teve 48 colunas candidatas. Os nós e limites efetivos do ajuste global ilustrativo estão em `flexible_spline_specification.csv`.

A grade foi mantida sem ajuste retrospectivo: alpha em {0; 0,25; 0,50; 0,75; 1} e quatro frações de lambda logaritmicamente espaçadas entre 1 e 0,001. Em cada treino externo, lambda absoluto foi a fração selecionada multiplicada pelo lambda máximo calculado naquele treino. A regra one-SE minimizou RMSE no desfecho contínuo e log loss no logístico; entre configurações elegíveis, escolheu a maior fração de lambda, depois o menor alpha e, por fim, o menor identificador da configuração. `flexible_selected_hyperparameters.csv` registra alpha, fração e valor absoluto de lambda, limiar one-SE e desempates para cada ajuste.
A regra selecionou ridge (alpha = 0) nos 100 ajustes externos. A fração de lambda foi 0,01 em 99 ajustes e 0,001 em 1 ajuste. A expansão exata das 48 colunas candidatas está em `flexible_design_expansion.csv`.

O solver minimizou perda média mais penalização elastic net, com intercepto não penalizado. Convergência exigiu solução finita e violação máxima de KKT de no máximo 1e-6. Houve 0 falhas nos 100 ajustes externos selecionados; a maior violação KKT externa foi 9.987e-09. Falhas internas e globais estão em `flexible_failure_audit.csv` e não foram convertidas silenciosamente em métricas válidas.

## Hierarquia verificada

Os efeitos principais correspondentes estavam presentes na matriz candidata. Isso é hierarquia de construção, não hierarquia forte: a penalização foi aplicada coeficiente a coeficiente e nenhuma restrição formal obrigou os efeitos principais a permanecerem ativos quando uma interação ficou ativa.

Entre os coeficientes externos, houve 1000 ocorrências de interações ativas e 0 violações da hierarquia forte. A auditoria por ajuste, interação e efeito principal está em `flexible_active_hierarchy_audit.csv`. Nenhum cenário hierarquicamente restrito foi introduzido nesta revisão.

## Comparação com os modelos congelados nos mesmos folds

Contínuo: diferença média flexível menos congelado entre as cinco repetições = -0.0897° para RMSE e -0.0716° para MAE. Valores negativos favorecem o flexível.
Logístico: diferença média flexível menos congelado = 0.0065 para AUC, -0.0042 para Brier e -0.0151 para log loss. AUC maior e perdas menores são favoráveis.
Calibração logística: diferenças flexível menos congelado de 0.0024 no intercepto e 0.2671 na inclinação. Para calibração, a proximidade de 0 e 1, respectivamente, importa mais que o sinal bruto da diferença.

As tabelas apresentam diferenças pareadas por repetição e seu desvio-padrão, sem tratar os 50 folds ou as cinco repetições como amostras independentes e sem produzir IC espúrios. Não se conclui superioridade por pontos médios; além de splines, a estratégia flexível acrescenta Cobb basal, interações e penalização.

## Impacto da correção do solver

Os índices externos antes/depois foram idênticos. No logístico, a mudança corrigido menos anterior foi 0.0002 para AUC, -0.0011 para Brier e -0.0038 para log loss, nas métricas pareadas por repetição.
No contínuo, a diferença de RMSE corrigido menos anterior foi 0.0000°, como esperado porque a correção incidiu no IRLS logístico; a família foi reexecutada para confirmar a identidade sob o fluxo compartilhado.

A correção elimina o uso clínico do solver antigo nas saídas da revisão. O efeito observado deve ser interpretado como impacto da correção algorítmica no procedimento completo de seleção e ajuste, não como evidência de benefício clínico.
A conclusão não mudou: a estratégia flexível permanece exploratória, com diferenças pontuais pequenas e sem demonstração formal de superioridade. A correção melhorou Brier e log loss médios e aproximou a inclinação logística de calibração de 1, mas não fornece validação externa nem isola o efeito das splines.

## Limitações

A avaliação é interna, repetida e exploratória. Coeficientes de bases spline penalizadas não são efeitos clínicos isolados. O ajuste global posterior à avaliação externa serve somente para descrição e geração futura de figuras. Validação externa e avaliação de utilidade clínica permanecem necessárias.
