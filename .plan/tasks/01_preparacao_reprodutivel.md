# Tarefa 01 — Preparar a estrutura reprodutível

## Dependências

Nenhuma. Esta é a primeira tarefa.

## Objetivo

Criar a estrutura técnica do novo relatório prognóstico sem alterar a base bruta nem o relatório exploratório histórico.

## Atividades

1. Registrar o estado inicial do Git e preservar mudanças preexistentes não relacionadas.
2. Preservar sem alterações `analisys.qmd`, `analisys.html` e `data/dataset_escoliose_01.xlsx`.
3. Criar o esqueleto de `relatorio_prognostico.qmd`, inicialmente sem resultados definitivos.
4. Separar funções em arquivos R com responsabilidades claras:
   - importação e preparação dos dados;
   - métricas e calibração;
   - bootstrap e estabilidade;
   - reamostragem aninhada;
   - apresentação de tabelas, equações e textos dinâmicos.
5. Definir uma pasta própria para resultados agregados, figuras, logs e objetos reduzidos da nova análise.
6. Criar verificação inicial de pacotes com falha explícita e informativa; o relatório não poderá executar `install.packages()`.
7. Fixar e documentar a semente global e as sementes específicas das rotinas paralelas.
8. Configurar a execução para não restaurar ou salvar `.RData`.
9. Registrar versões de R, Quarto, sistema operacional e pacotes relevantes.

## Entregáveis

- Esqueleto do novo relatório `relatorio_prognostico.qmd`.
- Estrutura de arquivos R auxiliares.
- Diretório separado para resultados prognósticos agregados.
- Verificador de dependências.
- Registro inicial de versões e sementes.

## Evidências obrigatórias

- Saída de `git status` antes e depois da tarefa mostrando que arquivos históricos e dados brutos não foram alterados.
- Execução do setup em uma sessão R limpa.
- Lista explícita de pacotes presentes e ausentes.
- Demonstração de que nenhum objeto da análise é lido de `.RData`.
- Renderização inicial do esqueleto ou execução isolada do setup sem erro.

## Critérios de conclusão

- A estrutura existe e pode ser carregada em sessão limpa.
- O novo relatório encontra a base pelo caminho documentado.
- Dependências ausentes interrompem a execução com mensagem clara.
- Nenhum resultado antigo é tratado como resultado final.
- Nenhum arquivo fora do escopo foi alterado.

## Fora do escopo

- Limpeza definitiva da coorte.
- Ajuste de modelos.
- Publicação no RPubs.
- Commit, push ou alteração do índice Git.

## Status de execução

- **Concluída em 2026-09-06.** Estrutura reprodutível criada e validada em
  sessão limpa; renderização inicial do Quarto concluída. Os arquivos
  históricos e a base bruta permaneceram inalterados.
