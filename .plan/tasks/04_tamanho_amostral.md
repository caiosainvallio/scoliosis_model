# Tarefa 04 — Atualizar a avaliação formal do tamanho amostral

## Dependências

- Tarefa 03 concluída, com métricas e distribuição dos desfechos recalculadas.

## Objetivo

Atualizar a justificativa quantitativa da amostra para os modelos congelados usando 615 participantes e os parâmetros recalculados, sem depender somente de regras de eventos por variável.

## Atividades

1. Confirmar 19 parâmetros candidatos nos modelos linear e logístico.
2. Recalcular média e desvio-padrão de `delta`.
3. Recalcular prevalência, Cox–Snell R², máximo de Cox–Snell e Nagelkerke R².
4. Executar `pmsampsize` para o modelo contínuo com:
   - R² ajustado recalculado como referência;
   - R² esperados de 0,35, 0,30, 0,25 e 0,20;
   - shrinkage desejado de 0,90.
5. Executar `pmsampsize` para o modelo binário com:
   - Cox–Snell aparente como referência otimista;
   - 80%, 70%, 60% e 50% do Cox–Snell aparente;
   - prevalência recalculada;
   - shrinkage desejado de 0,90.
6. Manter cenários de AUC somente como análise de sensibilidade.
7. Comparar cada tamanho mínimo com 615, sem selecionar retrospectivamente o cenário mais favorável.
8. Limitar a conclusão à especificação congelada de 19 parâmetros.

## Entregáveis

- Tabela de entradas utilizadas no cálculo.
- Tabela consolidada de cenários, tamanho mínimo, margem e suficiência.
- Saídas detalhadas do `pmsampsize`.
- Texto interpretativo para métodos, resultados e limitações.
- Bloco “Sugestão para o manuscrito” com números dinâmicos.

## Evidências obrigatórias

- Entradas reconciliadas com a Tarefa 03.
- Código registra versão do `pmsampsize` e parâmetros usados.
- Resultados reproduzíveis com a mesma semente nos cenários baseados em AUC.
- Conclusão diferencia cenário principal, cenários conservadores e sensibilidades.
- Nenhum resultado do arquivo antigo é copiado como se fosse atual.

## Critérios de conclusão

- Todos os cenários planejados foram executados e documentados.
- A suficiência ou insuficiência é apresentada condicionalmente às premissas.
- Eventos por parâmetro aparecem apenas como descrição complementar.
- O cálculo não é usado para justificar a complexidade da modelagem flexível exploratória.

## Status de execução

- **Concluída em 2026-09-06.** A avaliação foi recalculada diretamente da coorte
  aprovada da Tarefa 03 (`n = 615`, 317 eventos, 298 não eventos), com 19
  parâmetros candidatos em cada modelo e `pmsampsize` 1.1.3.
- Média de `delta` = −4,655°; DP = 5,353°; R² linear ajustado = 0,383;
  Cox–Snell aparente = 0,379; máximo = 0,750; Nagelkerke aparente = 0,505.
- Os cenários principais/conservadores foram executados com n mínimo linear de
  312, 350, 422, 524 e 676; e n mínimo logístico de 392, 464, 545, 654 e
  805. Cada um foi comparado diretamente com 615, sem seleção retrospectiva.
- Cenários AUC foram mantidos apenas como sensibilidades, com semente comum
  `20260906` (RNG `Mersenne-Twister`) e n mínimo 392, 481 e 647 para AUC
  aparente atual, 0,82 e 0,78.
- Saídas: `scripts/run_sample_size_assessment.R`,
  `results/prognostico/aggregated/sample_size_inputs.csv`,
  `sample_size_scenarios.csv`, `sample_size_pmsampsize_outputs.txt`,
  `sample_size_assessment.md` e logs correspondentes.
