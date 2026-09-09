# Entrega da Task 13 — integração do relatório prognóstico

Data: 2026-09-08.

## Resultado

`relatorio_prognostico.qmd` foi reescrito como relatório integrado de desenvolvimento e avaliação interna. A estrutura agora segue: sumário quantitativo; pergunta/cenário/cronologia; coorte; desfechos e preditores; métodos; modelos contínuo e logístico; CART; sensibilidades; discussão/conclusão; apêndices com equações, análise flexível, cobertura, checklists e rastreabilidade.

A hierarquia aprovada foi preservada: modelo linear de `delta` principal, logístico de melhora radiográfica secundário, CART e modelagem flexível exploratórias. Não foram reintroduzidos progressão, seleção por p-valor, divisão treino–teste simples, indicação terapêutica ou análise de decisão sem objetivo.

## Resultados integrados

- coorte: 621 registros, 618 após deduplicação, 615 casos completos, 317 eventos e 298 não eventos;
- linear fixo: R² corrigido 0,3637 (IC95% 0,3218–0,4410), RMSE 4,2763° (3,9267–4,4730) e MAE 3,3944° (3,1028–3,5559);
- logístico fixo: AUC corrigida 0,8483 (0,8291–0,8839), Brier 0,1600 (0,1363–0,1707) e log loss 0,4892 (0,4297–0,5143);
- procedimento completo pós-shrinkage: RMSE linear 4,2965° e inclinação logística 0,9930 na CV interna repetida;
- a cada dez pontos percentuais de correção transversal pelo colete: −1,1873° no `delta` e OR 2,3271 para melhora, relações ajustadas sem interpretação causal;
- cobertura conformal interna 94,86%, largura média 17,44°; não é intervalo final externo;
- CART: correção pelo colete na raiz em 50/50 árvores; corte mediano 49,4186%, amplitude 45,3463–54,8589%; árvore/folhas aparentes separadas do desempenho interno;
- sensibilidade com Cobb basal: redução interna de RMSE de 0,0686°; exclusão temporária das três hipercorreções alterou RMSE em +0,0019° e Brier em menos de 0,000001;
- flexível corrigido: ganhos médios modestos nos mesmos folds, sem IC de superioridade e sem promoção a principal.

## Seleção explícita dos artefatos

O QMD falha se um arquivo obrigatório estiver ausente/vazio e verifica o SHA-256 da fonte contra `results/prognostico/revisao/logs/manifesto_inicial.csv`. A árvore de revisão é canônica para coorte, diagnóstico, validação adicional, shrinkage, CART estrutural, análise flexível, sensibilidades, figuras e checklists.

Somente dois resultados congelados continuam sendo lidos por caminho explícito porque não foram invalidados: `results/prognostico/aggregated/cart_external_metric_distribution.csv` (desempenho CART preservado pela Task 06) e `results/prognostico/aggregated/frozen_prediction_stability_summary.csv` (estabilidade bootstrap preservada pela Task 09). Não há fallback silencioso.

## Cobertura do parecer

| Seção do parecer | Implementação/justificativa/limitação |
|---|---|
| 1. Prioridades | Terminologia, solver flexível corrigido, CART primária, HC3, incerteza, citações e sumário quantitativo integrados. |
| 2. Pergunta e temporalidade | Linha temporal e correção pelo colete transversal basal incorporadas; detalhes clínicos ausentes listados. |
| 3. Desfecho/preditores | Equação, sinal, limiar radiográfico, região máxima, dicionário, 19 parâmetros, distinção de flexibilidade e Cobb basal explicados. |
| 4. Pressupostos | Evidência → interpretação → ação → limite, heteroscedasticidade/HC3, forma, caudas, colinearidade, influência e separação relatados. |
| 5. Validação/amostra/incerteza | Bootstrap, contagem de falhas, IC deslocado, CV do procedimento pós-shrinkage, conformal e cenários amostrais detalhados. |
| 6. CART | Método/grade/one-SE, árvore, folhas, desempenho, estabilidade estrutural e denominador de calibração incluídos. |
| 7. Flexível | Apenas solver corrigido, comparações pareadas, falhas KKT, hierarquia observada e limites integrados no apêndice. |
| 8. Sensibilidades/ausência | Influência, hipercorreções, Cobb basal, comparadores e dados ausentes apresentados com números. |
| 9. Mensagens diretas | Sumário e conclusão comunicam erro, discriminação, calibração, estabilidade e efeito por 10 pontos percentuais. |
| 10. Bibliografia/transparência | YAML BibTeX, citações próximas às afirmações e checklists com evidência/pendência. |
| 11. Implementação | Artefatos versionados, ausência de IDs, render temporário e limitações registrados. |

## Checklists

- `tripod_ai_checklist.csv`: 27 itens principais da versão 7-Feb-2024; nenhum “atendido” genérico, cada linha tem localização, evidência ou pendência.
- `probast_ai_assessment.csv`: 14 linhas que separam quatro domínios de desenvolvimento, quatro de avaliação interna e três domínios de aplicabilidade para cada componente. Os julgamentos são rascunhos incertos; não se declara avaliação independente.

## Limitações preservadas

Não foram inventados recrutamento, elegibilidade, centro, período, protocolo radiográfico, avaliadores, ética, financiamento, registro, envolvimento público, adesão ou tratamentos concomitantes. A correção pelo colete permanece basal e transversal, sem suspeita de vazamento temporal. RMSE não é margem individual; AUC não é acurácia; OR não é risco relativo. Relações ajustadas não são intervenções causais e a manutenção da correção não é garantida.

## Saídas para consumo

As Tasks 14 e 15 devem consumir `relatorio_prognostico.qmd`, `references_prognostico.bib`, os dois CSVs de checklist e somente os caminhos analíticos declarados no setup do QMD. A Task 14 deve renderizar o HTML oficial e realizar inspeção visual; o HTML temporário desta task é apenas evidência de executabilidade.

## Complemento solicitado após a entrega

Em 2026-09-08, a redação foi ampliada para funcionar também como material de aprendizagem: acrescentou-se um guia de leitura, a lógica das regressões, a sequência das decisões, interpretação do tamanho amostral, heteroscedasticidade/colinearidade/separação, bootstrap passo a passo, shrinkage, calibração, CV, CART, one-SE, splines, penalização e condições KKT. A tabela de sensibilidades passou a ser construída integralmente em português a partir dos resultados numéricos. As equações finais passaram de texto monoespaçado para LaTeX em blocos `$$`, gerados programaticamente dos coeficientes pós-shrinkage.
