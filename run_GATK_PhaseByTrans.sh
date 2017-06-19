#!/bin/bash

#--5b--#
echo -e "\n#--5b--#";
echo -e "\t#-----# PHASE BY TRANSMISSION"
	if [ ${countsample} -ge 30 ]
	then
		echo -e "\tCOMMAND: java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T PhaseByTransmission -R $refdir/$myref -V $vcfdir/${project}_recalibrated_variants.vcf -ped $outdir/$project.ped -o $vcfdir/${project}_recalibrated_variants_phased.vcf"
		java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T PhaseByTransmission -R $refdir/$myref -V $vcfdir/${project}_recalibrated_variants.vcf -ped $outdir/$project.ped -o $vcfdir/${project}_recalibrated_variants_phased.vcf
	else
		echo -e "\tCOMMAND: java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T PhaseByTransmission -R $refdir/$myref -V $vcfdir/${project}.raw.vcf -ped $outdir/$project.ped -o $vcfdir/${project}.raw.phased.vcf"
		java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T PhaseByTransmission -R $refdir/$myref -V $vcfdir/${project}.raw.vcf -ped $outdir/$project.ped -o $vcfdir/${project}.raw.phased.vcf
	fi
