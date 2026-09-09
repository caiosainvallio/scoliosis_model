#!/usr/bin/env Rscript
# Tabelas e insumos autônomos do relatório. Não executa bootstrap ou tuning.
source("R/00_config.R")
source("R/01_dependencies.R")
source("R/02_import_prepare.R")
out <- "results/prognostico/revisao/aggregated"
logs <- "results/prognostico/revisao/logs"
d <- prepare_prognostic_data(import_prognostic_data())
stopifnot(nrow(d)==615L, sum(d$delta_cat)==317L)
fit <- glm(reformulate(MODEL_PREDICTORS, response="delta_cat"), data=d, family=binomial())
z <- coef(summary(fit))
old <- read.csv("results/prognostico/aggregated/frozen_coefficients_logit.csv")
stopifnot(identical(rownames(z),old$term), max(abs(z[,1]-old$estimate))<1e-10,
          max(abs(z[,2]-old$std_error))<1e-10, fit$converged)
logi <- data.frame(term=rownames(z),estimate=z[,1],std_error=z[,2],
                   conf_low=z[,1]-qnorm(.975)*z[,2],conf_high=z[,1]+qnorm(.975)*z[,2])
stopifnot(max(abs(logi$conf_low-old$conf_low))<1e-10,
          max(abs(logi$conf_high-old$conf_high))<1e-10)
lin <- read.csv(file.path(out,"coefficients_linear_hc3.csv"))
shrunk <- read.csv(file.path(out,"validation_final_shrinkage_coefficients.csv"))
labels <- c("Intercepto","Idade","IMC","Cifose torácica","Lordose lombar","Correção pelo colete",
            "Sexo: masculino","Lenke 2","Lenke 3","Lenke 4","Lenke 5","Lenke 6",
            "Risser 1","Risser 2","Risser 3","Risser 4","Flexibilidade: rígido",
            "Escoliômetro: torácica","Escoliômetro: lombar","Escoliômetro: torácica e lombar")
contrasts <- c("Todos os numéricos = 0; categorias de referência", "+1 ano", "+1 kg/m²", "+10°", "+10°", "+10 pontos percentuais",
               "versus feminino",rep("versus Lenke 1",5),rep("versus Risser 0",4),
               "versus flexível",rep("versus normal",3))
mult <- c(1,1,1,10,10,10,rep(1,14))
stopifnot(length(labels)==20, identical(lin$term,logi$term))
for (model in c("linear","logistic")) {
  a <- if(model=="linear") lin else logi
  s <- shrunk[shrunk$model==model,]; stopifnot(identical(a$term,s$term))
  t <- data.frame(term=a$term,preditor=labels,contraste=contrasts,multiplicador=mult,
                  beta=a$estimate*mult,erro_padrao=a$std_error*mult,
                  ic95_inf=a$conf_low*mult,ic95_sup=a$conf_high*mult,
                  beta_pos_shrinkage=s$coefficient_shrunk*mult,
                  metodo_ic=if(model=="linear")"HC3; t595; ajuste sem shrinkage" else "Wald normal; máxima verossimilhança; ajuste sem shrinkage")
  t$or <- if(model=="logistic") exp(t$beta) else NA_real_
  t$or_ic95_inf <- if(model=="logistic") exp(t$ic95_inf) else NA_real_
  t$or_ic95_sup <- if(model=="logistic") exp(t$ic95_sup) else NA_real_
  t$or_pos_shrinkage <- if(model=="logistic") exp(t$beta_pos_shrinkage) else NA_real_
  t$interpretacao <- vapply(seq_len(nrow(t)),function(i) {
    if(i==1) return("Constante da equação; combinação numérica zero fora do domínio clínico. Não interpretar como paciente típico.")
    if(model=="linear") sprintf("%s: delta médio ajustado %.3f° %s; IC95%% [%.3f; %.3f]°. Demais preditores constantes; associação não causal.",
      contrasts[i],abs(t$beta[i]),if(t$beta[i]<0)"menor (maior redução)" else "maior (menor redução)",t$ic95_inf[i],t$ic95_sup[i])
    else sprintf("%s: chances de melhora multiplicadas por %.3f; IC95%% [%.3f; %.3f]. Demais preditores constantes; não é risco relativo ou efeito causal.",
      contrasts[i],t$or[i],t$or_ic95_inf[i],t$or_ic95_sup[i])
  },character(1))
  # IC não é transferido para beta pós-shrinkage. Intercepto não é contraste OR.
  if(model=="logistic") t[1,c("or","or_ic95_inf","or_ic95_sup","or_pos_shrinkage")] <- NA_real_
  write.csv(t,file.path(out,paste0("article_coefficients_",model,".csv")),row.names=FALSE,na="")
}
# Pacote agregado: cópias explícitas e verificadas, sem alterar os originais.
sources <- c("cart_external_metric_distribution.csv","frozen_prediction_stability_summary.csv")
provenance <- lapply(sources,function(n) {
  src <- file.path("results/prognostico/aggregated",n); dst <- file.path(out,n)
  stopifnot(file.copy(src,dst,overwrite=TRUE))
  a <- digest::digest(file=src,algo="sha256"); b <- digest::digest(file=dst,algo="sha256")
  stopifnot(identical(a,b))
  data.frame(origem=src,destino=dst,sha256=b,operacao="cópia fiel de agregado auditado; nenhuma reestimação")
})
write.csv(do.call(rbind,provenance),file.path(logs,"standalone_inputs_manifest.csv"),row.names=FALSE)
cat("615 participantes; 20 termos/modelo; coeficientes, EP e IC logísticos reproduzidos <1e-10; contrastes explicitados.\n")
cat("2 tabelas para artigo + 2 agregados empacotados com SHA-256; nenhuma nova reamostragem.\n")
