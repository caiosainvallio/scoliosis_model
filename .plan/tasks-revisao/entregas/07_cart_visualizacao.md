# Entrega da Task 07 — árvore CART, folhas e estabilidade

Data: 2026-09-08

## Saídas para integração

- `results/prognostico/revisao/figures/cart_illustrative_tree.png` e `.svg`;
- `results/prognostico/revisao/figures/cart_stability.png` e `.svg`;
- `results/prognostico/revisao/aggregated/cart_leaves.csv`.

A árvore é um ajuste **ilustrativo** com a configuração global previamente selecionada, feito uma vez na coorte completa (615 participantes; 317 com melhora). Ela não é uma árvore avaliada externamente e as proporções nas folhas são aparentes. O desempenho do procedimento CART deve ser relatado exclusivamente a partir da validação interna por CV aninhada, nos folds externos, já preservada nas saídas CART correspondentes.

As caixas exibem o ramo que segue a condição (`sim`) ou sua negação (`não`), limiares arredondados apenas para apresentação, e, nas folhas, probabilidade de melhora radiográfica de pelo menos 5°, eventos/n e `n`. Os valores computacionais completos permanecem em `cart_illustrative_primary_splits.csv`; regras reprodutíveis e sem arredondamento permanecem em `cart_illustrative_leaf_rules.csv`. `cart_leaves.csv` traz o caminho completo em português, n, eventos e proporção aparente. `grupo_pequeno_n_menor_30` é um marcador descritivo de apresentação, não um limiar inferencial.

## Legendas propostas para Quarto

```{=markdown}
![Árvore CART ilustrativa para melhora radiográfica de pelo menos 5°. A árvore foi ajustada uma única vez na coorte completa (n=615) com a configuração global previamente selecionada; portanto, as probabilidades e contagens das folhas são aparentes. Rótulos de ramos indicam a condição (sim) e sua negação (não). O asterisco identifica folhas com n<30. Esta figura não representa desempenho externo nem valida uma regra de decisão clínica.](results/prognostico/revisao/figures/cart_illustrative_tree.png){fig-alt="Árvore CART com seis divisões, sete folhas, ramos sim e não, e proporções aparentes de melhora." width="100%"}
```

```{=markdown}
![Estabilidade estrutural da CART nas 50 árvores ajustadas nos treinamentos externos da validação cruzada aninhada. As barras mostram a frequência por árvore da variável na raiz e em todos os níveis, usando somente cortes primários; o painel final resume a amplitude, intervalo interquartil e mediana do corte primário da raiz. A estabilidade de escolha ou de limiar não demonstra efeito causal, e esta figura não é desempenho externo.](results/prognostico/revisao/figures/cart_stability.png){fig-alt="Barras de frequência de variáveis CART e resumo da distribuição do corte de correção pelo colete na raiz." width="100%"}
```

```{r}
#| label: tbl-cart-folhas
#| tbl-cap: "Folhas da árvore CART ilustrativa. As proporções são aparentes e os grupos com n<30 são sinalizados apenas para leitura cautelosa."
readr::read_csv("results/prognostico/revisao/aggregated/cart_leaves.csv", show_col_types = FALSE) |>
  dplyr::mutate(proporcao_aparente_melhora = scales::percent(proporcao_aparente_melhora, accuracy = 0.1)) |>
  knitr::kable()
```

## Resultado e interpretação limitada

`correcao_colete` aparece na raiz em 50/50 árvores externas. Na figura ilustrativa, a primeira divisão computacional é 49,4186046511628%; a exibição usa 49,42%. Essa correção é a medida transversal basal da anamnese, interpretada como possível marcador de maleabilidade/corrigibilidade imediata; a estabilidade da raiz não demonstra causalidade nem manutenção longitudinal da correção.

O resumo de estabilidade mostra frequência de variáveis em 50 árvores externas e, para o corte primário da raiz, mínimo 45,3463%, mediana 49,4186% e máximo 54,8589%. A variação do limiar reforça que a árvore ilustrativa não deve ser convertida em regra clínica fixa.

## Passagem

As Tasks 12 e 13 devem consumir somente estas figuras, `cart_leaves.csv` e os agregados corrigidos da Task 06. Nenhuma dependência anterior foi alterada. A ausência de validação externa e a instabilidade dos limiares permanecem limitações a serem descritas; esta task não executou a próxima etapa.
