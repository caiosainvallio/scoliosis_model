# Execução da Tarefa 03 — bibliografia e fontes

Data: 2026-09-07  
Diretório: `/Users/caiosainvallio/consultoria/scoliosis_model`

## Escopo e insumos consumidos

Foram lidos o índice, o parecer, `relatorio_prognostico.qmd` e as entregas verificadas das Tasks 01 e 02 (`01_inventario.md`, `01_execucao.md`, `02_matriz_evidencias.md` e `02_execucao.md`). A bibliografia preserva o esclarecimento clínico: `correcao_colete` é uma medida transversal basal, compatível com marcador de maleabilidade/corrigibilidade imediata; não se tratou a medida como vazamento temporal, ausência de estrutura ou garantia de resposta sustentada.

## Consultas e verificações

| Ação | Resultado |
|---|---|
| Consulta às páginas oficiais BMJ de TRIPOD+AI e PROBAST+AI | Metadados, DOI e status de instrumento confirmados. TRIPOD+AI é BMJ 2024;385:e078378; o suplemento de checklist identifica versão 7-Feb-2024. PROBAST+AI é BMJ 2025;388:e082505. |
| Consulta a fontes metodológicas primárias/editoriais | Conferidos metadados de glmnet (JSS), elastic net (JRSS B), calibração (BMC Medicine), CV aninhada (JMLR), bootstrap (J Clin Epidemiol) e referência CART. |
| Consulta PubMed para mensuração/flexibilidade | Confirmados autores, título, periódico, páginas, DOI e PMID de Ohrt-Nissen et al. (2016), estudo transversal de flexão lateral supina e correção inicial no colete. |
| Conferência dos artigos de tamanho amostral | `10.1002/sim.7993` corresponde ao artigo de Riley para desfecho contínuo; `10.1002/sim.7992`, ao artigo binário/tempo-até-evento. |
| Inspeção do QMD, sem editá-lo | A lista manual ainda contém `10.1002/sim.7991` na referência contínua. Foi registrado para remoção na Task 13; o QMD e o HTML foram preservados. |
| Verificação estrutural do BibTeX | 14 chaves únicas; cada entrada tem autor, título, ano, URL e periódico/editora; 13 entradas com DOI usam DOI explícito. A referência CART é livro (sem DOI atribuído). |

O teste HTTP direto dos DOI retornou `200` para Elsevier, BMC, JSS e JSTOR. Para BMJ, Wiley e Wolters Kluwer a resolução chegou à página do editor, cuja proteção automatizada devolveu `403`; os metadados e o destino foram então conferidos pelas páginas oficiais consultadas no navegador. Isto é limitação do cliente HTTP, não evidência de DOI inexistente. O conversor `quarto pandoc` também não pôde ser usado porque o binário do ambiente falhou ao identificar sua arquitetura; a sintaxe foi verificada independentemente por contagem de entradas/chaves e campos obrigatórios.

## Arquivos produzidos

- `references_prognostico.bib`;
- `.plan/tasks-revisao/entregas/03_mapa_citacoes.md`;
- `.plan/tasks-revisao/entregas/03_fontes_checklists.md`;
- `.plan/tasks-revisao/entregas/03_execucao.md`.

## Limitações e passagem

Esta é uma bibliografia dirigida, não revisão sistemática. Fontes de relato e avaliação crítica não foram usadas como justificativa única de algoritmos estatísticos. Não foram atribuídos itens atendidos, julgamentos de risco de viés ou alegações de conformidade com TRIPOD+AI/PROBAST+AI. A Task 13 deve integrar o YAML, substituir a lista manual e citar estas chaves; fontes novas de tasks analíticas devem ser conciliadas naquele momento. As Tasks 04, 06, 08, 09, 10 e 11 podem consumir a fonte metodológica apropriada, mas não devem reinterpretar a temporalidade clínica confirmada.
