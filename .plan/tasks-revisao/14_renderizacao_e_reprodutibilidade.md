# Task 14 — Renderizar e verificar reprodutibilidade e apresentação

- **Modelo recomendado:** terra (`gpt-5.6-terra`).
- **Complexidade:** Moderada a alta.
- **Justificativa do modelo:** Execução técnica e inspeção sistemática de um relatório com critérios de qualidade já especificados.
- **Dependências:** [Task 13](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/13_reescrita_integral_relatorio.md)
- **Status:** Pendente.

## Contexto e regras

Leia o [índice e contrato de execução](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/00_indice_execucao.md) e o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) antes de executar. A raiz do projeto é `/Users/caiosainvallio/consultoria/scoliosis_model`. Esta task pertence à revisão do relatório; a numeração é diferente da antiga pasta `.plan/tasks`.

A correção pelo colete é uma avaliação transversal da anamnese inicial, disponível como preditor basal e interpretada como possível marcador de maleabilidade/corrigibilidade imediata. Essa definição foi esclarecida pelo usuário e não deve ser reaberta como suspeita de vazamento temporal. Preserve a coorte e a especificação dos modelos principais; mantenha análises novas e saídas corrigidas rastreáveis.

## Objetivo

Entregar HTML renderizado e um pacote de evidências que comprove consistência técnica e visual.

## Entradas

- [relatorio_prognostico.qmd](/Users/caiosainvallio/consultoria/scoliosis_model/relatorio_prognostico.qmd)
- [references_prognostico.bib](/Users/caiosainvallio/consultoria/scoliosis_model/references_prognostico.bib)
- [tests/run_tests.R](/Users/caiosainvallio/consultoria/scoliosis_model/tests/run_tests.R)
- [results/prognostico/revisao/logs/manifesto_inicial.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/logs/manifesto_inicial.csv)
- [.plan/tasks-revisao/entregas/13_integracao.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/13_integracao.md)

As entregas de tasks anteriores só estarão disponíveis após sua conclusão. Leia o resumo e as evidências das dependências antes de consumir suas saídas.

## Atividades

1. Executar testes relevantes às mudanças e a suíte de integração aplicável em sessão R limpa, sem restaurar .RData. Registrar versões de execução das análises e da renderização separadamente.
2. Renderizar relatorio_prognostico.qmd para HTML self-contained em sessão limpa. Não instalar dependências ou recalcular modelos pesados durante a renderização.
3. Capturar logs de warnings/erros mesmo quando o documento os oculta. Corrigir problemas de integração, referências e renderização; direcionar falhas analíticas à task responsável.
4. Conferir exemplos de previsões por cálculo manual, equações, coeficientes, unidades, referências de fatores e identidade das fontes. Usar exemplos sintéticos, sem publicar registros individuais.
5. Inspecionar o HTML em navegador: sumário, ancoragem, tabelas, citações, equações longas, árvore, imagens e layout em telas de diferentes larguras. Conferir também as figuras vetoriais.
6. Comparar números do texto, tabelas, gráficos e manifestos; procurar descrições analíticas incorretas de validação externa, progressão, IC ou alegações clínicas. Não remover discussões legítimas sobre ausência de validação externa.
7. Auditar HTML e artefatos compartilháveis contra exposição de IDs, listas de exclusão, model.frame e dados brutos. Manter objetos individuais apenas no diretório interno.
8. Verificar hashes dos dados e históricos contra task 01. Repetir computações apenas onde faltarem evidências de reprodutibilidade após as mudanças, evitando refazer reamostragens invariantes já verificadas.
9. Preparar manifesto final com versões, sementes, hashes, scripts, saídas, status de testes, limitações e alterações em relação ao início.

## Entregáveis

- `/Users/caiosainvallio/consultoria/scoliosis_model/relatorio_prognostico.html` renderizado e inspecionado
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/logs/renderizacao.log`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/logs/testes.log`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/logs/manifesto_final.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/14_verificacao_tecnica.md`

Registre comandos, arquivos produzidos/alterados, verificações e limitações em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/14_execucao.md`. Quando houver decisão estatística nova, inclua justificativa e referência verificável e atualize o BibTeX, se aplicável.

## Critérios de conclusão

- [ ] Renderização limpa concluída sem erros ou warnings críticos não resolvidos.
- [ ] Referências e links internos funcionam; tabelas e figuras não estão cortadas.
- [ ] Teste numérico, integridade das fontes e correspondência texto–resultado estão registrados.
- [ ] HTML compartilhável não expõe registros identificáveis e históricos permanecem preservados.
- [ ] Resumo de execução e manifesto atualizados com as evidências desta task.

## Encerramento e passagem

Atualize o status deste arquivo somente após verificar os critérios. Informe o que mudou, como foi verificado, quais saídas devem ser consumidas e se há dependências afetadas. Registre pendências sem inventar informação ou tratar uma limitação não resolvida como aprovação. Não execute automaticamente a próxima task.

