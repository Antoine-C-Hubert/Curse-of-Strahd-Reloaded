#!/usr/bin/env python3

import os
import glob
import sys
from pathlib import Path
from tqdm import tqdm

def concatenate_markdown_files(base_dir=None):
    """
    Find all folders starting with 'Act' or 'Arc', enter each folder,
    and concatenate all markdown files into a single file.
    The concatenated file is saved outside the folder with the folder's name.
    
    Args:
        base_dir (str, optional): Base directory to search for Act/Arc folders.
                                 If None, uses the current directory.
    """
    if base_dir is None:
        base_dir = os.getcwd()
        
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
        parent_dir = os.path.dirname(folder)
        output_file = os.path.join(parent_dir, f"{folder_name}.md")
        
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
        concatenate_markdown_files(base_dir)
    else:
        concatenate_markdown_files()
    
    print("Concatenation complete.")