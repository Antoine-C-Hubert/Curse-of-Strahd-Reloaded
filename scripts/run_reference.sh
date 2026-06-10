#!/bin/bash

# run_reference.sh - Script for processing Chapter folders and Appendices
# This script handles the translation workflow for reference materials
# separate from the main campaign guide

set -e  # Exit immediately if a command exits with a non-zero status

# Set paths relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APP_DIR="$PROJECT_ROOT/app"
TRANSLATIONS_DIR="$PROJECT_ROOT/translations"
SPLITS_DIR="$TRANSLATIONS_DIR/splits"
SPLITS_TRANSLATED_DIR="$TRANSLATIONS_DIR/splits_translated"
TRANSLATED_GROUPED_DIR="$TRANSLATIONS_DIR/translated_grouped"
PDF_DIR="$TRANSLATIONS_DIR/pdf"

# Display help message
show_help() {
    echo "Curse of Strahd Reloaded - Reference Materials Translation Script"
    echo "--------------------------------------------------------------"
    echo "Usage: ./run_reference.sh [OPTIONS] [TARGET]"
    echo ""
    echo "Targets:"
    echo "  chapters                 Process all Chapter folders"
    echo "  appendices              Process all Appendices"
    echo "  all                     Process both chapters and appendices (default)"
    echo ""
    echo "Options:"
    echo "  -h, --help               Show this help message"
    echo "  -s, --step STEP          Specify which step to run (split,translate,concat,pdf,all)"
    echo "                           Default: all"
    echo "  -m, --model MODEL        Specify Claude model (default: claude-sonnet-4-6)"
    echo "  -c, --css FILE           Specify CSS file for PDF styling (default: publish_two_columns.css)"
    echo "  -o, --output FILE        Specify output PDF file name (without extension)"
    echo "  -e, --even-pages         Add a blank page at the end if total page count is odd (default)"
    echo "  --no-even-pages          Don't add a blank page if the page count is odd"
    echo ""
    echo "Examples:"
    echo "  # Process all reference materials:"
    echo "  ./run_reference.sh"
    echo ""
    echo "  # Process only chapters:"
    echo "  ./run_reference.sh chapters"
    echo ""
    echo "  # Only perform splitting step for appendices:"
    echo "  ./run_reference.sh -s split appendices"
    echo ""
    echo "  # Generate combined PDF for chapters with custom name:"
    echo "  ./run_reference.sh -s pdf -o \"Chapters_Reference\" chapters"
    echo ""
    echo "Note: This script requires an OpenAI API key in a .env file"
}

# Check if .env file exists
check_env_file() {
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        echo "Warning: .env file not found in project root."
        echo "If you're running translation steps, you'll need an OpenAI API key."
        echo "Create a .env file at: $PROJECT_ROOT/.env"
        echo "Example: echo 'ANTHROPIC_API_KEY=your-api-key-here' > $PROJECT_ROOT/.env"
    fi
}

# Check if dependencies are installed
check_dependencies() {
    python3 -c "import anthropic, dotenv, tqdm, markdown, weasyprint" 2>/dev/null || {
        echo "Error: Required Python packages not found."
        echo "Please install them using: pip install -r $PROJECT_ROOT/requirements.txt"
        exit 1
    }
}

# Create necessary directories
create_directories() {
    mkdir -p "$SPLITS_DIR" "$SPLITS_TRANSLATED_DIR" "$TRANSLATED_GROUPED_DIR" "$PDF_DIR"
}

# Get list of files to process based on target
get_files_list() {
    local target="$1"
    local files=()
    
    case "$target" in
        chapters)
            # Get all markdown files from Chapter folders
            while IFS= read -r -d '' file; do
                files+=("$file")
            done < <(find "$PROJECT_ROOT" -path "*/Chapter*/*.md" -print0 | sort -z)
            ;;
        appendices)
            # Get all markdown files from Appendices folder
            while IFS= read -r -d '' file; do
                files+=("$file")
            done < <(find "$PROJECT_ROOT/Appendices" -name "*.md" -print0 | sort -z)
            ;;
        all)
            # Get both chapters and appendices
            while IFS= read -r -d '' file; do
                files+=("$file")
            done < <(find "$PROJECT_ROOT" -path "*/Chapter*/*.md" -o -path "*/Appendices/*.md" -print0 | sort -z)
            ;;
        *)
            echo "Error: Invalid target: $target"
            echo "Valid targets are: chapters, appendices, all"
            exit 1
            ;;
    esac
    
    printf '%s\n' "${files[@]}"
}

# Process a single file through the workflow
process_file() {
    local file_path="$1"
    local step="$2"
    local model="$3"
    local css_file="$4"
    local use_even_pages="$5"
    
    echo "Processing: $file_path"
    
    case "$step" in
        split)
            "$SCRIPT_DIR/run.sh" -s split "$file_path"
            ;;
        translate)
            "$SCRIPT_DIR/run.sh" -s translate -m "$model" "$file_path"
            ;;
        concat|concatenate)
            "$SCRIPT_DIR/run.sh" -s concat "$file_path"
            ;;
        pdf)
            if [ "$use_even_pages" = true ]; then
                "$SCRIPT_DIR/run.sh" -s pdf -c "$css_file" -e "$file_path"
            else
                "$SCRIPT_DIR/run.sh" -s pdf -c "$css_file" --no-even-pages "$file_path"
            fi
            ;;
        all)
            if [ "$use_even_pages" = true ]; then
                "$SCRIPT_DIR/run.sh" -m "$model" -c "$css_file" -e "$file_path"
            else
                "$SCRIPT_DIR/run.sh" -m "$model" -c "$css_file" --no-even-pages "$file_path"
            fi
            ;;
    esac
}

# Create a combined PDF for the target by merging existing PDFs
create_combined_pdf() {
    local target="$1"
    local output_name="$2"
    local css_file="$3"
    local use_even_pages="$4"
    
    # Get list of processed files
    local files_list
    readarray -t files_list < <(get_files_list "$target")
    
    if [ ${#files_list[@]} -eq 0 ]; then
        echo "No files found for target: $target"
        return 1
    fi
    
    # Check if pdftk is available for merging
    if ! command -v pdftk &> /dev/null; then
        echo "Warning: pdftk not found. Cannot create merged PDF."
        echo "Install pdftk using: sudo apt install pdftk"
        return 1
    fi
    
    # Build list of existing PDF files
    local pdf_files=()
    for file_path in "${files_list[@]}"; do
        local base_name=$(basename "$file_path" .md)
        local pdf_file="$PDF_DIR/${base_name}.pdf"
        
        if [ -f "$pdf_file" ]; then
            pdf_files+=("$pdf_file")
            echo "Found PDF: $base_name.pdf"
        else
            echo "Warning: PDF not found: $pdf_file"
        fi
    done
    
    if [ ${#pdf_files[@]} -eq 0 ]; then
        echo "Error: No PDF files found to merge. Make sure individual PDFs have been generated first."
        return 1
    fi
    
    # Determine output PDF path (merged PDFs go in translations/ not translations/pdf/)
    local output_pdf
    if [ -z "$output_name" ]; then
        case "$target" in
            chapters)
                output_pdf="$TRANSLATIONS_DIR/Reference_Chapters.pdf"
                ;;
            appendices)
                output_pdf="$TRANSLATIONS_DIR/Reference_Appendices.pdf"
                ;;
            all)
                output_pdf="$TRANSLATIONS_DIR/Complete_Reference.pdf"
                ;;
        esac
    else
        output_pdf="$TRANSLATIONS_DIR/${output_name}.pdf"
    fi
    
    echo "Merging ${#pdf_files[@]} PDF files into: $output_pdf"
    
    # Use the dedicated merge script for better title page and TOC
    local merge_prefix
    if [ -z "$output_name" ]; then
        merge_prefix="Reference"
    else
        merge_prefix="$output_name"
    fi
    
    case "$target" in
        chapters)
            "$SCRIPT_DIR/merge_reference_pdfs.sh" -o "$merge_prefix" chapters
            ;;
        appendices)
            "$SCRIPT_DIR/merge_reference_pdfs.sh" -o "$merge_prefix" appendices
            ;;
        all)
            "$SCRIPT_DIR/merge_reference_pdfs.sh" -o "$merge_prefix" all
            ;;
    esac
    
    if [ -f "$output_pdf" ]; then
        echo "Combined PDF generated successfully: $output_pdf"
    else
        echo "Error: Combined PDF generation failed."
    fi
}

# Process all files for a target
process_target() {
    local target="$1"
    local step="$2"
    local model="$3"
    local css_file="$4"
    local output_name="$5"
    local use_even_pages="$6"
    
    echo "===== PROCESSING $target ====="
    
    # Get list of files to process
    local files_list
    readarray -t files_list < <(get_files_list "$target")
    
    if [ ${#files_list[@]} -eq 0 ]; then
        echo "No files found for target: $target"
        return 1
    fi
    
    echo "Found ${#files_list[@]} files to process for $target"
    
    # Process each file individually (except for combined PDF step)
    if [ "$step" != "pdf" ] || [ -z "$output_name" ]; then
        for file_path in "${files_list[@]}"; do
            echo "----------------------------------------"
            process_file "$file_path" "$step" "$model" "$css_file" "$use_even_pages"
            echo ""
        done
    fi
    
    # If step is PDF and output name is specified, create combined PDF
    if [ "$step" = "pdf" ] && [ -n "$output_name" ]; then
        echo "----------------------------------------"
        echo "Creating combined PDF..."
        create_combined_pdf "$target" "$output_name" "$css_file" "$use_even_pages"
    elif [ "$step" = "all" ] && [ -n "$output_name" ]; then
        echo "----------------------------------------"
        echo "Creating combined PDF..."
        create_combined_pdf "$target" "$output_name" "$css_file" "$use_even_pages"
    fi
    
    echo "===== COMPLETE: $target ====="
}

# Main script execution
main() {
    local target="all"
    local step="all"
    local model="claude-sonnet-4-6"
    local css_file="$PROJECT_ROOT/templates/publish_two_columns.css"
    local output_name=""
    local even_pages=true
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--step)
                step="$2"
                shift 2
                ;;
            -m|--model)
                model="$2"
                shift 2
                ;;
            -c|--css)
                css_file="$2"
                # Check various locations for the CSS file
                if [ -f "$css_file" ]; then
                    # Absolute path or path relative to current directory
                    css_file="$css_file"
                elif [ -f "$PROJECT_ROOT/templates/$css_file" ]; then
                    # CSS file in templates directory
                    css_file="$PROJECT_ROOT/templates/$css_file"
                elif [ -f "$PROJECT_ROOT/$css_file" ]; then
                    # CSS file relative to project root
                    css_file="$PROJECT_ROOT/$css_file"
                else
                    # Just pass the filename and let md_to_pdf.py handle it
                    echo "Note: CSS file will be looked up in templates directory: $css_file"
                fi
                shift 2
                ;;
            -o|--output)
                output_name="$2"
                shift 2
                ;;
            -e|--even-pages)
                even_pages=true
                shift
                ;;
            --no-even-pages)
                even_pages=false
                shift
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
    
    # Check environment and dependencies
    check_env_file
    check_dependencies
    create_directories
    
    # Execute requested step for target
    process_target "$target" "$step" "$model" "$css_file" "$output_name" "$even_pages"
}

# Execute main function
main "$@"