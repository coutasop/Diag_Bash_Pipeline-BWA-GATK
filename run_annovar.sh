#!/bin/bash
#
# Juliette AURY-LANDAS & Sophie COUTANT
# 11/07/2013
#
#------------------------------------------------------------------------------------------------------------------------------------------------------------#
# This script allows the automation of variants annotation using the ANNOVAR tool                                                                            #
# Wang K, Li M, Hakonarson H. ANNOVAR: Functional annotation of genetic variants from next-generation sequencing data, Nucleic Acids Research, 38:e164, 2010 #
#                                                                                                                                                            #
# 1- convert variant calling file (output of CASAVA, Samtools or GATK) to ANNOVAR input file                                                                 #
#    -> tab separated file: chromosome, start position, end position, reference nucleotides, observed nucleotides (+ other free optional columns)            #
# 2- variant annotation by ANNOVAR                                                                                                                           #
#------------------------------------------------------------------------------------------------------------------------------------------------------------#

# usage
function usage
{
    echo "USAGE: run_annovar.sh -a <directory> -i <directory> -o <directory>"
    echo "		 -a <annovar source directory>"
    echo "		 -i <input directory containing variant calling files (vcf)>"
    echo "		 -o <output directory for the annotated files>"
    echo "EXAMPLE: ./run_annovar.sh -a /home/me/Program/Annovar -i Project/VCF -o Project/Annotated"
}

# get the arguments of the command line
if [ $# -lt 3 ]; then
	usage
	exit
else
	while [ "$1" != "" ]; do
	    case $1 in
		-a | --annovar )         shift
					if [ "$1" != "" ]; then
						# Annovar scripts path
						annovarPath=$1
					else
						usage
						exit
					fi
		                        ;;
		                        
		-i | --iDirectory )    	shift
					if [ "$1" != "" ]; then
						inputDirectory=$1
					else
						usage
						exit
					fi
		                        ;;
		                        
		                        
		-o | --oDirectory )    	shift
					if [ "$1" != "" ]; then
						outputDirectory=$1
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

#Test if the output directory exists, if no, create it
if [ -d $outputDirectory ]; then
 echo -e "\n\tOUTPUT FOLDER: $outputDirectory (folder already exist)" 
else
 mkdir $outputDirectory 
 echo -e "\n\tOUTPUT FOLDER : $outputDirectory (folder created)"
fi


#format des fichiers vcf en input
fileExt=".vcf"

# initialisation des variables
chr=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y)

echo -e "\t TIME: BEGIN ANNOVAR ANNOTATION".`date`
for vcFile in `ls $inputDirectory/*$fileExt`; do #pour chaque fichier de variant calling contenu dans le répertoire
	fileName=${vcFile%.*} #nom du fichier sans sa dernière extension (ici: .vcf)
	sample=$(basename $fileName) #nom du fichier sans path et sans extention
	path=$(dirname $fileName) #nom du path, sans le fichier
	
	nbCol=$(tail -n 1 $vcFile | wc -w);
	if [ $nbCol != 10 ]; then
		fileFormat="vcf4old"	#multivcf File
	else
		fileFormat="vcf4"		#vcf with 1 sample
	fi
	echo -e "\n\t#FILE: $vcFile:"
	
	#------------------------------------------------------------------------------------------------------------------------------------------------------------#
	# 1- CONVERSION du fichier de variant calling (sortie de Casava, Samtools ou GATK) en fichier d'entrée d'Annovar
	echo -e "\t1- CONVERSION IN ANNOVAR INPUT"
	echo -e "\t#CMD: $annovarPath/convert2annovar.pl -format $fileFormat -includeinfo $vcFile > $fileName.avinput"
	$annovarPath/convert2annovar.pl -format $fileFormat -includeinfo $vcFile > $fileName.avinput

	#------------------------------------------------------------------------------------------------------------------------------------------------------------#
	# 2- ANNOTATIONS des variants par Annovar
	echo -e "\t2- ANNOTATION WITH ANNOVAR"
#OLD 2013 command	#~ echo -e "\t#CMD: $annovarPath/table_annovar.pl $fileName.avinput $annovarPath/humandb/ -buildver hg19 -protocol refGene,ljb2_all,cosmic64,esp6500si_ea,esp6500si_all,1000g2012apr_eur,1000g2012apr_all,snp137,snp137NonFlagged,cytoBand,wgRna -operation g,f,f,f,f,f,f,f,f,r,r -otherinfo -outfile $outputDirectory/$sample"
#OLD 2013 command	#~ $annovarPath/table_annovar.pl $fileName.avinput $annovarPath/humandb/ -buildver hg19 -protocol refGene,ljb2_all,esp6500si_ea,esp6500si_all,1000g2012apr_eur,1000g2012apr_all,snp137,snp137NonFlagged,wgRna -operation g,f,f,f,f,f,f,f,r -nastring . -argument '-hgvs -exonicsplicing -splicing_threshold 50',,,,,,,, -otherinfo -outfile $outputDirectory/$sample
#OLD 2014 command	echo -e "\t#CMD: $annovarPath/table_annovar.pl $fileName.avinput $annovarPath/humandb/ -buildver hg19 -protocol refGene,ljb26_all,esp6500si_ea,esp6500si_all,1000g2014oct_eur,1000g2014oct_all,exac02,snp138,snp138NonFlagged,wgRna -operation g,f,f,f,f,f,f,f,f,f,r,r -otherinfo -outfile $outputDirectory/$sample"
#OLD 2014 command	$annovarPath/table_annovar.pl $fileName.avinput $annovarPath/humandb/ -buildver hg19 -protocol refGene,ljb26_all,esp6500si_ea,esp6500si_all,1000g2014oct_eur,1000g2014oct_all,exac02,snp138,snp138NonFlagged,wgRna -operation g,f,f,f,f,f,f,f,f,r -nastring . -argument '-hgvs -exonicsplicing -splicing_threshold 50',,,,,,,,, -otherinfo -outfile $outputDirectory/$sample

#OLD 2015 command	echo -e "\t#CMD: $annovarPath/table_annovar.pl $fileName.avinput $annovarPath/humandb/ -buildver hg19 -protocol refGene,exac03,esp6500siv2_ea,esp6500siv2_all,1000g2014oct_eur,1000g2014oct_all,snp138,snp138NonFlagged,ljb26_all,wgRna -operation g,f,f,f,f,f,f,f,f,r -argument '-hgvs -otherinfo -splicing_threshold 2','-otherinfo',,,,,,,, -nastring . -otherinfo -outfile $outputDirectory/$sample"
#OLD 2015 command	$annovarPath/table_annovar.pl $fileName.avinput $annovarPath/humandb/ -buildver hg19 -protocol refGene,exac03,esp6500siv2_ea,esp6500siv2_all,1000g2014oct_eur,1000g2014oct_all,snp138,snp138NonFlagged,ljb26_all,wgRna -operation g,f,f,f,f,f,f,f,f,r -argument '-hgvs -otherinfo -splicing_threshold 2','-otherinfo',,,,,,,, -nastring . -otherinfo -outfile $outputDirectory/$sample

#OLD 2016 command	echo -e "\t#CMD: $annovarPath/table_annovar.pl $fileName.avinput $annovarPath/humandb/ -buildver hg19 -protocol refGene,popfreq_max_20150413,exac03,esp6500siv2_ea,esp6500siv2_all,1000g2015aug_eur,1000g2015aug_all,snp138,snp138NonFlagged,ljb26_all,wgRna -operation g,f,f,f,f,f,f,f,f,f,r -argument '-hgvs -otherinfo -splicing_threshold 2','-otherinfo',,,,,,,,, -nastring . -otherinfo -outfile $outputDirectory/$sample"
#OLD 2016 command	$annovarPath/table_annovar.pl $fileName.avinput $annovarPath/humandb/ -buildver hg19 -protocol refGene,popfreq_max_20150413,exac03,esp6500siv2_ea,esp6500siv2_all,1000g2015aug_eur,1000g2015aug_all,snp138,snp138NonFlagged,ljb26_all,wgRna -operation g,f,f,f,f,f,f,f,f,f,r -argument '-hgvs -otherinfo -splicing_threshold 2','-otherinfo',,,,,,,,, -nastring . -otherinfo -outfile $outputDirectory/$sample

	#2017 command
	echo -e "\t#CMD: $annovarPath/table_annovar.pl $fileName.avinput $annovarPath/humandb/ -buildver hg19 -protocol refGene,wgRna,intervar_20170202,clinvar_20170130,gnomad_genome,gnomad_exome,popfreq_max_20150413,exac03,esp6500siv2_all,1000g2015aug_all,avsnp147,dbnsfp33a,cadd13 -operation g,r,f,f,f,f,f,f,f,f,f,f,f,f -argument '-hgvs -otherinfo -splicing_threshold 2',,,,,,,,,,,, -nastring . -otherinfo -outfile $outputDirectory/$sample"
	$annovarPath/table_annovar.pl $fileName.avinput $annovarPath/humandb/ -buildver hg19 -protocol refGene,wgRna,intervar_20170202,clinvar_20170130,gnomad_genome,gnomad_exome,popfreq_max_20150413,exac03,esp6500siv2_all,1000g2015aug_all,avsnp147,dbnsfp33a,cadd13 -operation g,r,f,f,f,f,f,f,f,f,f,f,f,f -argument '-hgvs -otherinfo -splicing_threshold 2',,,,,,,,,,,, -nastring . -otherinfo -outfile $outputDirectory/$sample

	#suppression des fichiers intermédiaires créés par table_annovar.pl
	rm $outputDirectory/*function
	rm $outputDirectory/*log
	rm $outputDirectory/*dropped
	rm $outputDirectory/*filtered
	rm $outputDirectory/*wgRna

	echo -e "\t#DONE - #Output $outputDirectory/$sample.hg19_multianno.txt"
done
echo -e "\t TIME: END ANNOVAR ANNOTATION".`date`
