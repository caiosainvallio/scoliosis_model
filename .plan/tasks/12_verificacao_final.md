# Tarefa 12 — Executar verificação final e empacotar evidências

## Dependências

- Tarefa 11 concluída.

## Objetivo

Demonstrar que a análise é reproduzível, estatisticamente coerente, segura para compartilhamento e completa segundo os critérios do plano mestre.

## Atividades

1. Iniciar ambiente sem restaurar `.RData` e renderizar o relatório do zero.
2. Executar toda a suíte de testes antes da renderização final.
3. Repetir a análise com a mesma semente e comparar resultados dentro de tolerância numérica.
4. Validar contagens, eventos, parâmetros, matrizes, convergência e réplicas válidas.
5. Procurar referências residuais a progressão em QMD, HTML, nomes de objetos, tabelas e figuras.
6. Conferir manualmente uma amostra de previsões a partir das equações publicadas.
7. Verificar consistência entre texto, tabelas, gráficos e arquivos agregados.
8. Revisar legibilidade visual do HTML:
   - títulos e hierarquia;
   - tabelas sem cortes;
   - eixos, unidades e legendas;
   - notas e sugestões para o manuscrito.
9. Inspecionar artefatos para impedir exposição de IDs, dados individuais ou `model.frame`.
10. Registrar hashes dos dados de entrada e principais entregáveis.
11. Produzir um manifesto final de evidências e limitações conhecidas.
12. Comparar o Git antes e depois para confirmar que mudanças não relacionadas foram preservadas.

## Entregáveis

- Relatório QMD e HTML finais verificados.
- Resultado completo da suíte de testes.
- Log da renderização limpa.
- Manifesto de versões, sementes, hashes e artefatos.
- Checklist TRIPOD+AI preenchido.
- Autoavaliação PROBAST.
- Resumo final de evidências, falhas descartadas e limitações.

## Evidências obrigatórias

- Coorte final: 615 participantes.
- Desfecho logístico: 317 eventos e 298 não eventos.
- Modelos congelados: 19 parâmetros preditores e mesmas observações.
- Bootstrap: 2.000 tentativas e pelo menos 1.980 válidas por modelo.
- Validação aninhada sem vazamento entre folds.
- Mesma semente reproduz resultados dentro da tolerância definida.
- Predições manuais coincidem com as funções de predição.
- Nenhuma ocorrência analítica de progressão permanece.
- Nenhuma dependência de `.RData` ou instalação durante a renderização.
- Nenhum dado individual identificável está nos artefatos públicos.
- `analisys.qmd`, `analisys.html` e a planilha bruta permanecem inalterados.

## Critérios de conclusão

- Todos os critérios de aceitação do plano mestre foram satisfeitos.
- O relatório renderiza integralmente sem erros ou warnings críticos.
- Evidências permitem auditar cada exclusão, transformação, ajuste e reamostragem.
- Qualquer limitação remanescente está declarada no relatório.
- Os artefatos finais estão prontos para revisão da equipe, sem publicação automática, commit ou push.

