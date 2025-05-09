#!/bin/bash

# run.sh - Unified script for Curse of Strahd Reloaded translation workflow
# This script handles the complete process from markdown splitting to PDF generation

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
    echo "Curse of Strahd Reloaded - Unified Translation Workflow Script"
    echo "-----------------------------------------------------------"
    echo "Usage: ./run.sh [OPTIONS] <markdown_file>"
    echo ""
    echo "Options:"
    echo "  -h, --help               Show this help message"
    echo "  -s, --step STEP          Specify which step to run (split,translate,concat,pdf,all)"
    echo "                           Default: all"
    echo "  -m, --model MODEL        Specify OpenAI model (default: gpt-4o)"
    echo "  -c, --css FILE           Specify CSS file for PDF styling (default: publish_two_columns.css)"
    echo "  -o, --output FILE        Specify output PDF file name (without extension)"
    echo ""
    echo "Examples:"
    echo "  # Complete workflow from markdown to PDF:"
    echo "  ./run.sh \"Act III - The Broken Land/Act III Summary.md\""
    echo ""
    echo "  # Only perform splitting step:"
    echo "  ./run.sh -s split \"Act III - The Broken Land/Act III Summary.md\""
    echo ""
    echo "  # Run translation with a specific model:"
    echo "  ./run.sh -s translate -m gpt-3.5-turbo \"Act III - The Broken Land/Act III Summary.md\""
    echo ""
    echo "  # Generate PDF with custom styling:"
    echo "  ./run.sh -s pdf -c custom.css \"Act III - The Broken Land/Act III Summary.md\""
    echo ""
    echo "  # Run the entire process with a custom output PDF name:"
    echo "  ./run.sh -o \"ActIII_French\" \"Act III - The Broken Land/Act III Summary.md\""
    echo ""
    echo "Note: This script requires an OpenAI API key in a .env file"
}

# Check if .env file exists
check_env_file() {
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        echo "Warning: .env file not found in project root."
        echo "If you're running translation steps, you'll need an OpenAI API key."
        echo "Create a .env file at: $PROJECT_ROOT/.env"
        echo "Example: echo 'OPENAI_API_KEY=your-api-key-here' > $PROJECT_ROOT/.env"
    fi
}

# Check if dependencies are installed
check_dependencies() {
    python3 -c "import openai, dotenv, tqdm, markdown, weasyprint" 2>/dev/null || {
        echo "Error: Required Python packages not found."
        echo "Please install them using: pip install -r $PROJECT_ROOT/requirements.txt"
        exit 1
    }
}

# Create necessary directories
create_directories() {
    mkdir -p "$SPLITS_DIR" "$SPLITS_TRANSLATED_DIR" "$TRANSLATED_GROUPED_DIR" "$PDF_DIR"
}

# Extract the base name without extension
get_base_name() {
    local file_path="$1"
    local file_name=$(basename "$file_path")
    echo "${file_name%.*}"
}

# Step 1: Split markdown file
run_split() {
    local file_path="$1"
    local base_name=$(get_base_name "$file_path")
    
    echo "===== STEP 1: SPLITTING ====="
    echo "Splitting $file_path into smaller sections..."
    python3 "$APP_DIR/md_splitter.py" "$file_path"
    
    echo "Split complete. Files saved in $SPLITS_DIR/$base_name/"
    echo ""
}

# Step 2: Translate the split files
run_translate() {
    local file_path="$1"
    local model="$2"
    local base_name=$(get_base_name "$file_path")
    local split_dir="$SPLITS_DIR/$base_name"
    
    echo "===== STEP 2: TRANSLATION ====="
    
    if [ ! -d "$split_dir" ]; then
        echo "Error: Split directory not found at $split_dir"
        echo "Did you run the split step first?"
        exit 1
    fi
    
    echo "Translating files in $split_dir using model: $model"
    python3 "$APP_DIR/md_translator.py" "$base_name" "" "$model"
    
    echo "Translation complete. Files saved in $SPLITS_TRANSLATED_DIR/$base_name/"
    echo ""
}

# Step 3: Concatenate the translated files
run_concatenate() {
    local file_path="$1"
    local base_name=$(get_base_name "$file_path")
    
    echo "===== STEP 3: CONCATENATION ====="
    echo "Concatenating translated files..."
    
    if [ ! -d "$SPLITS_TRANSLATED_DIR/$base_name" ]; then
        echo "Error: Translated directory not found at $SPLITS_TRANSLATED_DIR/$base_name"
        echo "Did you run the translation step first?"
        exit 1
    fi
    
    python3 "$APP_DIR/md_concatenator.py"
    
    # Verify the concatenated file exists
    if [ ! -f "$TRANSLATED_GROUPED_DIR/$base_name.md" ]; then
        echo "Warning: Expected concatenated file not found at $TRANSLATED_GROUPED_DIR/$base_name.md"
    else
        echo "Concatenation complete. File saved as $TRANSLATED_GROUPED_DIR/$base_name.md"
    fi
    echo ""
}

# Step 4: Generate PDF from translated file
run_pdf() {
    local file_path="$1"
    local css_file="$2"
    local output_name="$3"
    local base_name=$(get_base_name "$file_path")
    local translated_file="$TRANSLATED_GROUPED_DIR/$base_name.md"
    
    echo "===== STEP 4: PDF GENERATION ====="
    
    # Use split translated files directly
    local source_dir="$SPLITS_TRANSLATED_DIR/$base_name"
    
    # Check if translations exist
    if [ ! -d "$source_dir" ]; then
        echo "Error: No translated files found at $source_dir"
        echo "Did you run the translation step first?"
        exit 1
    fi
    
    # Determine output file name
    if [ -z "$output_name" ]; then
        output_pdf="$PDF_DIR/${base_name}.pdf"
    else
        output_pdf="$PDF_DIR/${output_name}.pdf"
    fi
    
    # Generate PDF directly from the split directory
    echo "Generating PDF from split translated files..."
    echo "Using CSS file: $css_file"
    echo "Output will be saved to: $output_pdf"
    
    # Use md_to_pdf.py with recursive and merge flags, and add cleanup flag
    python3 "$APP_DIR/md_to_pdf.py" -s "$css_file" -r -m --cleanup "$source_dir" -o "$output_pdf"
    
    if [ -f "$output_pdf" ]; then
        echo "PDF generation complete. File saved as $output_pdf"
    else
        echo "Error: PDF generation failed."
    fi
    echo ""
}

# Run the entire process
run_all() {
    local file_path="$1"
    local model="$2"
    local css_file="$3"
    local output_name="$4"
    
    run_split "$file_path"
    run_translate "$file_path" "$model"
    run_concatenate "$file_path"
    run_pdf "$file_path" "$css_file" "$output_name"
    
    echo "===== COMPLETE ====="
    local base_name=$(get_base_name "$file_path")
    if [ -z "$output_name" ]; then
        echo "Full translation workflow completed for $base_name"
        echo "PDF available at: $PDF_DIR/${base_name}.pdf"
    else
        echo "Full translation workflow completed for $base_name"
        echo "PDF available at: $PDF_DIR/${output_name}.pdf"
    fi
}

# Main script execution
main() {
    local step="all"
    local model="gpt-4o"
    local css_file="$PROJECT_ROOT/templates/publish_two_columns.css"
    local output_name=""
    local file_path=""
    
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
            *)
                if [[ -z "$file_path" ]]; then
                    file_path="$1"
                    # Handle relative paths
                    if [[ ! "$file_path" = /* ]]; then
                        file_path="$PROJECT_ROOT/$file_path"
                    fi
                    
                    if [ ! -f "$file_path" ]; then
                        echo "Error: File not found: $file_path"
                        exit 1
                    fi
                    
                    shift
                else
                    echo "Error: Unexpected argument: $1"
                    show_help
                    exit 1
                fi
                ;;
        esac
    done
    
    # Check if a file path was provided
    if [[ -z "$file_path" ]]; then
        echo "Error: No markdown file specified."
        show_help
        exit 1
    fi
    
    # Check environment and dependencies
    check_env_file
    check_dependencies
    create_directories
    
    # Execute requested step
    case "$step" in
        split)
            run_split "$file_path"
            ;;
        translate)
            run_translate "$file_path" "$model"
            ;;
        concat|concatenate)
            run_concatenate "$file_path"
            ;;
        pdf)
            run_pdf "$file_path" "$css_file" "$output_name"
            ;;
        all)
            run_all "$file_path" "$model" "$css_file" "$output_name"
            ;;
        *)
            echo "Error: Invalid step specified: $step"
            echo "Valid steps are: split, translate, concat, pdf, all"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"