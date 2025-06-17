#!/bin/bash

# Display banner
echo "
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|      ..| search crt.sh v 2.0 |..    |
+                                     +
|             Piyush  recon           |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
"

# Function: Help
# Purpose: Display the help message with usage instructions.
Help() {
    echo "Options:"
    echo ""
    echo "-h     Help"
    echo "-d     Search Domain Name       | Example: $0 -d hackerone.com"
    echo "-o     Search Organization Name | Example: $0 -o hackerone+inc"
    echo ""
}

# Function: CleanResults
# Purpose: Clean and filter the results by removing unwanted characters and duplicates.
# - Converts escaped newlines to actual newlines.
# - Removes wildcard characters (*).
# - Filters out email addresses.
# - Sorts the results and removes duplicates.
CleanResults() {
    sed 's/\\n/\n/g' | \
    sed 's/\*.//g' | \
    sed -r 's/([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4})//g' | \
    sort | uniq
}

# Function: ValidateJSON
# Purpose: Check if the response is valid JSON
ValidateJSON() {
    echo "$1" | jq -e . >/dev/null 2>&1
}

# Function: Domain
# Purpose: Search for certificates associated with a specific domain name.
Domain() {
    # Check if the domain name is provided
    if [ -z "$req" ]; then
        echo "Error: Domain name is required."
        exit 1
    fi

    # Perform the search request to crt.sh with proper User-Agent
    response=$(curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
        "https://crt.sh?q=%.$req&output=json")

    # Check if curl failed
    if [ $? -ne 0 ]; then
        echo "Error: Failed to connect to crt.sh"
        exit 1
    fi

    # Check if the response is empty
    if [ -z "$response" ]; then
        echo "No results found for domain $req"
        exit 1
    fi

    # Validate JSON response
    if ! ValidateJSON "$response"; then
        echo "Error: crt.sh returned invalid response. This usually happens when:"
        echo "1. The service is blocking your requests (try again later)"
        echo "2. The domain doesn't exist in their database"
        echo "3. You need to use a VPN"
        echo ""
        echo "You can try manually visiting: https://crt.sh/?q=%.$req"
        exit 1
    fi

    # Process the response
    results=$(echo "$response" | jq -r ".[].common_name,.[].name_value" | CleanResults)

    # Check if there are any valid results after cleaning
    if [ -z "$results" ]; then
        echo "No valid results found for domain $req"
        exit 1
    fi

    # Create output directory if it doesn't exist
    mkdir -p output

    # Define the output file name
    output_file="output/domain.$req.txt"

    # Save the results
    echo "$results" > "$output_file"

    # Display results
    echo ""
    echo "$results"
    echo ""
    echo -e "\e[32m[+]\e[0m Found \e[31m$(echo "$results" | wc -l)\e[0m unique domains"
    echo -e "\e[32m[+]\e[0m Output saved to $output_file"
}

# Function: Organization
# Purpose: Search for certificates associated with a specific organization name.
Organization() {
    # Check if the organization name is provided
    if [ -z "$req" ]; then
        echo "Error: Organization name is required."
        exit 1
    fi

    # Perform the search request to crt.sh with proper User-Agent
    response=$(curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
        "https://crt.sh?q=$req&output=json")

    # Check if curl failed
    if [ $? -ne 0 ]; then
        echo "Error: Failed to connect to crt.sh"
        exit 1
    fi

    # Check if the response is empty
    if [ -z "$response" ]; then
        echo "No results found for organization $req"
        exit 1
    fi

    # Validate JSON response
    if ! ValidateJSON "$response"; then
        echo "Error: crt.sh returned invalid response for organization '$req'"
        echo "You can try manually visiting: https://crt.sh/?q=$req"
        exit 1
    fi

    # Process the response
    results=$(echo "$response" | jq -r ".[].common_name" | CleanResults)

    # Check if there are any valid results after cleaning
    if [ -z "$results" ]; then
        echo "No valid results found for organization $req"
        exit 1
    fi

    # Create output directory if it doesn't exist
    mkdir -p output

    # Define the output file name
    output_file="output/org.$req.txt"

    # Save the results
    echo "$results" > "$output_file"

    # Display results
    echo ""
    echo "$results"
    echo ""
    echo -e "\e[32m[+]\e[0m Found \e[31m$(echo "$results" | wc -l)\e[0m unique domains"
    echo -e "\e[32m[+]\e[0m Output saved to $output_file"
}

# Main Script Logic
if [ -z "$1" ]; then
    Help
    exit
fi

# Parse command-line options
while getopts "h:d:o:" option; do
    case $option in
        h) Help ;;
        d) 
            req=$OPTARG
            Domain
            ;;
        o) 
            req=$OPTARG
            Organization
            ;;
        *) Help ;;
    esac
done
