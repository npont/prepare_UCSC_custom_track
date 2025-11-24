# Upload Tracks onto UCSC Genome Browser 
This repository contains scripts to prepare the data to be loaded onto UCSC genome browser. It is a special case in which we want to display DCM binding sites and their binding score onto the Zebrafish genome. I made it as most generic as possible to be adapted to any type of data. 
Genome at use: Danio rerio (Zebrafish). Just upload the correct chrom.sizes file for your genome of interest.

# Workflow
## Prepare the conda environments
Activate those environments from the yml files:
- environment_1 (it contains many libraries not needed here, but it's my common environment used on scNMT-seq data, might be optional)
- galaxy-upload (required)
## Prepare input files
Create a text file where each row contains the name of the sample to be uploaded onto the browser
Place the latter file in the directory containing the bed files 

## Code part
- conda activate environment_1
- Run prepare_UCSC_genome_browser.sh after replacing paths properly under section ### User Dependent ###
The latter will create a directory bigWig_for_UCSC_genome_browser/ containing the files that will be uploaded to Galaxy (and then shown on UCSC Genome Browser)
- Check "hub_${file_of_samples_to_upload_to_ucsc}“ in bed files directory & if you ran prepare_UCSC_genome_browser.sh on several sample_names.txt, then the last hub text file generated contains everything so just do mv <last_hub_file_created> hub.txt
- Go to Galaxy, connect and create a new History (=a folder) and name it (no constraint on naming, free)
- conda activate galaxy-upload
- Get the history id through typing the following in terminal:
galaxy-history-search --api-key <galaxy_api_key> --url https://usegalaxy.org 
- Go to bed file directory/bigWig_for_UCSC_genome_browser/ and run the following by replacing the history-id:
for file in *.bw; do
galaxy-upload --history-id <history_id> --url https://usegalaxy.org --api-key <galaxy_api_key> $file
done
- The latter uploaded our files to Galaxy
- Run: python add_GalaxyURL_to_hub.py #after replacing properly the paths inside
(the later will add the links of the files into final_hub.txt)
- Run the following from the bed files directory:
galaxy-upload --history-id <history_id> --url https://usegalaxy.org --api-key <galaxy_api_key> final_hub.txt
- Finally, go to https://genome.ucsc.edu/cgi-bin/hgHubConnect?hgsid=2789695104_J4iqtvzVWqyVN637NYSbko1A6JlT  “Connected Hubs” and connect the hub by pasting its URL (copied from Galaxy website by clicking on final_hub.txt and copy the chain symbol) and save it in my session
