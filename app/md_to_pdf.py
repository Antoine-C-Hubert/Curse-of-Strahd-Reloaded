#!/usr/bin/env python3

import argparse
import glob
import markdown
import os
import sys
from pathlib import Path
from tqdm import tqdm
from weasyprint import HTML, CSS
from weasyprint.text.fonts import FontConfiguration

# Define paths
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEMPLATES_DIR = os.path.join(PROJECT_ROOT, "templates")

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
    
    # Process a directory recursively
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
        
        # Convert each file
        successful = 0
        for md_file in tqdm(markdown_files, desc="Converting files"):
            # Determine the output path, preserving the directory structure
            rel_path = os.path.relpath(md_file, directory)
            output_file = os.path.join(output_dir, os.path.splitext(rel_path)[0] + '.pdf')
            
            if convert_file(md_file, output_file):
                successful += 1
        
        return successful
    
    # Process a single file or merge multiple files
    def process_single_file_or_merge(file_path, output_file_path=None):
        # For a single file, just convert it
        if os.path.isfile(file_path):
            if convert_file(file_path, output_file_path):
                return 1
            return 0
        
        # For a directory with the merge option, we generate individual PDFs and merge them
        pattern = os.path.join(file_path, "**/*.md") if recursive else os.path.join(file_path, "*.md")
        markdown_files = sorted(glob.glob(pattern, recursive=recursive))
        
        if not markdown_files:
            print(f"No markdown files found in {file_path}")
            return 0
        
        print(f"Found {len(markdown_files)} markdown files to process")
        
        # Create a temporary directory for individual PDFs
        temp_dir = os.path.join(PROJECT_ROOT, "tmp", "pdf_temp")
        os.makedirs(temp_dir, exist_ok=True)
        
        # Convert each markdown file to PDF individually
        pdf_files = []
        successful_conversions = 0
        
        for md_file in tqdm(markdown_files, desc="Converting individual files"):
            # Create output path for individual PDF
            rel_path = os.path.relpath(md_file, file_path)
            base_name = os.path.splitext(rel_path)[0]
            pdf_path = os.path.join(temp_dir, f"{base_name}.pdf")
            
            # Ensure subdirectories exist
            os.makedirs(os.path.dirname(pdf_path), exist_ok=True)
            
            # Convert to PDF
            if convert_file(md_file, pdf_path):
                successful_conversions += 1
                pdf_files.append(pdf_path)
        
        if not pdf_files:
            print("No PDFs were successfully generated")
            return 0
        
        print(f"Successfully converted {successful_conversions} markdown files to PDF")
        print(f"Merging {len(pdf_files)} PDFs into a single file")
        
        # Ensure output directory exists
        os.makedirs(os.path.dirname(os.path.abspath(output_file_path)), exist_ok=True)
        
        try:
            # Import PyPDF2 for merging PDFs
            from PyPDF2 import PdfMerger
            
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
            
            return 1
            
        except ImportError:
            print("PyPDF2 is not installed. Falling back to combining markdown content.")
            
            # Combine all markdown content as fallback
            combined_md = ""
            for md_file in tqdm(markdown_files, desc="Reading files"):
                with open(md_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    # Add a page break between files
                    combined_md += content + "\n\n<div style='page-break-after: always;'></div>\n\n"
            
            # Create a temporary markdown file
            temp_md_path = os.path.join(os.path.dirname(output_file_path), "_temp_combined.md")
            with open(temp_md_path, 'w', encoding='utf-8') as f:
                f.write(combined_md)
            
            # Convert the combined file
            success = convert_file(temp_md_path, output_file_path)
            
            # Clean up temporary file
            os.remove(temp_md_path)
            
            return 1 if success else 0
    
    # Main execution logic
    if os.path.isfile(input_path):
        # Process single file
        return process_single_file_or_merge(input_path, output_path)
    elif os.path.isdir(input_path):
        if output_path and output_path.endswith('.pdf'):
            # Merge all files into a single PDF
            return process_single_file_or_merge(input_path, output_path)
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
    
    args = parser.parse_args()
    
    # Validate input
    if not os.path.exists(args.input):
        print(f"Error: Input path '{args.input}' does not exist")
        return 1
    
    # Handle merging option
    if args.merge and os.path.isdir(args.input):
        if not args.output:
            # Default output filename for merged PDF
            args.output = os.path.basename(os.path.normpath(args.input)) + ".pdf"
        elif not args.output.endswith('.pdf'):
            args.output = args.output + ".pdf"
    
    # Process files
    successful = convert_markdown_to_pdf(
        args.input,
        args.output,
        args.style,
        args.recursive
    )
    
    print(f"Conversion completed: {successful} file(s) converted")
    return 0

if __name__ == "__main__":
    sys.exit(main())