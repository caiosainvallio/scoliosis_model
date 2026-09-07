# Plano de execução — revisão do relatório prognóstico

Criado em 07/09/2026. **15 tasks de execução**, numeradas de 01 a 15; este arquivo 00 é somente o índice. Estado inicial: todas pendentes. Os arquivos descrevem trabalho futuro e não representam execução ou aprovação das análises.

Este plano transforma o [parecer atualizado](/Users/caiosainvallio/consultoria/scoliosis_model/revisao_relatorio_prognostico.md) em tarefas completas, com modelo sugerido, dependências, entregáveis e critérios de conclusão. O produto final é uma versão cientificamente enriquecida e tecnicamente verificada de [relatorio_prognostico.qmd](/Users/caiosainvallio/consultoria/scoliosis_model/relatorio_prognostico.qmd) e seu HTML.

## Ordem de execução e modelos

A sequência numérica abaixo é uma ordem válida: execute **01 → 02 → … → 15**. Consulte também as dependências; nenhuma saída de análise ainda pendente deve ser usada como resultado final.

| Task | Trabalho | Modelo | Complexidade | Depende de |
|---|---|---|---|---|
| 01 | [Inventário e rastreabilidade da revisão](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/01_inventario_e_rastreabilidade.md) | **luna** | Baixa | — |
| 02 | [Definições clínicas e racional dos preditores](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/02_definicoes_clinicas_e_racional.md) | **sol** | Alta | 01 |
| 03 | [Bibliografia verificável e matriz de citações](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/03_bibliografia_e_fontes.md) | **terra** | Moderada | 01, 02 |
| 04 | [Corrigir e verificar o algoritmo logístico flexível](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/04_correcao_solver_flexivel.md) | **astra** | Muito alta | 01, 03 |
| 05 | [Reexecutar a análise flexível e esclarecer a hierarquia](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/05_reexecucao_flexivel_e_hierarquia.md) | **sol** | Alta | 02, 03, 04 |
| 06 | [Corrigir a extração e a estabilidade estrutural da CART](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/06_auditoria_estrutural_cart.md) | **sol** | Alta | 01, 03 |
| 07 | [Redesenhar a árvore CART e a tabela de folhas](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/07_arvore_cart_e_folhas.md) | **terra** | Moderada | 02, 06 |
| 08 | [Pressupostos, diagnósticos e inferência robusta](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/08_pressupostos_e_inferencia_robusta.md) | **sol** | Alta | 02, 03 |
| 09 | [Avaliação interna, incerteza e equações após shrinkage](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/09_validacao_incerteza_e_shrinkage.md) | **astra** | Muito alta | 03, 08 |
| 10 | [Sensibilidades, Cobb basal e comparadores simples](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/10_sensibilidades_e_comparadores.md) | **sol** | Alta | 02, 03, 08, 09 |
| 11 | [Descrição completa da coorte e tamanho amostral](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/11_coorte_descricao_e_tamanho_amostral.md) | **terra** | Moderada | 01, 02, 03 |
| 12 | [Figuras dos modelos, calibração e estabilidade](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/12_figuras_diagnosticas_e_resultados.md) | **terra** | Moderada a alta | 05, 07, 08, 09, 10, 11 |
| 13 | [Reescrever e integrar o relatório prognóstico](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/13_reescrita_integral_relatorio.md) | **sol** | Alta | 02, 03, 05, 06, 07, 08, 09, 10, 11, 12 |
| 14 | [Renderizar e verificar reprodutibilidade e apresentação](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/14_renderizacao_e_reprodutibilidade.md) | **terra** | Moderada a alta | 13 |
| 15 | [Auditoria científica final para revisão por pares](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/15_auditoria_cientifica_final.md) | **astra** | Muito alta | 14 |

A distribuição dos modelos é uma recomendação minha baseada no esforço de raciocínio e no impacto de um erro em cada tarefa. A [documentação oficial dos modelos](https://developers.openai.com/api/docs/models) descreve Astra para os trabalhos mais complexos, Sol para trabalho profissional complexo, Terra para equilíbrio entre capacidade e custo e Luna para cargas sensíveis a custo. Isso orienta a alocação, sem constituir um benchmark específico deste projeto.

| Nome utilizado | Identificador |
|---|---|
| luna | `gpt-5.6-luna` |
| terra | `gpt-5.6-terra` |
| sol | `gpt-5.6-sol` |
| astra | `gpt-6-astra` |

Astra fica reservado à correção numérica do solver, aos estimadores de incerteza/shrinkage e à auditoria científica final. Sol conduz análises e síntese científica; Terra executa bibliografia, tabelas, gráficos e integração técnica com critérios definidos; Luna faz o inventário inicial. Não é necessário criar tarefas no aplicativo ou alterar automaticamente o modelo desta conversa para usar estes arquivos.

## Contexto confirmado e precedência

1. Ler as instruções aplicáveis do projeto e [RTK.md](/Users/caiosainvallio/.codex/RTK.md); prefixar comandos shell com `rtk`.
2. Respeitar o esclarecimento do usuário: **correcao_colete é uma avaliação transversal realizada na anamnese**, que quantifica a diferença momentânea com um colete rígido e pode indicar maleabilidade/corrigibilidade. Está disponível como preditor basal. Não repetir a suspeita temporal retirada do parecer.
3. Na redação científica, falar em componente flexível/redutível e potencial prognóstico. A manutenção da correção é uma hipótese longitudinal; não declarar ausência de estrutura ou garantia de resposta apenas pela medida momentânea.
4. O [plano original](/Users/caiosainvallio/consultoria/scoliosis_model/.plan/00_alteracao_prognostico.md) já registra tratamento conservador com colete e exercícios S4D, medida transversal antes do tratamento longitudinal, hipercorreções confirmadas e exclusão dos modelos de progressão. Recuperar essas decisões antes de listar algo como desconhecido.
5. Coorte vigente: 621 registros brutos, 618 após deduplicação, 615 completos, 317 eventos de melhora e 298 não eventos. São invariantes desta revisão enquanto a fonte permanecer a mesma, a conferir pelo hash.
6. Os modelos principais conservam dez preditores, 19 parâmetros preditores e intercepto. Linear para delta é principal, logística de melhora radiográfica de pelo menos 5° é secundária; CART e modelagem flexível são exploratórias.
7. Preservar hipercorreções verdadeiras e a coorte principal. Exclusões por influência e inclusão de Cobb basal são sensibilidades identificadas. Não reintroduzir modelos de progressão, seleção por p-valor, divisão treino–teste simples ou indicação terapêutica.
8. O plano de revisão complementa as tasks antigas em `.plan/tasks`; não reutilizar a numeração como se as antigas tivessem sido reabertas. As tasks antigas concluídas são histórico, não certificado de correção de novos achados.

## Contrato de arquivos e execução

Raiz do projeto: `/Users/caiosainvallio/consultoria/scoliosis_model`.

- Base bruta e relatórios históricos são somente leitura. Preservar [analisys.qmd](/Users/caiosainvallio/consultoria/scoliosis_model/analisys.qmd), seu HTML e a planilha.
- Preservar resultados congelados originais para comparação. Gerar novas tabelas, figuras, logs e objetos em `/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/`, com subdiretórios `aggregated`, `figures`, `logs` e `reduced_objects`.
- As tasks analíticas podem corrigir código R e testes; devem permitir destino explícito das saídas, sem sobrescrever silenciosamente resultados congelados.
- Objetos com registros/previsões individuais permanecem internos. Tabelas e HTML de compartilhamento devem conter apenas conteúdo apropriado, sem IDs ou cópias da base.
- Evidências de cada task ficam em `/Users/caiosainvallio/consultoria/scoliosis_model/.plan/tasks-revisao/entregas/`. As entregas específicas são descritas em cada arquivo; também manter `NN_execucao.md` com comandos, resultados, arquivos e limitações.
- Cada task usa as saídas **já verificadas** de suas dependências. Evitar fallback silencioso para resultados antigos quando uma saída corrigida estiver ausente.
- A task 13 concentra a reescrita e integração global do QMD. As tasks anteriores entregam resultados, texto, legendas e blocos de integração. A task 03 cria o BibTeX; autores das tasks analíticas podem acrescentar fontes, conciliadas na task 13.
- A task 14 renderiza e verifica o conjunto; a task 15 faz auditoria crítica e exige nova verificação dos componentes que forem alterados. Uma correção após renderizar requer atualizar também o HTML correspondente.
- Não instalar dependências durante a renderização. Registrar mudanças de ambiente necessárias à execução nos scripts e logs.
- Executar testes proporcionais às mudanças; usar testes numéricos independentes para correções estatísticas. Não adicionar testes que apenas reproduzem a implementação.
- Não repetir os bootstraps de 2.000 tentativas ou ajustes aninhados completos quando os insumos e procedimentos continuam válidos e já foram verificados. Mudanças no solver ou no alvo da avaliação exigem reexecução dos componentes afetados.
- Não selecionar novos cenários para favorecer resultados. Identificar complementos decorrentes desta revisão e registrar decisões metodológicas antes de executar novos cálculos.
- As tasks são locais: não publicar, enviar mensagens a terceiros, fazer commit ou push automaticamente. Não disparar a próxima task ao concluir uma delas.

## Uso de cada arquivo

Abra a task no modelo recomendado e use uma instrução como:

> Execute integralmente a task indicada neste arquivo. Leia o índice e as dependências, implemente seu escopo, verifique os critérios de conclusão e registre as evidências. Preserve as decisões clínicas já esclarecidas. Ao concluir, informe os resultados e atualize somente o status correspondente.

Não é necessário copiar a conversa inteira: os arquivos remetem ao parecer, ao plano aprovado e às entradas relevantes. Quando houver informação clínica realmente ausente, consultar primeiro os documentos; registrar a pendência e avançar no trabalho que não depende dela. Não inventar fatos nem pedir reconfirmação das decisões já registradas.

## Cobertura do parecer

| Recomendação | Tasks responsáveis |
|---|---|
| Temporalidade resolvida do colete, maleabilidade, cenário e dicionário | 02, 13, 15 |
| Justificativa do desfecho, preditores, Cobb basal e escopo sem progressão | 02, 10, 13 |
| Bibliografia, DOI e fontes oficiais dos checklists | 03, 13, 15 |
| Objetivo incorreto do solver e testes tautológicos | 04 |
| Reexecução flexível, hierarquia efetiva e comparação nos mesmos folds | 05 |
| Cortes primários, escopos, denominadores e falhas de calibração CART | 06 |
| Árvore bonita, regras de folhas e estabilidade | 07, 12, 13 |
| Heteroscedasticidade, IC/testes coerentes, GVIF e separação | 08, 12, 13 |
| Bootstrap, falhas por réplica, IC de desempenho, shrinkage e cobertura | 09 |
| Influência, hipercorreções, alternativas com Cobb basal e referências simples | 10 |
| Dados faltantes antes da exclusão, descrição integral e cenários amostrais | 11 |
| Gráficos de calibração, estabilidade, coeficientes e formas funcionais | 12 |
| Metodologia detalhada, mensagens quantitativas e discussão aplicável | 13 |
| Renderização, privacidade, evidências, testes e identidade das fontes | 14 |
| TRIPOD+AI/PROBAST+AI com evidência e parecer final de prontidão | 15 |

## Condição de término

O trabalho estará concluído quando o QMD e o HTML incorporarem a revisão, as análises afetadas tiverem sido corrigidas e verificadas e a task 15 não identificar falhas críticas pendentes. Limitações científicas que não possam ser resolvidas com esta coorte devem estar explícitas. Não confundir ausência de falhas críticas no relatório com validação clínica externa do modelo.

