#!/usr/bin/env Rscript
# Auditoria determinística da Task 15. Não reexecuta bootstrap ou tuning.
source("R/00_config.R")
source("R/01_dependencies.R")
source("R/02_import_prepare.R")
source("R/09_shrinkage_equations.R")
agg <- "results/prognostico/revisao/aggregated"
logs <- "results/prognostico/revisao/logs"
read <- function(name) read.csv(file.path(agg, name), check.names = FALSE)
checks <- list()
check <- function(name, ok, evidence) {
  checks[[length(checks) + 1L]] <<- data.frame(check = name, passed = isTRUE(ok), evidence = evidence)
  if (!isTRUE(ok)) warning("Falha: ", name, call. = FALSE)
}
near <- function(a, b, tol = 1e-9) length(a) == length(b) && all(is.finite(a)) && all(is.finite(b)) && max(abs(a-b)) < tol
initial <- read.csv(file.path(logs, "manifesto_inicial.csv"))
for (path in c("data/dataset_escoliose_01.xlsx", "analisys.qmd", "analisys.html")) {
  expected <- initial$sha256[initial$artefato == path]
  actual <- digest::digest(file = path, algo = "sha256")
  check(paste("hash", path), length(expected) == 1L && identical(expected, actual), actual)
}
d <- prepare_prognostic_data(import_prognostic_data())
check("coorte e eventos", nrow(d) == 615L && sum(d$delta_cat) == 317L && sum(d$correcao_colete > 100) == 3L,
      "615 participantes; 317 eventos; 298 não eventos; 3 hipercorreções preservadas")
check("definição dos desfechos", near(d$delta, d$maior_curva_6_meses - d$cobb_inicial_maior) && all(d$delta_cat == as.integer(d$delta <= -5)),
      "Delta entre máximos e limiar -5 reproduzidos")
f <- reformulate(MODEL_PREDICTORS, response = "delta")
m <- lm(f, data = d); X <- model.matrix(m)
check("especificação", length(MODEL_PREDICTORS) == 10L && ncol(X) == 20L && qr(X)$rank == 20L,
      "10 preditores, 19 parâmetros mais intercepto; posto 20")
# HC3 reconstruído diretamente por álgebra matricial, sem chamar o produtor.
bread <- solve(crossprod(X))
u <- residuals(m) / (1-hatvalues(m))
V <- bread %*% crossprod(X, X * as.numeric(u^2)) %*% bread
se <- sqrt(diag(V)); h <- read("coefficients_linear_hc3.csv")
check("HC3-t independente", near(se, h$std_error) && near(coef(m)-qt(.975,595)*se,h$conf_low) && near(2*pt(-abs(coef(m)/se),595), h$p_value),
      sprintf("20 termos; máximo desvio EP %.3g; t595 coerente", max(abs(se-h$std_error))))
b <- readRDS("results/prognostico/reduced_objects/frozen_bootstrap_internal.rds")
p <- read("validation_performance_ci.csv")
for (model in c("linear", "logistic")) {
  t <- b[[model]]$table
  check(paste("bootstrap",model), nrow(t)==2000 && all(t$status=="valid"), "2000 tentativas válidas; falha contada por réplica, não somada sobre métricas")
  for (i in which(p$model == model & p$primary_metric)) {
    metric <- p$metric[i]
    tr <- t[[paste0("train_",metric)]]; te <- t[[paste0("test_",metric)]]
    shift <- mean(te-tr)
    limits <- quantile(tr,c(.025,.975),type=6,names=FALSE)+shift
    check(paste("IC", model, metric), near(p$estimate[i], p$apparent[i]+shift) && near(limits,c(p$ci_lower[i],p$ci_upper[i])),
          sprintf("estimativa %.12g; IC [%.12g; %.12g]; recomposição das réplicas",p$estimate[i],limits[1],limits[2]))
  }
}
check("IC degenerados não publicados", all(is.na(p$ci_lower[!p$primary_metric])) && all(is.na(p$ci_upper[!p$primary_metric])), "5 métricas secundárias sem IC espúrio")
s <- readRDS("results/prognostico/revisao/reduced_objects/validation_review_reduced.rds")
cc <- read("validation_final_shrinkage_coefficients.csv")
# Caso inteiramente sintético, sem copiar uma linha de participante.
synthetic <- data.frame(idade=13, imc=19, cifose_toracica=25, lordose_lombar=50,
  correcao_colete=50, sexo=factor("feminino",levels=levels(d$sexo)),
  lenke=factor("1",levels=levels(d$lenke)), risser=factor("0",levels=levels(d$risser)),
  flexibilidade=factor("flexivel",levels=levels(d$flexibilidade)),
  escoliometro_maior_10_graus=factor("normal",levels=levels(d$escoliometro_maior_10_graus)))
for (model in c("linear","logistic")) {
  obj <- s$final_models[[model]]; z <- cc[cc$model==model,]
  check(paste("coeficientes finais",model), near(z$coefficient_shrunk, unname(obj$coefficients[z$term])), "CSV e objeto final correspondem")
  xx <- c(1,13,19,25,50,50,rep(0,14))
  manual <- sum(xx*z$coefficient_shrunk)
  if (model=="logistic") manual <- 1/(1+exp(-manual))
  prediction <- predict(obj,synthetic)
  check(paste("previsão sintética",model),near(manual,as.numeric(prediction)),sprintf("soma manual=%.12g; predict=%.12g",manual,prediction))
}
a <- read("validation_shrinkage_procedure_audit.csv")
check("shrinkage somente no treino", nrow(a)==50 && !any(a$test_used_for_factor | a$test_used_for_intercept) && sum(a$inner_valid_linear+a$inner_valid_logistic)==20000,
      "50 folds; 200 réplicas por modelo; 20000 válidos")
cf <- read("prediction_intervals_coverage_by_fold.csv")
check("conformal separado", nrow(cf)==50 && !any(cf$test_used_for_fit|cf$test_used_for_factor|cf$test_used_for_intercept|cf$calibration_used_for_fit|cf$calibration_used_for_factor),
      sprintf("cobertura empírica %.8f; largura %.8f; sem garantia estratificada",weighted.mean(cf$observed_coverage,cf$n_test),weighted.mean(cf$mean_width_degrees,cf$n_test)))
cart <- read("cart_primary_splits.csv"); trees <- read("cart_tree_summaries.csv")
check("CART primária", nrow(cart)==313 && sum(trees$n_splits)==313 && all(cart$split_role=="primary") && sum(cart$split_type=="continuous")==221 && sum(cart$split_type=="categorical")==92,
      "313 nós; 221 contínuos; 92 categóricos; concorrentes/substitutos separados")
roots <- cart[cart$depth==0,]
check("CART raiz", nrow(roots)==50 && all(roots$variable=="correcao_colete"),sprintf("mediana %.8f; amplitude %.8f–%.8f",median(roots$cutpoint),min(roots$cutpoint),max(roots$cutpoint)))
leaf <- read("cart_leaves.csv")
check("CART folhas aparentes", nrow(leaf)==7 && sum(leaf$n)==615 && sum(leaf$eventos_melhora)==317,"7 folhas; n/eventos reconciliados")
cm <- read.csv("results/prognostico/aggregated/cart_external_metric_distribution.csv")
check("CART denominador calibração", cm$n[cm$metric=="calibration_intercept"]==49 && all(cm$n[cm$metric!="calibration_intercept"]==50), "49 interceptos; 50 demais métricas")
sel <- read("flexible_selected_hyperparameters.csv"); hh <- read("flexible_active_hierarchy_audit.csv")
check("solver selecionado e hierarquia", nrow(sel)==100 && all(sel$alpha==0 & sel$converged & sel$kkt_max<=1e-6) && all(hh$strong_hierarchy_satisfied & !hh$formal_hierarchy_constraint),"100 ajustes ridge; KKT <= 1e-6; hierarquia observada, não imposta")
fail <- read("flexible_failure_audit.csv")
check("falhas flexíveis",sum(fail$n_failed)==160 && fail$n_evaluations[fail$family=="continuous" & fail$stage=="inner_tuning_configuration_folds"]==5000,"160/5000 internas contínuas; zero selecionadas")
paired <- read("flexible_paired_prediction_audit.csv")
cmp <- read("flexible_frozen_comparison.csv")
valid_cmp <- is.finite(cmp$flexible) & is.finite(cmp$frozen)
check("comparação pareada flexível",all(paired$approved) && all(is.na(cmp$difference_flexible_minus_frozen[!valid_cmp])) && near(cmp$difference_flexible_minus_frozen[valid_cmp], (cmp$flexible-cmp$frozen)[valid_cmp]),"chaves pareadas; diferenças finitas recomputadas; métricas de outra família indisponíveis; não são IC")
sr <- read("sensitivity_resampling_metrics_by_repeat.csv")
check("sensibilidade repetições",length(unique(sr$repeat_id))==5,"cinco repetições; exclusões apenas no treino confirmadas no R/14_review_sensitivity.R")
sa <- read("sensitivity_resampling_audit.csv")
check("sensibilidade testes completos",nrow(sa)==50 && all(!sa$test_used_for_fit & !sa$test_used_for_exclusion & sa$comparator_estimated_in_training) && all(aggregate(n_test~repeat_id,sa,sum)$n_test==615),"50 testes completos; 615 previsões/repetição; exclusões e referências somente no treino")
cb <- read("sensitivity_cobb_reparameterization.csv")
check("Cobb reparametrização",all(cb$equivalent_within_tolerance & cb$same_design_all_folds) && max(cb$maximum_prediction_absolute_difference)<1e-10 && max(cb$maximum_coefficient_absolute_difference_after_conversion)<1e-10,"identidade delta/Cobb final com mesmo desenho e conversão; tolerância 1e-10")
tripod <- read("tripod_ai_checklist.csv"); probast <- read("probast_ai_signaling_task15.csv")
check("checklists",nrow(tripod)==52 && !anyDuplicated(tripod$item) && nrow(probast)==34 && all(nzchar(tripod$evidence_or_pending)) && all(nzchar(probast$evidence)),"52 itens/subitens TRIPOD; 16+18 sinalizações PROBAST, evidências explícitas")
out <- do.call(rbind,checks)
write.csv(out,file.path(logs,"auditoria_numerica_task15.csv"),row.names=FALSE)
print(out,row.names=FALSE)
cat("\n",sum(out$passed),"/",nrow(out)," verificações aprovadas\n",sep="")
stopifnot(all(out$passed))
