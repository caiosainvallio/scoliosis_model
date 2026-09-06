# Tarefa 05 — Implementar e testar métricas e bootstrap

## Dependências

- Tarefa 02 concluída.
- Especificações e objetos da Tarefa 03 disponíveis para testes de integração.

## Objetivo

Construir funções estatísticas independentes e testadas para métricas, calibração, correção de otimismo, estabilidade e tratamento de falhas de reamostragem.

## Atividades

1. Implementar funções puras para:
   - R², RMSE, MAE e erro médio;
   - AUC, Brier score e log loss;
   - intercepto e inclinação de calibração linear;
   - calibration-in-the-large e inclinação logística;
   - limitação numérica segura de probabilidades no log loss.
2. Implementar uma função de uma réplica bootstrap que:
   - amostre 615 participantes com reposição;
   - ajuste novamente o modelo completo;
   - produza desempenho na amostra bootstrap e na base original;
   - devolva otimismo, previsões, avisos e estado da réplica.
3. Definir a correção conforme a direção da métrica:
   - métricas maiores são melhores: aparente menos otimismo médio;
   - erros menores são melhores: aparente mais diferença média teste–treino.
4. Implementar captura estruturada de:
   - não convergência;
   - separação ou coeficientes não finitos;
   - predições inválidas;
   - nível categórico ausente;
   - falha na calibração;
   - amostra com desfecho sem variação.
5. Garantir geração reprodutível de números aleatórios, inclusive em processamento paralelo.
6. Separar resultados completos internos de tabelas agregadas publicáveis.
7. Criar testes unitários e de integração com amostras pequenas e resultados conhecidos.

## Entregáveis

- Arquivo R de métricas e calibração.
- Arquivo R do mecanismo de bootstrap.
- Suíte automatizada de testes.
- Esquema padronizado da saída de cada réplica.
- Função de consolidação de otimismo e falhas.

## Evidências obrigatórias

- R², RMSE, MAE, AUC, Brier e log loss conferidos contra cálculo independente ou pacote de referência.
- Testes com previsão perfeita, constante, invertida e contendo probabilidades extremas.
- Testes de sinais da correção de otimismo para métricas de benefício e de erro.
- Testes de falha simulada retornando motivo estruturado sem interromper toda a execução.
- Duas execuções com a mesma semente produzem a mesma sequência de índices e os mesmos resultados.
- Nenhuma função depende de objetos globais ou `.RData`.

## Critérios de conclusão

- Todos os testes passam em sessão limpa.
- Uma réplica válida e cada classe de falha possuem comportamento documentado.
- A saída contém informação suficiente para auditoria e estabilidade individual sem expor IDs no relatório público.
- As funções aceitam explicitamente dados, fórmula, família e semente.

## Status de execução

- **Concluída em 2026-09-06.** Métricas, calibração, bootstrap reprodutível,
  falhas estruturadas e consolidação foram implementados com testes unitários e
  de integração aprovados em sessão limpa, incluindo uma réplica da coorte de
  615 participantes.
