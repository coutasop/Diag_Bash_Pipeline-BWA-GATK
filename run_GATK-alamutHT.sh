#!/bin/bash
#
# Sophie COUTANT
# 20/03/2014

#Faire le sed /",\*"/""/ avant alamut
cp $vcfdir/$project.raw.vcf $vcfdir/$project.original.raw.vcf
mv $vcfdir/$project.raw.vcf $vcfdir/$project.asterisk.raw.vcf
sed s/",\*"/",-"/g $vcfdir/$project.asterisk.raw.vcf > $vcfdir/$project.raw.vcf


#Avant AlamutHT il faut séparer chaque patient du vcf multiple.
echo -e "\tCOMMAND: vcf-subset -c $sample $vcfdir/$project.raw.vcf > "$vcfdir"/"$sample"_"$project".vcf"
$vcftoolsdir/vcf-subset -c $sample $vcfdir/$project.raw.vcf > $vcfdir"/"$sample"_"$project".vcf"

#Run AlamutHT
echo -e "\tCOMMAND: $alamutHTdir/alamut-ht --in "$vcfdir"/"$sample"_"$project".vcf --ann "$anndir"/"$sample"_"$project".ann --unann "$anndir"/"$sample"_"$project".unann --alltrans --glist $refdir/$gList --nonnsplice --nogenesplicer --ssIntronicRange 2 --outputVCFQuality --outputVCFInfo AC AF AN DP --outputVCFGenotypeData GT AD DP GQ PL --outputEmptyValuesAs ."
$alamutHTdir/alamut-ht --in $vcfdir"/"$sample"_"$project".vcf" --ann $anndir"/"$sample"_"$project".ann" --unann $anndir"/"$sample"_"$project".unann" --alltrans --glist $refdir/$gList --nonnsplice --nogenesplicer --ssIntronicRange 2 --outputVCFQuality --outputVCFInfo AC AF AN DP --outputVCFGenotypeData GT AD DP GQ PL --outputEmptyValuesAs .
