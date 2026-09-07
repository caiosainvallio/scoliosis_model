# Resultados do relatório prognóstico

Esta árvore é separada dos resultados históricos em `diagnostico_modelos/`.

- `aggregated/`: tabelas e resultados agregados da análise nova;
- `figures/`: figuras geradas pela análise nova;
- `logs/`: dependências, versões, sementes e execução;
- `reduced_objects/`: objetos reduzidos, sem cópia da base bruta.

Nenhum arquivo desta árvore deve ser interpretado como resultado definitivo
antes da conclusão das tarefas do plano.

Para a Tarefa 08, somente resumos agregados da CART são publicados. As
definições detalhadas dos folds e as previsões individuais ficam no objeto
interno `reduced_objects/cart_nested_internal.rds`; não há IDs de participantes
nas tabelas públicas da CART.
