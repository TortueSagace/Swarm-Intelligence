#
# Example ants
#
# Change for the your filenames and the names of your tests
file.names <- c("mydata/output-m5-1234.txt", "mydata/output-m10-1234.txt", "mydata/output-m20-1234.txt", "mydata/output-m50-1234.txt", "mydata/output-m100-1234.txt")
test.names <- c("m5", "m10", "m20", "m50", "m100")

# Read data in a list with "names" as elements
data <- list() 
for(i in 1:length(file.names)){
  data[[test.names[i]]] <- read.table(file=file.names[i], header=TRUE, sep=":")
}


source("R-scripts/convergence.R")
do.lines.plot(data)
