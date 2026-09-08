# Task 11 — Descrição completa da coorte e tamanho amostral

- **Modelo recomendado:** terra (`gpt-5.6-terra`).
- **Complexidade:** Moderada.
- **Justificativa do modelo:** Expansão de tabelas e relato a partir de procedimentos e resultados já definidos.
- **Dependências:** [Task 01](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/01_inventario_e_rastreabilidade.md), [Task 02](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/02_definicoes_clinicas_e_racional.md), [Task 03](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/03_bibliografia_e_fontes.md)
- **Status:** Concluída em 2026-09-08.

## Contexto e regras

Leia o [índice e contrato de execução](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/00_indice_execucao.md) e o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) antes de executar. A raiz do projeto é `/Users/caiosainvallio/consultoria/scoliosis_model`. Esta task pertence à revisão do relatório; a numeração é diferente da antiga pasta `.plan/tasks`.

A correção pelo colete é uma avaliação transversal da anamnese inicial, disponível como preditor basal e interpretada como possível marcador de maleabilidade/corrigibilidade imediata. Essa definição foi esclarecida pelo usuário e não deve ser reaberta como suspeita de vazamento temporal. Preserve a coorte e a especificação dos modelos principais; mantenha análises novas e saídas corrigidas rastreáveis.

## Objetivo

Fornecer ao leitor a população efetivamente analisada e as premissas da adequação amostral.

## Entradas

- [R/02_import_prepare.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/02_import_prepare.R)
- [R/06_report_helpers.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/06_report_helpers.R)
- [results/prognostico/aggregated/cohort_summary.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/cohort_summary.csv)
- [results/prognostico/aggregated/missing_report.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/missing_report.csv)
- [results/prognostico/aggregated/sample_size_assessment.md](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/sample_size_assessment.md)
- [results/prognostico/aggregated/sample_size_scenarios.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/aggregated/sample_size_scenarios.csv)

As entregas de tasks anteriores só estarão disponíveis após sua conclusão. Leia o resumo e as evidências das dependências antes de consumir suas saídas.

## Atividades

1. Produzir tabela de todos os preditores e desfechos: n, ausentes, média/DP, mediana/IIQ e amplitude quando úteis; contagens e proporções para fatores.
2. Conferir fluxo 621 → 618 → 615 e eventos 317/298. Mostrar ausentes antes da exclusão e a proporção de três casos incompletos entre os 618 participantes deduplicados.
3. Resumir comparações incluídos/excluídos sem divulgar registros individuais ou detalhes que identifiquem o grupo de três excluídos. Evitar teste de hipótese de pouco valor nesse grupo.
4. Produzir distribuição de delta e resumo da magnitude basal, com marcações descritivas em −5°, 0° e +5°, sem criar análise/modelo de progressão. Reportar empates basais e a regra anatômica.
5. Expor 19 parâmetros de preditores, intercepto, 615 participantes, 317 eventos e shrinkage desejado 0,90; separar variáveis de parâmetros.
6. Incorporar cenários pmsampsize e premissas de R²/Cox–Snell/prevalência. Mostrar cenários insuficientes, caráter retrospectivo dos inputs aparentes e inaplicabilidade do cálculo à complexidade flexível.
7. Entregar tabelas, legenda, síntese metodológica e dados agregados para gráficos. Não transformar baixo percentual de ausentes em prova de ausência de viés nem executar imputação sem uma pergunta definida.

## Entregáveis

- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/cohort_descriptive.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/missing_before_after.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/sample_size_display.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/11_coorte_amostra.md`

Registre comandos, arquivos produzidos/alterados, verificações e limitações em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/11_execucao.md`. Quando houver decisão estatística nova, inclua justificativa e referência verificável e atualize o BibTeX, se aplicável.

## Critérios de conclusão

- [ ] Tabelas cobrem todas as variáveis usadas e conciliam denominadores.
- [ ] Ausência de dados após caso completo não oculta exclusões anteriores.
- [ ] Tamanho amostral é apresentado como condicional às premissas.
- [ ] Dados e figuras permitem descrição completa sem divulgar IDs ou linhas individuais.
- [ ] Resumo de execução e manifesto atualizados com as evidências desta task.

## Encerramento e passagem

Atualize o status deste arquivo somente após verificar os critérios. Informe o que mudou, como foi verificado, quais saídas devem ser consumidas e se há dependências afetadas. Registre pendências sem inventar informação ou tratar uma limitação não resolvida como aprovação. Não execute automaticamente a próxima task.
