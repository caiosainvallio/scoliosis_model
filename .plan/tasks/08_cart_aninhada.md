# Tarefa 08 — Corrigir a avaliação da CART exploratória

## Dependências

- Tarefa 02 concluída.
- Funções gerais de métricas da Tarefa 05 aprovadas.

## Objetivo

Reavaliar a CART de melhora sem reutilizar os mesmos dados para escolher hiperparâmetros e estimar desempenho.

## Escopo

- Desfecho: melhora radiográfica `delta_cat`.
- Preditores: os mesmos dez preditores dos modelos congelados.
- Natureza: exclusivamente exploratória e geradora de hipóteses.

## Atividades

1. Criar folds externos estratificados: 10 folds × 5 repetições.
2. Para cada conjunto de treinamento externo, criar 5 folds internos estratificados.
3. Executar no ciclo interno todo o pré-processamento e tuning.
4. Avaliar grade pré-especificada de `cost_complexity`, `tree_depth` e `min_n`.
5. Selecionar por AUC interna usando a regra de um erro-padrão e favorecendo a árvore mais simples.
6. Ajustar a configuração selecionada no treinamento externo.
7. Prever somente a partição externa correspondente.
8. Consolidar previsões externas para AUC, Brier, log loss e calibração exploratória.
9. Ajustar uma árvore em toda a coorte apenas para visualização das regras.
10. Avaliar estabilidade da estrutura entre folds.

## Entregáveis

- Definição persistida dos folds externos e internos.
- Tabela de hiperparâmetros selecionados por fold externo.
- Previsões estritamente fora da amostra.
- Métricas externas agregadas e sua distribuição.
- Curva de calibração exploratória externa.
- Árvore final ilustrativa.
- Tabelas de frequência das variáveis, pontos de corte e tamanhos dos nós.

## Evidências obrigatórias

- Nenhuma linha do fold externo participa de tuning ou pré-processamento interno.
- Cada participante possui somente previsões geradas quando estava fora do treinamento correspondente.
- Seleção aplica a regra de um erro-padrão de forma determinística.
- AUC, Brier e log loss são calculados nas previsões externas.
- Registro da frequência de árvores sem divisão.
- Frequência da variável na raiz, primeiros níveis e distribuição dos pontos de corte.
- Desempenho da árvore ajustada em toda a base não é apresentado como avaliação externa.

## Critérios de conclusão

- O viés da avaliação anterior por reutilização de folds foi eliminado.
- Desempenho e estabilidade da CART estão documentados.
- O relatório identifica a CART como exploratória e não concorrente clínica dos modelos regressivos.
- Nenhum modelo de progressão permanece.

## Status de execução

- **Concluída em 2026-09-07.** A CART exploratória foi reavaliada com 10 folds
  externos por 5 repetições, tuning interno estratificado e regra one-SE
  determinística. Resultados públicos são agregados; folds e previsões
  detalhados foram preservados somente em objeto interno compacto.
