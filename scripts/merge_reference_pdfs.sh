#!/bin/bash

# merge_reference_pdfs.sh - Script to merge reference material PDFs separately
# This script creates combined PDFs for chapters and appendices

set -e  # Exit immediately if a command exits with a non-zero status

# Set paths relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PDF_DIR="$PROJECT_ROOT/translations/pdf"
OUTPUT_DIR="$PROJECT_ROOT/translations"
TEMP_DIR="$PROJECT_ROOT/tmp"

# Display help message
show_help() {
    echo "Curse of Strahd Reloaded - Reference Materials PDF Merger"
    echo "-------------------------------------------------------"
    echo "Usage: ./merge_reference_pdfs.sh [OPTIONS] [TARGET]"
    echo ""
    echo "Targets:"
    echo "  chapters                 Merge all Chapter PDFs"
    echo "  appendices              Merge all Appendices PDFs"
    echo "  all                     Merge both (creates separate files) (default)"
    echo ""
    echo "Options:"
    echo "  -h, --help               Show this help message"
    echo "  -o, --output-prefix PREFIX  Prefix for output file names (default: Reference)"
    echo ""
    echo "Examples:"
    echo "  # Merge all reference materials into separate PDFs:"
    echo "  ./merge_reference_pdfs.sh"
    echo ""
    echo "  # Merge only chapters:"
    echo "  ./merge_reference_pdfs.sh chapters"
    echo ""
    echo "  # Merge with custom prefix:"
    echo "  ./merge_reference_pdfs.sh -o \"Campaign_Reference\" all"
    echo ""
    echo "Note: This script requires pdftk"
}

# Check if dependencies are installed
check_dependencies() {
    if ! command -v pdftk &> /dev/null; then
        echo "Error: pdftk is not installed."
        echo "Please install it using: sudo apt install pdftk"
        exit 1
    fi
}

# Get Chapter PDF files
get_chapter_pdfs() {
    local pdfs=()
    
    # Define expected chapter PDF names
    local chapter_files=(
        "Character Creation.pdf"
        "Session Zero.pdf"
        "History of Barovia.pdf"
        "Lore of Barovia.pdf"
        "Strahd von Zarovich.pdf"
        "Adventure Summary.pdf"
        "Running the Adventure.pdf"
    )
    
    # Check which files exist
    for pdf in "${chapter_files[@]}"; do
        if [ -f "$PDF_DIR/$pdf" ]; then
            pdfs+=("$pdf")
        else
            echo "Warning: Chapter PDF not found: $PDF_DIR/$pdf"
        fi
    done
    
    printf '%s\n' "${pdfs[@]}"
}

# Get Appendices PDF files
get_appendices_pdfs() {
    local pdfs=()
    
    # Define expected appendices PDF names
    local appendices_files=(
        "Amber Shards.pdf"
        "Bestiary.pdf"
        "Glossary.pdf"
        "Non-Player Characters.pdf"
    )
    
    # Check which files exist
    for pdf in "${appendices_files[@]}"; do
        if [ -f "$PDF_DIR/$pdf" ]; then
            pdfs+=("$pdf")
        else
            echo "Warning: Appendices PDF not found: $PDF_DIR/$pdf"
        fi
    done
    
    printf '%s\n' "${pdfs[@]}"
}

# Create title page for reference materials
create_reference_title_page() {
    local title="$1"
    local output_file="$2"
    
    echo "Creating title page for $title..."
    mkdir -p "$TEMP_DIR"
    
    # Create HTML for the title page
    cat > "$TEMP_DIR/ref_title_page.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$title</title>
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
        .description {
            font-size: 18px;
            margin-top: 30px;
            font-style: italic;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>$title</h1>
        <div class="subtitle">Curse of Strahd Reloaded</div>
        <div class="description">Reference Materials</div>
    </div>
</body>
</html>
EOF
    
    # Try to convert HTML to PDF
    if command -v wkhtmltopdf &> /dev/null; then
        wkhtmltopdf --quiet --page-size A4 --margin-top 0 --margin-bottom 0 "$TEMP_DIR/ref_title_page.html" "$output_file" 2>/dev/null || {
            echo "wkhtmltopdf failed, using fallback method..."
            echo "" | pdftk - output "$output_file"
        }
    else
        echo "wkhtmltopdf not available, using fallback method..."
        echo "" | pdftk - output "$output_file"
    fi
    
    echo "Title page created: $output_file"
}

# Create ToC page for reference materials
create_reference_toc_page() {
    local output_file="$1"
    local title="$2"
    shift 2
    local pdf_files=("$@")
    
    echo "Creating ToC page for $title..."
    mkdir -p "$TEMP_DIR"
    
    # Create HTML for the ToC page
    cat > "$TEMP_DIR/ref_toc_page.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Table of Contents - $title</title>
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
    <h2>$title</h2>
    <table>
        <tr>
            <th>Section</th>
            <th>Page</th>
        </tr>
EOF
    
    # Calculate page numbers for the ToC table
    local current_page=3  # Start at 3 (1:title, 2:toc)
    
    for pdf in "${pdf_files[@]}"; do
        # Remove file extension
        local display_name="${pdf%.pdf}"
        
        # Add row to table
        echo "<tr><td>$display_name</td><td>$current_page</td></tr>" >> "$TEMP_DIR/ref_toc_page.html"
        
        # Get page count of current PDF
        local page_count=$(pdftk "$PDF_DIR/$pdf" dump_data | grep "NumberOfPages" | awk '{print $2}')
        
        # Update current page for next file
        current_page=$((current_page + page_count))
    done
    
    # Close the HTML document
    cat >> "$TEMP_DIR/ref_toc_page.html" << EOF
    </table>
</body>
</html>
EOF
    
    # Try to convert HTML to PDF
    if command -v wkhtmltopdf &> /dev/null; then
        wkhtmltopdf --quiet --page-size A4 "$TEMP_DIR/ref_toc_page.html" "$output_file" 2>/dev/null || {
            echo "wkhtmltopdf failed, using fallback method..."
            echo "" | pdftk - output "$output_file"
        }
    else
        echo "wkhtmltopdf not available, using fallback method..."
        echo "" | pdftk - output "$output_file"
    fi
    
    echo "ToC page created: $output_file"
}

# Merge PDFs for a specific target
merge_reference_pdfs() {
    local target="$1"
    local output_prefix="$2"
    
    local pdf_files=()
    local title=""
    local output_file=""
    
    case "$target" in
        chapters)
            title="Chapters Reference"
            if [ "$output_prefix" = "Reference" ]; then
                output_file="$OUTPUT_DIR/Reference_Chapters.pdf"
            else
                output_file="$OUTPUT_DIR/${output_prefix}.pdf"
            fi
            readarray -t pdf_files < <(get_chapter_pdfs)
            ;;
        appendices)
            title="Appendices Reference"
            if [ "$output_prefix" = "Reference" ]; then
                output_file="$OUTPUT_DIR/Reference_Appendices.pdf"
            else
                output_file="$OUTPUT_DIR/${output_prefix}.pdf"
            fi
            readarray -t pdf_files < <(get_appendices_pdfs)
            ;;
        *)
            echo "Error: Invalid target: $target"
            return 1
            ;;
    esac
    
    if [ ${#pdf_files[@]} -eq 0 ]; then
        echo "Warning: No PDF files found for $target"
        return 1
    fi
    
    echo "===== MERGING $target PDFs ====="
    echo "Found ${#pdf_files[@]} files to merge:"
    printf '  %s\n' "${pdf_files[@]}"
    
    # Create title and ToC pages
    mkdir -p "$TEMP_DIR"
    local title_page="$TEMP_DIR/ref_title_page.pdf"
    local toc_page="$TEMP_DIR/ref_toc_page.pdf"
    
    create_reference_title_page "$title" "$title_page"
    create_reference_toc_page "$toc_page" "$title" "${pdf_files[@]}"
    
    # Prepare the full list of PDFs with their paths
    local all_pdfs=("$title_page" "$toc_page")
    for pdf in "${pdf_files[@]}"; do
        all_pdfs+=("$PDF_DIR/$pdf")
    done
    
    # Merge all PDFs
    echo "Merging ${#pdf_files[@]} PDF files (plus title and ToC) into $output_file"
    pdftk "${all_pdfs[@]}" cat output "$output_file"
    
    if [ -f "$output_file" ]; then
        echo "$target PDF merging complete. File saved as $output_file"
    else
        echo "Error: $target PDF merging failed."
    fi
    
    # Clean up temporary files
    rm -f "$title_page" "$toc_page" "$TEMP_DIR/ref_title_page.html" "$TEMP_DIR/ref_toc_page.html"
    
    echo "===== $target MERGE COMPLETE ====="
    echo ""
}

# Main script execution
main() {
    local target="all"
    local output_prefix="Reference"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -o|--output-prefix)
                output_prefix="$2"
                shift 2
                ;;
            chapters|appendices|all)
                target="$1"
                shift
                ;;
            *)
                echo "Error: Unexpected argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Create necessary directories
    mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"
    
    # Check dependencies
    check_dependencies
    
    echo "Curse of Strahd Reloaded - Reference Materials PDF Merger"
    echo "========================================================"
    echo "Target: $target"
    echo "Output prefix: $output_prefix"
    echo "========================================================"
    echo ""
    
    # Execute merge operation
    case "$target" in
        chapters)
            merge_reference_pdfs "chapters" "$output_prefix"
            ;;
        appendices)
            merge_reference_pdfs "appendices" "$output_prefix"
            ;;
        all)
            merge_reference_pdfs "chapters" "$output_prefix"
            merge_reference_pdfs "appendices" "$output_prefix"
            ;;
        *)
            echo "Error: Invalid target specified: $target"
            show_help
            exit 1
            ;;
    esac
    
    echo "===== ALL REFERENCE MERGING COMPLETE ====="
    echo "Check the translations directory for output files."
}

# Execute main function
main "$@"