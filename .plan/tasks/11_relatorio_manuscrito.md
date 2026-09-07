# Tarefa 11 — Montar o relatório e os subsídios para o manuscrito

## Dependências

- Tarefas 02 a 10 concluídas e suas evidências aprovadas.

## Objetivo

Consolidar métodos, resultados, interpretação e limitações em um relatório estatístico autocontido, claro para clínicos e suficiente para a pesquisadora principal redigir o manuscrito.

## Atividades

1. Completar `relatorio_prognostico.qmd` e renderizar `relatorio_prognostico.html` autocontido.
2. Organizar o corpo principal na hierarquia:
   - modelo linear principal;
   - modelo logístico secundário;
   - CART exploratória;
   - modelagem flexível no apêndice.
3. Incluir população, momento zero, horizonte, uso pretendido e condição radiográfica.
4. Apresentar fluxo da coorte e exclusões sem divulgar IDs no HTML.
5. Inserir resultados exclusivamente a partir de objetos R; não digitar valores clínicos manualmente.
6. Criar tabela consolidada de desempenho aparente, otimismo e desempenho corrigido.
7. Apresentar calibração, estabilidade, shrinkage e equações completas.
8. Interpretar erros lineares em graus e em relação ao limiar de 5°.
9. Explicar que AUC não substitui calibração e que não existe limiar de decisão clínica nesta etapa.
10. Remover todo código, texto, tabela e figura relativo à progressão.
11. Produzir subseções “Sugestão para o manuscrito” com redações dinâmicas para:
    - objetivos;
    - métodos;
    - formação da coorte;
    - tamanho amostral;
    - resultados linear e logístico;
    - bootstrap e shrinkage;
    - CART e análise flexível;
    - limitações, discussão e conclusão.
12. Preencher uma conferência de relato baseada no TRIPOD+AI.
13. Incluir autoavaliação de risco de viés e aplicabilidade orientada pelo PROBAST, sem apresentá-la como revisão independente.

## Entregáveis

- `relatorio_prognostico.qmd`.
- `relatorio_prognostico.html` autocontido.
- Tabelas e figuras agregadas finais.
- Equações reproduzíveis dos modelos.
- Blocos de sugestão para todas as seções principais do manuscrito.
- Checklist de itens de relato e autoavaliação metodológica.
- Informações completas da sessão e referências.

## Evidências obrigatórias

- Todos os números narrativos são gerados dinamicamente.
- Coeficientes, referências e unidades permitem reproduzir previsões.
- O corpo principal não promove CART ou elastic net ao status de modelo principal.
- Resultados aparentes e corrigidos estão visualmente diferenciados.
- O texto usa “desenvolvimento e avaliação interna” e evita “modelo validado” sem qualificação.
- O relatório declara necessidade de validação externa e ausência de indicação terapêutica.
- Nenhum ID ou registro clínico individual aparece no HTML.
- O relatório histórico permanece inalterado.

## Critérios de conclusão

- O relatório responde integralmente aos objetivos aprovados pela equipe.
- A pesquisadora consegue extrair texto para introdução metodológica, métodos, resultados e discussão sem reinterpretar saídas brutas.
- Tabelas, figuras, narrativa e equações usam os mesmos objetos de origem.
- Apêndices mantêm as análises exploratórias separadas da conclusão principal.

## Status de execução

- **Concluída em 2026-09-07.** Relatório Quarto autocontido gerado com resultados dinâmicos, equações reproduzíveis, síntese para manuscrito, checklist TRIPOD+AI e autoavaliação PROBAST. A revisão de escopo não identificou conteúdo individual, código exposto ou artefatos excessivos.
