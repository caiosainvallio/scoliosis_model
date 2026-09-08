# Execução da Task 07 — árvore CART e tabela de folhas

Data: 2026-09-08  
Diretório: `/Users/caiosainvallio/consultoria/scoliosis_model`

## Escopo e insumos

Foram lidos o índice/contrato, o parecer e as entregas verificadas das Tasks 02 e 06. Foram consumidos exclusivamente `cart_illustrative_primary_splits.csv`, `cart_illustrative_leaf_rules.csv`, `cart_variable_frequency_summary.csv` e `cart_cutpoint_summary.csv` em `results/prognostico/revisao/aggregated/`, além do objeto reduzido congelado somente para reconstruir e conferir a árvore ilustrativa com sua configuração global já salva. Não foi usado o desenho histórico nem houve retuning, bootstrap, CV adicional ou modificação da coorte/modelos principais.

## Comandos e verificações

| Comando/ação | Resultado |
|---|---|
| `rtk Rscript --vanilla scripts/render_cart_revision.R` | Reconstruiu deterministicamente a árvore ilustrativa, gerou PNG/SVG e `cart_leaves.csv`; todas as cinco verificações internas passaram. |
| Verificação R independente de `cart_leaves.csv` | `sum(n)=615`, `sum(eventos_melhora)=317`, proporções no intervalo [0,1] e iguais a `eventos/n` com tolerância numérica. |
| `rtk file` nos quatro gráficos | PNGs válidos de 4200×3000 e 4800×1800 pixels; dois SVGs válidos. |
| Inspeção visual dos PNGs em largura de publicação | Caixas, ramos sim/não, nomes em português, níveis categóricos, eventos/n e aviso de grupos pequenos legíveis; sem sobreposição. |
| Leitura dos SVGs e hashes SHA-256 | As exportações vetoriais foram geradas e estão rastreáveis; os SVGs são o formato vetorial para uso editorial, e os PNGs são adequados ao HTML. |

## Arquivos produzidos ou alterados

- `scripts/render_cart_revision.R`;
- `results/prognostico/revisao/aggregated/cart_leaves.csv`;
- `results/prognostico/revisao/figures/cart_illustrative_tree.png` e `.svg`;
- `results/prognostico/revisao/figures/cart_stability.png` e `.svg`;
- `.plan/tasks-revisao/entregas/07_cart_visualizacao.md`;
- `.plan/tasks-revisao/entregas/07_execucao.md`;
- `results/prognostico/revisao/logs/manifesto_inicial.csv`.

## Decisões e limitações

Não houve decisão estatística nova, portanto não houve alteração do BibTeX. O arredondamento dos limiares limita-se ao desenho; os CSVs estruturais mantêm a precisão computacional. A marcação de grupo pequeno (`n<30`) é apenas um auxílio de leitura, não um teste, critério de poda ou decisão clínica. Proporções das folhas são aparentes; desempenho e generalização devem permanecer vinculados à CV aninhada e a futura validação externa.

A definição clínica preservada é que `correcao_colete` é uma avaliação transversal basal da anamnese, possível marcador de maleabilidade/corrigibilidade imediata. Esta task não a trata como vazamento temporal, efeito causal ou garantia de manutenção longitudinal.
