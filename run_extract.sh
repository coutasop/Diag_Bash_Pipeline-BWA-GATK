#!/bin/bash
#
# Sophie COUTANT
# 20/05/2014
#
#------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Ce script permet l'automatisation du lancement de l'extraction à partir des fichiers output d'alamutHT													 #
#                                                                                                                                                            #
# 1- extract specified transcripts															                                                                 #
# 2- (optionnal) extract variants in specified regions (bed file)																							 #
#------------------------------------------------------------------------------------------------------------------------------------------------------------#

# usage
function usage
{
    echo -e "\nUSAGE: run_extract.sh -i <directory> -o <directory> -nm <file> -bt <bedtoolsdir> [optional -bed <file>]"
    echo "		 -i <input Folder>"
    echo "		 -o <output Folder>"
    echo "		 -bt <bedtools dir>"
    echo "		 -nm <file containing the nmList to extract>"
    echo "		 [optional] -bed <bed file containing the region of interest>"
    echo -e "\nEXAMPLE: ./run_extract.sh -i /storage/crihan-msa/runsPlateforme/GaIIx/111125_HWUSI-EAS1884_00002_FC64F86AAXX/VariantsDiag/alamutHT -o /storage/crihan-msa/runsPlateforme/GaIIx/111125_HWUSI-EAS1884_00002_FC64F86AAXX/VariantsDiag/Result_alamutHT/Fbrut -nm /storage/crihan-msa/runsPlateforme/Reference/Capture/MMR/nmList.txt [-bed /storage/crihan-msa/runsPlateforme/Reference/Capture/MMR/DiagCapture-11genes_20130506_extract.bed]"
    echo -e "\nREQUIREMENT: If using bed File, BedTool must be installed and in your PATH\n"
}

# get the arguments of the command line
if [ $# -lt 6 ]; then
	usage
	exit
else
	while [ "$1" != "" ]; do
	    case $1 in
		-i | --input )         shift
					if [ "$1" != "" ]; then
						#Run folderPath path
						inputFolder=$1
					else
						usage
						exit
					fi
		                        ;;
		-o | --output )         shift
					if [ "$1" != "" ]; then
						#Output folder Path
						outputFolder=$1
					else
						usage
						exit
					fi
		                        ;;
		-bed | --bedFile )         shift
					if [ "$1" != "" ]; then
						#bedFile Path
						bedFile=$1
					else
						usage
						exit
					fi
		                        ;;		                    
		-nm | --nmFile )         shift
					if [ "$1" != "" ]; then
						#nmFile Path
						nmFile=$1
					else
						usage
						exit
					fi
		                        ;;
		-bt | --bedToolsDir )         shift
					if [ "$1" != "" ]; then
						#$bedtools Path
						bedtoolsdir=$1
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

echo -e "\tTIME: BEGIN EXTRACT".`date`

#Test if the output directory exists, if no, create it
if [ -d $outputFolder ]; then
 echo -e "\n\tOUTPUT FOLDER: $outputFolder (folder already exist)" 
else
 mkdir -p $outputFolder 
 echo -e "\n\tOUTPUT FOLDER : $outputFolder (folder created)"
fi

#Pour chaque Fichier
for f in `ls $inputFolder/*.ann`
do
	echo -e "\t----------------------------------------"
	fich=$(basename $f) #nom du fichier sans path
	fileName=${fich%.*} #nom du fichier sans sa dernière extension (ici: .vcf)
	path=$(dirname $f) #nom du path, sans le fichier
	echo -e "\t$fich";

	#extrait le premier champ du nom de fichier (en prenant '_' comme séparateur)
	#il s'agit du numero d'individu
	ind=$(echo $fich | awk -F"_" '{print $1}')
	echo -e "\t\t----------------------------------------"
	echo -e "\t\tIndividual "$ind

	
	#get le numéro de colonne des champs utilisé pour l'extract (les champs bed obligatoire chrom gDNAstart gDNAend)
	chrom=$(awk -F'\t' 'BEGIN {OFS="\t" ; FS="\t"} { for(i;i<=NF;i++){ if ($i ~ /chrom/) {print i} } }' $f)
	gDNAstart=$(awk -F'\t' 'BEGIN {OFS="\t" ; FS="\t"} { for(i;i<=NF;i++){ if ($i ~ /gDNAstart/) {print i} } }' $f)
	gDNAend=$(awk -F'\t' 'BEGIN {OFS="\t" ; FS="\t"} { for(i;i<=NF;i++){ if ($i ~ /gDNAend/) {print i} } }' $f)
	
	#Get header et inverser les colonnes pour avoir "chr" "pos1" "pos2" au début
	head -n 1 $f | awk -v chrom="$chrom" -F'\t' 'BEGIN {OFS="\t"}{temp = $1; $1 = $chrom; $chrom = temp; print }' | awk -v gDNAstart="$gDNAstart" -F'\t' 'BEGIN {OFS="\t"}{temp = $2; $2 = $gDNAstart; $gDNAstart = temp; print }' | awk -v gDNAend="$gDNAend" -F'\t' 'BEGIN {OFS="\t"}{temp = $3; $3 = $gDNAend; $gDNAend = temp; print }' > $outputFolder"/"$fich".header"
	#~ANCIENNE COMMANDE BASEE SUR NUMERO DE COL: head -n 1 $f | awk -F'\t' 'BEGIN {OFS="\t"}{temp = $1; $1 = $2; $2 = temp; print }' | awk -F'\t' 'BEGIN {OFS="\t"}{temp = $2; $2 = $15; $15 = temp; print }' | awk -F'\t' 'BEGIN {OFS="\t"}{temp = $3; $3 = $16; $16 = temp; print }' > $outputFolder"/"$fich".header"
	touch $outputFolder"/"$fich".nmOfInterest"
	
	#Parcourir les NM dans le fichier, faire 1 grep dans le fichier total, intervertir les colonnes pour avoir "chr" "pos1" "pos2" au début, et les stocker dans un fichier temporaire
	while read NM
	do
		echo -e "\t\t\tExtracting: "$NM
		grep $NM $f | awk -v chrom="$chrom" -F'\t' 'BEGIN {OFS="\t"}{temp = $1; $1 = $chrom; $chrom = temp; print }' | awk -v gDNAstart="$gDNAstart" -F'\t' 'BEGIN {OFS="\t"}{temp = $2; $2 = $gDNAstart; $gDNAstart = temp; print }' | awk -v gDNAend="$gDNAend" -F'\t' 'BEGIN {OFS="\t"}{temp = $3; $3 = $gDNAend; $gDNAend = temp; print }' | sort -n >> $outputFolder"/"$fich".nmOfInterest"
		
	done < $nmFile
	
	#Rassembler le header et les nm d'intêret dans 1 seul fichier
	cat $outputFolder"/"$fich".header" > $outputFolder"/"$fich"-extract"
	cat $outputFolder"/"$fich".nmOfInterest" >> $outputFolder"/"$fich"-extract"
	
	echo -e "\t\t#DONE NM Extract - #Output $outputFolder/$fich-extract"
		
	if [ 1$bedFile != 1 ]; then
		#Bedfile is given for the ROI extraction
		#Out put will be .vcf-50.ann-extract"
		echo -e "\t\tBED file specified, Extraction of ROI will proceed"
		echo -e "COMMAND: tail -n +2 $outputFolder/$fich-extract | sed -e s/^/chr/g -e s/\\t\\t/\\t.\\t/g | $bedtoolsdir/intersectBed -a stdin -b $bedFile > $outputFolder/$fileName-50.ann-extract.data"
		tail -n +2 $outputFolder"/"$fich"-extract" | sed -e s/^/chr/g -e s/\\t\\t/\\t.\\t/g | $bedtoolsdir"/"intersectBed -a stdin -b $bedFile > $outputFolder"/"$fileName"-50.ann-extract.data"
		#Rassembler le header et les ROI d'intêret dans 1 seul fichier
		cat $outputFolder"/"$fich".header" > $outputFolder"/"$fileName"-50.ann-extract"
		cat $outputFolder"/"$fileName"-50.ann-extract.data" >> $outputFolder"/"$fileName"-50.ann-extract"
		echo -e "\t\t#DONE BED Extract - #Output $outputFolder/$fich-50-extract"
		#rm of the temp files and file .vcf.ann-extract
		rm $outputFolder"/"$fileName"-50.ann-extract.data"
		rm $outputFolder"/"$fich"-extract"
	fi

	echo -e "\t\t#DONE Extract"
	
	rm $outputFolder"/"$fich".header"
	rm $outputFolder"/"$fich".nmOfInterest"

done

echo -e "\tTIME: END EXTRACT".`date`
