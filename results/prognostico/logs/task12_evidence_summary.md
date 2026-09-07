# Resumo final de evidências, falhas descartadas e limitações

## Resultado

A verificação final foi concluída. A suíte passou nas tarefas 05, 07, 08, 09 e 10. A renderização limpa do relatório prognóstico completou 49/49 etapas, sem erros ou warnings críticos, e produziu HTML autocontido.

## Falhas descartadas

- A falha inicial do wrapper ocorreu antes do Quarto executar, porque a sandbox bloqueou a consulta de arquitetura via `sysctl`; a renderização final autorizada concluiu normalmente.
- Os avisos `glm.fit` observados na suíte são registrados pelos diagnósticos de separação/convergência e não causaram falha: o ajuste final convergiu, os coeficientes são finitos e as asserções passaram.
- Diferenças entre repetições ficaram restritas a timestamps e duração; os 40 campos analíticos comparados foram idênticos.

## Limitações conhecidas

Fonte única, caso completo, erro potencial de mensuração radiográfica, regressão à média, possível mudança da região anatômica da maior curva, horizonte fixo e ausência de validação externa. Os modelos são prognósticos, não causais, e não fornecem indicação terapêutica ou limiar clínico.

## Segurança para compartilhamento

O HTML e as tabelas públicas são agregados; não incluem IDs, dados individuais, `model.frame` ou objetos de workspace. Arquivos reduzidos internos permanecem separados das tabelas públicas. A planilha bruta e o relatório histórico permaneceram inalterados.

## Revisão visual

O HTML foi renderizado integralmente e revisado estruturalmente (hierarquia, 19 tabelas, 8 figuras e texto visível). A inspeção pixel a pixel em navegador local não foi executada: a política bloqueou `file://` e rejeitou a exposição HTTP local do relatório clínico, mesmo em diretório temporário. Não foram observados cortes ou referências externas no artefato renderizado; uma revisão visual humana continua recomendada antes da circulação.
