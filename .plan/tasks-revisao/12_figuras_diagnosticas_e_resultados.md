# Task 12 — Figuras dos modelos, calibração e estabilidade

- **Modelo recomendado:** terra (`gpt-5.6-terra`).
- **Complexidade:** Moderada a alta.
- **Justificativa do modelo:** Implementação visual em R com interpretação e estimadores previamente definidos pelas tasks analíticas.
- **Dependências:** [Task 05](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/05_reexecucao_flexivel_e_hierarquia.md), [Task 07](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/07_arvore_cart_e_folhas.md), [Task 08](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/08_pressupostos_e_inferencia_robusta.md), [Task 09](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/09_validacao_incerteza_e_shrinkage.md), [Task 10](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/10_sensibilidades_e_comparadores.md), [Task 11](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/11_coorte_descricao_e_tamanho_amostral.md)
- **Status:** Pendente.

## Contexto e regras

Leia o [índice e contrato de execução](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/00_indice_execucao.md) e o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) antes de executar. A raiz do projeto é `/Users/caiosainvallio/consultoria/scoliosis_model`. Esta task pertence à revisão do relatório; a numeração é diferente da antiga pasta `.plan/tasks`.

A correção pelo colete é uma avaliação transversal da anamnese inicial, disponível como preditor basal e interpretada como possível marcador de maleabilidade/corrigibilidade imediata. Essa definição foi esclarecida pelo usuário e não deve ser reaberta como suspeita de vazamento temporal. Preserve a coorte e a especificação dos modelos principais; mantenha análises novas e saídas corrigidas rastreáveis.

## Objetivo

Produzir figuras informativas e consistentes, adequadas ao HTML e à publicação científica.

## Entradas

- [R/06_report_helpers.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/06_report_helpers.R)
- [R/07_frozen_models.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/07_frozen_models.R)
- [R/09_shrinkage_equations.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/09_shrinkage_equations.R)
- [.plan/tasks-revisao/entregas/05_flexivel.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/05_flexivel.md)
- [.plan/tasks-revisao/entregas/08_pressupostos.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/08_pressupostos.md)
- [.plan/tasks-revisao/entregas/09_validacao_incerteza.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/09_validacao_incerteza.md)

As entregas de tasks anteriores só estarão disponíveis após sua conclusão. Leia o resumo e as evidências das dependências antes de consumir suas saídas.

## Atividades

1. Definir tema comum de fontes, cores acessíveis, títulos, unidades e legendas. Reutilizar as figuras CART da task 07 sem mudar seus dados ou regras.
2. Criar distribuição de delta, observado versus previsto, resíduos com suavização, Q–Q e influência, usando o estimador correto e identificando avaliação aparente ou por reamostragem.
3. Criar curva ROC e calibração suavizada com linha de identidade e distribuição das probabilidades; mostrar bandas apenas se o método tiver sido validado na task 09.
4. Representar estabilidade linear e logística em graus e pontos percentuais, com denominadores explícitos. Nas curvas com previsões repetidas, não tratá-las como pessoas independentes.
5. Criar gráficos de coeficientes lineares e OR em contrastes úteis, incluindo correção por dez pontos percentuais. Não colocar IC aparentes em coeficientes pós-shrinkage; usar estimadores/IC compatíveis ou painéis separados.
6. Para splines e interações flexíveis, representar relações ajustadas na escala clínica e com suporte dos dados. Não interpretar coeficientes isolados da base spline como efeitos clínicos.
7. Criar sínteses visuais de sensibilidades e comparação com referências simples, sem ordenar estratégias como vencedoras com base em avaliações incompatíveis.
8. Exportar PNG e formato vetorial dos gráficos principais, inspecionar dimensões de publicação e entregar legendas autossuficientes e blocos Quarto.

## Entregáveis

- Scripts R reproduzíveis de geração das figuras da revisão
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/figures/linear_*`, logistic_*, stability_*, flexible_*, sensitivity_*
- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/12_figuras_e_legendas.md`

Registre comandos, arquivos produzidos/alterados, verificações e limitações em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/12_execucao.md`. Quando houver decisão estatística nova, inclua justificativa e referência verificável e atualize o BibTeX, se aplicável.

## Critérios de conclusão

- [ ] Todas as figuras foram abertas e verificadas visualmente.
- [ ] Estimador e tipo de avaliação são identificáveis em cada legenda.
- [ ] Unidades, eixos, escalas e denominadores coincidem com tabelas.
- [ ] Nenhuma banda, intervalo ou gráfico dá precisão não sustentada pela análise.
- [ ] Resumo de execução e manifesto atualizados com as evidências desta task.

## Encerramento e passagem

Atualize o status deste arquivo somente após verificar os critérios. Informe o que mudou, como foi verificado, quais saídas devem ser consumidas e se há dependências afetadas. Registre pendências sem inventar informação ou tratar uma limitação não resolvida como aprovação. Não execute automaticamente a próxima task.

