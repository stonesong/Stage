cor_text <- function(cor) {
	if (cor$p.value < 0.05) {
		return(paste(round(cor$estimate, digits = 2)))
	} else {
		return(paste(round(cor$estimate, digits = 2), "*", sep = ""))
	}
}

projects <- c("jenkins 1.420 > 1.430","jquery 1.1 > 1.2","phpunit 3.7.0 > 4.7.0","pyramid 1.0 > 1.1","rails 2.3.0 > 3.0.0")

results_churn <- c()
files_churn <- list.files(path="churn", pattern=".csv")
for (file in files_churn) {
	d <- read.csv(paste("churn/", file, sep = ""))
	c_act <- cor.test(d$churn[d$active == 1], d$churnWithRename[d$active == 1], method="spearman")
	c_all <- cor.test(d$churn, d$churnWithRename, method="spearman")
	results_churn <- rbind(results_churn, cbind(cor_text(c_act), cor_text(c_all)))
}

results_devs <- c()
files_devs <- list.files(path="devs", pattern=".csv")
for (file in files_devs) {
	d <- read.csv(paste("devs/", file, sep = ""))
	c_act <- cor.test(d$X.devs[d$active == 1], d$X.devsWithRename[d$active == 1], method="spearman")
	c_all <- cor.test(d$X.devs, d$X.devsWithRename, method="spearman")
	results_devs <- rbind(results_devs, cbind(cor_text(c_act), cor_text(c_all)))
}

results_modifications <- c()
files_modifications <- list.files(path="modifications", pattern=".csv")
for (file in files_modifications) {
	d <- read.csv(paste("modifications/", file, sep = ""))
	c_act <- cor.test(d$X.commits[d$active == 1], d$X.commitsWithRename[d$active == 1], method="spearman")
	c_all <- cor.test(d$X.commits, d$X.commitsWithRename, method="spearman")
	results_modifications <- rbind(results_modifications, cbind(cor_text(c_act), cor_text(c_all)))
}

results <- rbind(c("churn_active", "churn_all", "devs_active", "devs_all", "modification_active", "modifications_all"), cbind(results_churn, results_devs, results_modifications))

write.csv(results, "correlations.csv")
