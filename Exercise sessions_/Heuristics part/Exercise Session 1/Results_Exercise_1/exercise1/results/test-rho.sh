#!/bin/bash

instance=$1
folder=$2

mkdir -p $folder
rm -rf ${folder}/data-rho.txt

echo "trial:r0.01:r0.2:r0.5:r1" >> ${folder}/data-rho.txt

seed=1234
for i in {1..50}; do
  AUX="${i}"
  for m in {0.01,0.2,0.5,1}; do
    echo "seed ${seed} executing ${m}"
    ./aco --instance ${instance} --tours 500 --alpha 1 --beta 1 --ants 10 --rho ${m} --seed ${seed} > ${folder}/data-convergence-r${m}-${seed}.txt
    SOL=$(cat ${folder}/data-convergence-r${m}-${seed}.txt | grep -o -E 'Best [-+0-9.e]+' | cut -d ' ' -f2)
    AUX="${AUX}:${SOL}"

    more +18 ${folder}/data-convergence-r${m}-${seed}.txt | sed 's/* //g' | sed 's/ : /:/g' | sed '/^[A-Z]/d' | sed '/^$/d' | awk -F: '{print NR,$2}' > ${folder}/data-convergence-r${m}-${seed}.tmp
    cat ${folder}/data-convergence-r${m}-${seed}.tmp > ${folder}/data-convergence-r${m}-${seed}.txt
    rm -f ${folder}/data-convergence-r${m}-${seed}.tmp

  done
  echo "$AUX" >>  ${folder}/data-rho.txt
  seed=$(( seed + 1 ))
done

rm -rf stat* cmp* best*
