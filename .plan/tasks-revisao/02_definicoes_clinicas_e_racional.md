# Task 02 — Definições clínicas e racional dos preditores

- **Modelo recomendado:** sol (`gpt-5.6-sol`).
- **Complexidade:** Alta.
- **Justificativa do modelo:** Exige síntese clínica, leitura crítica de literatura e distinção entre informação confirmada e hipótese prognóstica.
- **Dependências:** [Task 01](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/01_inventario_e_rastreabilidade.md)
- **Status:** Concluída em 2026-09-07.

## Contexto e regras

Leia o [índice e contrato de execução](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/00_indice_execucao.md) e o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) antes de executar. A raiz do projeto é `/Users/caiosainvallio/consultoria/scoliosis_model`. Esta task pertence à revisão do relatório; a numeração é diferente da antiga pasta `.plan/tasks`.

A correção pelo colete é uma avaliação transversal da anamnese inicial, disponível como preditor basal e interpretada como possível marcador de maleabilidade/corrigibilidade imediata. Essa definição foi esclarecida pelo usuário e não deve ser reaberta como suspeita de vazamento temporal. Preserve a coorte e a especificação dos modelos principais; mantenha análises novas e saídas corrigidas rastreáveis.

## Objetivo

Produzir a fundamentação clínica e operacional que sustentará os métodos e a discussão.

## Entradas

- [revisao_relatorio_prognostico.md](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md)
- [.plan/00_alteracao_prognostico.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/00_alteracao_prognostico.md)
- [R/02_import_prepare.R](/Users/caiosainvallio/consultoria/scoliosis_model/R/02_import_prepare.R)
- [relatorio_prognostico.qmd](/Users/caiosainvallio/consultoria/scoliosis_model/relatorio_prognostico.qmd)

As entregas de tasks anteriores só estarão disponíveis após sua conclusão. Leia o resumo e as evidências das dependências antes de consumir suas saídas.

## Atividades

1. Consolidar os fatos já aprovados: adolescentes com escoliose idiopática, manejo conservador com colete e exercícios S4D conforme plano, avaliação transversal antes do tratamento longitudinal, horizonte de seis meses e hipercorreções reconhecidas pela equipe.
2. Definir correcao_colete como diferença momentânea avaliada na anamnese com colete rígido, disponível na previsão basal; explicar maleabilidade/corrigibilidade e seu possível valor prognóstico. Usar 'componente flexível ou redutível', sem afirmar ausência de alterações estruturais ou manutenção garantida.
3. Recuperar dos documentos a comparação radiográfica sem/com colete e os detalhes de cálculo e protocolo. Não reabrir a temporalidade já esclarecida; marcar somente informações ainda não documentadas, como fórmula exata, período de recrutamento, adesão ou avaliadores.
4. Produzir dicionário dos dez preditores, 19 parâmetros mais intercepto: definição, unidade, codificação, referência, graus de liberdade, aquisição e justificativa. Distinguir a medida quantitativa de correção da variável categórica flexibilidade.
5. Explicar delta, limiar radiográfico de 5°, máximos de regiões possivelmente diferentes e empates basais. Recuperar a decisão de excluir análises de progressão; não reinseri-las nem pedir autorização novamente para decisões existentes.
6. Justificar a especificação congelada sem Cobb basal e delimitar a sensibilidade da task 10. Reconstruir a cronologia das decisões para evitar usar 'a priori' sem evidência.
7. Consultar fontes primárias clínicas e metodológicas já indicadas no parecer. Criar matriz afirmação–fonte–população–horizonte–limite de extrapolação; distinguir hipóteses e escolhas por disponibilidade.

## Entregáveis

- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/02_definicoes_clinicas.md`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/dicionario_preditores.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/02_matriz_evidencias.md`

Registre comandos, arquivos produzidos/alterados, verificações e limitações em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/02_execucao.md`. Quando houver decisão estatística nova, inclua justificativa e referência verificável e atualize o BibTeX, se aplicável.

## Critérios de conclusão

- [ ] Temporalidade da correção está resolvida e coerente em todos os textos entregues.
- [ ] Dicionário cobre todos os termos e referências das fórmulas reais.
- [ ] Textos distinguem melhora radiográfica, efeito causal, maleabilidade e prognóstico.
- [ ] Pendências são apenas fatos ausentes; nenhuma informação clínica foi inventada.
- [ ] Resumo de execução e manifesto atualizados com as evidências desta task.

## Encerramento e passagem

Atualize o status deste arquivo somente após verificar os critérios. Informe o que mudou, como foi verificado, quais saídas devem ser consumidas e se há dependências afetadas. Registre pendências sem inventar informação ou tratar uma limitação não resolvida como aprovação. Não execute automaticamente a próxima task.

