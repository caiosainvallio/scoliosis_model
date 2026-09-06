# Tarefa 03 — Reajustar os modelos congelados e seus diagnósticos

## Dependências

- Tarefa 02 concluída e coorte com 615 participantes aprovada.

## Objetivo

Reajustar os modelos prognósticos principal e secundário com a especificação previamente congelada e regenerar todos os diagnósticos após a deduplicação.

## Especificação congelada

Preditores comuns:

- idade;
- IMC;
- cifose torácica;
- lordose lombar;
- correção com o colete;
- sexo;
- Lenke;
- Risser;
- flexibilidade;
- região do escoliômetro acima de 10°.

Os fatores deverão manter as referências: feminino, Lenke 1, Risser 0, flexível e escoliômetro normal. A matriz deverá conter 19 parâmetros preditores mais intercepto.

## Atividades

1. Ajustar por mínimos quadrados o modelo linear para `delta`.
2. Ajustar por máxima verossimilhança o modelo logístico para `delta_cat`.
3. Confirmar ausência de seleção por p-valor, stepwise, splines ou interações.
4. Gerar coeficientes, IC95%, matriz de desenho e equações aparentes.
5. Calcular métricas aparentes:
   - linear: R², R² ajustado, RMSE, MAE e erro médio;
   - logístico: AUC, Brier score e log loss.
6. Calcular calibração aparente, rotulando intercepto 0 e slope 1 como resultados esperados por construção.
7. Refazer diagnósticos de posto, colinearidade, separação, estimativas não finitas e categorias problemáticas.
8. Refazer resíduos, heteroscedasticidade, leverage e distância de Cook.
9. Gerar observado versus previsto, resíduos, probabilidades, ROC e calibração aparente.
10. Comparar os resultados novos com os diagnósticos de 21/07/2026 somente para detectar mudanças inesperadas.

## Entregáveis

- Objetos reduzidos dos modelos, sem `model.frame`.
- Tabelas de coeficientes linear, logit e odds ratios.
- Tabelas de métricas e calibração aparentes.
- Diagnósticos atualizados de matriz, separação, colinearidade e influência.
- Figuras atualizadas de desempenho e adequação.
- Registro das diferenças em relação aos resultados preliminares.

## Evidências obrigatórias

- `n = 615` em ambos os modelos.
- 317 eventos e 298 não eventos no logístico.
- 19 parâmetros preditores e matrizes de posto completo.
- Mesma ordenação dos IDs e mesmas colunas preditoras nos dois modelos.
- Convergência do modelo logístico e coeficientes finitos.
- Equivalência entre métricas calculadas por funções próprias e por pacote de referência, dentro de tolerância definida.
- Lista das observações influentes sem exclusão automática.

## Critérios de conclusão

- Os dois modelos congelados podem ser reproduzidos a partir da coorte aprovada.
- Todos os resultados anteriores foram recalculados.
- Resultados aparentes estão claramente identificados como otimistas.
- Nenhum texto ou objeto de progressão foi introduzido.

## Status de execução

- **Concluída em 2026-09-06.** Os modelos linear e logístico congelados foram
  reajustados e auditados com `n = 615`; diagnósticos, métricas aparentes,
  objetos reduzidos e comparação histórica foram regenerados sem exclusões
  automáticas de observações influentes.
