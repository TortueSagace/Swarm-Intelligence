## Instance ulysses22
# Replace here the name of your file
file.name <- ("alpha-beta_ulysses22/data-ab.txt")

# Read file
all.data <- read.table(file=file.name, header=TRUE, sep=":") #Replace the separator for any of your preference
trials <- all.data[,1]  # Remove this line of there are no trial/instances
data <- all.data[,-1, drop=FALSE] # Get the data

#Plot details in the file boxplot.R
source("./R-scripts/boxplot.R")
do.boxplot(data.matrix=data, plot.title=expression(paste("AS solution quality {", alpha, "=0,", beta," =1} {", alpha,"=1,", beta, "=0},", " #ants 10 ", rho, "=0.5",sep="")), output="alpha-beta-bxp-ulysses22.png")


## Instance att532
# Replace here the name of your file
file.name <- ("alpha-beta_att532/data-ab.txt")

# Read file
all.data <- read.table(file=file.name, header=TRUE, sep=":") #Replace the separator for any of your preference
trials <- all.data[,1]  # Remove this line of there are no trial/instances
data <- all.data[,-1, drop=FALSE] # Get the data

#Plot details in the file boxplot.R
source("./R-scripts/boxplot.R")
do.boxplot(data.matrix=data, plot.title=expression(paste("AS solution quality {", alpha, "=0,", beta," =1} {", alpha,"=1,", beta, "=0},", " #ants 10 ", rho, "=0.5",sep="")), output="alpha-beta-bxp-att532.png")
