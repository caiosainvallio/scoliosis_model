# Execução da Task 12 — figuras diagnósticas e resultados

Data: 2026-09-08.

## Comando reproduzível

```sh
rtk Rscript --vanilla R/15_review_figures.R
```

O script consome somente `diagnostics_plot_data.rds`, `validation_review_reduced.rds`, `flexible_nested_internal.rds` e agregados auditados das Tasks 07–11. Não reestima a coorte, não acessa IDs e não altera a árvore CART já entregue.

## Arquivos produzidos

- `R/15_review_figures.R`;
- 10 pares PNG/SVG novos sob `results/prognostico/revisao/figures/`: `linear_*`, `logistic_*`, `stability_*`, `flexible_*` e `sensitivity_*`;
- reuso verificado, sem alteração, de `cart_illustrative_tree.{png,svg}` e `cart_stability.{png,svg}`;
- `results/prognostico/revisao/aggregated/figures_task12_manifest.csv`, com hash por arquivo e modalidade de avaliação;
- `results/prognostico/revisao/logs/figures_task12_sessioninfo.txt`;
- `12_figuras_e_legendas.md`.

## Verificações e evidências

1. `Rscript --vanilla` concluiu sem erro.
2. O manifesto contém 24 arquivos (10 pares novos e 4 arquivos CART reusados); todos existem e têm tamanho maior que zero.
3. Os PNGs novos foram abertos e inspecionados visualmente: eixos, unidades, distinção aparente/interna, contraste de cores e ausência de bandas/IC indevidos foram confirmados. As figuras CART foram preservadas para reuso com as legendas auditadas da Task 07.
4. Os PNGs têm 1.800 × 1.200 px; SVGs são vetoriais. O manifesto registra hash e dimensões.
5. O gráfico de estabilidade usa 615 participantes e declara explicitamente cinco previsões repetidas por participante; os gráficos de sensibilidade identificam barras como amplitude entre cinco repetições, não IC.

## Limitações

ROC, calibração, observado-versus-previsto e diagnósticos são aparentes e estão rotulados como tal. A calibração suave deliberadamente não tem banda. As relações flexíveis são ilustrações do ajuste global pós-CV, limitadas ao suporte observado, e não suportam interpretação causal ou conclusão clínica isolada. Não houve validação externa.
