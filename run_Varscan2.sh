#!/bin/bash
#
# Sophie COUTANT
# 22/06/2015

#Pour le matched normal
#PICARD MergeSamFile pour fusionner un bam témoin.
#java -jar /opt/PICARD/MergeSamFiles.jar `cat bam.list` O=PoolNorm.bam USE_THREADING=True

# usage
function usage
{
	echo "#------------------------------------------------------------------------------------------------------------------------------------------------------------#"
	echo "# Ce script permet le lancement du variant caller Somatic VarScan2                                                                                           #"
	echo "# Etape:                                                                                                                                                     #"
	echo "# 1- Convertir les bam en pileup                                                                                                                             #"
	echo "# 2- Lancer VarScan2                                                                                                                                         #"
	echo "# 3-a- reformater les vcf output pour les rendre compatible avec GATK                                                                                         #"
	echo "# 3-b- Fusionner les output vcf snp et indel en 1 seul en utilisant gatk combineVariants                                                                      #"
	echo "# 4- Annoter les variants avec alamutHT                                                                                                                      #"
	echo "#------------------------------------------------------------------------------------------------------------------------------------------------------------#"
	echo " "
	echo "USAGE: run_VarScan2.sh -runFold <dir> -bamDir <dir> -ref <file> [-norm <file>] -outDirVCF <dir> outDirANN <dir> -varscan <dir> -gatk <dir> -alamutBatchPath <dir>" 
	echo "	-runFold <path to the run folder>"
	echo "	-bamDir <path to the Bam folder relatively to runFolder>"
	echo "	-ref <path to the reference genome file>"
	echo "	-norm [optional] <path to the pooled generated normal bam file>"
	echo "	-outDirVCF <path to vcf outpur folder relativelt to runFolder>"
	echo "	-outDirANN <path to ann outpur folder relativelt to runFolder>"
	echo "	-varscan <path to the varscan tool folder>"
	echo "	-gatk <path to the gatk tool folder>"
	echo "	-alamutBatchPath <path to the alamutBatch tool folder>"
	echo "EXAMPLE: /opt/pipeline_NGS/Pipeline-BWA-GATK/run_Varscan2.sh -runFold /storage/crihan-msa/RunsPlateforme/MiSeq/150416_M02807_0012_000000000-D0CDB -bamDir BWA-GATK_EGFR/BAM -ref /storage/crihan-msa/RunsPlateforme/Reference/Homo_sapiens/hg19/human_g1k_v37.fasta -norm /storage/crihan-msa/RunsPlateforme/Reference/Amplicon/EGFRreads_B1_1000000x151bp.sorted.dedup.bam -outDirVCF BWA-GATK_EGFR/VarScan2 -outDirANN BWA-GATK_EGFR/VarScan2/ANN -varscan /opt/VARSCAN -gatk /opt/GATK -alamutBatchPath /opt/alamutHT"
	echo -e "\nREQUIREMENT: Samtools, VarScan2, GATK and AlamutHT doivent etre installe"
	echo " "
}

# get the arguments of the command line
if [ $# -lt 16 ]; then
	usage
	exit
else
	while [ "$1" != "" ]; do
	    case $1 in
		-runFold | --runFold )         shift
			if [ "$1" != "" ]; then
				#Run folderPath path
				runFold=$1
			else
				usage
				exit
			fi
						;;
		-bamDir | --bamDir )         shift
			if [ "$1" != "" ]; then
				bamDir=$1
			else
				usage
				exit
			fi
						;;
		-ref | --ref )         shift
			if [ "$1" != "" ]; then
				ref=$1
			else
				usage
				exit
			fi
						;;	
		-norm | --norm )         shift
			if [ "$1" != "" ]; then
				norm=$1
			else
				usage
				exit
			fi
						;;
		-outDirVCF | --outDirVCF )         shift
			if [ "$1" != "" ]; then
				outDirVCF=$1
			else
				usage
				exit
			fi
						;;	
		-outDirANN | --outDirANN )         shift
			if [ "$1" != "" ]; then
				outDirANN=$1
			else
				usage
				exit
			fi
						;;	
		-varscan | --varscan )    	shift
					if [ "$1" != "" ]; then
						varscan=$1
					else
						usage
						exit
					fi
						;;
		-gatk | --gatk )    	shift
					if [ "$1" != "" ]; then
						gatk=$1
					else
						usage
						exit
					fi
						;;
		-alamutBatchPath | --alamutBatchPath )    	shift
					if [ "$1" != "" ]; then
						alamutBatchPath=$1
					else
						usage
						exit
					fi
						;;						
	    esac
	    shift
	done
fi

echo -e "\tTIME: BEGIN RUN VARSCAN2".`date`

if [ -d $outDirVCF ]; 
then
	echo -e "\n\tOUTPUT FOLDER: $outDirVCF (folder already exist)" 
else
	mkdir -p $outDirVCF
	echo -e "\n\tOUTPUT FOLDER : $outDirVCF (folder created)"
fi
if [ -d $outDirANN ]; 
then
	echo -e "\n\tOUTPUT FOLDER: $outDirANN (folder already exist)" 
else
	mkdir -p $outDirANN
	echo -e "\n\tOUTPUT FOLDER : $outDirANN (folder created)"
fi

for file in `ls $bamDir | grep "BQSR.bam$"`;
do
	sample=$(echo $file | awk -F"." '{print $1}')
	echo -e "\n\tSample: $sample"; 

	#2 cas distincts : lancement paire sample/pool ou tum/norm
	if [ "$norm" != "" ];
	then
		#sample/pool
		echo -e "\n\tPooled Normal bam defined"
		if [ -f $norm".pileup" ];
		then
			echo -e "\tPooled Normal bam: $norm.pileup' (file already exist)";
		else
			echo -e "\tPooled Normal bam: convert to pileup"
			samtools mpileup -A -BQ0 -d10000000 -f $ref $norm > $norm".pileup";
		fi
		
		echo -e "\tSample bam to pileup: $runFold/$bamDir/$file"
		samtools mpileup -A -BQ0 -d10000000 -f $ref $runFold/$bamDir/$file > $runFold/$outDirVCF/$sample".pileup"
		
		echo -e "\n\tRun VarScan2"
		java -Xmx8g -jar $varscan/VarScan.v2.3.9.jar somatic $norm".pileup" $runFold/$outDirVCF/$sample".pileup" $runFold/$outDirVCF/$sample"_VarScan2.vcf" --output-vcf 1 --min-var-freq 0.01
	else
		#FIXME trouver une nomenclature si les échantillons sont pairés norm/tum
		#tum/norm
		echo "not yet supported : please specify a pooled normal sample"
		#~ echo -e "\n\tConvert sample normal bam to pileup"
		#~ if [ -f $runFold/$outDirVCF/$sample"_Norm.pileup" ];
		#~ then
			#~ echo -e "\tNormal bam: $sample'_Norm.pileup' (file already exist)";
		#~ else
			#~ echo -e "\tNormal bam"
			#~ samtools mpileup -A -BQ0 -d10000000 -f $ref $norm > $runFold/$outDirVCF/$sample"_Norm.pileup";
		#~ fi
		#~ 
		#~ echo -e "\tTumor bam"
		#~ samtools mpileup -A -BQ0 -d10000000 -f $ref $runFold/$bamDir/$file > $runFold/$outDirVCF/$sample"_Tum.pileup"
		#~ 
		#~ echo -e "\n\tRun VarScan2"
		#~ java -Xmx8g -jar $varscan/VarScan.v2.3.9.jar somatic $runFold/$outDirVCF/$sample"_Norm.pileup" $runFold/$outDirVCF/$sample"_Tum.pileup" $runFold/$outDirVCF/$sample"_VarScan2.vcf" --output-vcf 1 --min-var-freq 0.01
	fi
	
	#Varscan2 vcf files are malformed and not compatible with GATK. Reformating is needed:
	echo -e "\tReformat vcf file for GATK compatibility"
	TAB=$'\t'
	
	#snp
	cp $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp" $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp.backup" #backup du fichier original
	echo -e "\tSNP -- remove alternative alleles in the REF colomn"		#Supprime les alleles alternatifs dans la colonne reference
	sed -e '/\/[ACGT]\+'"${TAB}"'[ACGT]\+/s/\/[ACGT]\+//' $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp" > $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp.tmp1"
	echo -e "\tSNP -- replace / by , in the ALT column"					#Remplace le / par , dans la colonne ALT
	sed -e '/\/[ACGT]\+/s/\//,/' $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp.tmp1" > $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp.tmp2"
	cp $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp.tmp2" $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp"
	rm $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp.tmp1"
	rm $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp.tmp2"
	
	#indel
	cp $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel" $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.backup" #backup du fichier original
	echo -e "\tINDEL -- remove /+ACGT from the REF and ALT column"		#Supprime les A/+GT dans colonne REF ou ALT
	sed -e s/"\/[+][ACGT]\+"/""/ $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel" > $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp1"
	echo -e "\tINDEL -- remove /-ACGT from the REF and ALT column"		#Supprime les A/-GT dans colonne REF ou ALT
	sed -e s/"\/[-][ACGT]\+"/""/ $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp1" > $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp2"
	echo -e "\tINDEL -- remove alternative alleles from the REF column"	#Supprime les alleles alternatifs dans la colonne reference
	sed -e '/\/[ACGT]\+'"${TAB}"'[ACGT]\+/s/\/[ACGT]\+//' $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp2" > $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp3"
	echo -e "\tINDEL -- replace / by , in the ALT column"				#Remplace le / par , dans la colonne ALT
	sed -e '/\/[ACGT]\+/s/\//,/' $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp3" > $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp4"
	#il faut suprimer les alleles répétés 2 fois dans la colonnes ALT: exemple: AT,AT
	for motif in `grep -o --color "[ACGT]\+,[ACGT]\+" $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp4"`
	do
		al1=$(echo $motif | awk -F"," '{print $1}'); 
		al2=$(echo $motif | awk -F"," '{print $2}'); 
		if [ "$al1" == "$al2" ]; 
		then 
			echo -e "\tINDEL -- replace reapeating double ALT alleles by one. ex: AT,AT become AT"
			sed -e '/'"${motif}"'/s/,'"${al2}"'//' $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp4" > $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp5"
		fi
	done
	if [ -f $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp5" ];
	then
		cp $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp5" $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel"	#fichier reformaté
		rm $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp5"
	else
		cp $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp4" $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel"	#fichier reformaté
	fi
	rm $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp1"
	rm $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp2"
	rm $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp3"
	rm $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel.tmp4"

	
	echo -e "\n\tRun GATK CombineVariants"
	java -Xmx8g -jar $gatk/GenomeAnalysisTK.jar -T CombineVariants -R $ref --variant:snp $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp" --variant:indel $runFold/$outDirVCF/$sample"_VarScan2.vcf.indel" -o $runFold/$outDirVCF/$sample"_VarScan2.vcf" -genotypeMergeOptions PRIORITIZE -priority snp,indel
	
	#AlamutHT
		##INFO=<ID=AC,Number=A,Type=Integer,Description="Allele count in genotypes, for each ALT allele, in the same order as listed">
		##INFO=<ID=AF,Number=A,Type=Float,Description="Allele Frequency, for each ALT allele, in the same order as listed">
		##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles in called genotypes">
		##INFO=<ID=DP,Number=1,Type=Integer,Description="Total depth of quality bases">
		##INFO=<ID=SS,Number=1,Type=String,Description="Somatic status of variant (0=Reference,1=Germline,2=Somatic,3=LOH, or 5=Unknown)">
		##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">	
		##FORMAT=<ID=AD,Number=.,Type=Integer,Description="Allelic depths for the ref and alt alleles in the order listed">
		##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read Depth">
		##FORMAT=<ID=DP4,Number=1,Type=String,Description="Strand read counts: ref/fwd, ref/rev, var/fwd, var/rev">
		##FORMAT=<ID=FREQ,Number=1,Type=String,Description="Variant allele frequency">
		##FORMAT=<ID=GQ,Number=1,Type=Integer,Description="Genotype Quality">
		##FORMAT=<ID=RD,Number=1,Type=Integer,Description="Depth of reference-supporting bases (reads1)">
	echo -e "\nAlamut-batch - $sample"
	$alamutBatchPath/alamut-batch --in $runFold/$outDirVCF/$sample"_VarScan2.vcf" --ann $outDirANN/$sample"_VarScan2.ann" --unann $outDirANN/$sample"_VarScan2.unann" --alltrans --nonnsplice --nogenesplicer --ssIntronicRange 2 --outputVCFFilter --outputVCFQuality --outputVCFInfo AC AF AN DP SS --outputVCFGenotypeData GT AD DP DP4 FREQ GQ RD --outputEmptyValuesAs .
done

echo -e "\n\tTIME: END RUN VARSCAN2".`date`;


#~ sed -e s/"\/-"/","/ $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp" > $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp.tmp1"
	#~ sed -e s/"\/[+][ACGT]*"/""/ $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp.tmp1" > $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp.tmp2"
	#~ sed -e '/\/[ACGT]/s/\//,/' $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp.tmp2" > $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp.tmp3"
	#~ sed -e '/\,[ACGT]\+/s/,[ACGT]//' $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp.tmp3" > $runFold/$outDirVCF/$sample"_VarScan2.vcf.snp.tmp4"
	
#outil BBMap pour générer des randoms reads
#/opt/bbmap/randomreads.sh ref=/storage/crihan-msa/RunsPlateforme/Reference/Amplicon/EGFR_GRGh37.fa length=151 illuminanames=true reads=1000000 paired=true maxq=36 midq=32 minq=28 adderrors=true
#puis : BWA mem, picard sort et samtools index
