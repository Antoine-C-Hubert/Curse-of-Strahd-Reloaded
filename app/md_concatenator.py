#!/usr/bin/env python3

import os
import glob
import sys
from pathlib import Path
from tqdm import tqdm

# Set project root and translation paths
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
TRANSLATIONS_DIR = os.path.join(project_root, "translations")
SPLITS_TRANSLATED_DIR = os.path.join(TRANSLATIONS_DIR, "splits_translated")
TRANSLATED_GROUPED_DIR = os.path.join(TRANSLATIONS_DIR, "translated_grouped")

def concatenate_markdown_files(base_dir=None):
    """
    Find all folders starting with 'Act' or 'Arc', enter each folder,
    and concatenate all markdown files into a single file.
    The concatenated file is saved to translations/translated_grouped/ with the folder's name.
    
    Args:
        base_dir (str, optional): Base directory to search for Act/Arc folders.
                                 If None, uses SPLITS_TRANSLATED_DIR.
    """
    if base_dir is None:
        base_dir = SPLITS_TRANSLATED_DIR
    
    # Create output directory if it doesn't exist
    os.makedirs(TRANSLATED_GROUPED_DIR, exist_ok=True)
        
    # Find all folders starting with Act or Arc
    act_arc_pattern = os.path.join(base_dir, '**/[Aa][cr][tc]*')
    matching_folders = [f for f in glob.glob(act_arc_pattern, recursive=True) if os.path.isdir(f)]
    
    if not matching_folders:
        print(f"No folders starting with 'Act' or 'Arc' found in {base_dir}")
        return
    
    print(f"Found {len(matching_folders)} Act/Arc folders")
    
    # Process each folder
    for folder in matching_folders:
        folder_name = os.path.basename(folder)
        output_file = os.path.join(TRANSLATED_GROUPED_DIR, f"{folder_name}.md")
        
        # Get all markdown files in the folder
        markdown_files = sorted(glob.glob(os.path.join(folder, "*.md")))
        
        if not markdown_files:
            print(f"No markdown files found in {folder}")
            continue
        
        print(f"Concatenating {len(markdown_files)} files from {folder_name} into {output_file}")
        
        # Concatenate files
        with open(output_file, 'w', encoding='utf-8') as outfile:
            for file_path in tqdm(markdown_files, desc=f"Processing {folder_name}"):
                with open(file_path, 'r', encoding='utf-8') as infile:
                    content = infile.read()
                    # Add a newline at the end of each file if not present
                    if content and not content.endswith('\n'):
                        content += '\n'
                    outfile.write(content)
        
        print(f"Created {output_file}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        base_dir = sys.argv[1]
        if not os.path.isdir(base_dir):
            print(f"Error: Directory '{base_dir}' does not exist.")
            sys.exit(1)
        print(f"Using custom base directory: {base_dir}")
        concatenate_markdown_files(base_dir)
    else:
        print(f"Using default base directory: {SPLITS_TRANSLATED_DIR}")
        concatenate_markdown_files()
    
    print(f"Concatenation complete. Files saved to {TRANSLATED_GROUPED_DIR}")