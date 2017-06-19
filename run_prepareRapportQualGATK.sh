#!/bin/bash
#
# Sophie COUTANT
# 03/10/2013
#
#------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Script permettant, pour un run donné, de générer un fichier contenant toutes les données pour les 2 rapports qualités excel                                #
# 1- A l'aide du fichier depth.bed pour chaque intervale defini dans le BED des ROI Diagnostique, on recherche la profondeure minimale                       #
# 2- OUTPUT : fichier Quality.txt dans le dossier runFolder/Variant/Annotation/Result/FBrut                                                                  #
#------------------------------------------------------------------------------------------------------------------------------------------------------------#

# usage
function usage
{
	echo "#------------------------------------------------------------------------------------------------------------------------------------------------------------#"
	echo "# Script permettant, pour un run donné, de générer un fichier contenant toutes les données pour les 2 rapports qualités excel                                #"
	echo "# 1- A l'aide du fichier depth.bed pour chaque intervale defini dans le BED des ROI Diagnostique, on recherche la profondeure minimale                       #"
	echo "# 2- OUTPUT : fichier Quality.txt dans le dossier runFolder/Variant/Annotation/Result/FBrut                                                                  #"
	echo "#------------------------------------------------------------------------------------------------------------------------------------------------------------#"
	echo " "
    echo -e "\nUSAGE: run_prepareRapportQualGATK.sh -i <directory> -bed <file>"
    echo "		 -i <input Folder>"
    echo "		 -o <output Folder>"
    echo "		 -bed <Diagnostic ROI bed file>"
    echo -e "\nEXAMPLE: ./run_prepareRapportQualGATK.sh -i /storage/IN/111125_HWUSI-EAS1884_00002_FC64F86AAXX/BWA-GATK/DEPTH -o /storage/IN/111125_HWUSI-EAS1884_00002_FC64F86AAXX/JoinRapport -bed /storage/IN/Reference/Capture/MMR/DiagCapture-11genes_20130730.bed"
}

# get the arguments of the command line
if [ $# -lt 4 ]; then
	usage
	exit
else
	while [ "$1" != "" ]; do
	    case $1 in
		-i | --input )         shift
					if [ "$1" != "" ]; then
						#Run folderPath path
						depthdir=$1
					else
						usage
						exit
					fi
		                        ;;
		-o | --output )         shift
					if [ "$1" != "" ]; then
						#Run folderPath path
						outputdir=$1
					else
						usage
						exit
					fi
		                        ;;
		-bed | --bedFile )         shift
					if [ "$1" != "" ]; then
						#bedFile path
						bedFile=$1
					else
						usage
						exit
					fi
		                        ;;
		*)           		usage
		                        exit
		                        ;;
	    esac
	    shift
	done
fi

echo -e "\tTIME: BEGIN PREPARE REPPORTS".`date`

if [ -f $outputdir"/QualityGATK.txt" ]; then
 echo -e "\n\tOUTPUT FILE: $outputdir/QualityGATK.txt (file already exist)" 
else
 touch $outputdir"/QualityGATK.txt"
 echo -e "\n\tOUTPUT FILE : $outputdir/QualityGATK.txt (file created)"
fi

echo "ind gene exon taille SumDepthInterval MeanDepthInterval MinDepthInterval" > $outputdir"/QualityGATK.txt";

i=0;
#Pour chaque interval
while read interval
do
	set $(echo $interval);
	chr=$(eval echo $1);
	chrN=${chr:3}
	pos1=$(eval echo $2);
	pos2=$(eval echo $3);
	gene=$(eval echo $5);
	exon=$(eval echo $4);
	#~ echo "-------------------------------------------------"
	taille=$(($pos2 - $pos1 + 1));
	echo "Computing min depth in: $gene -> $exon"
	
	#Pour chaque Individu
	for j in `ls $depthdir | grep "depth.bed"`
	do
		#extrait le 1er champs du nom de fichier (en prenant '_' comme séparateur)
		#il s'agit du numero d'individu
		ind=$(echo $j | awk -F"_" '{print $1}')
		#~ echo -e "\t\tIndividual "$ind
		
		fileDepth=$depthdir"/"$j;
		linePos1="";
		linePos2="";
		linePos1=$(grep -w -n "$chrN"$'\t'"$pos1" $fileDepth | awk -F":" '{print $1}');
		linePos2=$(grep -w -n "$chrN"$'\t'"$pos2" $fileDepth | awk -F":" '{print $1}');
		
		#Si pos1 est vide, on avance dans le fichier pour tenter de trouver une position définie (on avance pas plus loin que pos2)
		if [ "${linePos1}" == '' ]
		then
			nondefini="Yes";
			while [ "${nondefini}" == 'Yes' ]
			do
				if [  $pos1 -lt $pos2 ]
				then	
					pos1=$(($pos1 + 1))
					linePos1=$(grep -w -n "$chrN"$'\t'"$pos1" $fileDepth | awk -F":" '{print $1}');
					if [ "${linePos1}" != '' ]
					then
						nondefini="No";
						break;
					fi
				else
					nondefini="No";
				fi
			done
		fi

		#Si pos2 est vide, on recule dans le fichier pour tenter de trouver une position définie (on ne recule pas plus loin que pos1)
		if [ "${linePos2}" == '' ]
		then
			nondefini="Yes";
			while [ "${nondefini}" == 'Yes' ]
			do
				if [  $pos2 -gt $pos1 ]
				then
					pos2=$(($pos2 - 1))
					linePos2=$(grep -w -n "$chrN"$'\t'"$pos2" $fileDepth | awk -F":" '{print $1}');
					if [ "${linePos2}" != '' ]
					then
						nondefini="No";
						break;
					fi
				else
					nondefini="No";
				fi
			done
		fi

		if [ "${linePos2}" == '' ]
		then
			SumDepthInterval=0;
			MeanDepthInterval=0;
			MinDepthInterval=0;
		else
			NombreLineDepth=$(($linePos2 - $linePos1 +1));
			#MeanDepthInterval=$(tail -n +$linePos1 $fileDepth | head -n $taille | awk '{sum += $3 } END { print (sum / NR)}');
			SumDepthInterval=$(tail -n +$linePos1 $fileDepth | head -n $NombreLineDepth | awk '{sum += $3 } END { print (sum)}');
			MeanDepthInterval=$(echo "scale = 2; $SumDepthInterval/$taille" | bc);
			#MinInterval
			MinDepthInterval=$(tail -n +$linePos1 $fileDepth | head -n $NombreLineDepth | awk '{if(min==""){min=max=$3}; if($3>max) {max=$3}; if($3< min) {min=$3}; total+=$3; count+=1} END {print min}');
		fi
		echo "$ind $gene $exon $taille $SumDepthInterval $MeanDepthInterval $MinDepthInterval" >> $outputdir"/QualityGATK.txt";
	done
	
done < $bedFile


echo -e "\n\tTIME: END PREPARE REPPORTS".`date`
