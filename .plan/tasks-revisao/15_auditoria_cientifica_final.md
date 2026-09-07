# Task 15 — Auditoria científica final para revisão por pares

- **Modelo recomendado:** astra (`gpt-6-astra`).
- **Complexidade:** Muito alta.
- **Justificativa do modelo:** Exige avaliação crítica transversal de validade, evidência clínica, implementação e força das conclusões.
- **Dependências:** [Task 14](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/14_renderizacao_e_reprodutibilidade.md)
- **Status:** Pendente.

## Contexto e regras

Leia o [índice e contrato de execução](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/00_indice_execucao.md) e o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) antes de executar. A raiz do projeto é `/Users/caiosainvallio/consultoria/scoliosis_model`. Esta task pertence à revisão do relatório; a numeração é diferente da antiga pasta `.plan/tasks`.

A correção pelo colete é uma avaliação transversal da anamnese inicial, disponível como preditor basal e interpretada como possível marcador de maleabilidade/corrigibilidade imediata. Essa definição foi esclarecida pelo usuário e não deve ser reaberta como suspeita de vazamento temporal. Preserve a coorte e a especificação dos modelos principais; mantenha análises novas e saídas corrigidas rastreáveis.

## Objetivo

Verificar se a versão revisada sustenta suas afirmações científicas e identificar qualquer impedimento concreto à submissão.

## Entradas

- [relatorio_prognostico.qmd](/Users/caiosainvallio/consultoria/scoliosis_model/relatorio_prognostico.qmd)
- [relatorio_prognostico.html](/Users/caiosainvallio/consultoria/scoliosis_model/relatorio_prognostico.html)
- [revisao_relatorio_prognostico.md](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md)
- [.plan/00_alteracao_prognostico.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/00_alteracao_prognostico.md)
- [.plan/tasks-revisao/entregas/14_verificacao_tecnica.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/14_verificacao_tecnica.md)
- [results/prognostico/revisao/aggregated/tripod_ai_checklist.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/tripod_ai_checklist.csv)
- [results/prognostico/revisao/aggregated/probast_ai_assessment.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/probast_ai_assessment.csv)

As entregas de tasks anteriores só estarão disponíveis após sua conclusão. Leia o resumo e as evidências das dependências antes de consumir suas saídas.

## Atividades

1. Ler o documento como parecerista, conferindo as evidências quando necessário. Não assumir que a conclusão de uma task anterior demonstra validade; tampouco declarar avaliação independente externa.
2. Auditar coerência entre população, anamnese/transversalidade do colete, disponibilidade de preditores, desfecho, horizonte, estimando e uso pretendido.
3. Conferir solver revisado, hierarquia efetiva, cortes primários CART, inferência robusta, contagem de falhas, estimativas corrigidas, intervalos e comparações pareadas. Verificar que a fonte dos números é a versão correta.
4. Verificar o alcance da validação de equações pós-shrinkage, as limitações dos intervalos e as afirmações de estabilidade; impedir apresentação de IC não fundamentados.
5. Revisar TRIPOD+AI item a item e PROBAST+AI com justificativa por domínio, evidência e localização. Não converter ausência de validação externa automaticamente em alto risco de viés interno.
6. Conferir literatura clínica, mensuração dos 5°, interpretação das OR, maleabilidade e distinção entre corrigibilidade imediata e manutenção longitudinal. Não extrapolar resultados a condutas ou além de seis meses.
7. Conferir a cobertura do parecer atualizado e das decisões prévias. Classificar pendências como crítica, relevante ou editorial, com arquivo/trecho, impacto e tarefa de origem.
8. Corrigir problemas locais de redação que não alterem análise. Para falhas analíticas, registrar retorno à task de origem com verificação exigida; não declarar auditoria concluída sem resolução das falhas críticas.
9. Após qualquer correção, repetir os checks e a renderização afetados da task 14. Emitir recomendação fundamentada de prontidão ou lista objetiva do que ainda impede a submissão.

## Entregáveis

- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/15_parecer_final.md`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/tripod_ai_checklist.csv` revisado
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/probast_ai_assessment.csv` revisado
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/logs/pendencias_finais.csv`
- QMD/HTML finais conciliados após eventuais correções

Registre comandos, arquivos produzidos/alterados, verificações e limitações em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/15_execucao.md`. Quando houver decisão estatística nova, inclua justificativa e referência verificável e atualize o BibTeX, se aplicável.

## Critérios de conclusão

- [ ] Não restam problemas críticos de validade sem resolução explícita.
- [ ] Todas as alegações fortes têm suporte em análise e literatura adequadas.
- [ ] Checklists identificam evidências e pendências reais, sem autoatestado genérico.
- [ ] Parecer final distingue relatório tecnicamente pronto de modelo clinicamente validado externamente.
- [ ] Nenhuma publicação, commit ou push é efetuado automaticamente.
- [ ] Resumo de execução e manifesto atualizados com as evidências desta task.

## Encerramento e passagem

Atualize o status deste arquivo somente após verificar os critérios. Informe o que mudou, como foi verificado, quais saídas devem ser consumidas e se há dependências afetadas. Registre pendências sem inventar informação ou tratar uma limitação não resolvida como aprovação. Não execute automaticamente a próxima task.

