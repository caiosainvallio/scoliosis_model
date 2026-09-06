# Tarefa 10 — Executar análises de sensibilidade

## Dependências

- Tarefa 03 concluída.
- Resultados das Tarefas 06 a 09 disponíveis.

## Objetivo

Verificar se decisões específicas, observações influentes ou características incomuns alteram materialmente coeficientes, previsões ou conclusões, sem modificar a análise principal.

## Atividades

1. Identificar observações influentes com critérios definidos antes da comparação:
   - distância de Cook;
   - leverage;
   - resíduos padronizados.
2. Reajustar os modelos após exclusão temporária dos casos mais influentes e comparar:
   - sinais e magnitudes dos coeficientes;
   - previsões individuais;
   - métricas aparentes e calibração.
3. Reajustar temporariamente sem os IDs 81, 174 e 401 para avaliar influência das hipercorreções, mantendo-os no modelo principal.
4. Avaliar descritivamente erro e calibração por:
   - faixas de previsão;
   - sexo;
   - categorias principais com tamanho suficiente.
5. Evitar inferência de subgrupos ou testes de interação não pré-especificados.
6. Ajustar o modelo alternativo de Cobb aos seis meses condicionado ao Cobb basal como sensibilidade do alvo.
7. Comparar esse alvo alternativo com `delta` usando métricas adequadas e sem escolher retrospectivamente pelo maior R².
8. Discutir regressão à média, erro de mensuração e mudança da região anatômica da maior curva.

## Entregáveis

- Tabela de critérios e observações influentes.
- Comparação principal versus exclusões temporárias.
- Comparação com e sem hipercorreções.
- Resumos descritivos por estratos, com contagens.
- Resultado do modelo alternativo de Cobb aos seis meses.
- Texto interpretativo para limitações e discussão.

## Evidências obrigatórias

- Casos retirados aparecem apenas nas análises de sensibilidade.
- Modelo principal continua contendo os 615 participantes.
- Hipercorreções continuam intactas na análise principal.
- Diferenças são quantificadas em coeficientes, métricas e previsões.
- Estratos pequenos são identificados e não recebem conclusões fortes.
- Comparação de alvos reconhece que R² não é diretamente suficiente para escolher o desfecho clínico.

## Critérios de conclusão

- Cada sensibilidade responde a uma pergunta previamente descrita.
- Nenhuma exclusão exploratória é incorporada silenciosamente ao modelo final.
- Mudanças materiais e ausência de mudanças materiais são relatadas objetivamente.
- Limitações relevantes estão prontas para o relatório e manuscrito.

