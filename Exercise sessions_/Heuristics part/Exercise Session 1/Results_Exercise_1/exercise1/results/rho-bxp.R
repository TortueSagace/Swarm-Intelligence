## Instance ulysses22
# Replace here the name of your file
file.name <- "rho_ulysses22/data-rho.txt"

# Read file
all.data <- read.table(file=file.name, header=TRUE, sep=":") #Replace the separator for any of your preference
trials <- all.data[,1]  # Remove this line of there are no trial/instances
data  <- all.data[,-1, drop=FALSE] # Get the data

#Plot details in the file boxplot.R
source("./R-scripts/boxplot.R")
do.boxplot(data.matrix=data, plot.title=expression(paste("AS solution quality ", rho,",", alpha, "=1,", beta,"=1 #ants=10",sep="")), output="rho-bxp-ulysses22.png")

## Instance att532
# Replace here the name of your file
file.name <- "rho_att532/data-rho.txt"

# Read file
all.data <- read.table(file=file.name, header=TRUE, sep=":") #Replace the separator for any of your preference
trials <- all.data[,1]  # Remove this line of there are no trial/instances
data  <- all.data[,-1, drop=FALSE] # Get the data

#Plot details in the file boxplot.R
source("./R-scripts/boxplot.R")
do.boxplot(data.matrix=data, plot.title=expression(paste("AS solution quality ", rho,",", alpha, "=1,", beta,"=1 #ants=10",sep="")), output="rho-bxp-att532.png")
