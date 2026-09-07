# Task 01 — Inventário e rastreabilidade da revisão

- **Modelo recomendado:** luna (`gpt-5.6-luna`).
- **Complexidade:** Baixa.
- **Justificativa do modelo:** Leitura estruturada, inventário de arquivos e registro de evidências, sem decisões estatísticas novas.
- **Dependências:** Nenhuma.
- **Status:** Concluída em 2026-09-07.

## Contexto e regras

Leia o [índice e contrato de execução](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/00_indice_execucao.md) e o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) antes de executar. A raiz do projeto é `/Users/caiosainvallio/consultoria/scoliosis_model`. Esta task pertence à revisão do relatório; a numeração é diferente da antiga pasta `.plan/tasks`.

A correção pelo colete é uma avaliação transversal da anamnese inicial, disponível como preditor basal e interpretada como possível marcador de maleabilidade/corrigibilidade imediata. Essa definição foi esclarecida pelo usuário e não deve ser reaberta como suspeita de vazamento temporal. Preserve a coorte e a especificação dos modelos principais; mantenha análises novas e saídas corrigidas rastreáveis.

## Objetivo

Estabelecer a versão inicial e um mapa das evidências para que as correções posteriores sejam auditáveis.

## Entradas

- [revisao_relatorio_prognostico.md](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md)
- [.plan/00_alteracao_prognostico.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/00_alteracao_prognostico.md)
- [.plan/tasks/12_verificacao_final.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks/12_verificacao_final.md)
- [R/00_config.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/00_config.R)
- [results/prognostico/logs/task12_manifest.md](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/logs/task12_manifest.md)

As entregas de tasks anteriores só estarão disponíveis após sua conclusão. Leia o resumo e as evidências das dependências antes de consumir suas saídas.

## Atividades

1. Inspecionar o estado atual do Git e registrar alterações pré-existentes sem revertê-las. Ler o parecer atualizado e as decisões clínicas do plano original.
2. Inventariar QMD, HTML, módulos R, scripts, testes, tabelas, figuras, objetos e logs relevantes. Registrar quais saídas já existem e quais precisam ser corrigidas, calculadas ou apenas incorporadas.
3. Registrar hashes da planilha, relatórios históricos, modelos congelados e saídas principais; registrar versões disponíveis de R, Quarto e dependências. Não imprimir registros individuais.
4. Criar a estrutura results/prognostico/revisao/{aggregated,figures,logs,reduced_objects} e .plan/tasks-revisao/entregas. Definir um manifesto que relacione cada nova saída a seu script, fonte, versão e tarefa responsável.
5. Mapear cada seção do parecer às tasks 02–15. Registrar como decisões já confirmadas a medida transversal do colete, a manutenção das hipercorreções, a coorte e a hierarquia dos modelos.
6. Registrar comandos de execução existentes e os pontos de configuração de diretórios. Não executar os bootstraps ou a CV nesta task.

## Entregáveis

- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/01_inventario.md`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/logs/manifesto_inicial.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/logs/ambiente_inicial.txt`

Registre comandos, arquivos produzidos/alterados, verificações e limitações em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/01_execucao.md`. Quando houver decisão estatística nova, inclua justificativa e referência verificável e atualize o BibTeX, se aplicável.

## Critérios de conclusão

- [ ] Inventário diferencia resultados históricos, resultados congelados e saídas da revisão.
- [ ] Cada recomendação do parecer tem uma tarefa responsável.
- [ ] Hashes e estado inicial permitem conferir preservação da base e dos modelos principais.
- [ ] Nenhuma alteração analítica ou renderização pesada foi executada.
- [ ] Resumo de execução e manifesto atualizados com as evidências desta task.

## Encerramento e passagem

Atualize o status deste arquivo somente após verificar os critérios. Informe o que mudou, como foi verificado, quais saídas devem ser consumidas e se há dependências afetadas. Registre pendências sem inventar informação ou tratar uma limitação não resolvida como aprovação. Não execute automaticamente a próxima task.
