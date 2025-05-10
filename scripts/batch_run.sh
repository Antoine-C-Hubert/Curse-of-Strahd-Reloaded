#!/bin/bash

# Script to process all files listed in files_list.txt through the translation workflow

# Check if files_list.txt exists
if [ ! -f "files_list.txt" ]; then
    echo "Error: files_list.txt not found in the current directory"
    exit 1
fi

echo "Starting batch processing of files..."

# Read each line from files_list.txt, removing line numbers if present
while IFS= read -r line; do
    # Remove line number if present (assumes tab separation)
    file_path=$(echo "$line" | sed -E 's/^[0-9]+\s+//')
    
    # Skip empty lines
    if [ -z "$file_path" ]; then
        continue
    fi
    
    echo "---------------------------------------"
    echo "Processing: $file_path"
    echo "---------------------------------------"
    
    # First cleanup temp directories
    rm -rf tmp/temp_splits_* tmp/temp_pdfs_* 2>/dev/null || true
    
    # Run the translation workflow on this file (even page count is now the default)
    ./scripts/run.sh "$file_path"
    
    # Optional: add a small delay between files
    sleep 1
done < files_list.txt

echo "Batch processing complete!"