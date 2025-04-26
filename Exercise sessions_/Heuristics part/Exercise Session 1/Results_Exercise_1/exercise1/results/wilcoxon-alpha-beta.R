file.name <- "alpha-beta_att532/data-ab.txt"

# Read file
all.data <- read.table(file=file.name, header=TRUE, sep=":") #Replace the separator for any of your preference
trials <- all.data[,1]  # Remove this line if there are no trial/instances
data      <- all.data[,-1, drop=FALSE] # Get the data

#Plot details in the file boxplot.R
source("./R-scripts/wilcoxon.R")
do.wilcoxon(data.matrix=data, output="wilcoxon-alpha-beta_att532.txt")


file.name <- "alpha-beta_ulysses22/data-ab.txt"

# Read file
all.data <- read.table(file=file.name, header=TRUE, sep=":") #Replace the separator for any of your preference
trials <- all.data[,1]  # Remove this line if there are no trial/instances
data      <- all.data[,-1, drop=FALSE] # Get the data

#Plot details in the file boxplot.R
source("./R-scripts/wilcoxon.R")
do.wilcoxon(data.matrix=data, output="wilcoxon-alpha-beta_ulysses22.txt")
