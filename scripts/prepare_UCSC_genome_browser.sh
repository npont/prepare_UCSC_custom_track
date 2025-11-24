#!/bin/bash

#SBATCH -J prepare_UCSC
#SBATCH --mem=4000
#SBATCH -t 2:00:00
#SBATCH -o output_prepare_UCSC
#SBATCH -e error_prepare_UCSC

############################ Script to prepare files for the UCSC genome browser #################


##################### Parameters User Dependent  #######################

name_experiment="name_DNA_experiment"
file_of_samples_to_upload_to_ucsc="samples_names.txt" # each row should contain a sample name that we want to upload to UCSC Genome Browser 

bed_directory="" #directory containing the bed files
chrom_sizes="/path_to_chrom_size_file/danRer11.chrom.sizes"
# hub = True if using the connected hub with Galaxy; otherwise False if using custom annotation track of UCSC Genome Browser
hub="True"

# Colors for the Tracks on UCSC Genome Browser
# Tracks are coloured according to the single/bulk and Dcm/noDcm (our experimental conditions)
color_ss_Dcm="70,157,243" #Light Blue
color_ss_noDcm="153,72,235" #Light violet
color_mb_Dcm="0,60,120" #Dark Blue
color_mb_noDcm="86,0,172" #Dark violet

###########################################################################




hub_file="hub_${file_of_samples_to_upload_to_ucsc}"
# Add a header if uploading the bedGraph file to UCSC genome browser manually in CUstom Track
# Or remove header if the bedGraph is further converted to a bigWig file that we upload to the Hub of UCSC using a hub.txt file
add_header="False" # False if hub=True

# Exit immediately if a command fails
set -e

cd ${bed_directory}

mkdir -p "bedGraph_for_UCSC_genome_browser"
mkdir -p "bigWig_for_UCSC_genome_browser" 

### Unzip bed files ###
while read sample; do 
	for bed_file in *"${sample}"*.bed.gz; do
		if [[ -f "$bed_file" ]]; then
			echo "Unzipping $bed_file";
			gunzip "$bed_file";
		else
			echo "No matching file for sample $sample"
		fi
	done
done < ${file_of_samples_to_upload_to_ucsc}



### Generate bedGraph files ###
while read sample; do
	## Color Assignment ##
	IFS='_' read -r part1 part2 part3 part4 rest <<< "$sample"
	if [[ "$part2" == "ss" && "$part4" == "Dcm" ]]; then
		color="${color_ss_Dcm}"
	elif [[ "$part2" == "ss" && "$part4" == "noDcm" ]]; then
		color="${color_ss_noDcm}"
	elif [[ "$part2" == "mb" && "$part4" == "Dcm" ]]; then
		color="${color_mb_Dcm}"
	else
		color="${color_mb_noDcm}"
	fi
	
	header="track type=bedGraph name='DCMmeth_${sample}' description='DCM methylation ratio' visibility=full color=${color} useScore=1 autoScale=off viewLimits=0:1"

	output_file="bedGraph_for_UCSC_genome_browser/${sample}.bedGraph"
	
	## Generate bedGraph file from bed file ##
	for bed_file in "${sample}"_S*.bed; do
		if [[ -f "$bed_file" ]]; then
			# Add header if custom track annotation
			if [ "$add_header" == "True" ]; then
				echo -e "${header}" > "$output_file"
			fi
			
			tmp_file="tmp_file"
			
			awk 'BEGIN{OFS="\t"} 
			{
				chr = ($1 == "MT") ? "chrM" : ($1 ~ /^(KN|KZ)/) ? "chrUn_"$1 : "chr"$1; 
				print chr,$2-1,$3,$4
			}' "$bed_file" >> $tmp_file
			
			awk 'BEGIN{OFS="\t"}
			{
				sub(/\.1$/, "v1", $1); 
				sub(/\.2$/, "v2", $1); 
				print
			}' $tmp_file >> $output_file

			rm $tmp_file
		else
			echo "${bed_file} not found"
		fi
	done
done < ${file_of_samples_to_upload_to_ucsc}

### Convert bedGraph to BigWig ###
chrom_sizes_file=${chrom_sizes}
cd bedGraph_for_UCSC_genome_browser/
output_bw_dir="../bigWig_for_UCSC_genome_browser/"
for file in *.bedGraph; do
	base="${file%.bedGraph}"
	echo "Generating ${base}.bw"
	bedGraphToBigWig $file $chrom_sizes_file "${output_bw_dir}${base}.bw" 
done


### Zip the bed files ###
cd ${bed_directory}
shopt -s nullglob #Tells the loop not to run if the pattern *.bed is not matched by any file. Safer.
for file in *.bed; do
    gzip "${file}"
done


### Remove the bedGraph files if using bigWig files ###
if [[ "$hub" == "True" ]]; then
	rm -r bedGraph_for_UCSC_genome_browser/
	## Create the hub text file, with following header ##
	cat <<EOF > "$hub_file"
hub "${name_experiment}_Naomie"
shortLabel $name_experiment
longLabel Hub for DCM methylation data of $name_experiment
useOneFile on
email genome-www@soe.ucsc.edu

genome danRer11

EOF
	cd bigWig_for_UCSC_genome_browser/
	for file in *.bw; do
		sample="${file%.bw}"
		IFS='_' read -r part1 part2 part3 part4 rest <<< "$sample"                                                 
		case "${part2}_${part4}" in
                        ss_Dcm)
                                color="${color_ss_Dcm}"
                                ;;
                        ss_noDcm)
                                color="${color_ss_noDcm}"
                                ;;
                        mb_Dcm)
                                color="${color_mb_Dcm}"
                                ;;
                        mb_noDcm)
                                color="${color_mb_noDcm}"
                                ;;
                esac
		cat <<EOF >> "../$hub_file"
track bigWig_${sample}
visibility full 
color $color
useScore 1 
autoScale off 
viewLimits 0:1
shortLabel $sample
longLabel $sample
type bigWig
visibility pack
bigDataUrl 

EOF
		done
fi




