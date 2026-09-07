# Task 13 — Reescrever e integrar o relatório prognóstico

- **Modelo recomendado:** sol (`gpt-5.6-sol`).
- **Complexidade:** Alta.
- **Justificativa do modelo:** Integra métodos, evidências, narrativa clínica e estrutura Quarto sem distorcer achados ou limitações.
- **Dependências:** [Task 02](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/02_definicoes_clinicas_e_racional.md), [Task 03](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/03_bibliografia_e_fontes.md), [Task 05](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/05_reexecucao_flexivel_e_hierarquia.md), [Task 06](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/06_auditoria_estrutural_cart.md), [Task 07](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/07_arvore_cart_e_folhas.md), [Task 08](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/08_pressupostos_e_inferencia_robusta.md), [Task 09](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/09_validacao_incerteza_e_shrinkage.md), [Task 10](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/10_sensibilidades_e_comparadores.md), [Task 11](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/11_coorte_descricao_e_tamanho_amostral.md), [Task 12](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/12_figuras_diagnosticas_e_resultados.md)
- **Status:** Pendente.

## Contexto e regras

Leia o [índice e contrato de execução](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/00_indice_execucao.md) e o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) antes de executar. A raiz do projeto é `/Users/caiosainvallio/consultoria/scoliosis_model`. Esta task pertence à revisão do relatório; a numeração é diferente da antiga pasta `.plan/tasks`.

A correção pelo colete é uma avaliação transversal da anamnese inicial, disponível como preditor basal e interpretada como possível marcador de maleabilidade/corrigibilidade imediata. Essa definição foi esclarecida pelo usuário e não deve ser reaberta como suspeita de vazamento temporal. Preserve a coorte e a especificação dos modelos principais; mantenha análises novas e saídas corrigidas rastreáveis.

## Objetivo

Entregar um QMD completo, fundamentado e interpretável, com mensagens quantitativas de aplicação prognóstica.

## Entradas

- [relatorio_prognostico.qmd](/Users/caiosainvallio/consultoria/scoliosis_model/relatorio_prognostico.qmd)
- [analisys.qmd](/Users/caiosainvallio/consultoria/scoliosis_model/analisys.qmd)
- [references_prognostico.bib](/Users/caiosainvallio/consultoria/scoliosis_model/references_prognostico.bib)
- [revisao_relatorio_prognostico.md](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md)
- [.plan/tasks-revisao/entregas/02_definicoes_clinicas.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/02_definicoes_clinicas.md)
- [.plan/tasks-revisao/entregas/03_mapa_citacoes.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/03_mapa_citacoes.md)
- [.plan/tasks-revisao/entregas/12_figuras_e_legendas.md](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/12_figuras_e_legendas.md)

As entregas de tasks anteriores só estarão disponíveis após sua conclusão. Leia o resumo e as evidências das dependências antes de consumir suas saídas.

## Atividades

1. Ler entregas 02–12 e o manifesto; resolver seleção das saídas atuais por caminho explícito e versão. Manter leitura dos resultados congelados onde continuam válidos e usar saídas corrigidas nos componentes afetados, sem fallback silencioso para resultados obsoletos.
2. Reestruturar em sumário executivo, pergunta/cenário, coorte, desfechos/preditores, métodos, modelo contínuo, logístico, CART, sensibilidades, discussão e apêndices.
3. Aplicar a sequência pergunta → método/pressupostos → resultado → interpretação/limite. Detalhar bootstrap, CV aninhada, tuning one-SE, shrinkage, tamanho amostral e diagnósticos.
4. Integrar a definição transversal do colete na anamnese, o racional de maleabilidade e a distinção de flexibilidade categórica. Recuperar decisões já aprovadas sobre tratamento e hierarquia dos modelos.
5. Incluir árvore CART, folhas, estabilidade estrutural, sensibilidades e figuras validadas. Renomear avaliações 'externas' para folds externos da validação interna aninhada; corrigir n de previsões repetidas e uso de 'a priori'/'hierarquia'.
6. Escrever sumário e conclusão com números calculados programaticamente. Comunicar erro em graus, discriminação, calibração e estabilidade; não interpretar AUC como acurácia nem RMSE como margem individual.
7. Discutir efeito por dez pontos percentuais de correção, comparadores, ausência de garantia de manutenção e limites da aplicação. OR não equivale a risco relativo; relações ajustadas não são intervenções causais.
8. Integrar BibTeX e citações junto aos métodos/afirmações, atualizando referências novas das tasks. Preservar precisão completa das equações em apêndice e usar arredondamento de leitura nas tabelas.
9. Revisar os blocos 'Sugestão para o manuscrito' com a análise final, sem frases fixas de ausência de falhas ou resultados desatualizados. Não reintroduzir modelo de progressão ou análise de decisão clínica sem objetivo definido.
10. Preencher rascunhos dos checklists oficiais com localização/evidência/pendência; distinguir desenvolvimento, avaliação e aplicabilidade. Não declarar preenchido um item sem suporte.

## Entregáveis

- `/Users/caiosainvallio/consultoria/scoliosis_model/relatorio_prognostico.qmd` reescrito
- `/Users/caiosainvallio/consultoria/scoliosis_model/references_prognostico.bib` reconciliado
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/tripod_ai_checklist.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/aggregated/probast_ai_assessment.csv`
- `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/13_integracao.md`

Registre comandos, arquivos produzidos/alterados, verificações e limitações em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/13_execucao.md`. Quando houver decisão estatística nova, inclua justificativa e referência verificável e atualize o BibTeX, se aplicável.

## Critérios de conclusão

- [ ] Todas as seções do parecer têm implementação, justificativa ou limitação registrada.
- [ ] Resultados são dinâmicos e correspondem à versão correta dos artefatos.
- [ ] Metodologia e pressupostos são explicados com referências e consequência prática.
- [ ] Sumário e conclusão dizem o que foi encontrado, além de descrever a hierarquia dos modelos.
- [ ] QMD não reintroduz achados inválidos da análise flexível anterior ou classificações clínicas não sustentadas.
- [ ] Resumo de execução e manifesto atualizados com as evidências desta task.

## Encerramento e passagem

Atualize o status deste arquivo somente após verificar os critérios. Informe o que mudou, como foi verificado, quais saídas devem ser consumidas e se há dependências afetadas. Registre pendências sem inventar informação ou tratar uma limitação não resolvida como aprovação. Não execute automaticamente a próxima task.

