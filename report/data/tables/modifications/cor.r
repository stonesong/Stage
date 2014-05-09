files <- list.files(pattern=".csv")
results <- c()
for (file in files ) {
	d <- read.csv(file)
	c_act <- cor.test(d$X.commits[d$active==1],d$X.commitsWithRename[d$active==1],method="spearman")
	c_all <- cor.test(d$X.commits,d$X.commitsWithRename,method="spearman")
	results <- rbind(results,cbind(c_act$estimate,c_all$estimate))
}
