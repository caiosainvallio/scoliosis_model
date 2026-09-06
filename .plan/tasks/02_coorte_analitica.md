# Tarefa 02 — Construir e auditar a coorte analítica

## Dependências

- Tarefa 01 concluída.

## Objetivo

Produzir, a partir da planilha bruta, uma única coorte analítica auditável para todos os modelos congelados, sem sobrescrever dados originais.

## Atividades

1. Ler `data/dataset_escoliose_01.xlsx`, aba `dados`, e limpar apenas os nomes das colunas em memória.
2. Confirmar que a base bruta contém 621 linhas e as colunas previstas no dicionário.
3. Confirmar que cada par abaixo é idêntico nas variáveis clínicas, radiográficas e no desfecho:
   - 17 / 46;
   - 21 / 162;
   - 16 / 248.
4. Manter os IDs 17, 21 e 16 e excluir explicitamente 46, 162 e 248.
5. Não usar deduplicação genérica por `distinct()`.
6. Recalcular em memória:
   - IMC;
   - Cobb máximo basal;
   - região da maior curva basal;
   - `delta`;
   - `delta_cat`;
   - classificação do escoliômetro acima de 10°.
7. Registrar empates na maior curva basal sem alterar o valor máximo.
8. Definir fatores e referências conforme o plano mestre.
9. Identificar os IDs 390, 535 e 628 com Lenke ausente e excluí-los por caso completo.
10. Confirmar que os mesmos casos completos alimentam os modelos linear e logístico.
11. Manter os IDs 81, 174 e 401 e seus valores de correção acima de 100%.
12. Gerar uma trilha de exclusões e um fluxograma de participantes.
13. Calcular hash e data de modificação da planilha usada.

## Entregáveis

- Função determinística de preparação da base.
- Coorte analítica em memória com 615 participantes.
- Tabela agregada do fluxo de participantes.
- Tabela de exclusões com ID e motivo para uso interno, não publicada no HTML.
- Relatório de dados ausentes e níveis categóricos.
- Figura ou fluxograma agregado da formação da coorte.

## Evidências obrigatórias

- 621 registros na leitura bruta.
- Exclusão exclusiva dos IDs 46, 162 e 248 como duplicatas.
- 618 IDs únicos após deduplicação.
- Exclusão exclusiva dos IDs 390, 535 e 628 por Lenke ausente.
- 615 casos completos finais.
- 317 eventos de melhora e 298 não eventos.
- IDs 81, 174 e 401 presentes com `correcao_colete > 100`.
- Comparação independente demonstrando que IMC, Cobb máximo, `delta` e `delta_cat` foram calculados corretamente.
- Lista dos níveis dos fatores e referências finais.

## Critérios de conclusão

- Todas as contagens esperadas são satisfeitas por asserções executáveis.
- Nenhum ID está duplicado na coorte final.
- Modelos linear e logístico recebem exatamente as mesmas 615 linhas.
- A planilha original permanece inalterada.
- O HTML público não contém IDs ou linhas individuais.

## Condição de bloqueio

Qualquer divergência em IDs, contagens, colunas ou identidade dos pares interrompe a execução. Não corrigir silenciosamente nem adaptar as expectativas ao dado encontrado.

