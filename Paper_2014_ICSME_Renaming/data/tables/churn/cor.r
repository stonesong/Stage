files <- list.files(pattern=".csv")
results <- c()
for (file in files ) {
	d <- read.csv(file)
	c_act <- cor.test(d$churn[d$active==1],d$churnWithRename[d$active==1],method="spearman")
	c_all <- cor.test(d$churn,d$churnWithRename,method="spearman")
	results <- rbind(results,cbind(c_act$estimate,c_all$estimate))
}
results
