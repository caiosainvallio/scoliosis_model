# Execução da Tarefa 02 — definições clínicas e racional

Data: 2026-09-07  
Diretório: `/Users/caiosainvallio/consultoria/scoliosis_model`

## Comandos e consultas

Todos os comandos shell após a leitura inicial foram prefixados com `rtk`, conforme `RTK.md`.

| Ação | Finalidade | Resultado |
|---|---|---|
| Leitura do índice, Tarefas 01/02 e entregas da Tarefa 01 | Confirmar dependência, contrato, baseline e decisões preservadas | Dependência 01 concluída; fonte e modelos congelados identificados. |
| Leitura dirigida do parecer, plano original, QMD e módulos `R/02`, `R/07` e `R/09` | Recuperar fatos clínicos, derivações, fórmulas e termos da matriz | Dez preditores, 19 parâmetros, referências e hierarquia confirmados. |
| Importação somente leitura da planilha com `@oai/artifact-tool` | Conferir estrutura, cabeçalhos e aba `dicionario` sem alterar a fonte | Abas `dados` e `dicionario`; 19 colunas de dados; unidades e notas de origem recuperadas. |
| Verificação agregada em R da relação entre `dif_colete`, `correcao_colete` e Cobb basal | Testar se a fórmula percentual poderia ser afirmada a partir do código/fonte | A fórmula candidata `100 × dif_colete / maior Cobb basal` não reproduz a variável; a fórmula exata permanece pendente. Nenhum registro individual foi emitido. |
| Consulta dirigida à literatura indicada no parecer | Verificar população, protocolo, horizonte, desfecho e DOI | PMIDs 26909835, 32009436, 28437355 e 31731999, SOSORT e TRIPOD+AI registrados na matriz com limites de extrapolação. |
| Histórico Git por arquivo | Reconstruir a cronologia da especificação | A lista de preditores aparece na análise exploratória em abril de 2026; o plano de congelamento precede a implementação prognóstica de setembro, mas não a exploração. |
| Inspeção dos agregados congelados | Confirmar empates e níveis/referências sem reanalisar modelos | Dez empates na coorte final; níveis, referências e 19 graus de liberdade conferidos. |

## Arquivos produzidos

- `.plan/tasks-revisao/entregas/02_definicoes_clinicas.md`;
- `.plan/tasks-revisao/entregas/02_matriz_evidencias.md`;
- `.plan/tasks-revisao/entregas/02_execucao.md`;
- `results/prognostico/revisao/aggregated/dicionario_preditores.csv`.

Também foi acrescentada ao `results/prognostico/revisao/logs/manifesto_inicial.csv` a rastreabilidade das quatro saídas. O único outro arquivo alterado ao encerrar será o status da própria Tarefa 02.

Não foram alterados a planilha, `analisys.*`, `relatorio_prognostico.*`, módulos R, modelos ou resultados congelados. Não houve ajuste de modelo, bootstrap, validação cruzada ou renderização.

## Verificações concluídas

- `validate_outputs.R`: `predictors=10`, `parameters=19`, `terms_complete=TRUE` e `references_match=TRUE`;
- a ordem dos dez nomes coincide exatamente com `MODEL_PREDICTORS`; os 19 nomes expandidos coincidem por conjunto com a matriz de desenho congelada;
- importação do CSV com `Workbook.fromCSV()` confirmou 11 linhas incluindo cabeçalho e 12 colunas; a busca por erros de fórmula encontrou zero ocorrências;
- a prévia visual temporária confirmou a estrutura tabular; como CSV não preserva larguras ou formatação, sua legibilidade é assegurada pelo conteúdo delimitado e não por uma apresentação de planilha;
- as entregas mantêm `correcao_colete` como basal/transversal e usam linguagem explícita para separar prognóstico, maleabilidade, melhora radiográfica, efeito causal e benefício clínico;
- as pendências documentais e os limites de extrapolação estão explícitos na entrega clínica, no dicionário e na matriz;
- hashes SHA-256 das quatro saídas foram adicionados ao manifesto;
- o diff final foi limitado às quatro saídas da task, ao manifesto e ao status da própria Tarefa 02.

## Decisões e limitações

Não foi tomada decisão estatística nova, portanto não foi criado/alterado BibTeX nesta task; a Tarefa 03 conciliará as referências. A sensibilidade com Cobb basal já está delimitada para a Tarefa 10.

A fórmula percentual de `correcao_colete` não aparece nos scripts nem na aba de dicionário. A coluna `dif_colete` existe em graus, mas não entra nos modelos e sua relação operacional com as radiografias não está definida. Uma tentativa agregada de reproduzir `correcao_colete` a partir de `dif_colete` e do maior Cobb basal não coincidiu com os valores, o que impede inferir a fórmula. O protocolo da categoria `flexibilidade`, o recrutamento, a adesão, os avaliadores e outros detalhes listados na entrega clínica continuam pendentes.

Essas limitações não alteram o fato já confirmado de que `correcao_colete` é uma avaliação transversal basal.

## Passagem

As Tarefas 03, 10, 11 e 13 devem consumir as três entregas e o dicionário. A Tarefa 03 deve criar/conferir o BibTeX e a matriz bibliográfica formal; a 10 executa as sensibilidades com Cobb basal; a 11 integra características e documentação da coorte; a 13 incorpora o texto no QMD. Nenhuma task subsequente foi executada.
