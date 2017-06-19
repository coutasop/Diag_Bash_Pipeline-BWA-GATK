#!/bin/bash

#--5--#
echo -e "\n#--5--#";
echo -e "\t#-----# JOIN GENOTYPING"
echo -e "\t#java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T GenotypeGVCFs -R $refdir/$myref $vcfarg -o $vcfdir/$project.raw.vcf"
	java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T GenotypeGVCFs -R $refdir/$myref $vcfarg -o $vcfdir/$project.raw.vcf

#--6--#
# Only if exome number of Sample > 30
#For anything smaller than exomes target VQSR is not indicated in the best practice

# copy of GATK Doc: 
##"For small-N sets and especially single sample experiments, we don't recommend VQSR, regardless of coverage, 
##because it is so unlikely that the modeling step will perform satisfactorily (if it even completes)."
##"This tool is expecting thousands of variant sites in order to achieve decent modeling with the Gaussian mixture model. 
##Whole exome call sets work well, but anything smaller than that scale might run into difficulties.
##One piece of advice is to turn down the number of Gaussians used during training. This can be accomplished by adding --maxGaussians 4 to your command line." 

echo -e "\n#--6--#";
echo -e "\t#-----# RECALIBRATION"
if [ $analysisType = "Diag" ]
then
	echo -e "\t#-----# Target size too small VQSR is not possible"
else
	if [ ${countsample} -ge 30 ]
	then
		
			echo -e "\t#-----# Sample count >= 30 : Begin DEFAULT VQSR "
			echo -e "\t#-----# Build SNP recalibration model"
			 java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T VariantRecalibrator -nt $maxthreads -R $refdir/$myref -input $vcfdir/$project.raw.vcf -resource:hapmap,known=false,training=true,truth=true,prior=15.0 $refdir/$hapmap -resource:omni,known=false,training=true,truth=false,prior=12.0 $refdir/$omni -resource:1000G,known=false,training=true,truth=false,prior=10.0 $refdir/$kG -resource:dbsnp,known=true,training=false,truth=false,prior=2.0 $refdir/$dbsnp -an QD -an FS -an MQRankSum -an ReadPosRankSum -mode SNP -tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 90.0 -recalFile $scriptdir/${project}.recalibrate_SNP.recal -tranchesFile $scriptdir/${project}.recalibrate_SNP.tranches -rscriptFile $scriptdir/${project}.recalibrate_SNP_plots.R 
				#arg: -numBad 3000 DEPRECATED GATK > v2.8
			
			echo -e "\t#-----# Apply Recalibration to SNPs"
			 java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T ApplyRecalibration -nt $maxthreads -R $refdir/$myref -input $vcfdir/${project}.raw.vcf -mode SNP --ts_filter_level 99.9 -recalFile $scriptdir/${project}.recalibrate_SNP.recal -tranchesFile $scriptdir/${project}.recalibrate_SNP.tranches -o $vcfdir/${project}.recalibrated_snps_raw_indels.vcf 

			echo -e "\t#-----# Build INDELs recalibration model"
			 java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T VariantRecalibrator -nt $maxthreads -R $refdir/$myref -input $vcfdir/${project}.recalibrated_snps_raw_indels.vcf -resource:mills,known=true,training=true,truth=true,prior=12.0 $refdir/$mills -resource:dbsnp,known=true,training=false,truth=false,prior=2.0 $refdir/$dbsnp -an FS -an MQRankSum -an ReadPosRankSum -mode INDEL -tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 90.0 --maxGaussians 4 -recalFile $scriptdir/${project}.recalibrate_INDEL.recal -tranchesFile $scriptdir/${project}.recalibrate_INDEL.tranches -rscriptFile $scriptdir/${project}.recalibrate_INDEL_plots.R 
				#arg: -numBad 3000 DEPRECATED GATK > v2.8

			echo -e "\t#-----# Apply Recalibration to INDELs"
			 java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T ApplyRecalibration -nt $maxthreads -R $refdir/$myref -input $vcfdir/${project}.recalibrated_snps_raw_indels.vcf -mode INDEL --ts_filter_level 99.9 -recalFile $scriptdir/${project}.recalibrate_INDEL.recal -tranchesFile $scriptdir/${project}.recalibrate_INDEL.tranches -o $vcfdir/${project}_recalibrated_variants.vcf 
	else
			echo -e "\t#-----# Sample size too small VQSR is not possible (<30 samples)"
	fi
fi


#~ #java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T CombineVariants -R $refdir/$myref -V $vcfdir/${project}_recalibrated_variants.vcf --sites_only -minimalVCF -o $vcfdir/${project}_Sites.vcf
#~ ### The file "$OUTPUT"_Sites.vcf is the file that needs to be shared at this point on the ftp site.

