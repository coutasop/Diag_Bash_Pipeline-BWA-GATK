#!/bin/bash

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
		

#Parcourir toutes les Lanes
for Lane in `ls $runFolder/Unaligned$project/ | grep "Project_"`
do
	echo -e "\tLane: "$Lane
	#Parcourir tous les Sample
	for Sample in `ls $runFolder/Unaligned$project/$Lane/ | grep "Sample_"`
	do
		echo -e "\t\tSample: "$Sample
		#extrait le dernier champs du nom du dossier (en prenant '_' comme séparateur)
		#il s'agit du numero d'individu
		ind=$(echo $Sample | awk -F"_" '{print $NF}')
		echo $ind >> $listIndv

		#Pour Chaque READ 
		fastq=(`ls $runFolder/Unaligned$project/$Lane/$Sample/ | grep "R1_001.fastq.gz"`)
		index=$(echo $fastq | awk -F"_" '{print $2}')
		lane=$(echo $fastq | awk -F"_" '{print $3}')

		if [ -e $fastqdir"/"$ind"_R1.fastq.gz" ]; #If file already exist
		then
			echo -e "\t\t File already in ouput folder -> ignore merge"
		else #If file does not already exist
			echo -e "\t\t#-----# FUSION FASTQ"
			echo -e "\t\tCOMMAND: cat $(ls -t "$runFolder"/Unaligned"$project"/"$Lane"/"$Sample"/"$ind"_"$index"_"$lane"_R1_*.fastq.gz) > "$fastqdir"/"$ind"_"$index"_"$lane"_R1.fastq.gz"
			cat $(ls -t $runFolder"/Unaligned"$project"/"$Lane"/"$Sample"/"$ind"_"$index"_"$lane"_R1_"*".fastq.gz") > $fastqdir"/"$ind"_R1.fastq.gz"
			echo -e "\t\tCOMMAND: cat $(ls -t "$runFolder"/Unaligned"$project"/"$Lane"/"$Sample"/"$ind"_"$index"_"$lane"_R2_*.fastq.gz) > "$fastqdir"/"$ind"_"$index"_"$lane"_R2.fastq.gz"
			cat $(ls -t $runFolder"/Unaligned"$project"/"$Lane"/"$Sample"/"$ind"_"$index"_"$lane"_R2_"*".fastq.gz") > $fastqdir"/"$ind"_R2.fastq.gz"
		fi

	done
	
done
