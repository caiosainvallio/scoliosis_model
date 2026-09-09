# Entrega da Task 14 — verificação técnica, renderização e reprodutibilidade

Data: 2026-09-08.

## Resultado

O HTML oficial [relatorio_prognostico.html](/Users/caiosainvallio/consultoria/scoliosis_model/relatorio_prognostico.html) foi renderizado em sessão limpa e é auto-contido. O Quarto concluiu as 37 etapas sem erro ou warning. A suíte de integração passou integralmente em `Rscript --vanilla`, e os avisos registrados pertencem aos casos sintéticos conhecidos de intervalo legado e separação logística, não à análise ou à renderização do relatório.

O relatório preserva o escopo aprovado: desenvolvimento e avaliação interna, sem modelo de progressão, sem alegação de validação externa e com a correção pelo colete tratada como medida basal transversal de corrigibilidade imediata.

## Evidências técnicas

| Verificação | Resultado |
|---|---|
| Renderização | `quarto render relatorio_prognostico.qmd --to html`: 37/37 etapas; HTML auto-contido criado. |
| Suíte limpa | 11 grupos aprovados: Tasks 04, 05, 07, 08, 09 e 10, CART, inferência, validação e Cobb. |
| Fonte | SHA-256 da planilha `f601adb42c299c2b0572f3e50ff26550b63a2f24dd7173f244a442b498965b71`, igual ao manifesto inicial. |
| Equações e cálculo independente | 20 coeficientes por modelo; exemplo sintético: delta −6,668365906857°, logito 1,595223637109 e probabilidade 0,831349763489. |
| Navegação | 44 links internos, nenhum alvo ausente; sumário e seções estão ancorados. |
| Figuras | 12 imagens embutidas no HTML; 12 PNGs e 11 SVGs revisados. Resoluções PNG entre 1600×1000 e 4800×1800; árvore 4200×3000. |
| Privacidade | 96 CSVs agregados inspecionados: nenhum campo pessoal/identificador de participante. `repeat_id`, `tree_id`, `config_id` e `scenario_id` são chaves técnicas agregadas. Não há listas de exclusão, `model.frame` nem dados brutos no HTML. |

As três figuras representativas — árvore CART, ROC/calibração e relações clínicas flexíveis — foram inspecionadas visualmente. Estão legíveis, com títulos, eixos, legendas e ressalvas de escopo; a árvore sinaliza folhas pequenas.

## Limitação de inspeção visual

O navegador do ambiente bloqueou a abertura de `file://` por política de URL. Portanto, não foi possível fazer a inspeção interativa do HTML em larguras distintas neste ambiente. Isso não impediu o teste estrutural do HTML, a checagem de âncoras, a inspeção das imagens locais nem a renderização auto-contida; a confirmação responsiva final deve ser feita em um navegador local que permita abrir o arquivo.

## Saídas para consumo

- HTML oficial: [relatorio_prognostico.html](/Users/caiosainvallio/consultoria/scoliosis_model/relatorio_prognostico.html)
- Logs: [renderizacao.log](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/logs/renderizacao.log) e [testes.log](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/logs/testes.log)
- Rastreabilidade final: [manifesto_final.csv](/Users/caiosainvallio/consultoria/scoliosis_model/results/prognostico/revisao/logs/manifesto_final.csv)

Nada foi recalculado além de testes sintéticos e verificações determinísticas. Bootstraps e ajustes aninhados já verificados permaneceram preservados. A Task 15 pode consumir este pacote e deve tratar a limitação de inspeção responsiva como pendência operacional, não como falha analítica.
