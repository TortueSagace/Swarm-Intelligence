#!/bin/bash

#USAGE: ./test-ants.sh instance folder

#inputs
instance=$1  # eil51.tsp
folder=$2    # ACO_tests

#remove previous files
mkdir -p ${folder}
rm -rf ${folder}/data-ants-best.txt


#####################################################
### Run 20 trials for each value of the parameter ###
#####################################################

#create new files (this line changes according to what your testing)
echo "trial:m5:m10:m20:m50:m100" >> ${folder}/data-ants-best.txt

#Set initial seed for different trials
seed=1234
#number of trial (in the first trial we test the different parameters with the same seed)
for i in {1..50}; do
  AUX="${i}"
  #number of ants
  for m in {5,10,20,50,100}; do
    #Execute the algorithm using the seed and the parameters and save the output file in a folder.
    ./aco --instance ${instance} --tours 500 --ants ${m} --seed ${seed} > ${folder}/output-m${m}-${seed}.txt

    #Read the output file and extract the best tour found
    SOL=$(cat ${folder}/output-m${m}-${seed}.txt | grep -o -E 'Best [-+0-9.e]+' | cut -d ' ' -f2)
    
    #Clean files to use other R scripts (check structure in the examples)
    more +18 ${folder}/output-m${m}-${seed}.txt | sed -e '0,/^$/{' -e 's/^$/tours:quality/' -e '}' | sed 's/* //g' | sed 's/ : /:/g' | sed '/^[A-Z]/d' | sed '/^$/d' > ${folder}/output-m${m}-${seed}.tmp
    cat ${folder}/output-m${m}-${seed}.tmp > ${folder}/output-m${m}-${seed}.txt
    rm -f ${folder}/output-m${m}-${seed}.tmp

    #Save for printing (trial:bestSolutions)
    AUX="${AUX}:${SOL}"
  done
  #Print matrix of best tour found
  echo "$AUX" >>  ${folder}/data-ants-best.txt
  #Next seed
  ((seed++))
done

##################################################################
### Compute the average of the results obtianed in the trials ####
##################################################################

### To be implemented

#Remove any unuseful file.....
rm -rf stat* cmp* best*
