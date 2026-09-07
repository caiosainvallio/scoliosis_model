# Tarefa 07 — Produzir shrinkage, equações finais e estabilidade

## Dependências

- Tarefa 06 concluída com previsões e inclinações corrigidas.

## Objetivo

Transformar os resultados da avaliação interna em equações prognósticas transparentes, corrigidas para sobreajuste, e quantificar a estabilidade das previsões individuais.

## Atividades

1. Obter a inclinação de calibração corrigida por otimismo de cada modelo.
2. Definir o fator de shrinkage como a inclinação limitada ao intervalo `[0, 1]`; não expandir coeficientes quando a estimativa for superior a 1.
3. Multiplicar todos os coeficientes não intercepto pelo fator.
4. Recalcular o intercepto:
   - linear: preservar a média observada de `delta`;
   - logístico: preservar a prevalência observada de melhora.
5. Validar numericamente a recalibração.
6. Produzir tabelas com coeficientes originais e após shrinkage.
7. Montar a equação linear completa e a equação da probabilidade logística.
8. Testar previsões manuais para perfis sintéticos contra as funções de predição.
9. Resumir, para cada participante, a distribuição de previsões dos modelos bootstrap aplicados à base original.
10. Calcular índice de instabilidade e identificar faixas de previsão mais instáveis.
11. Construir gráficos de estabilidade sem exibir IDs.
12. Produzir intervalos de predição de 95% do modelo linear e distingui-los dos intervalos de confiança da média.

## Entregáveis

- Fatores de shrinkage linear e logístico.
- Tabelas de coeficientes originais e corrigidos.
- Interceptos recalibrados.
- Equações completas e instruções de cálculo individual.
- Casos sintéticos de validação das equações.
- Métricas e gráficos de estabilidade.
- Intervalos de predição e texto de interpretação clínica.

## Evidências obrigatórias

- A média das previsões lineares corrigidas coincide com a média observada dentro da tolerância definida.
- A média das probabilidades corrigidas coincide com a prevalência observada.
- Predições manuais e `predict()` coincidem para todos os casos de teste.
- Fatores usados pertencem a `[0, 1]`.
- Tabelas mantêm precisão suficiente para reproduzir as previsões.
- Gráficos públicos não contêm IDs nem dados individuais identificáveis.
- O texto afirma que shrinkage não substitui validação externa.

## Critérios de conclusão

- Cada modelo possui uma versão aparente e uma versão final corrigida claramente diferenciadas.
- As equações são reproduzíveis fora do objeto R.
- A instabilidade está quantificada e interpretada.
- A incerteza da previsão linear está apresentada em unidades de graus.

## Status de execução

- **Concluída em 2026-09-07.** Foram produzidos os fatores de shrinkage, interceptos
  recalibrados, tabelas de coeficientes aparentes e corrigidos, equações completas,
  casos sintéticos, resumos de estabilidade sem IDs clínicos, gráficos anônimos e
  intervalos de confiança da média versus predição individual em graus. As
  verificações numéricas passaram e o texto afirma que shrinkage não substitui
  validação externa.
