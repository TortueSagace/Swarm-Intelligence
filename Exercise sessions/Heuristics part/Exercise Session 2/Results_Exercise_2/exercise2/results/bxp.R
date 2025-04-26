options(width=200)

#Get arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
    stop("Usage: Rscript bxp.R [file]")
}

file.name <- args[1]

# Read file
all.data <- read.table(file=file.name, header=TRUE, sep=":") #Replace the separator for any of your preference
trials <- all.data[,1]  # Remove this line of there are no trial/instances
data <- all.data[,-1, drop=FALSE] # Get the data

cat("Mean result:\n")
print(colMeans(data))
#Plot details in the file boxplot.R
source("./R-scripts/boxplot.R")
do.boxplot(data.matrix=data, plot.title=expression(paste("AS solution quality #ants 10 ", alpha, "=1,", beta,"=1 ", rho, "=0.5  eval 1000",sep="")), output=paste(print(as.character(dirname(file.name))),"-bxp.png"))


