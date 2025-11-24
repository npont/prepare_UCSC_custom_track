import requests
import re
import os

#################################### Parameters User Dependant ######################################
data_path="name_DNA_experiment/06_bed_dcm/"
API_KEY = '' #from Galaxy, Private
HISTORY_ID = '' #ID of Galaxy repository (in Galaxy, repo are called Histories) #get it with galaxy-history-search --api-key <api_key_here> --url https://usegalaxy.org
GALAXY_URL = 'https://usegalaxy.org'
INPUT_HUB_FILE = data_path+'hub.txt' #output of prepare_UCSC_genome_browser.sh
OUTPUT_HUB_FILE = data_path+'final_hub.txt' #similar to hub.txt but with the Galaxy files URL added
#######################################################################################################





# Step 1: Get all bigWig datasets from Galaxy
headers = {'x-api-key': API_KEY}
history_url = f'{GALAXY_URL}/api/histories/{HISTORY_ID}/contents'
response = requests.get(history_url, headers=headers)
datasets = response.json()


bigwig_map = {}
for ds in datasets:
    if ds['extension'] == 'bigwig':
        name = ds['name'].replace(' ', '_')  # Normalize for matching
        url = f'{GALAXY_URL}/api/datasets/{ds["id"]}/display?to_ext=bigwig'
        bigwig_map[name] = url


# Step 2: Parse the existing hub.txt and inject bigDataUrls
output_lines = []
current_track = None

with open(INPUT_HUB_FILE) as f:
    for line in f:
        track_match = re.match(r'^track\s+(\S+)', line)
        if track_match:
            current_track = track_match.group(1)
            output_lines.append(line)
            continue

        if line.strip().startswith('bigDataUrl'):
            if current_track:
                # Normalize current track name to match Galaxy names
                norm_track = current_track.replace('bigWig_', '')+".bw"
                if norm_track in bigwig_map:
                    output_lines.append(f'bigDataUrl {bigwig_map[norm_track]}\n')
                else:
                    output_lines.append('bigDataUrl MISSING_URL\n')
            else:
                output_lines.append('bigDataUrl MISSING_URL\n')
            continue

        output_lines.append(line)

# Step 3: Write new hub.txt
with open(OUTPUT_HUB_FILE, 'w') as f:
    f.writelines(output_lines)

print(f"✅ Updated hub file written to {OUTPUT_HUB_FILE}")

