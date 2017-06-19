#!/bin/bash

## add bwa to PATH
#~ PATH=$PATH:/opt/bwa-0.7.5a

if [ -z ${bwadir+x} ]; 
then 
	echo "Erreur: bwadir est non défini -> exit"; 
	exit
else 

echo -e "\t#-----# ALIGNEMENT"
echo -e "\nRun bwa mem -P -M for Sample: "$sample
	## run bwa mem
	## -t for number of threads
	## -P for paired-end mode
	## -M for Picard compatibility
	echo "COMMAND: $bwadir/bwa mem -t 8 -M $refdir/$myref $fastqdir/${sample}_R1.fastq.gz $fastqdir/${sample}_R2.fastq.gz > $samdir/${sample}_bwa-mem-P-M.sam"
	
	$bwadir/bwa mem -t $maxthreads -M $refdir/$myref $fastqdir/${sample}_R1.fastq.gz $fastqdir/${sample}_R2.fastq.gz > $samdir/${sample}_bwa-mem-P-M.sam
	
#~ -t 1
#~ //pour 1 exome
#~ [main] Real time: 13419.203 sec; CPU: 13386.824 sec
#~ //pour 2 exomes
#~ real	381m47.686s
#~ user	378m4.807s
#~ sys	1m14.937s

#~ -t 8
#~ //pour 1 exome
#~ [main] Real time: 2176.486 sec; CPU: 13515.997 sec
#~ //pour 2 exomes
#~ real	62m12.402s
#~ user	379m43.729s
#~ sys	3m0.704s


fi
