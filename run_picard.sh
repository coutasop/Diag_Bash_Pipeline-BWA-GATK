#!/bin/bash

if [ -z ${picarddir+x} ]; 
then 
	echo "Erreur: picarddir est non défini -> exit"; 
	exit
else 

	#a#-----------------------------------------
		## Sort aligned reads by coordinate order
		echo -e "\t#-----# Sort aligned reads by coordinate order"
		echo -e "\tRun picard/SortSam.jar for: "$sample
		## run picard SortSam
		## SORT_ORDER=coordinate for Sort order of output file
		## CREATE_INDEX=true to create a BAM index when writing a coordinate-sorted BAM file
		## MAX_RECORDS_IN_RAM= rule of thumb for reads ¬100bp, 250000 by GB of RAM given to -Xmx
		echo "	COMMAND: java -Xmx8g -jar $picarddir/SortSam.jar SORT_ORDER=coordinate INPUT=$samdir/${sample}_bwa-mem-P-M.sam OUTPUT=$bamdir/${sample}.sorted.bam MAX_RECORDS_IN_RAM=2000000"
		time java -Xmx8g -Djava.io.tmpdir=`pwd`/tmp -jar $picarddir/SortSam.jar SORT_ORDER=coordinate INPUT=$samdir/${sample}_bwa-mem-P-M.sam OUTPUT=$bamdir/${sample}.sorted.bam MAX_RECORDS_IN_RAM=2000000
	
	
	#b#-----------------------------------------
		## Mark duplicate reads
		echo -e "\t#-----# Mark duplicate reads"
		echo -e "\tRun picard/MarkDuplicates.jar for: "$sample
		## run picard MarkDuplicates
		## METRICS_FILE=File to write duplication metrics to
		## ASSUME_SORTED=true Assume that the input file is coordinate sorted even if the header says otherwise. 
		
		echo "	COMMAND: java -Xmx8g -jar $picarddir/MarkDuplicates.jar METRICS_FILE=$bamdir/${sample}.metrics ASSUME_SORTED=true INPUT=$bamdir/${sample}.sorted.bam OUTPUT=$bamdir/${sample}.sorted.dedup.bam"
		time java -Xmx8g -Djava.io.tmpdir=`pwd`/tmp -jar $picarddir/MarkDuplicates.jar METRICS_FILE=$bamdir/${sample}.metrics ASSUME_SORTED=true INPUT=$bamdir/${sample}.sorted.bam OUTPUT=$bamdir/${sample}.sorted.dedup.bam
	
	
	#c#-----------------------------------------
		## Add read groups to bam files
		## run picard AddOrReplaceReadGroups
		## RGLB=Read Group Library
		## RGPL=Read Group platform (e.g. illumina, solid)
		## RGPU=Read Group platform unit (eg. run barcode)
		## RGSM=Read Group sample name
		## RGCN=Read Group sequencing center name 
		echo -e "\t#-----# Add read groups to bam files"
		echo -e "\tRun picard/AddOrReplaceReadGroups.jar for: "$sample
		
		echo "	COMMAND: java -Xmx8g -jar $picarddir/AddOrReplaceReadGroups.jar RGLB=unknown RGPL=ILLUMINA RGPU=unknown RGSM=${sample} RGCN=${seqcenter} INPUT=$bamdir/${sample}.sorted.dedup.bam OUTPUT=$bamdir/${sample}.sorted.dedup.withRG.bam"
		time java -Xmx8g -Djava.io.tmpdir=`pwd`/tmp -jar $picarddir/AddOrReplaceReadGroups.jar RGLB=unknown RGPL=ILLUMINA RGPU=unknown RGSM=${sample} RGCN=${seqcenter} INPUT=$bamdir/${sample}.sorted.dedup.bam OUTPUT=$bamdir/${sample}.sorted.dedup.withRG.bam
	
				
	
	#d#-----------------------------------------
		## Build Index for bam file
		echo -e "\t#-----# Build Index for bam file"
		echo -e "\tRun picard/BuildBamIndex.jar for: "$sample	
		echo "	COMMAND: java -Xmx8g -jar $picarddir/BuildBamIndex.jar INPUT=$bamdir/$sample.sorted.dedup.withRG.bam"
		time java -Xmx8g -Djava.io.tmpdir=`pwd`/tmp -jar $picarddir/BuildBamIndex.jar INPUT=$bamdir/$sample.sorted.dedup.withRG.bam
		
fi


##Note temps Camille
## First exome
#real	106m35.319s
#user	143m12.105s
#sys	3m21.278s
## Second exome
#real	146m59.157s
#user	193m18.303s
#sys	4m51.651s



