#!/bin/bash
#
# Sophie COUTANT
# 03/10/2013
#
#------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Script permettant, pour un run CASAVA donné, de générer les fichier depth.bed                                                                              #
# 1- run samtools depth                                                                                                                                      #
#------------------------------------------------------------------------------------------------------------------------------------------------------------#

# usage
function usage
{
	echo "#------------------------------------------------------------------------------------------------------------------------------------------------------------#"
	echo "# Script permettant, pour un dossier BAM donné, de générer les fichier depth.bed                                                                             #"
	echo "# 1- run samtools depth                                                                                                                                      #"
	echo "#------------------------------------------------------------------------------------------------------------------------------------------------------------#"
	echo " "
    echo -e "\nUSAGE: run_depthDiagGATK.sh -i <directory> -o <directory> -bed <file>"
    echo "		 -i <bam input Folder>"
    echo "		 -o <depth output Folder>"
    echo "		 -bed <Agilent Target bed file>"
    echo -e "\nEXAMPLE: ./run_depthDiag.sh -i /storage/IN/111125_HWUSI-EAS1884_00002_FC64F86AAXX/BWA-GATK/BAM -o /storage/IN/111125_HWUSI-EAS1884_00002_FC64F86AAXX/BWA-GATK/DEPTH -bed /storage/IN/Reference/Capture/MMR/036540_D_BED_20110915-DiagK_colique-U614_TARGET.bed"
    echo -e "\nREQUIREMENT: Samtools must be installed and in your PATH\n"
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
						#bam folder path
						bamFolder=$1
					else
						usage
						exit
					fi
		                        ;;
		-o | --output )         shift
					if [ "$1" != "" ]; then
						#depth output path
						depthFolder=$1
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

echo -e "\tTIME: BEGIN RUN DEPTH".`date`

#Test if the output directory exists, if no, create it
if [ -d $depthFolder ]; then
 echo -e "\n\tOUTPUT FOLDER: $depthFolder (folder already exist)" 
else
 mkdir -p $depthFolder
 echo -e "\n\tOUTPUT FOLDER : $depthFolder (folder created)"
fi
		
#Pour chaque BQSR.bam
for i in `ls $bamFolder | grep "BQSR.bam$"`
do
	echo -e "\t\t----------------------------------------"	
	ind=$(echo $i | awk -F"." '{print $1}');
	echo -e "\t\t$ind"
	#execute les calculs profondeur
	echo -e "\t\tCOMMAND: samtools depth -d 10000000 -b $bedFile $bamFolder/$i > $depthFolder/"$ind"_depth.bed";
	samtools depth -d 10000000 -b $bedFile $bamFolder/$i > $depthFolder/$ind"_depth.bed";

done

echo -e "\tTIME: END RUN DEPTH".`date`
