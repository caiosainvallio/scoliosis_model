# Task 03 — Bibliografia verificável e matriz de citações

- **Modelo recomendado:** terra (`gpt-5.6-terra`).
- **Complexidade:** Moderada.
- **Justificativa do modelo:** Verificação bibliográfica e organização de referências com escopo delimitado pela fundamentação clínica.
- **Dependências:** [Task 01](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/01_inventario_e_rastreabilidade.md), [Task 02](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/02_definicoes_clinicas_e_racional.md)
- **Status:** Pendente.

## Contexto e regras

Leia o [índice e contrato de execução](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/00_indice_execucao.md) e o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) antes de executar. A raiz do projeto é `/Users/caiosainvallio/consultoria/scoliosis_model`. Esta task pertence à revisão do relatório; a numeração é diferente da antiga pasta `.plan/tasks`.

A correção pelo colete é uma avaliação transversal da anamnese inicial, disponível como preditor basal e interpretada como possível marcador de maleabilidade/corrigibilidade imediata. Essa definição foi esclarecida pelo usuário e não deve ser reaberta como suspeita de vazamento temporal. Preserve a coorte e a especificação dos modelos principais; mantenha análises novas e saídas corrigidas rastreáveis.

## Objetivo

Criar uma bibliografia reproduzível e associar fontes às decisões científicas do relatório.

## Entradas

- [revisao_relatorio_prognostico.md](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md)
- [.plan/tasks-revisao/entregas/02_matriz_evidencias.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/02_matriz_evidencias.md)
- [relatorio_prognostico.qmd](/Users/caiosainvallio/consultoria/scoliosis_model/relatorio_prognostico.qmd)

As entregas de tasks anteriores só estarão disponíveis após sua conclusão. Leia o resumo e as evidências das dependências antes de consumir suas saídas.

## Atividades

1. Criar references_prognostico.bib, sem substituir eventual bibliografia histórica. Verificar autores, título, ano, periódico, DOI e URL em fontes primárias.
2. Corrigir o DOI do artigo de Riley para desfechos contínuos para 10.1002/sim.7993; conferir o artigo binário 10.1002/sim.7992.
3. Cobrir TRIPOD+AI, PROBAST+AI, tamanho amostral, bootstrap, CV aninhada, calibração, estabilidade, inferência robusta, elastic net, CART e contexto clínico da mensuração/flexibilidade.
4. Consultar as versões oficiais dos checklists TRIPOD+AI e PROBAST+AI e registrar links, versão e campos a preencher posteriormente. Não atribuir avaliações de risco nesta task.
5. Produzir mapa seção/afirmação/chave BibTeX/fonte/limitação. Não usar uma diretriz de relato como fundamento único de um algoritmo estatístico.
6. Verificar DOI resolvível e ausência de chaves duplicadas. Referências novas usadas nas tasks analíticas devem ser acrescentadas por seus executores e reconciliadas na task 13.
7. Entregar instrução de integração Quarto com bibliography e citações, mantendo a edição global do QMD para a task 13.

## Entregáveis

- `/Users/caiosainvallio/consultoria/scoliosis_model/references_prognostico.bib`
- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/03_mapa_citacoes.md`
- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/03_fontes_checklists.md`

Registre comandos, arquivos produzidos/alterados, verificações e limitações em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/03_execucao.md`. Quando houver decisão estatística nova, inclua justificativa e referência verificável e atualize o BibTeX, se aplicável.

## Critérios de conclusão

- [ ] Metadados conferidos nas fontes; nenhuma referência inventada.
- [ ] Cada decisão metodológica relevante tem ao menos uma fonte adequada no mapa.
- [ ] DOI incorreto foi corrigido no BibTeX e sinalizado para remoção no QMD.
- [ ] Checklists têm versão e fonte identificadas; não há falsa declaração de conformidade.
- [ ] Resumo de execução e manifesto atualizados com as evidências desta task.

## Encerramento e passagem

Atualize o status deste arquivo somente após verificar os critérios. Informe o que mudou, como foi verificado, quais saídas devem ser consumidas e se há dependências afetadas. Registre pendências sem inventar informação ou tratar uma limitação não resolvida como aprovação. Não execute automaticamente a próxima task.

