#!/bin/bash

instance=$1
folder=$2

mkdir -p $folder
rm -rf ${folder}/data-ants.txt

echo "trial:m2:m5:m10:m20:m50:m100" >> ${folder}/data-ants.txt

seed=1234
for i in {1..20}; do
  AUX="${i}"
  for m in {2,5,10,20,50,100}; do
    echo "seed ${seed} executing ${m}"
    ./aco --instance ${instance} --tours 500 --ants ${m} --seed ${seed} > ${folder}/data-convergence-m${m}-${seed}.txt
    SOL=$(cat ${folder}/data-convergence-m${m}-${seed}.txt | grep -o -E 'Best [-+0-9.e]+' | cut -d ' ' -f2)
    AUX="${AUX}:${SOL}"

   #Clean files to use other R scripts (check structure in the examples)
    more +18 ${folder}/data-convergence-m${m}-${seed}.txt | sed 's/* //g' | sed 's/ : /:/g' | sed '/^[A-Z]/d' | sed '/^$/d' | awk -F: '{print NR,$2}' > ${folder}/data-convergence-m${m}-${seed}.tmp
    cat ${folder}/data-convergence-m${m}-${seed}.tmp > ${folder}/data-convergence-m${m}-${seed}.txt
    rm -f ${folder}/data-convergence-m${m}-${seed}.tmp

  done
  echo "$AUX" >>  ${folder}/data-ants.txt
  seed=$(( seed + 1 ))
done

rm -rf stat* cmp* best*
