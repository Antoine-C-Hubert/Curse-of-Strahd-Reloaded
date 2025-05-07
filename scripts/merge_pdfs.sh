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
TEMP_DIR="$PROJECT_ROOT/tmp"

# Display help message
show_help() {
    echo "Curse of Strahd Reloaded - PDF Merger Script"
    echo "-------------------------------------------"
    echo "Usage: ./merge_pdfs.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help               Show this help message"
    echo "  -o, --output FILE        Specify output PDF file name (default: Guide_Complet.pdf)"
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
    echo "Note: This script requires pdftk (required) and wkhtmltopdf (optional)"
    echo "(sudo apt install pdftk wkhtmltopdf)"
}

# Check if dependencies are installed
check_dependencies() {
    if ! command -v pdftk &> /dev/null; then
        echo "Error: pdftk is not installed."
        echo "Please install it using: sudo apt install pdftk"
        exit 1
    fi
    
    # Check for wkhtmltopdf but don't require it
    if ! command -v wkhtmltopdf &> /dev/null; then
        echo "Note: wkhtmltopdf is not installed. Using fallback methods for title and TOC pages."
        echo "For better output, install wkhtmltopdf: sudo apt install wkhtmltopdf"
        USE_WKHTMLTOPDF="false"
    else
        USE_WKHTMLTOPDF="true"
    fi
}

# Create title page
create_title_page() {
    local title="$1"
    local output_file="$2"
    
    # Remove file extension for title display
    local display_title="${title%.pdf}"
    
    # Replace underscores with spaces for better display
    display_title="${display_title//_/ }"
    
    echo "Creating title page..."
    mkdir -p "$TEMP_DIR"
    
    # Try using wkhtmltopdf first
    if command -v wkhtmltopdf &> /dev/null && [ "$USE_WKHTMLTOPDF" = "true" ]; then
        # Create HTML for the title page
        cat > "$TEMP_DIR/title_page.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$display_title</title>
    <style>
        html, body {
            height: 100%;
            margin: 0;
            padding: 0;
        }
        body {
            font-family: 'Times New Roman', Times, serif;
            text-align: center;
            display: table;
            width: 100%;
        }
        .container {
            display: table-cell;
            vertical-align: middle;
            padding: 20px;
        }
        h1 {
            font-size: 48px;
            margin-bottom: 30px;
            padding: 0 40px;
        }
        .subtitle {
            font-size: 24px;
            font-style: italic;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>$display_title</h1>
        <div class="subtitle">Curse of Strahd Reloaded</div>
    </div>
</body>
</html>
EOF
        
        # Try to convert HTML to PDF, if it fails, use fallback method
        if wkhtmltopdf --quiet --page-size A4 --margin-top 0 --margin-bottom 0 "$TEMP_DIR/title_page.html" "$output_file" 2>/dev/null; then
            echo "Title page created with wkhtmltopdf."
            return 0
        else
            echo "wkhtmltopdf failed, using fallback method..."
        fi
    fi
    
    # Fallback method: Create a simple text-based PDF with pdftk
    echo "Using pdftk fallback method for title page..."
    
    # Create a simple text file
    cat > "$TEMP_DIR/title.txt" << EOF
$display_title

Curse of Strahd Reloaded
EOF
    
    # Generate empty PDF with pdftk
    echo "" | pdftk - output "$output_file"
    
    # Add text annotation to the empty PDF
    pdftk "$output_file" update_info_utf8 <(echo "InfoValue: $display_title") output "$output_file.annotated"
    
    # Replace original with annotated version
    mv "$output_file.annotated" "$output_file"
    
    echo "Fallback title page created with pdftk."
}

# Create ToC page with table of contents
create_toc_page() {
    local output_file="$1"
    shift
    local pdf_files=("$@")
    
    echo "Creating ToC page..."
    mkdir -p "$TEMP_DIR"
    
    # Try using wkhtmltopdf first
    if command -v wkhtmltopdf &> /dev/null && [ "$USE_WKHTMLTOPDF" = "true" ]; then
        # Create HTML for the ToC page
        cat > "$TEMP_DIR/toc_page.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Table of Contents</title>
    <style>
        body {
            font-family: 'Times New Roman', Times, serif;
            margin: 40px;
            padding: 0;
        }
        h1 {
            font-size: 36px;
            text-align: center;
            margin-bottom: 30px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
    </style>
</head>
<body>
    <h1>Table of Contents</h1>
    <table>
        <tr>
            <th>Chapter</th>
            <th>Page</th>
        </tr>
EOF
        
        # Calculate page numbers for the ToC table
        local current_page=3  # Start at 3 (1:title, 2:toc)
        
        for pdf in "${pdf_files[@]}"; do
            # Remove file extension
            local display_name="${pdf%.pdf}"
            
            # Add row to table
            echo "<tr><td>$display_name</td><td>$current_page</td></tr>" >> "$TEMP_DIR/toc_page.html"
            
            # Get page count of current PDF
            local page_count=$(pdftk "$PDF_DIR/$pdf" dump_data | grep "NumberOfPages" | awk '{print $2}')
            
            # Update current page for next file
            current_page=$((current_page + page_count))
        done
        
        # Close the HTML document
        cat >> "$TEMP_DIR/toc_page.html" << EOF
    </table>
</body>
</html>
EOF
        
        # Try to convert HTML to PDF, if it fails, use fallback method
        if wkhtmltopdf --quiet --page-size A4 "$TEMP_DIR/toc_page.html" "$output_file" 2>/dev/null; then
            echo "ToC page created with wkhtmltopdf."
            # Get page info for debugging
            echo "ToC PDF info:"
            pdftk "$output_file" dump_data | grep "Number"
            return 0
        else
            echo "wkhtmltopdf failed, using fallback method..."
        fi
    fi
    
    # Fallback method: Create a simple text-based PDF with pdftk
    echo "Using pdftk fallback method for ToC page..."
    
    # Create a simple text file for TOC
    cat > "$TEMP_DIR/toc.txt" << EOF
TABLE OF CONTENTS

EOF
    
    # Calculate page numbers for the ToC table
    local current_page=3  # Start at 3 (1:title, 2:toc)
    
    for pdf in "${pdf_files[@]}"; do
        # Remove file extension
        local display_name="${pdf%.pdf}"
        
        # Add row to text file
        echo "$display_name ... Page $current_page" >> "$TEMP_DIR/toc.txt"
        
        # Get page count of current PDF
        local page_count=$(pdftk "$PDF_DIR/$pdf" dump_data | grep "NumberOfPages" | awk '{print $2}')
        
        # Update current page for next file
        current_page=$((current_page + page_count))
    done
    
    # Generate empty PDF with pdftk
    echo "" | pdftk - output "$output_file"
    
    # Add text annotation to the empty PDF
    pdftk "$output_file" update_info_utf8 <(echo "InfoValue: Table of Contents") output "$output_file.annotated"
    
    # Replace original with annotated version
    mv "$output_file.annotated" "$output_file"
    
    echo "Fallback ToC page created with pdftk."
    # Get page info for debugging
    echo "ToC PDF info:"
    pdftk "$output_file" dump_data | grep "Number"
}

# Merge PDFs in default order
merge_default_pdfs() {
    local output_file="$1"
    local output_basename=$(basename "$output_file")
    
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
            existing_pdfs+=("$pdf")
        fi
    done
    
    if [ ${#existing_pdfs[@]} -eq 0 ]; then
        echo "Error: No PDF files found to merge."
        exit 1
    fi
    
    # Create title and ToC pages
    mkdir -p "$TEMP_DIR"
    local title_page="$TEMP_DIR/title_page.pdf"
    local toc_page="$TEMP_DIR/toc_page.pdf"
    
    create_title_page "$output_basename" "$title_page"
    create_toc_page "$toc_page" "${existing_pdfs[@]}"
    
    # Prepare the full list of PDFs with their paths
    local all_pdfs=("$title_page" "$toc_page")
    for pdf in "${existing_pdfs[@]}"; do
        all_pdfs+=("$PDF_DIR/$pdf")
    done
    
    # Merge all PDFs
    echo "Merging ${#existing_pdfs[@]} PDF files (plus title and ToC) into $output_file"
    pdftk "${all_pdfs[@]}" cat output "$output_file"
    
    if [ -f "$output_file" ]; then
        echo "PDF merging complete. File saved as $output_file"
    else
        echo "Error: PDF merging failed."
    fi
    
    # Clean up temporary files
    rm -f "$title_page" "$toc_page"
}

# Merge PDFs in custom order
merge_custom_pdfs() {
    local output_file="$1"
    local output_basename=$(basename "$output_file")
    shift
    local custom_pdfs=("$@")
    
    echo "===== MERGING PDFs IN CUSTOM ORDER ====="
    
    # Check that all specified PDFs exist
    local existing_pdfs=()
    for pdf in "${custom_pdfs[@]}"; do
        if [ -f "$PDF_DIR/$pdf" ]; then
            existing_pdfs+=("$pdf")
        else
            echo "Warning: PDF file not found: $PDF_DIR/$pdf"
            echo "The file will be skipped in the merged output."
        fi
    done
    
    if [ ${#existing_pdfs[@]} -eq 0 ]; then
        echo "Error: No valid PDF files specified."
        exit 1
    fi
    
    # Create title and ToC pages
    mkdir -p "$TEMP_DIR"
    local title_page="$TEMP_DIR/title_page.pdf"
    local toc_page="$TEMP_DIR/toc_page.pdf"
    
    create_title_page "$output_basename" "$title_page"
    create_toc_page "$toc_page" "${existing_pdfs[@]}"
    
    # Prepare the full list of PDFs with their paths
    local all_pdfs=("$title_page" "$toc_page")
    for pdf in "${existing_pdfs[@]}"; do
        all_pdfs+=("$PDF_DIR/$pdf")
    done
    
    # Merge all PDFs
    echo "Merging ${#existing_pdfs[@]} PDF files (plus title and ToC) into $output_file"
    pdftk "${all_pdfs[@]}" cat output "$output_file"
    
    if [ -f "$output_file" ]; then
        echo "PDF merging complete. File saved as $output_file"
    else
        echo "Error: PDF merging failed."
    fi
    
    # Clean up temporary files
    rm -f "$title_page" "$toc_page"
}

# Main script execution
main() {
    local output_name="Guide_Complet.pdf"
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
    
    # Create necessary directories
    mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"
    
    # Check dependencies
    check_dependencies
    
    # Execute requested merge operation
    if $use_custom && [ ${#custom_pdfs[@]} -gt 0 ]; then
        merge_custom_pdfs "$output_file" "${custom_pdfs[@]}"
    else
        merge_default_pdfs "$output_file"
    fi
    
    # Clean up temp directory
    rm -rf "$TEMP_DIR/title_page.html" "$TEMP_DIR/toc_page.html"
    
    echo "===== COMPLETE ====="
    echo "Final merged PDF available at: $output_file"
}

# Execute main function
main "$@"