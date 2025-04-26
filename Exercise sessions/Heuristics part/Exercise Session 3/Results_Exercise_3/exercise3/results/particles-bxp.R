# Replace here the name of your file
file.name <- "eval1/data.txt"

# Read file
all.data <- read.table(file=file.name, header=TRUE, sep=":") #Replace the separator for any of your preference
trials <- all.data[,1]  # Remove this line of there are no trial/instances
data      <- all.data[,-1, drop=FALSE] # Get the data

#Plot details in the file boxplot.R
source("../../scripts/R-scripts/boxplot.R")
do.boxplot(data.matrix=data, plot.title=expression(paste("PSO solution quality rastrigin p=5,10,20,50,100,200",psi,"1 ", psi, "1,inertia=1",sep="")), output="particles-rastrigin-eval.png")


