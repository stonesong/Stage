pdf(file="../figures/renaming.pdf")

files <- c("jenkins.csv", "jquery.csv", "phpunit.csv", "pyramid.csv", "rails.csv")
projects <- c("Jenkins", "JQuery", "PHPUnit", "Pyramid", "Rails")
colors <- heat.colors(3)

colorize <- function(kind) {
	if (kind == "init") {
		return(colors[1])
	} else if (kind == "major") {
		return(colors[2]) 
	} else {
		return(colors[3])
	}
}

par(mar=c(7,1,1,1), mfrow=c(3,2))
numProj <- 1
for (file in files) {
	#v0,v1,kind,nf,naf,paf,pfr,pafr
	data <- read.csv(file, colClasses=c("character","character","character","integer","integer","double","double","double"))
	names <- paste(data$v0, " - ", data$v1)
	barColors <- sapply(data$kind, colorize)
	barplot(data$pfr, names=names, ylim=c(0,100),las=2, main=projects[numProj], width=1, ylab="% of files renamed", col=barColors)
	numProj <- numProj + 1
}
