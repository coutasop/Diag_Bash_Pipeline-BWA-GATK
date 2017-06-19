#!/bin/bash
#
# Sophie COUTANT
# 23/07/2013
#
# Juliette AURY-LANDAS
# 19/09/2013
#
#------------------------------------------------------------------------------------------------------------------------------------------------------------#
# This script allows the automation of variants annotation using the Annovar tool, and allows the parsing of the output to generate a standard input for EVA #
# Annovar:                                                                                                                                                   #
# Wang K, Li M, Hakonarson H. ANNOVAR: Functional annotation of genetic variants from next-generation sequencing data, Nucleic Acids Research, 38:e164, 2010 #
#                                                                                                                                                            #
# 1- call the script run_annovar.sh (Conversion + annotation, see script for more details)                                                                   #
# 2- call the script parsing_annovarOutput.sh (Parse the annovar output, see script for more details)                                                     	 #
#------------------------------------------------------------------------------------------------------------------------------------------------------------#


# usage
function usage
{
	echo "#------------------------------------------------------------------------------------------------------------------------------------------------------------#"
	echo "# This script allows the automation of variants annotation using the Annovar tool, and allows the parsing of the output to generate a standard input for EVA #"
	echo "# Annovar:                                                                                                                                                   #"
	echo "# Wang K, Li M, Hakonarson H. ANNOVAR: Functional annotation of genetic variants from next-generation sequencing data, Nucleic Acids Research, 38:e164, 2010 #"
	echo "#                                                                                                                                                            #"
	echo "# I- call the script run_annovar.sh (Conversion + annotation, see script for more details)                                                                   #"
	echo "# II- call the script parsing_annovarOutput.sh (Parse the annovar output, see script for more details)                                                       #"
	echo "#------------------------------------------------------------------------------------------------------------------------------------------------------------#"
	echo " "
	echo "USAGE: run_annotExome.sh -c <CASAVA/GATK/Samtools> -t <1K/ESP/dbSNP/exome> -a <directory> -i <directory> -o <directory> -v <directory> [Casava Only -c2v <directory>]" 
	echo "	-c <CASAVA/GATK/Samtools> the variant caller tool used "
	echo "	-t <1K/ESP/dbSNP/exome> the type of data "
	echo "	-a <annovar source directory> "
	echo "	-i <input directory containing variant calling files (give Run folder for Casava runs)> "
	echo "	-o <output directory for the annotated files> "
	echo "	-c2v [Casava Only] <casava2vcf source directory> "
	echo "	-v <variant directory>"
	echo "EXAMPLE: ./run_annotExome.sh -c GATK -t exome -a /home/me/Program/Annovar -i Project/VCF -o Project/Annotated [-c2v /opt/alamutHT]"
	echo " "
}

# get the arguments of the command line
if [ $# -lt 10 ]; then
	usage
	exit
else
	while [ "$1" != "" ]; do
	    case $1 in
	    -c | --caller )    	shift
					if [ "$1" != "" ]; then
						caller=$1
						if [[ $caller = "CASAVA" ]]; then
							fileExt=".txt"
	
						elif [[ $caller = "GATK" ]]; then
							fileExt=".vcf"
							
						elif [[ $caller = "Samtools" ]]; then
							fileExt=".vcf"
	
						else
							echo "Only casava or vcf (Samtool or GATK) variant calling files are supported!"
							usage
							exit
						fi
					else
						usage
						exit
					fi
											;;
		 
		 -t | --type )    	shift
					if [ "$1" != "" ]; then
						type=$1
						if [[ $type = "1K" ]]; then
							echo "1K"
	
						elif [[ $type = "ESP" ]]; then
							echo "ESP"
							
						elif [[ $type = "dbSNP" ]]; then
							echo "dbSNP"

						elif [[ $type = "exome" ]]; then
							echo "exome"
							
						else
							echo "Only 1000 genomes, ESP, dbSNP or exome variant calling files supported!"
							usage
							exit
						fi
					else
						usage
						exit
					fi
					                       ;;
					                       
		-a | --annovar )         shift
					if [ "$1" != "" ]; then
						# Path of Annovar scripts
						annovarPath=$1
					else
						usage
						exit
					fi
		                        ;;
		                        
		-i | --inputDirectory )    	shift
					if [ "$1" != "" ]; then
						inputDirectory=$1
					else
						usage
						exit
					fi
		                        ;;
		                        
		                        
		-o | --outputDirectory )    	shift
					if [ "$1" != "" ]; then
						outputDirectory=$1
					else
						usage
						exit
					fi
		                        ;;
		                        
		-c2v | --casava2vcf )    	shift
					if [ "$1" != "" ]; then
						alamutHTPath=$1
					else
						usage
						exit
					fi
		                        ;;
		-v | --variantDir )         shift
					if [ "$1" != "" ]; then
						#variantsdir path
						variantsdir=$1
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

echo -e "\t TIME: BEGIN RUN ANNOTATION".`date`
#Get the path of all the scripts that will be launched
scriptPath=$(dirname $0)

#Variants Folder Name (different for Diag and Exome)
VariantsFolder=$(echo $variantsdir | awk 'BEGIN {FS="/"} {print $NF}')

#If Caller = CASAVA convert snp.txt/indels.txt using casava2vcf
if [[ $caller = "CASAVA" ]]; then
	
	if [ 1$alamutHTPath != 1 ]; then
	
		#prepare run folder name
		runFolder=$inputDirectory;

		#Executing the run_Casava2vcf.sh script
		echo -e "\n\t#---------------------------------------------------------#"
		echo -e "\tI- RUNNING casava2vcf"
		echo -e "\t#CMD: $scriptPath/run_Casava2vcf.sh -i $runFolder -v $VariantsFolder -c $alamutHTPath"
		$scriptPath/run_Casava2vcf.sh -i $runFolder -v $VariantsFolder -c $alamutHTPath
		
		#prepare input directory name for the next step
		inputDirectory=$inputDirectory/$VariantsFolder/VCF
	
	else
		usage
		echo -e "ERROR: -c2v argument must be set for CASAVA variants\n"
		exit
	fi
	
fi

#Executing the run_annovar.sh script
echo -e "\n\t#---------------------------------------------------------#"
echo -e "\tI- RUNNING Annovar"
echo -e "\t#CMD: $scriptPath/run_annovar.sh -a $annovarPath -i $inputDirectory -o $outputDirectory"
$scriptPath/run_annovar.sh -a $annovarPath -i $inputDirectory -o $outputDirectory

#~ #Executing the run_annovarOutputParsing.sh script
#~ directory=$outputDirectory
#~ echo -e "\n\t#---------------------------------------------------------#"
#~ echo -e "\tII- RUNNING Parsing"
#~ if [[ $type = "exome" ]]; then
	#~ echo -e "\t#CMD: $scriptPath/parsing_annovarOutput.sh -d $directory -c $caller"
	#~ $scriptPath/parsing_annovarOutput.sh -d $directory -c $caller
#~ else #1000 genomes, ESP or dbSNP vcf data
	#~ echo -e "\t#CMD: $scriptPath/parsing_annovarOutput_otherInfo_publicDataset.sh -d $directory -t $type"
	#~ $scriptPath/parsing_annovarOutput_otherInfo_publicDataset.sh -d $directory -t $type
#~ fi
echo -e "\n\t#---------------------------------------------------------#"
echo -e "\t#ALLDONE: run_annotExome.sh"
echo -e "\t#---------------------------------------------------------#"
echo -e "\t TIME: END RUN ANNOTATION".`date`	
