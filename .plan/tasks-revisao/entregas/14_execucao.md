# Execução da Task 14 — renderização e reprodutibilidade

Data: 2026-09-08.

## Comandos executados

| Comando | Resultado |
|---|---|
| `rtk Rscript --vanilla tests/run_tests.R` | Suíte registrada em `results/prognostico/revisao/logs/testes.log`; todos os grupos aprovados. |
| `rtk quarto render relatorio_prognostico.qmd --to html` | Render oficial registrado em `results/prognostico/revisao/logs/renderizacao.log`; 37 etapas concluídas. |
| `rtk Rscript --vanilla -e ...` | Recomposição manual de equações pós-shrinkage para vetor sintético; 20 termos por modelo. |
| `rtk shasum -a 256 ...` | Fonte, QMD, HTML, BibTeX, configuração, testes e logs conferidos. |
| `rtk Rscript --vanilla -e ...xml2...` | 44 links internos e 82 IDs; nenhum destino ausente; 12 imagens embutidas. |
| `rtk sips -g pixelWidth -g pixelHeight ...` | Resolução de todas as figuras PNG conferida; SVGs presentes. |

## Arquivos produzidos ou alterados

- atualizado por renderização: `relatorio_prognostico.html`;
- criados: `results/prognostico/revisao/logs/renderizacao.log`, `testes.log` e `manifesto_final.csv`;
- criados: `14_verificacao_tecnica.md` e este registro;
- atualizado somente o status da Task 14 após as verificações.

## Ambiente

- Quarto 1.6.40;
- R 4.6.1; `digest` 0.6.39; `knitr` 1.51;
- configuração: semente global 20260906; sementes paralelas 20260907–20260910;
- commit corrente: `df0ef15ffc5a8e408d2f7e601c8ac6d10891ee03`.

## Limitações

Não foram instaladas dependências nem reexecutados bootstraps/CV. Os warnings da suíte são esperados em testes sintéticos e permanecem no log. A política do navegador bloqueou `file://`; a inspeção de responsividade em navegador permanece uma confirmação operacional externa, documentada em `14_verificacao_tecnica.md`.
