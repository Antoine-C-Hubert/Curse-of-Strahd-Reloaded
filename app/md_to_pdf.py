#!/usr/bin/env python3

import argparse
import glob
import markdown
import os
import re
import shutil
import sys
from pathlib import Path
from tqdm import tqdm
from weasyprint import HTML, CSS
from weasyprint.text.fonts import FontConfiguration
from PyPDF2 import PdfMerger, PdfReader

# Define paths
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEMPLATES_DIR = os.path.join(PROJECT_ROOT, "templates")
TRANSLATIONS_DIR = os.path.join(PROJECT_ROOT, "translations")
TRANSLATED_GROUPED_DIR = os.path.join(TRANSLATIONS_DIR, "translated_grouped")
TMP_DIR = os.path.join(PROJECT_ROOT, "tmp")

def convert_markdown_to_pdf(input_path, output_path=None, stylesheet_path=None, recursive=False):
    """
    Convert a markdown file or all markdown files in a directory to PDF.
    
    Args:
        input_path (str): Path to a markdown file or directory containing markdown files
        output_path (str, optional): Output file or directory. If None, will use the input name with .pdf extension
        stylesheet_path (str, optional): Path to a CSS file for styling the PDF
        recursive (bool, optional): Whether to process subdirectories recursively
    """
    # Load CSS if provided
    css = None
    font_config = FontConfiguration()
    if stylesheet_path:
        # Check if the stylesheet path exists directly
        if os.path.exists(stylesheet_path):
            css_path = stylesheet_path
        # Check if it's in the templates directory
        elif os.path.exists(os.path.join(TEMPLATES_DIR, os.path.basename(stylesheet_path))):
            css_path = os.path.join(TEMPLATES_DIR, os.path.basename(stylesheet_path))
        # Check if it's a filename without path
        elif os.path.exists(os.path.join(TEMPLATES_DIR, stylesheet_path)):
            css_path = os.path.join(TEMPLATES_DIR, stylesheet_path)
        else:
            print(f"Warning: CSS file not found: {stylesheet_path}")
            css_path = None
            
        if css_path:
            with open(css_path, 'r', encoding='utf-8') as css_file:
                css = CSS(string=css_file.read(), font_config=font_config)
    
    # Function to convert a single file
    def convert_file(md_file_path, output_file_path=None):
        # Default output path if not specified
        if output_file_path is None:
            output_file_path = os.path.splitext(md_file_path)[0] + '.pdf'
        
        # Ensure output directory exists
        os.makedirs(os.path.dirname(os.path.abspath(output_file_path)), exist_ok=True)
        
        # Read markdown content
        with open(md_file_path, 'r', encoding='utf-8') as md_file:
            md_content = md_file.read()
        
        # Convert markdown to HTML
        html_content = markdown.markdown(
            md_content, 
            extensions=[
                'markdown.extensions.tables',
                'markdown.extensions.fenced_code',
                'markdown.extensions.codehilite',
                'markdown.extensions.toc',
                'markdown.extensions.meta',
                'markdown.extensions.footnotes',
                'markdown.extensions.attr_list',
                'markdown.extensions.def_list',
                'markdown.extensions.admonition'
            ]
        )
        
        # Process the admonition blocks (tip, warning, lore)
        html_content = html_content.replace('<div class="admonition tip">', '<div class="admonition tip" style="break-inside: avoid; page-break-inside: avoid;">')
        html_content = html_content.replace('<div class="admonition warning">', '<div class="admonition warning" style="break-inside: avoid; page-break-inside: avoid;">')
        html_content = html_content.replace('<div class="admonition lore">', '<div class="admonition lore" style="break-inside: avoid; page-break-inside: avoid;">')
        
        # Process any div with class description
        html_content = html_content.replace('<div class="description">', '<div class="description" style="break-inside: avoid; page-break-inside: avoid;">')
        
        # Page breaks are now handled in CSS for h1 elements
        
        # Wrap HTML content in basic HTML document structure
        file_name = os.path.basename(md_file_path)
        title = os.path.splitext(file_name)[0]
        
        full_html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>{title}</title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body>
            {html_content}
        </body>
        </html>
        """
        
        # Convert HTML to PDF
        try:
            print(f"Converting {md_file_path} to {output_file_path}")
            HTML(string=full_html).write_pdf(
                output_file_path,
                stylesheets=[css] if css else [],
                font_config=font_config
            )
            return True
        except Exception as e:
            print(f"Error converting {md_file_path} to PDF: {str(e)}")
            return False
    
    # Split a markdown file by main titles (h1) and create temp files
    def split_by_main_titles(md_file_path):
        with open(md_file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Find all level 1 (# Title) sections
        level1_pattern = r'(?m)^# (.+?)$'
        level1_matches = list(re.finditer(level1_pattern, content))
        
        # Create temp directory for split files
        file_name = os.path.basename(md_file_path)
        file_name_no_ext = os.path.splitext(file_name)[0]
        temp_dir = os.path.join(TMP_DIR, f"temp_splits_{file_name_no_ext}")
        os.makedirs(temp_dir, exist_ok=True)
        
        temp_files = []
        
        # If no level 1 headers, treat the whole file as one section
        if not level1_matches:
            temp_file_path = os.path.join(temp_dir, "000.md")
            with open(temp_file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            temp_files.append(temp_file_path)
            return temp_files
        
        # Check if there's content before the first heading
        if level1_matches[0].start() > 0:
            intro_content = content[:level1_matches[0].start()]
            if intro_content.strip():  # Only save if there's actual content
                temp_file_path = os.path.join(temp_dir, "000.md")
                with open(temp_file_path, 'w', encoding='utf-8') as f:
                    # Add document title as main title
                    f.write(f"# {file_name_no_ext}\n\n")
                    f.write(intro_content)
                temp_files.append(temp_file_path)
        
        # Process each level 1 section
        for i, match in enumerate(level1_matches):
            start_pos = match.start()
            end_pos = len(content)
            if i < len(level1_matches) - 1:
                end_pos = level1_matches[i + 1].start()
            
            section_content = content[start_pos:end_pos]
            section_index = f"{i+1:03d}"
            
            temp_file_path = os.path.join(temp_dir, f"{section_index}.md")
            with open(temp_file_path, 'w', encoding='utf-8') as f:
                f.write(section_content)
            
            temp_files.append(temp_file_path)
        
        return temp_files
    
    # Process a single markdown file by splitting it into main sections
    def process_by_main_sections(md_file_path, output_file_path=None):
        if output_file_path is None:
            output_file_path = os.path.splitext(md_file_path)[0] + '.pdf'
        
        # Split the file by main titles
        temp_files = split_by_main_titles(md_file_path)
        
        if not temp_files:
            print(f"No sections found in {md_file_path}")
            return 0
        
        print(f"Split {md_file_path} into {len(temp_files)} sections")
        
        # Create a temporary directory for section PDFs
        file_name = os.path.basename(md_file_path)
        file_name_no_ext = os.path.splitext(file_name)[0]
        temp_pdf_dir = os.path.join(TMP_DIR, f"temp_pdfs_{file_name_no_ext}")
        os.makedirs(temp_pdf_dir, exist_ok=True)
        
        # Convert each section to PDF
        pdf_files = []
        successful_conversions = 0
        
        for temp_file in tqdm(temp_files, desc="Converting sections"):
            # Create output path for individual PDF
            base_name = os.path.basename(temp_file)
            pdf_path = os.path.join(temp_pdf_dir, f"{os.path.splitext(base_name)[0]}.pdf")
            
            # Convert to PDF
            if convert_file(temp_file, pdf_path):
                successful_conversions += 1
                pdf_files.append(pdf_path)
        
        # Clean up temporary markdown files
        for temp_file in temp_files:
            os.remove(temp_file)
        
        if not pdf_files:
            print("No PDFs were successfully generated")
            return 0
        
        print(f"Successfully converted {successful_conversions} sections to PDF")
        print(f"Merging {len(pdf_files)} PDFs into a single file")
        
        # Sort PDF files by their numeric prefix
        pdf_files.sort(key=lambda path: os.path.basename(path).split('.')[0])
        
        # Ensure output directory exists
        os.makedirs(os.path.dirname(os.path.abspath(output_file_path)), exist_ok=True)
        
        try:
            # Merge PDFs
            merger = PdfMerger()
            for pdf in pdf_files:
                merger.append(pdf)
            
            merger.write(output_file_path)
            merger.close()
            
            print(f"Successfully merged PDFs into {output_file_path}")
            
            # Clean up temporary PDFs
            for pdf in pdf_files:
                os.remove(pdf)
            
            # Remove temp directories safely using shutil
            try:
                shutil.rmtree(temp_pdf_dir)
                shutil.rmtree(os.path.dirname(temp_files[0]))
            except Exception as e:
                print(f"Warning: Failed to clean up temporary directories: {str(e)}")
            
            return 1
            
        except ImportError:
            print("PyPDF2 is not installed. Please install it for PDF merging.")
            return 0
        except Exception as e:
            print(f"Error merging PDFs: {str(e)}")
            return 0
    
    # Process a directory
    def process_directory(directory, output_dir=None):
        if output_dir is None:
            output_dir = directory
        
        # Get all markdown files in directory
        pattern = os.path.join(directory, "**/*.md") if recursive else os.path.join(directory, "*.md")
        markdown_files = glob.glob(pattern, recursive=recursive)
        
        if not markdown_files:
            print(f"No markdown files found in {directory}")
            return 0
        
        print(f"Found {len(markdown_files)} markdown files to convert")
        
        # Convert each file using the main sections approach
        successful = 0
        for md_file in tqdm(markdown_files, desc="Converting files"):
            # Determine the output path, preserving the directory structure
            rel_path = os.path.relpath(md_file, directory)
            output_file = os.path.join(output_dir, os.path.splitext(rel_path)[0] + '.pdf')
            
            if process_by_main_sections(md_file, output_file):
                successful += 1
        
        return successful
    
    # Main execution logic
    if os.path.isfile(input_path):
        # Process single file
        return process_by_main_sections(input_path, output_path)
    elif os.path.isdir(input_path):
        if output_path and output_path.endswith('.pdf'):
            # Process directory but output a single PDF
            # For this case, we'll concatenate all markdown files first, then process
            temp_concat_path = os.path.join(TMP_DIR, "temp_concat.md")
            
            # Get all markdown files
            pattern = os.path.join(input_path, "**/*.md") if recursive else os.path.join(input_path, "*.md")
            markdown_files = sorted(glob.glob(pattern, recursive=recursive))
            
            if not markdown_files:
                print(f"No markdown files found in {input_path}")
                return 0
            
            # Concatenate files
            with open(temp_concat_path, 'w', encoding='utf-8') as concat_file:
                for md_file in tqdm(markdown_files, desc="Concatenating files"):
                    with open(md_file, 'r', encoding='utf-8') as f:
                        content = f.read()
                        concat_file.write(content + "\n\n")
            
            # Process the concatenated file
            result = process_by_main_sections(temp_concat_path, output_path)
            
            # Clean up
            os.remove(temp_concat_path)
            
            return result
        else:
            # Process directory, converting each file individually
            return process_directory(input_path, output_path)
    else:
        print(f"Error: Input path '{input_path}' does not exist")
        return 0

def main():
    parser = argparse.ArgumentParser(description="Convert Markdown to PDF")
    parser.add_argument("input", help="Markdown file or directory containing markdown files")
    parser.add_argument("-o", "--output", help="Output PDF file or directory", default=None)
    parser.add_argument("-s", "--style", help="CSS stylesheet for PDF styling", default=None)
    parser.add_argument("-r", "--recursive", help="Process directories recursively", action="store_true")
    parser.add_argument("-m", "--merge", help="Merge all input files into a single PDF", action="store_true")
    parser.add_argument("--cleanup", help="Clean up temporary directories before starting", action="store_true")
    parser.add_argument("--even-pages", help="Add a blank page at the end if total page count is odd", action="store_true")
    
    args = parser.parse_args()
    
    # Validate input
    if not os.path.exists(args.input):
        print(f"Error: Input path '{args.input}' does not exist")
        return 1
    
    # Handle merging option with dir input
    if args.merge and os.path.isdir(args.input):
        if not args.output:
            # Default output filename for merged PDF
            args.output = os.path.basename(os.path.normpath(args.input)) + ".pdf"
        elif not args.output.endswith('.pdf'):
            args.output = args.output + ".pdf"
    
    # Create tmp directory if it doesn't exist
    os.makedirs(TMP_DIR, exist_ok=True)
    
    # Clean up any existing temp directories if requested
    if args.cleanup and os.path.exists(TMP_DIR):
        print("Cleaning up temporary directories...")
        for item in os.listdir(TMP_DIR):
            item_path = os.path.join(TMP_DIR, item)
            try:
                if os.path.isdir(item_path):
                    shutil.rmtree(item_path)
                else:
                    os.remove(item_path)
            except Exception as e:
                print(f"Warning: Failed to remove {item_path}: {str(e)}")
    
    # Process files
    successful = convert_markdown_to_pdf(
        args.input,
        args.output,
        args.style,
        args.recursive
    )
    
    # Add blank page if requested and output is a PDF
    if args.even_pages and args.output and args.output.endswith('.pdf') and os.path.exists(args.output):
        print("Checking if PDF has an odd number of pages...")
        with open(args.output, 'rb') as pdf_file:
            pdf_reader = PdfReader(pdf_file)
            page_count = len(pdf_reader.pages)
            
            if page_count % 2 != 0:  # If odd number of pages
                print(f"PDF has {page_count} pages (odd). Adding blank page...")
                blank_page_path = os.path.join(TEMPLATES_DIR, "blank_page.pdf")
                
                if os.path.exists(blank_page_path):
                    merger = PdfMerger()
                    merger.append(args.output)
                    merger.append(blank_page_path)
                    
                    # Create a temporary file for the new PDF
                    temp_output = args.output + ".tmp"
                    merger.write(temp_output)
                    merger.close()
                    
                    # Replace the original file with the new one
                    os.replace(temp_output, args.output)
                    print(f"Added blank page. PDF now has {page_count + 1} pages (even)")
                else:
                    print(f"Warning: Could not find blank page template at {blank_page_path}")
            else:
                print(f"PDF already has {page_count} pages (even). No blank page needed.")
    
    print(f"Conversion completed: {successful} file(s) converted")
    return 0

if __name__ == "__main__":
    sys.exit(main())