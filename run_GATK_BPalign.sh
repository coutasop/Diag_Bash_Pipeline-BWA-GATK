###--------------------------------------------------------------------------------------------###
###     Realignement and Base Quality Score Recalibration according to GATK Best Practices     ###
###--------------------------------------------------------------------------------------------###


#-a-# Perform realignment on targeted intervals

	#CAMILLE Version
	#~ time java -Xmx16g -jar $gatkdir/GenomeAnalysisTK.jar -T IndelRealigner -R $refdir/$myref -I $bamdir/$sample.sorted.dedup.withRG.bam -targetIntervals $outdir/target_intervals.list -known $refdir/$mills -known $refdir/$kGindels -o $bamdir/$sample.sorted.dedup.withRG.real.bam 
	#28.04min
			
	#SOPHIE Version
	#-a1# Create targeted intervals with bam file for realignment
	echo -e "\t#-----# Create targeted intervals with bam file for realignment"
	echo -e "\tCOMMAND: time java -Xmx16g -jar $gatkdir/GenomeAnalysisTK.jar -T RealignerTargetCreator -R $refdir/$myref -L $refdir/$targets -nt $maxthreads -I $bamdir/$sample.sorted.dedup.withRG.bam -o $scriptdir/$sample-target_intervals.list -known $refdir/$mills -known $refdir/$kGindels"
	time java -Xmx16g -jar $gatkdir/GenomeAnalysisTK.jar -T RealignerTargetCreator -R $refdir/$myref -L $refdir/$targets -nt $maxthreads -I $bamdir/$sample.sorted.dedup.withRG.bam -o $scriptdir/$sample-target_intervals.list -known $refdir/$mills -known $refdir/$kGindels
	#-a2# do the realignment on targeted intervals
	echo -e "\t#-----# realignment on targeted intervals"
	echo -e "\tCOMMAND: time java -Xmx16g -jar $gatkdir/GenomeAnalysisTK.jar -T IndelRealigner -R $refdir/$myref -I $bamdir/$sample.sorted.dedup.withRG.bam -targetIntervals $outdir/target_intervals.list -known $refdir/$mills -known $refdir/$kGindels -o $bamdir/$sample.sorted.dedup.withRG.real.bam"
	time java -Xmx16g -jar $gatkdir/GenomeAnalysisTK.jar -T IndelRealigner -R $refdir/$myref -I $bamdir/$sample.sorted.dedup.withRG.bam -targetIntervals $scriptdir/$sample-target_intervals.list -known $refdir/$mills -known $refdir/$kGindels -o $bamdir/$sample.sorted.dedup.withRG.real.bam 


#-b-# Perform Base Quality Score Recalibration (BQSR)
	## Analyse patterns of covariation in the sequence dataset
	
	#CAMILLE output dans outdir
	#~ time java -Xmx16g -jar $gatkdir/GenomeAnalysisTK.jar -T BaseRecalibrator -nct 8 -R $refdir/$myref -I $bamdir/$sample.sorted.dedup.withRG.real.bam -knownSites $refdir/$dbsnp -knownSites $refdir/$mills -knownSites $refdir/$kGindels -o $outdir/$sample.BQSR.table 
	# 30min

	#SOPHIE output dans scriptdir
	echo -e "\t#-----# Perform Base Quality Score Recalibration (BQSR)"
	echo -e "\tCOMMAND: time java -Xmx16g -jar $gatkdir/GenomeAnalysisTK.jar -T BaseRecalibrator -nct $maxthreads -R $refdir/$myref -I $bamdir/$sample.sorted.dedup.withRG.real.bam -knownSites $refdir/$dbsnp -knownSites $refdir/$mills -knownSites $refdir/$kGindels -o $scriptdir/$sample.BQSR.table "
	time java -Xmx16g -jar $gatkdir/GenomeAnalysisTK.jar -T BaseRecalibrator -nct $maxthreads -R $refdir/$myref -I $bamdir/$sample.sorted.dedup.withRG.real.bam -knownSites $refdir/$dbsnp -knownSites $refdir/$mills -knownSites $refdir/$kGindels -o $scriptdir/$sample.BQSR.table 
			

#-?-#
	## Second pass: analyse remaining covariation after recalibration
	#time java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T BaseRecalibrator -nct 8 -R $refdir/$myref -I $bamdir/$sample.sorted.dedup.withRG.withRG.real.bam -knownSites $refdir/$dbsnp -knownSites $refdir/$mills -BQSR $outdir/$sample.BQSR.table -o $outdir/$sample.postBQSR.table
	# Quasi 2h...
#-?-#
	## Generate before/after plots
	#time java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T AnalyzeCovariates -R $refdir/$myref -before $outdir/$sample.BQSR.table -after $outdir/$sample.postBQSR.table -plots $outdir/$sample.BQSRplots.pdf
	# Plante à la génération du pdf dans le Rscript


#-c-# Apply recalibration to sequence data Pourrait demander jusqu'a 8 cpu aussi ici.
	
	#CAMILLE BQSR input dans outdir
	#~ time java -Xmx16g -jar $gatkdir/GenomeAnalysisTK.jar -T PrintReads -nct 8 -R $refdir/$myref -I $bamdir/$sample.sorted.dedup.withRG.real.bam -BQSR $outdir/$sample.BQSR.table -o $bamdir/$sample.sorted.dedup.withRG.real.BQSR.bam
	#1h30

	#SOPHIE BQSR input dans scriptdir
	echo -e "\t#-----# Apply recalibration to sequence data"
	echo -e "\tCOMMAND: time java -Xmx16g -jar $gatkdir/GenomeAnalysisTK.jar -T PrintReads -nct $maxthreads -R $refdir/$myref -I $bamdir/$sample.sorted.dedup.withRG.real.bam -BQSR $script/$sample.BQSR.table -o $bamdir/$sample.sorted.dedup.withRG.real.BQSR.bam"
	time java -Xmx16g -jar $gatkdir/GenomeAnalysisTK.jar -T PrintReads -nct $maxthreads -R $refdir/$myref -I $bamdir/$sample.sorted.dedup.withRG.real.bam -BQSR $scriptdir/$sample.BQSR.table -o $bamdir/$sample.sorted.dedup.withRG.real.BQSR.bam

#---# Compress bam file using Reduce Reads (deprecated with GATK v3)
	# CAMILLE
	#~ echo -e "\tCOMMAND: time java -Xmx24g -jar $gatkdir/GenomeAnalysisTK.jar -T ReduceReads -R $refdir/$myref -I $bamdir/$sample.sorted.dedup.withRG.real.BQSR.bam -o $bamdir/$sample.sorted.dedup.withRG.real.BQSR.RR.bam "
	#~ time java -Xmx24g -jar $gatkdir/GenomeAnalysisTK.jar -T ReduceReads -R $refdir/$myref -I $bamdir/$sample.sorted.dedup.withRG.real.BQSR.bam -o $bamdir/$sample.sorted.dedup.withRG.real.BQSR.RR.bam 

	#SOPHIE Etape inutile pour le diag -> rendu sorted.dedup.withRG.real.BQSR.bam


#-d-# Nettoyage des bam temporaires
	## CAMILLE 
	#~ if [ -f $bamdir/$sample.sorted.dedup.withRG.real.BQSR.RR.bam ]
	#~ then
		#~ rm $bamdir/$sample.sorted.dedup.bam $bamdir/$sample.sorted.dedup.withRG.bam $bamdir/$sample.sorted.dedup.withRG.real.bam $bamdir/$sample.sorted.dedup.withRG.real.BQSR.bam 
	#~ fi

	## SOPHIE 
	echo -e "\t#-----# Nettoyage des bam temporaires"
	if [ -f $bamdir/$sample.sorted.dedup.withRG.real.BQSR.bam ]
	then
		echo -e "\tCOMMAND:"
		echo -e	"\t rm $bamdir/$sample.sorted.dedup.bam"
		echo -e	"\t rm $bamdir/$sample.sorted.dedup.withRG.bam "
		echo -e	"\t rm $bamdir/$sample.sorted.dedup.withRG.bai "
		echo -e	"\t rm $bamdir/$sample.sorted.dedup.withRG.real.bam "
		echo -e	"\t rm $bamdir/$sample.sorted.dedup.withRG.real.bai "
		rm $bamdir/$sample.sorted.dedup.bam 
		rm $bamdir/$sample.sorted.dedup.withRG.bam 
		rm $bamdir/$sample.sorted.dedup.withRG.bai 
		rm $bamdir/$sample.sorted.dedup.withRG.real.bam 
		rm $bamdir/$sample.sorted.dedup.withRG.real.bai
	fi

