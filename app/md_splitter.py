#!/usr/bin/env python3

import os
import re
import sys
from pathlib import Path

# Set project root and translation paths
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
TRANSLATIONS_DIR = os.path.join(project_root, "translations")
SPLITS_DIR = os.path.join(TRANSLATIONS_DIR, "splits")

def split_markdown_file(file_path):
    """
    Split a markdown file into multiple files at each # and ## section.
    Text before the first heading is saved as the first file.
    Main sections will only contain content up to the first subsection.
    Each subsection will be in its own file.
    
    Args:
        file_path (str): Path to the markdown file to split
    """
    # Read the input file
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Get the base name without extension for output directory
    base_name = os.path.basename(file_path)
    file_name_no_ext = os.path.splitext(base_name)[0]
    
    # Create output directory in the translations/splits/ folder
    output_dir = os.path.join(SPLITS_DIR, file_name_no_ext)
    os.makedirs(output_dir, exist_ok=True)
    
    # Find all level 1 (# Title) sections
    level1_pattern = r'(?m)^# (.+?)$'
    level1_matches = list(re.finditer(level1_pattern, content))
    
    if not level1_matches:
        print(f"No level 1 headers found in {file_path}")
        return
    
    # Check if there's content before the first heading
    if level1_matches[0].start() > 0:
        # Extract text before the first heading
        intro_content = content[:level1_matches[0].start()]
        
        if intro_content.strip():  # Only save if there's actual content
            intro_file_path = os.path.join(output_dir, "000-Introduction.md")
            with open(intro_file_path, 'w', encoding='utf-8') as f:
                # Add original filename as main title
                f.write(f"# {file_name_no_ext}\n\n")
                f.write(intro_content)
            print(f"Created {intro_file_path}")
    
    # Process each level 1 section
    for i, match in enumerate(level1_matches):
        # Get the title and sanitize it for use as a filename
        title = match.group(1).strip()
        safe_title = re.sub(r'[^\w\s-]', '', title).strip().replace(' ', '_')
        
        # Determine the start and end position of this section
        start_pos = match.start()
        end_pos = len(content)
        if i < len(level1_matches) - 1:
            end_pos = level1_matches[i + 1].start()
        
        # Extract the entire section content (including subsections)
        section_content = content[start_pos:end_pos]
        
        # Find all level 2 (## Title) sections within this section
        level2_pattern = r'(?m)^## (.+?)$'
        level2_matches = list(re.finditer(level2_pattern, section_content))
        
        # Create index for proper sorting
        section_index = f"{i+1:03d}"
        
        # Extract main section content (up to the first subsection)
        if level2_matches:
            # Content before the first subsection
            main_section_end = level2_matches[0].start()
            main_section_content = section_content[:main_section_end]
        else:
            # No subsections, use the entire section content
            main_section_content = section_content
        
        # Create a file for this level 1 section (without subsections)
        level1_file_path = os.path.join(output_dir, f"{section_index}-{safe_title}.md")
        with open(level1_file_path, 'w', encoding='utf-8') as f:
            f.write(main_section_content)
        
        print(f"Created {level1_file_path}")
        
        # Process each level 2 section if any
        for j, l2_match in enumerate(level2_matches):
            l2_title = l2_match.group(1).strip()
            safe_l2_title = re.sub(r'[^\w\s-]', '', l2_title).strip().replace(' ', '_')
            
            # Determine the start and end position of this subsection
            l2_start_pos = l2_match.start()
            l2_end_pos = len(section_content)
            if j < len(level2_matches) - 1:
                l2_end_pos = level2_matches[j + 1].start()
            
            # Extract the subsection content
            subsection_content = section_content[l2_start_pos:l2_end_pos]
            
            # Create index for proper sorting of subsections
            subsection_index = f"{j+1:03d}"
            
            # Create a file for this level 2 section
            level2_file_path = os.path.join(output_dir, f"{section_index}.{subsection_index}-{safe_l2_title}.md")
            with open(level2_file_path, 'w', encoding='utf-8') as f:
                f.write(subsection_content)
            
            print(f"Created {level2_file_path}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <markdown_file>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    if not os.path.isfile(file_path):
        print(f"Error: File '{file_path}' does not exist.")
        sys.exit(1)
    
    split_markdown_file(file_path)
    base_name = os.path.basename(file_path)
    file_name_no_ext = os.path.splitext(base_name)[0]
    output_dir = os.path.join(SPLITS_DIR, file_name_no_ext)
    print(f"Splitting complete. Files saved in {output_dir} directory.")