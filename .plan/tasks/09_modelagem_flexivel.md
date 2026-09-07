# Tarefa 09 — Executar a modelagem flexível exploratória

## Dependências

- Tarefa 02 concluída.
- Funções e infraestrutura de métricas da Tarefa 05 aprovadas.

## Objetivo

Avaliar, em apêndice exploratório, se penalização, Cobb basal, não linearidades e interações clínicas pré-especificadas sugerem ganho preditivo ou hipóteses para estudos futuros.

## Conjunto candidato

- Dez preditores dos modelos congelados.
- Cobb máximo basal como preditor adicional.
- Termos não lineares de baixa complexidade para:
  - idade;
  - IMC;
  - cifose torácica;
  - lordose lombar;
  - correção com o colete;
  - Cobb máximo basal.
- Interações pré-especificadas:
  - correção com colete × flexibilidade;
  - correção com colete × Lenke;
  - idade × Risser.

## Atividades

1. Construir versões contínua e logística com elastic net.
2. Criar splines cúbicos naturais/restritos com baixa complexidade.
3. Estimar nós, centralização, dummies e padronização apenas nos dados de treinamento de cada reamostragem.
4. Usar componentes lineares nas interações para limitar a dimensionalidade.
5. Preservar hierarquia: interação não poderá ser interpretada sem os efeitos principais correspondentes.
6. Avaliar grade fixa de `alpha` entre ridge e lasso e sequência logarítmica de `lambda`.
7. Usar validação cruzada aninhada:
   - externa: 10 folds estratificados × 5 repetições;
   - interna: 5 folds;
   - mesmos folds externos da CART quando aplicável.
8. Selecionar pela regra de um erro-padrão:
   - RMSE no modelo contínuo;
   - log loss no modelo logístico;
   - favorecer maior penalização em caso de equivalência.
9. Medir externamente:
   - contínuo: R², RMSE, MAE e calibração;
   - logístico: AUC, Brier, log loss e calibração.
10. Ajustar uma versão exploratória em toda a coorte somente após concluir a avaliação externa aos folds.
11. Calcular frequência de seleção, magnitude dos coeficientes e estabilidade das previsões.
12. Comparar com os modelos congelados em diferenças absolutas, usando as mesmas observações e partições quando possível.

## Entregáveis

- Receitas de pré-processamento contínua e logística.
- Grade e resultados de tuning interno.
- Previsões externas e métricas agregadas.
- Tabela de hiperparâmetros escolhidos.
- Frequência de seleção dos componentes adicionais.
- Gráficos de não linearidade, interação e estabilidade quando interpretáveis.
- Comparação explícita com os modelos congelados.
- Apêndice metodológico e texto de cautela para revisores.

## Evidências obrigatórias

- Nós das splines e parâmetros de padronização são aprendidos dentro do treinamento.
- Nenhuma observação externa participa do tuning.
- As interações respeitam hierarquia na construção e interpretação.
- Métricas provêm de previsões fora da amostra.
- Resultados distinguem seleção de dummy, termo e variável clínica completa.
- Reexecução com a mesma semente reproduz folds e resultados.
- Eventual ganho é apresentado com sua magnitude e variabilidade, não apenas como ranking.

## Critérios de conclusão

- As duas versões penalizadas foram avaliadas corretamente.
- A análise permanece no apêndice e não altera o modelo principal.
- Limitações de multiplicidade, instabilidade e exploração pós-dados são declaradas.
- Nenhuma conclusão clínica depende exclusivamente dessa estratégia.

## Status de execução

- **Concluída em 2026-09-07.** Foram implementadas as versões contínua e
  logística penalizadas, com splines naturais de baixa complexidade, interações
  hierárquicas, pré-processamento aprendido dentro de cada reamostragem,
  validação cruzada aninhada estratificada, seleção one-SE, avaliação externa,
  ajuste exploratório pós-avaliação em toda a coorte e comparação pareada com
  os modelos congelados. Os detalhes internos permanecem em objeto reduzido;
  os resultados públicos são agregados e acompanhados de cautela metodológica.
