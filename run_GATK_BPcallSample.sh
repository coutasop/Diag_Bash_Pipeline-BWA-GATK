#!/bin/bash

#~ 1. Variant calling
#~ Run the HaplotypeCaller on each sample's BAM file(s) (if a sample's data is spread over more than one BAM, then pass them all in together) to create single-sample gVCFs, with the following options:
#~ --emitRefConfidence GVCF --variant_index_type LINEAR --variant_index_parameter 128000

# Variant calling	

if [ $analysisType = "Diag" ]; 
then 

	#HaplotypeCaller Per Sample
	echo -e "\t#-----# Variant calling"
	echo "Variant Calling (HaplotypeCaller) pour: "	$sample
    #~ time java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T HaplotypeCaller -R $refdir/$myref -D $refdir/$dbsnp -L $refdir/$targets -stand_call_conf 30.0 -stand_emit_conf 10.0 --emitRefConfidence GVCF --variant_index_type LINEAR --variant_index_parameter 128000 -pairHMM VECTOR_LOGLESS_CACHING -o $vcfdir/$sample.raw.snps.indels.vcf -I $bamdir/$sample".sorted.dedup.withRG.real.BQSR.bam"
    time java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T HaplotypeCaller -R $refdir/$myref -D $refdir/$dbsnp -L $refdir/$targets -A BaseCounts -stand_call_conf 30.0 -stand_emit_conf 10.0 --emitRefConfidence GVCF --variant_index_type LINEAR --variant_index_parameter 128000 -gt_mode DISCOVERY -ip 100 -pairHMM VECTOR_LOGLESS_CACHING -o $vcfdir/$sample.raw.snps.indels.vcf -I $bamdir/$sample".sorted.dedup.withRG.real.BQSR.bam"
    # -nt $maxthreads -> Impossible avec l'HaplotypeCaller

elif [ $analysisType = "Exome" ]; 	
then

#HaplotypeCaller Per Sample - BP_RESOLUTION
	#$targets + 100 padding
    # -nt $maxthreads -> Impossible avec l'HaplotypeCaller
	echo -e "\t#-----# Variant calling"
	echo "Variant Calling (HaplotypeCaller) pour: "	$sample
	
#OLD NGS PLATFORM COMMAND
#   time java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T HaplotypeCaller -R $refdir/$myref -D $refdir/$dbsnp -L $refdir/$targets -ip 100 -A BaseCounts -stand_call_conf 30.0 -stand_emit_conf 10.0 --emitRefConfidence BP_RESOLUTION --variant_index_type LINEAR --variant_index_parameter 128000 -pairHMM VECTOR_LOGLESS_CACHING -o $vcfdir/$sample.raw.snps.indels.vcf -I $bamdir/$sample".sorted.dedup.withRG.real.BQSR.bam"

#NEURO COMMAND
    time java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T HaplotypeCaller -R $refdir/$myref -D $refdir/$dbsnp -L $refdir/$targets --emitRefConfidence BP_RESOLUTION --variant_index_type LINEAR --variant_index_parameter 128000 -gt_mode DISCOVERY -ip 100 -pairHMM VECTOR_LOGLESS_CACHING -o $vcfdir/$sample.raw.snps.indels.vcf -I $bamdir/$sample".sorted.dedup.withRG.real.BQSR.bam"




else
	echo -e "\nAnalysis type not recognised: speciffy 'Diag' or 'Exome'";
fi
