#!/bin/bash
#
# Camille, Sophie
# LAST UPDATE : 06/06/2014
#
#------------------------------------------------------------------------------------------------------------------------------------------------------------#
# Ce script permet le lancement automatique du pipeline BEST PRACTICE de GATK                                                                                #
# Etape:                                                                                                                                                     #
# 0- (OPTIONNEL = donnée ayant une structure CASAVA)  Fusionner les FASTQ issus du démultipléxage en 1 seul fichier                                          #
# 0- (OPTIONNEL = donnée n'ayant pas une structure CASAVA) créer les targets pour le réalignement                                                            #
# 1- Lancer BWA                                                                                                                                              #
# 2- Lancer Picard                                                                                                                                           #
# 3- Lancer GATK realign et BQSR                                                                                                                             #
# 4- Lancer GATK variant calling                                                                                                                             #
# 5- Lancer GATK join genotyping (si GATKv3+) and recalibration                                                                                              #
#------------------------------------------------------------------------------------------------------------------------------------------------------------#

#----------------------------------------------------------------------#
#-------------------------USAGE AND PARAMETERS-------------------------#
#----------------------------------------------------------------------#

# usage
function usage
{
	echo "#------------------------------------------------------------------------------------------------------------------------------------------------------------#"
	echo "# Ce script permet le lancement automatique du pipeline BEST PRACTICE de GATK                                                                                #"
	echo "# Etape:                                                                                                                                                     #"
	echo "# 0- (OPTIONNEL = donnée ayant une structure CASAVA)  Fusionner les FASTQ issus du démultipléxage en 1 seul fichier                                          #"
	echo "# 0- (OPTIONNEL = donnée n'ayant pas une structure CASAVA) créer les targets pour le réalignement                                                            #"
	echo "# 1- Lancer BWA                                                                                                                                              #"
	echo "# 2- Lancer Picard                                                                                                                                           #"
	echo "# 3- Lancer GATK realign et BQSR                                                                                                                             #"
	echo "# 4- Lancer GATK variant calling                                                                                                                             #"
	echo "# 5- Lancer GATK join genotyping (si GATKv3+) and recalibration                                                                                              #"
	echo "#------------------------------------------------------------------------------------------------------------------------------------------------------------#"
	echo " "
	echo "USAGE: runMaster_BWA-GATK.sh -s <file>" 
	echo "	-s <path to settings file>"
	echo "EXAMPLE: ./run_BWA-GATK.sh -s path/to/settings.txt"
	echo -e "\nREQUIREMENT: BWA / PICARD / GATK / JAVA7 must be installed"
	echo -e "\tSettings for the programs and data must be set the setting file provided as an argument\n"
	echo " "
}

# get the arguments of the command line
if [ $# -lt 2 ]; then
	usage
	exit
else
	while [ "$1" != "" ]; do
	    case $1 in
		-s | --settings )    	shift
					if [ "$1" != "" ]; then
						settingsFile=$1
					else
						usage
						exit
					fi
		                        ;;     
	    esac
	    shift
	done
fi

echo "#------------------------------------------------------------------------------------------------------------------------------------------------------------#"
echo "# Ce script permet le lancement automatique du pipeline BEST PRACTICE de GATK                                                                                #"
echo "# Etapes:                                                                                                                                                    #"
echo "# 0- (OPTIONNEL = donnée ayant une structure CASAVA)  Fusionner les FASTQ issus du démultipléxage en 1 seul fichier                                          #"
echo "# 0- (OPTIONNEL = donnée n'ayant pas une structure CASAVA) créer les targets pour le réalignement                                                            #"
echo "# 1- BWA                                                                                                                                                     #"
echo "# 2- Picard                                                                                                                                                  #"
echo "# 3- GATK realign et BQSR                                                                                                                                    #"
echo "# 4- GATK variant calling per sample                                                                                                                         #"
echo "# 5- Lancer GATK join genotyping (si GATKv3+) and recalibration                                                                                              #"
echo "#------------------------------------------------------------------------------------------------------------------------------------------------------------#"

echo -e "\n#----------------------------PIPELINE BEGIN------------------------------#"
date

#----------------------------------------------------------------------#
#-----------------READ SETTINGS AND OUTPUT FOLDER CHECK----------------#
#----------------------------------------------------------------------#

#Get the paths and names of all the scripts and datas that will be launched
scriptPath=$(dirname $0) #Get the folder path of this script
source $settingsFile	 #Import the settings
GATKversion=$(java -jar $gatkdir/GenomeAnalysisTK.jar -version);


#Test if the outDIRs directory exists, if no, create them
# -- outdir -- fastqdir -- samdir -- bamdir -- vcfdir -- scriptdir
if [ -d $outdir ]; then
 echo -e "\n\tOUTPUT FOLDER: $outdir (folder already exist)" 
else
 mkdir -p $outdir
 echo -e "\n\tOUTPUT FOLDER : $outdir (folder created)"
fi
if [ -d $fastqdir ]; then
 echo -e "\n\tOUTPUT FOLDER: $fastqdir (folder already exist)" 
else
 mkdir -p $fastqdir 
 echo -e "\n\tOUTPUT FOLDER : $fastqdir (folder created)"
fi
if [ -d $samdir ]; then
 echo -e "\n\tOUTPUT FOLDER: $samdir (folder already exist)" 
else
 mkdir -p $samdir 
 echo -e "\n\tOUTPUT FOLDER : $samdir (folder created)"
fi
if [ -d $bamdir ]; then
 echo -e "\n\tOUTPUT FOLDER: $bamdir (folder already exist)" 
else
 mkdir -p $bamdir 
 echo -e "\n\tOUTPUT FOLDER : $bamdir (folder created)"
fi
if [ -d $vcfdir ]; then
 echo -e "\n\tOUTPUT FOLDER: $vcfdir (folder already exist)" 
else
 mkdir -p $vcfdir 
 echo -e "\n\tOUTPUT FOLDER : $vcfdir (folder created)"
fi
if [ -d $scriptdir ]; then
 echo -e "\n\tOUTPUT FOLDER: $scriptdir (folder already exist)" 
else
 mkdir -p $scriptdir 
 echo -e "\n\tOUTPUT FOLDER : $scriptdir (folder created)"
fi
chmod -R 777 $outdir

#----------------------------------------------------------------------#
#---------------------------PIPELINE BEGIN-----------------------------#
#----------------------------------------------------------------------#

#--0--#
#Si Run issus du GAIIx et Data rangé selon architecture CASAVA
#Fusionne les FASTQ issus du démultiplexage et créé la liste des échantillons à annalyser
if [ -z ${runFolder+x} ]; 
then #Si pas CASAVA
	echo -e "\n#--0--#";
	echo -e "\tData not organised with a CASAVA Struture";
	####CAMILLE
	#Create realignment target
	#### NB When analysing large samples, 
	####-----------------------------------
	#### only focus on known indel sites for realignments and use the same target_interval.list for all individuals, 
	#### only needs to be done once for each update of known indel sites.
	   # time java -Xmx8g -jar $gatkdir/GenomeAnalysisTK.jar -T RealignerTargetCreator -nt 8 -R $refdir/$myref -known $refdir/$mills -known $refdir/$kGindels -o $outdir/target_intervals.list
else #Si CASAVA
	echo -e "\n#--0--#";
	echo -e "\tA CASAVA runFolder is set : Merge FASTQ"; 
	echo -e "\tCOMMAND: time source $pipedir/run_mergeFASTQ.sh";
	time source $pipedir/run_mergeFASTQ.sh #source permet de lancer un script dans le même bash
	#export listIndv=$scriptdir/listePatients.txt	
fi

#----------------------------------------------------------------------#
#--A--#PER SAMPLE ANALYSIS 
echo -e "\n#--A--#PER SAMPLE ANALYSIS"
	
	countsample=0;
	while read sample  
	do 
		export sample
		countsample=$(($countsample + 1))
		echo -e "\n#-----#SAMPLE $countsample: $sample"
		#--1--# Alignement
		if [ $doALN = "y" ]; 
		then  
			echo -e "\n\t#--1--# Alignement";
			echo -e "\tCOMMAND: time bash $pipedir/run_bwa.sh";
			time bash $pipedir/run_bwa.sh
		else
			echo -e "\n\tSKIP: #--1--# Alignement"
		fi

		#--2--# Clean Sam/Bam files with Picard
		if [ $doPIC = "y" ]; 
		then  
			echo -e "\n\t#--2--# Picard";
			echo -e "\tCOMMAND: time bash $pipedir/run_picard.sh";
			time bash $pipedir/run_picard.sh
		else
			echo -e "\n\tSKIP: #--2--# Picard"
		fi

		#--3--# Perform Realignment and BQSR according to GATK BP
		if [ $doREALN = "y" ]; 
		then  
			echo -e "\n\t#--3--# GATK REALIGN";
			echo -e "\tCOMMAND: time bash $pipedir/run_GATK_BPalign.sh";
			time bash $pipedir/run_GATK_BPalign.sh
		else
			echo -e "\n\tSKIP: #--3--# GATK REALIGN"
		fi
		
		#Si GATKversion >= v3
		if [ ${GATKversion:0:1} -ge 3 ] 
		then
			#--4--# Variant Calling
			if [ $doVC = "y" ]; 
			then  
				echo -e "\n\t#--4--# Variant Calling";
				echo -e "\tCOMMAND: time source $pipedir/run_GATK_BPcallSample.sh";
				time source $pipedir/run_GATK_BPcallSample.sh
			
				#Contruit l'argument d'input des gvcf pour l'étape #B#5#
				vcfarg="$vcfarg -V $vcfdir/$sample.raw.snps.indels.vcf"
								
				#rename les .bai en .bam.bai (pour les visualisateurs)
				rename .BQSR.bai .BQSR.bam.bai $bamdir/*.BQSR.bai
				
			else
				echo -e "\n\tSKIP: #--4--# Variant Calling"
			fi			
		fi
		
	done < $listIndv
	export countsample

#----------------------------------------------------------------------#
#--B--# PER PROJECT ANALYSIS: 
echo -e "\n#--B--#PER PROJECT ANALYSIS"

	#Si GATKversion < v3
	if [ ${GATKversion:0:1} -lt 3 ] 
	then
		#CAMILLE
		#--4--#
		#--5--#
		#Variant Calling and recalibration
		bash /opt/pipeline/run_GATK_BPCall.sh
	else
		#SOPHIE
		#--5--# Join Genotyping and recalibration
		if [ $doJOINGT = "y" ]; 
		then  		
			echo -e "\n#--5--# Join Genotyping and recalibration"
			export vcfarg #export argument gvcflist
			echo -e "$vcfarg"
			echo -e "\tCOMMAND: time source $pipedir/run_GATK_JoinGT-recal.sh";
			time source $pipedir/run_GATK_JoinGT-recal.sh
			
			if [ $doPhaseByTrans = "y" ]; 
			then
				echo -e "\n\t#--5b--# Phase By Transmission"
				echo -e "\t\tCOMMAND: time source $pipedir/run_GATK_JoinGT-recal.sh";
				time source $pipedir/run_GATK_PhaseByTrans.sh
			fi
			
		else
			echo -e "\nSKIP: #--5--# Join Genotyping and recalibration"
		fi	
	fi

if [ $analysisType = "Diag" ]; 
then #Si DIAG -> ANNOTATION AlamutHT
	
	#--C--#PER SAMPLE ANALYSIS 
	echo -e "\n#--C--#PER SAMPLE ANALYSIS"

	if [ $doANN = "y" ]; 
	then  
		#Prepare Output
		if [ -d $anndir ]; then
		 echo -e "\n\tOUTPUT FOLDER: $anndir (folder already exist)" 
		else
		 mkdir -p $anndir
		 echo -e "\n\tOUTPUT FOLDER : $anndir (folder created)"
		fi
		
		if [ -d $extractdir ]; then
		 echo -e "\n\tOUTPUT FOLDER: $extractdir (folder already exist)" 
		else
		 mkdir -p $extractdir
		 echo -e "\n\tOUTPUT FOLDER : $extractdir (folder created)"
		fi
		
		countsample=0;
		while read sample  
		do 
			export sample
			countsample=$(($countsample + 1))
			echo -e "\n#-----#SAMPLE $countsample: $sample"
			#--6--#VCF split per Sample (En conservant GT 0/0) & Annotation
			echo -e "\n\t#--6--# Annotation:";
			echo -e "\tCOMMAND: time source $pipedir/run_GATK-alamutHT.sh";
			time source $pipedir/run_GATK-alamutHT.sh

		done < $listIndv
					
		#--7--#Rapport
		echo -e "\n\t#--7a--#Extract";	
			#--7a--#Extract
			echo -e "\tCOMMAND: time source $pipedir/run_extract.sh -i $runFolder/$anndir -o $runFolder/$extractdir -nm $refdir/$nmList -bt $bedtoolsdir -bed $refdir/$targetsDiagExtract";
			time source $pipedir/run_extract.sh -i $anndir -o $extractdir -nm $refdir/$nmList -bt $bedtoolsdir -bed $refdir/$targetsDiagExtract
			#--7c--#Rapport
			#-> Join et Rapport commun lancé par le script runMaster_CASAVA.sh	
	else
		echo -e "\nSKIP: #--6--# Annotation"
	fi
	
	if [ $doQUAL = "y" ]; 
	then  
		if [ -d $depthdir ]; then
		 echo -e "\n\tOUTPUT FOLDER: $depthdir (folder already exist)" 
		else
		 mkdir -p $depthdir
		 echo -e "\n\tOUTPUT FOLDER : $depthdir (folder created)"
		fi
		if [ -d $joinDir ]; then
		 echo -e "\n\tOUTPUT FOLDER: $joinDir (folder already exist)" 
		else
		 mkdir -p $joinDir
		 echo -e "\n\tOUTPUT FOLDER : $joinDir (folder created)"
		fi
	
			#--7b--#Quality
			echo -e "\n\t#--7b--#Quality";	
			#Depth#
			echo -e "\tCOMMAND: time source $pipedir/run_depthDiagGATK.sh -i $bamdir -o $depthdir -bed $refdir/$targets";
			time source $pipedir/run_depthDiagGATK.sh -i $bamdir -o $depthdir -bed $refdir/$targets
			#PrepareRapport#			
			echo -e "\tCOMMAND: time source $pipedir/run_prepareRapportQualGATK.sh -i $depthdir -o $joinDir -bed $refdir/$targetsDiag";
			time source $pipedir/run_prepareRapportQualGATK.sh -i $depthdir -o $joinDir -bed $refdir/$targetsDiag
			touch $joinDir/"qual.completed"
	else
		echo -e "\nSKIP: #--6--# Quality"
	fi	
	
elif [ $analysisType = "Exome" ]; 	
then
	echo -e "\n#--C--#PER SAMPLE ANALYSIS"
	echo -e "\n\t#--6--# Annotation:";
	#~ echo -e "\tANNOVAR not yet implemented in this script (launch separately) see autoAnnot/run_AnnotExome.sh";
	echo -e "\n\tANNOVAR + EVANNOT:"
	echo -e "\n\tCOMMAND: $pipedir/run_annotExome.sh -c GATK -t exome -a $Annovardir -i $runFolder -o $anndir"
	$pipedir/run_annotExome.sh -c GATK -t exome -a $Annovardir -i $vcfdir -o $anndir
else
	echo -e "\nAnalysis type not recognised: speciffy 'Diag' or 'Exome'";
fi

date
echo -e "\n#----------------------------PIPELINE END------------------------------#";
		
#----------------------------------------------------------------------#
#----------------------------PIPELINE END------------------------------#
#----------------------------------------------------------------------#


#Notes temps calculs (PC Sophie)
##Diag Colon
	#--A--#PER SAMPLE ANALYSIS (temps pour 1 patient Diag)
		#--0--#Fusion Fastq
			#~ real	0m17.776s
			#~ user	0m0.732s
			#~ sys	0m2.656s
		#--1--#BWA
			#~ real	4m11.870s
			#~ user	29m13.606s
			#~ sys	0m9.313s
		#--2--#PICARD
			#--a--#SORT SAM
			#--b--#Mark Duplicate
				#~ real	1m48.095s
				#~ user	2m55.867s
				#~ sys	0m7.836s
			#--c--#ReadGroup
				#~ real	1m23.711s
				#~ user	1m22.449s
				#~ sys	0m1.052s
			#--d--#BamIndex
				#~ real	0m17.569s
				#~ user	0m16.825s
				#~ sys	0m1.756s
		#--3--#GATK-bpAlign
			#--a--#Indel Realign
				#--1--#TargetCreator
					#~ real	0m12.556s
					#~ user	0m44.796s
					#~ sys	0m2.251s
				#--2--#Realigner
					#~ real	2m18.213s
					#~ user	3m9.172s
					#~ sys	0m5.328s
			#--b--#BQSR
				#~ real	6m29.410s
				#~ user	12m29.899s
				#~ sys	0m20.733s
			#--c--#Apply BQSR
				#~ real	3m15.893s
				#~ user	18m44.282s
				#~ sys	0m35.122s
		#--4--#GATK-bpCallSample
			#~ real	6m19.302s
			#~ user	6m44.133s
			#~ sys	0m1.552s
	#--B--#PER PROJECT ANALYSIS (1 seul fichier, pas informatif)
		#--5--#Join genotyping &  VQSR
			#--a--#Join Genotyping
				#~ real	0m6.495s
				#~ user	0m10.533s
				#~ sys	0m0.280s
			#--b--#Recalibration (VQSR)
				#~ Pas si diag (impossible avec petite target Diag)
#~ Si Diag :
	#--C--#PER SAMPLE ANALYSIS 
		#--6--#Annotation
			#--a--# VCF split per Sample  (En conservant GT 0/0)
			#--b--# Annotation (alamutHT)
			#~ real	0m13.854s
			#~ user	0m3.268s
			#~ sys	0m3.704s
		#--9--#Rapport

