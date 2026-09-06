# Tarefa 06 — Executar a avaliação interna dos modelos congelados

## Dependências

- Tarefa 05 concluída e testada.

## Objetivo

Executar 2.000 reamostragens bootstrap para estimar o otimismo e o desempenho corrigido dos modelos linear e logístico congelados.

## Atividades

1. Calcular e congelar as métricas aparentes da base completa.
2. Executar 2.000 réplicas para o modelo linear.
3. Executar 2.000 réplicas para o modelo logístico.
4. Em cada réplica, repetir o ajuste completo sem seleção ou alteração da fórmula.
5. Aplicar cada modelo bootstrap tanto à amostra bootstrap quanto à base original.
6. Calcular otimismo e consolidar as métricas corrigidas.
7. Registrar tempo, semente, índice da réplica, warnings e motivos de falha.
8. Verificar que pelo menos 1.980 réplicas sejam válidas em cada modelo.
9. Se o limite não for atingido, investigar antes de aceitar resultados; não usar fallback diferente somente nas réplicas problemáticas.
10. Armazenar previsões bootstrap de forma interna para a análise de estabilidade da Tarefa 07.

## Métricas

Modelo linear:

- R²;
- RMSE;
- MAE;
- erro médio;
- intercepto e inclinação de calibração.

Modelo logístico:

- AUC;
- Brier score;
- log loss;
- calibration-in-the-large;
- inclinação de calibração.

## Entregáveis

- Tabela por réplica com métricas de treinamento, teste e otimismo.
- Tabela consolidada com aparente, otimismo médio e corrigido.
- Log de réplicas válidas e inválidas por motivo.
- Distribuições gráficas do otimismo.
- Arquivo interno com previsões necessárias para estabilidade.
- Objeto agregado publicável sem dados clínicos individuais.

## Evidências obrigatórias

- Exatamente 2.000 tentativas registradas por modelo.
- Pelo menos 99% de réplicas válidas por modelo.
- Cada réplica usa amostra de tamanho 615 com reposição.
- Métricas de treino e teste são calculadas com o mesmo modelo bootstrap.
- Os sinais do otimismo são coerentes com a orientação das métricas.
- Reexecução com a mesma semente reproduz resultados dentro da tolerância numérica definida.
- As métricas corrigidas não são confundidas com métricas de validação externa.

## Critérios de conclusão

- Todas as métricas planejadas possuem valor aparente, otimismo e valor corrigido.
- Falhas estão quantificadas e justificadas.
- A execução é reproduzível e não depende de estado de sessão.
- Os resultados estão prontos para shrinkage, estabilidade e apresentação.

