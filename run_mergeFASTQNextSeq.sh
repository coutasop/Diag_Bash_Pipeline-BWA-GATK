#!/bin/bash
#MERGE FASTQ POUR NEXTSEQ

project="ExomeCortico"
runFolder="/storage/crihan-msa/RunsPlateforme/NextSeq/150902_NB501076_0002_AHFTTGBGXX"
scriptdir=$runFolder"/BWA-GATK_ExomeCortico/SCRIPT"
fastqdir=$runFolder"/BWA-GATK_ExomeCortico/FASTQ"



#Construit la liste des individus au fur et à mesure
if [ -e "$scriptdir/listePatients.txt" ]; 
then
	rm $scriptdir/listePatients.txt
	touch $scriptdir/listePatients.txt
else
	touch $scriptdir/listePatients.txt
fi
export listIndv=$scriptdir/listePatients.txt


#Avant de lancer la fusion il faut attendre que le demultiplexage soit terminé
	#Fichier à verifier pour savoir si le Demultiplexage est terminé
	demultiplex="demultiplexing.completed"
	#while the demultiplex file does not exist continue to check
	while [ ! -f $runFolder/Unaligned$project/$demultiplex ]; 
	do
		echo -e "\t".`date`.": WAIT 15min : File $runFolder/Unaligned$project/$demultiplex doesn't exists"
		sleep 15m
	done
		

#Parcourir toutes les patients L001 seulement
for Sample in `ls $runFolder/Unaligned$project/Project_$project | grep L001`
do
	echo -e "\t\tSample: "$Sample
	#extrait le dernier champs du nom du dossier (en prenant '_' comme séparateur)
	#il s'agit du numero d'individu
	ind=$(echo $Sample | awk -F"_" '{print $1}')
	echo $ind >> $listIndv

	#Pour Chaque READ 
	fastqall=(`ls $runFolder"/Unaligned"$project"/Project_"$project"/"$ind* | grep "L001_R1_001.fastq.gz"`)
	fastq=(`basename $fastqall`)
	sline=$(echo $fastq | awk -F"_" '{print $2}')

	if [ -e $fastqdir"/"$ind"_R1.fastq.gz" ]; #If file already exist
	then
		echo -e "\t\t File already in ouput folder -> ignore merge"
	else #If file does not already exist
		echo -e "\t\t#-----# FUSION FASTQ"
		#R1
		echo -e "\t\tCOMMAND: cat $(ls -t "$runFolder"/Unaligned"$project"/Project_"$project"/"$ind"_"$sline"_L00*_R1_001.fastq.gz) > "$fastqdir"/"$ind"_R1.fastq.gz"
		cat $(ls -t "$runFolder"/Unaligned"$project"/Project_"$project"/"$ind"_"$sline"_L00*_R1_001.fastq.gz) > $fastqdir"/"$ind"_R1.fastq.gz"
		#R2
		echo -e "\t\tCOMMAND: cat $(ls -t "$runFolder"/Unaligned"$project"/Project_"$project"/"$ind"_"$sline"_L00*_R2_001.fastq.gz) > "$fastqdir"/"$ind"_R2.fastq.gz"
		cat $(ls -t "$runFolder"/Unaligned"$project"/Project_"$project"/"$ind"_"$sline"_L00*_R2_001.fastq.gz) > $fastqdir"/"$ind"_R2.fastq.gz"
	fi
	
done
