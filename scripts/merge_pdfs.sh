#!/bin/bash

# merge_pdfs.sh - Script to merge PDF files in a specified order
# This script concatenates multiple PDF files from the translations/pdf directory
# into a single PDF file

set -e  # Exit immediately if a command exits with a non-zero status

# Set paths relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PDF_DIR="$PROJECT_ROOT/translations/pdf"
OUTPUT_DIR="$PROJECT_ROOT/translations"

# Display help message
show_help() {
    echo "Curse of Strahd Reloaded - PDF Merger Script"
    echo "-------------------------------------------"
    echo "Usage: ./merge_pdfs.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help               Show this help message"
    echo "  -o, --output FILE        Specify output PDF file name (default: Complete_Guide.pdf)"
    echo "  -c, --custom             Use custom order from command arguments instead of default"
    echo ""
    echo "Examples:"
    echo "  # Merge PDFs using default order:"
    echo "  ./merge_pdfs.sh"
    echo ""
    echo "  # Merge PDFs with custom output name:"
    echo "  ./merge_pdfs.sh -o \"French_Campaign_Guide.pdf\""
    echo ""
    echo "  # Merge specific PDFs in custom order:"
    echo "  ./merge_pdfs.sh -c \"Act I Summary.pdf\" \"Arc A - Escape From Death House.pdf\""
    echo ""
    echo "Note: This script requires the pdftk tool (sudo apt install pdftk)"
}

# Check if pdftk is installed
check_dependencies() {
    if ! command -v pdftk &> /dev/null; then
        echo "Error: pdftk is not installed."
        echo "Please install it using: sudo apt install pdftk"
        exit 1
    fi
}

# Merge PDFs in default order
merge_default_pdfs() {
    local output_file="$1"
    
    echo "===== MERGING PDFs IN DEFAULT ORDER ====="
    
    # Define the default order of PDFs
    local pdf_files=(
        "Act I Summary.pdf"
        "Arc A - Escape From Death House.pdf"
        "Arc B - Welcome to Barovia.pdf"
        "Arc C - Into the Valley.pdf"
        "Act II Summary.pdf"
        "Arc D - St. Andral's Feast.pdf"
        "Arc E - The Missing Vistana.pdf"
        # Add more files here as they are translated
    )
    
    # Check that all required PDFs exist
    for pdf in "${pdf_files[@]}"; do
        if [ ! -f "$PDF_DIR/$pdf" ]; then
            echo "Warning: PDF file not found: $PDF_DIR/$pdf"
            echo "The file will be skipped in the merged output."
        fi
    done
    
    # Create a list of existing PDF files
    local existing_pdfs=()
    for pdf in "${pdf_files[@]}"; do
        if [ -f "$PDF_DIR/$pdf" ]; then
            existing_pdfs+=("$PDF_DIR/$pdf")
        fi
    done
    
    if [ ${#existing_pdfs[@]} -eq 0 ]; then
        echo "Error: No PDF files found to merge."
        exit 1
    fi
    
    echo "Merging ${#existing_pdfs[@]} PDF files into $output_file"
    pdftk "${existing_pdfs[@]}" cat output "$output_file"
    
    if [ -f "$output_file" ]; then
        echo "PDF merging complete. File saved as $output_file"
    else
        echo "Error: PDF merging failed."
    fi
}

# Merge PDFs in custom order
merge_custom_pdfs() {
    local output_file="$1"
    shift
    local custom_pdfs=("$@")
    
    echo "===== MERGING PDFs IN CUSTOM ORDER ====="
    
    # Check that all specified PDFs exist
    local existing_pdfs=()
    for pdf in "${custom_pdfs[@]}"; do
        if [ -f "$PDF_DIR/$pdf" ]; then
            existing_pdfs+=("$PDF_DIR/$pdf")
        else
            echo "Warning: PDF file not found: $PDF_DIR/$pdf"
            echo "The file will be skipped in the merged output."
        fi
    done
    
    if [ ${#existing_pdfs[@]} -eq 0 ]; then
        echo "Error: No valid PDF files specified."
        exit 1
    fi
    
    echo "Merging ${#existing_pdfs[@]} PDF files into $output_file"
    pdftk "${existing_pdfs[@]}" cat output "$output_file"
    
    if [ -f "$output_file" ]; then
        echo "PDF merging complete. File saved as $output_file"
    else
        echo "Error: PDF merging failed."
    fi
}

# Main script execution
main() {
    local output_name="Complete_Guide.pdf"
    local use_custom=false
    local custom_pdfs=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -o|--output)
                output_name="$2"
                shift 2
                ;;
            -c|--custom)
                use_custom=true
                shift
                while [[ $# -gt 0 && ! "$1" == -* ]]; do
                    custom_pdfs+=("$1")
                    shift
                done
                ;;
            *)
                if $use_custom; then
                    custom_pdfs+=("$1")
                    shift
                else
                    echo "Error: Unexpected argument: $1"
                    show_help
                    exit 1
                fi
                ;;
        esac
    done
    
    # Add extension if not provided
    if [[ ! "$output_name" =~ \.pdf$ ]]; then
        output_name="${output_name}.pdf"
    fi
    
    # Set full output path
    local output_file="$OUTPUT_DIR/$output_name"
    
    # Check dependencies
    check_dependencies
    
    # Execute requested merge operation
    if $use_custom && [ ${#custom_pdfs[@]} -gt 0 ]; then
        merge_custom_pdfs "$output_file" "${custom_pdfs[@]}"
    else
        merge_default_pdfs "$output_file"
    fi
    
    echo "===== COMPLETE ====="
    echo "Final merged PDF available at: $output_file"
}

# Execute main function
main "$@"