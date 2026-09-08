# Task 08 — Pressupostos, diagnósticos e inferência robusta

- **Modelo recomendado:** sol (`gpt-5.6-sol`).
- **Complexidade:** Alta.
- **Justificativa do modelo:** Exige interpretar diagnósticos e corrigir inferência sem alterar silenciosamente os modelos principais.
- **Dependências:** [Task 02](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/02_definicoes_clinicas_e_racional.md), [Task 03](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/03_bibliografia_e_fontes.md)
- **Status:** Concluída em 2026-09-08.

## Contexto e regras

Leia o [índice e contrato de execução](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/00_indice_execucao.md) e o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) antes de executar. A raiz do projeto é `/Users/caiosainvallio/consultoria/scoliosis_model`. Esta task pertence à revisão do relatório; a numeração é diferente da antiga pasta `.plan/tasks`.

A correção pelo colete é uma avaliação transversal da anamnese inicial, disponível como preditor basal e interpretada como possível marcador de maleabilidade/corrigibilidade imediata. Essa definição foi esclarecida pelo usuário e não deve ser reaberta como suspeita de vazamento temporal. Preserve a coorte e a especificação dos modelos principais; mantenha análises novas e saídas corrigidas rastreáveis.

## Objetivo

Vincular cada pressuposto às evidências observadas, às suas consequências e às análises de sensibilidade apropriadas.

## Entradas

- [R/07_frozen_models.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/07_frozen_models.R)
- [R/12_sensitivity_analysis.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/12_sensitivity_analysis.R)
- [results/prognostico/aggregated/frozen_coefficients_linear.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/frozen_coefficients_linear.csv)
- [results/prognostico/aggregated/frozen_heteroscedasticity.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/frozen_heteroscedasticity.csv)
- [results/prognostico/aggregated/frozen_collinearity.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/frozen_collinearity.csv)

As entregas de tasks anteriores só estarão disponíveis após sua conclusão. Leia o resumo e as evidências das dependências antes de consumir suas saídas.

## Atividades

1. Auditar hipóteses da média linear e do logit, independência, heteroscedasticidade, caudas dos resíduos, colinearidade, influência e separação logística. Diferenciar diagnóstico por desenho de teste numérico.
2. Corrigir a mistura de IC normais de confint.default e p-valores t para lm. Documentar convenção coerente para estimativas aparentes e criar testes que detectem a inconsistência.
3. Calcular inferência robusta HC3 para coeficientes lineares como sensibilidade; justificar a convenção dos IC/testes e comparar com a inferência clássica. Não alterar coeficientes pontuais apenas para corrigir erros padrão.
4. Interpretar Breusch–Pagan, incluindo magnitude e padrão gráfico. Explicar que HC3 não corrige automaticamente não linearidade nem intervalos individuais.
5. Apresentar GVIF com graus de liberdade e transformação ajustada; verificar rank e indicadores de condicionamento sem impor um limiar arbitrário como prova de validade.
6. Avaliar separação multivariável por método apropriado quando viável; se houver apenas sinais indiretos, registrar explicitamente esse alcance. Integrar convergência, estimabilidade e categorias raras.
7. Preparar dados de resíduos com suavização, Q–Q e influência para a task 12; vincular observações influentes às sensibilidades da task 10, sem excluir casos da análise principal.
8. Entregar tabela pressuposto/evidência/interpretação/ação/limitação. Não reinstalar testes de normalidade ou autocorrelação do relatório histórico sem necessidade científica.

## Entregáveis

- `/Users/caiosainvallio/consultoria/scoliosis_model/R/07_frozen_models.R` com convenções inferenciais corrigidas
- `/Users/caiosainvallio/consultoria/scoliosis_model/tests/test_review_inference.R`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/diagnostics_*.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/coefficients_linear_hc3.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/08_pressupostos.md`

Registre comandos, arquivos produzidos/alterados, verificações e limitações em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/08_execucao.md`. Quando houver decisão estatística nova, inclua justificativa e referência verificável e atualize o BibTeX, se aplicável.

## Critérios de conclusão

- [ ] IC e testes correspondem ao mesmo estimador e à mesma convenção.
- [ ] Coeficientes dos modelos principais e coorte permanecem identificados e preservados.
- [ ] Heteroscedasticidade tem interpretação explícita e sensibilidade quantitativa.
- [ ] Nenhuma aprovação global de pressupostos se baseia apenas em p>0,05 ou convergência.
- [ ] Resumo de execução e manifesto atualizados com as evidências desta task.

## Encerramento e passagem

Atualize o status deste arquivo somente após verificar os critérios. Informe o que mudou, como foi verificado, quais saídas devem ser consumidas e se há dependências afetadas. Registre pendências sem inventar informação ou tratar uma limitação não resolvida como aprovação. Não execute automaticamente a próxima task.
