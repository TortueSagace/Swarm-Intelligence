#!/bin/bash

instance=$1
folder=$2

mkdir -p $folder
rm -rf ${folder}/data-ab.txt

echo "trial:a0b1:a1b0" >> ${folder}/data-ab.txt

seed=1234
for i in {1..20}; do
  AUX="${i}"
  for m in "--alpha 0 --beta 1" "--alpha 1 --beta 0" ; do
    echo "seed ${seed} executing ${m}"
    FNAME=${m//' '/'_'}
    ./aco --instance ${instance} --tours 500 --ants 10 ${m} --rho 0.001 --seed ${seed}  >  ${folder}/data-convergence-${FNAME}-${seed}.txt
    SOL=$(cat ${folder}/data-convergence-${FNAME}-${seed}.txt | grep -o -E 'Best [-+0-9.e]+' | cut -d ' ' -f2)
    AUX="${AUX}:${SOL}"
 
   #Clean files to use other R scripts (check structure in the examples)
    more +18 ${folder}/data-convergence-${FNAME}-${seed}.txt | sed 's/* //g' | sed 's/ : /:/g' | sed '/^[A-Z]/d' | sed '/^$/d' | awk -F: '{print NR,$2}' > ${folder}/data-convergence-${FNAME}-${seed}.tmp
    cat ${folder}/data-convergence-${FNAME}-${seed}.tmp > ${folder}/data-convergence-${FNAME}-${seed}.txt
    rm -f ${folder}/data-convergence-${FNAME}-${seed}.tmp

  done
  echo "$AUX" >>  ${folder}/data-ab.txt
  seed=$(( seed + 1 ))
done

rm -rf stat* cmp* best*
