# Execução da Task 15

Data: 08/09/2026 America/Sao_Paulo; encerramento em 09/09/2026 UTC. Execução local, sem delegação, publicação, commit ou push.

## Entradas e decisões

Lidos índice/contrato, task 15, dependência 14 e suas evidências, parecer atualizado, plano clínico e entregas metodológicas das tasks 02–13 pertinentes. A atividade 10 de revisão bibliográfica já era alteração do usuário no início e foi preservada. Nenhum status de outra task ou do índice foi alterado.

Não houve novo modelo, nova seleção ou mudança de estimando. Foram esclarecidos os limites dos IC deslocados, da CV pós-shrinkage e da cobertura conformal estratificada; a referência de Noma fundamenta o deslocamento e Lei fundamenta o método conformal, sem transferir garantias além do desenho implementado. Os bootstraps pesados e a CV aninhada completa foram preservados conforme o contrato. O script de auditoria recompõe resultados existentes e faz um ajuste principal para conferência independente, sem substituir saídas analíticas.

## Comandos e evidências

Todos os comandos de shell usaram `rtk`; leituras, scripts Python e shell auxiliar passaram por `rtk proxy`.

| Execução | Evidência e resultado |
|---|---|
| `rtk Rscript --vanilla scripts/audit_scientific_final.R` | `logs/auditoria_task15.log` e `auditoria_numerica_task15.csv`: 33/33 verificações aprovadas |
| `rtk Rscript --vanilla tests/run_tests.R` | `logs/testes_task15.log`: 11 grupos aprovados; avisos esperados de cenários sintéticos de intervalos/separação preservados |
| `rtk quarto render relatorio_prognostico.qmd --to html` | `logs/renderizacao_task15.log`: render final concluído, 37 etapas; sem falhas/citações não resolvidas |
| `rtk Rscript --vanilla -e ... knitr::purl(...); source(...) ...` | `logs/chunks_task15.log`: avaliação dos chunks com captura explícita de avisos, zero avisos; última mudança subsequente foi apenas CSS |
| `rtk proxy python3` — verificação bibliográfica | 17 DOI consultados no Crossref; JSON de metadados e CSV com 20 referências, pertinência e limites |
| Consultas web oficiais | TRIPOD expandido; suplemento PROBAST; PubMed e fontes editoriais de mensuração/colete, livro, JMLR e rpart |
| `rtk proxy python3` — HTMLParser e citações | `logs/verificacao_html_task15.json`: 50 links internos válidos, 12/12 imagens embutidas com texto alternativo; 20/20 referências citadas |
| Navegador local CUA | HTML agregado servido em 127.0.0.1:8765, diretório temporário contendo somente HTML; desktop 1440×900 e móvel 390×844 sem transbordamento da página, zero imagens quebradas e erros MathJax |
| SHA-256 e inspeção do diff | `logs/manifesto_final.csv` atualizado; fonte/históricos preservados; mudanças restritas à task e entregas |

O sandbox bloqueou inicialmente detecção de arquitetura do Quarto, DNS da consulta bibliográfica e abertura do socket local; as execuções necessárias foram aprovadas pela revisão automática de escalonamento. Não houve rejeição de aprovação pendente nem instalação de dependências. O navegador bloqueava file:// na task 14; nesta task a inspeção ocorreu por HTTP exclusivamente de loopback, sem disponibilizar a planilha ou objetos individuais.

A primeira versão da checagem pareada tratava métricas de outra família, legitimamente NA, como falha; o verificador foi corrigido para conferir diferenças finitas e ausência esperada por família. Nenhum resultado analítico foi alterado por isso. A inspeção visual detectou equações invadindo o índice e a tela móvel; foram ajustadas quebras em dois termos, largura e rolagem local. Capturas foram inspecionadas nas ferramentas, não salvas em disco. O servidor de loopback foi encerrado ao final. Finais de linha CRLF dos CSVs editados foram normalizados para LF, sem mudança do conteúdo tabular; `rtk proxy git diff --check` passou. Não se afirma inspeção visual de cada pixel do documento.

## Arquivos produzidos ou alterados

- `relatorio_prognostico.qmd` e HTML: título, linguagem clínica, escopo da validação/intervalos, unidades, texto de submissão, equações, responsividade e checklists atualizados.
- `references_prognostico.bib`: correções bibliográficas, inclusão de Xu e citação do manual rpart.
- `aggregated/tripod_ai_checklist.csv`, `probast_ai_assessment.csv` e novo `probast_ai_signaling_task15.csv`.
- Novo `scripts/audit_scientific_final.R`; logs e JSON/CSV descritos na tabela; novo `pendencias_finais.csv`; manifesto final atualizado.
- `15_parecer_final.md`, este registro e somente o status correspondente no arquivo da Task 15.

Os caminhos abreviados `logs/` e `aggregated/` acima pertencem a `results/prognostico/revisao/`. O manifesto registra os caminhos completos relativos à raiz e hashes das entregas, exceto o próprio manifesto para evitar autorreferência.

## Critérios de conclusão

| Critério da task | Resultado |
|---|---|
| Sem problema crítico sem resolução explícita | Atendido para o relatório restrito à fórmula fixa; limitação histórica mantida, alto risco dessa estratégia declarado e condição de retorno à Task 09 especificada |
| Alegações fortes sustentadas | Números recompostos, literatura confrontada, causalidade/uso clínico/garantias de IC e manutenção não afirmados |
| Checklists com evidência real | 52 itens TRIPOD, 14 julgamentos PROBAST e 34 sinalizações; pendências e fontes explícitas |
| Prontidão técnica distinta da validação externa | Parecer não recomenda submissão imediata e não declara modelo clinicamente validado |
| Sem publicação/commit/push | Atendido; somente trabalho local e servidor de loopback temporário |
| Resumo e manifesto atualizados | Este registro, parecer, pendências, logs e hashes finais |

## Limitações e passagem

Auditoria local, não revisão independente externa nem certificação TRIPOD/PROBAST. Não foram produzidos IC finais de coeficientes ou previsão, validação externa ou avaliação de equidade/utilidade. Pendências documentais dependem dos investigadores; não foram inventadas respostas. Consumir o parecer final, registro de pendências, checklists e HTML conciliado. As dependências permanecem com seus status preservados; qualquer ampliação para validar toda a seleção histórica exige retorno explícito à Task 09. Nenhuma próxima task foi disparada.
