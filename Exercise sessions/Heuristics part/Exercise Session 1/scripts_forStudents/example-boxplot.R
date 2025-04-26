# Boxplot from file

# Replace here the name of your file
file.name <- "mydata/data-ants-best.txt"

# Read file
all.data <- read.table(file=file.name, header=TRUE, sep=":") #Replace the separator for any of your preference
trials <- all.data[,1]  # Remove this line of there are no trial/instances
data <- all.data[,-1, drop=FALSE] # Get the data

#Plot details in the file boxplot.R
source("R-scripts/boxplot.R")
do.boxplot(data.matrix=data)


