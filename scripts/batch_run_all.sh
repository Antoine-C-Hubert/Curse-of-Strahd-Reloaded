#!/bin/bash

# batch_run_all.sh - Comprehensive batch processing script
# This script processes both the main campaign guide and reference materials

set -e  # Exit immediately if a command exits with a non-zero status

# Set paths relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Display help message
show_help() {
    echo "Curse of Strahd Reloaded - Comprehensive Batch Processing Script"
    echo "-------------------------------------------------------------"
    echo "Usage: ./batch_run_all.sh [OPTIONS] [TARGET]"
    echo ""
    echo "Targets:"
    echo "  guide                   Process main campaign guide files (using files_list.txt)"
    echo "  chapters                Process all Chapter folders"
    echo "  appendices              Process all Appendices"
    echo "  reference               Process both chapters and appendices"
    echo "  all                     Process everything (default)"
    echo ""
    echo "Options:"
    echo "  -h, --help               Show this help message"
    echo "  -s, --step STEP          Specify which step to run (split,translate,concat,pdf,all)"
    echo "                           Default: all"
    echo "  -m, --model MODEL        Specify Claude model (default: claude-sonnet-4-6)"
    echo "  -c, --css FILE           Specify CSS file for PDF styling (default: publish_two_columns.css)"
    echo "  --no-guide-merge         Skip merging the main guide into a single PDF"
    echo "  --no-reference-merge     Skip merging reference materials into combined PDFs"
    echo ""
    echo "Examples:"
    echo "  # Process everything with default settings:"
    echo "  ./batch_run_all.sh"
    echo ""
    echo "  # Process only the main guide:"
    echo "  ./batch_run_all.sh guide"
    echo ""
    echo "  # Process only reference materials:"
    echo "  ./batch_run_all.sh reference"
    echo ""
    echo "  # Only perform translation step for everything:"
    echo "  ./batch_run_all.sh -s translate all"
    echo ""
    echo "  # Process chapters only, skip merging:"
    echo "  ./batch_run_all.sh --no-reference-merge chapters"
    echo ""
    echo "Note: This script requires an OpenAI API key in a .env file"
}

# Process main guide files from files_list.txt
process_guide() {
    local step="$1"
    local model="$2"
    local css_file="$3"
    local merge_guide="$4"
    
    echo "===== PROCESSING MAIN CAMPAIGN GUIDE ====="
    
    # Check if files_list.txt exists
    if [ ! -f "$PROJECT_ROOT/files_list.txt" ]; then
        echo "Warning: files_list.txt not found. Skipping main guide processing."
        return 0
    fi
    
    # Process files using the existing batch script approach
    echo "Processing files from files_list.txt..."
    
    while IFS= read -r line; do
        # Remove line number if present (assumes tab separation)
        file_path=$(echo "$line" | sed -E 's/^[0-9]+\s+//')
        
        # Skip empty lines
        if [ -z "$file_path" ]; then
            continue
        fi
        
        echo "---------------------------------------"
        echo "Processing: $file_path"
        echo "---------------------------------------"
        
        # First cleanup temp directories
        rm -rf "$PROJECT_ROOT/tmp/temp_splits_*" "$PROJECT_ROOT/tmp/temp_pdfs_*" 2>/dev/null || true
        
        # Run the translation workflow on this file
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
                "$SCRIPT_DIR/run.sh" -s pdf -c "$css_file" "$file_path"
                ;;
            all)
                "$SCRIPT_DIR/run.sh" -m "$model" -c "$css_file" "$file_path"
                ;;
        esac
        
        # Optional: add a small delay between files
        sleep 1
    done < "$PROJECT_ROOT/files_list.txt"
    
    # If merging is enabled and we processed PDFs, create the merged guide
    if [ "$merge_guide" = true ] && [[ "$step" == "pdf" || "$step" == "all" ]]; then
        echo "---------------------------------------"
        echo "Creating merged campaign guide PDF..."
        "$SCRIPT_DIR/merge_pdfs.sh" -o "Campaign_Guide_Complete"
    fi
    
    echo "===== MAIN GUIDE PROCESSING COMPLETE ====="
}

# Process reference materials
process_reference() {
    local target="$1"
    local step="$2"
    local model="$3"
    local css_file="$4"
    local merge_reference="$5"
    
    echo "===== PROCESSING REFERENCE MATERIALS ($target) ====="
    
    # Determine output names for merged PDFs
    local output_name=""
    if [ "$merge_reference" = true ]; then
        case "$target" in
            chapters)
                output_name="Reference_Chapters"
                ;;
            appendices)
                output_name="Reference_Appendices"
                ;;
            reference)
                # Process both separately
                echo "Processing chapters..."
                "$SCRIPT_DIR/run_reference.sh" -s "$step" -m "$model" -c "$css_file" -o "Reference_Chapters" chapters
                echo "Processing appendices..."
                "$SCRIPT_DIR/run_reference.sh" -s "$step" -m "$model" -c "$css_file" -o "Reference_Appendices" appendices
                return 0
                ;;
        esac
    fi
    
    # Run the reference processing script
    if [ -n "$output_name" ]; then
        "$SCRIPT_DIR/run_reference.sh" -s "$step" -m "$model" -c "$css_file" -o "$output_name" "$target"
    else
        "$SCRIPT_DIR/run_reference.sh" -s "$step" -m "$model" -c "$css_file" "$target"
    fi
    
    echo "===== REFERENCE MATERIALS PROCESSING COMPLETE ====="
}

# Main script execution
main() {
    local target="all"
    local step="all"
    local model="claude-sonnet-4-6"
    local css_file="publish_two_columns.css"
    local merge_guide=true
    local merge_reference=true
    
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
                shift 2
                ;;
            --no-guide-merge)
                merge_guide=false
                shift
                ;;
            --no-reference-merge)
                merge_reference=false
                shift
                ;;
            guide|chapters|appendices|reference|all)
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
    
    echo "Curse of Strahd Reloaded - Batch Processing"
    echo "==========================================="
    echo "Target: $target"
    echo "Step: $step"
    echo "Model: $model"
    echo "CSS: $css_file"
    echo "Guide merge: $merge_guide"
    echo "Reference merge: $merge_reference"
    echo "==========================================="
    echo ""
    
    # Execute based on target
    case "$target" in
        guide)
            process_guide "$step" "$model" "$css_file" "$merge_guide"
            ;;
        chapters)
            process_reference "chapters" "$step" "$model" "$css_file" "$merge_reference"
            ;;
        appendices)
            process_reference "appendices" "$step" "$model" "$css_file" "$merge_reference"
            ;;
        reference)
            process_reference "reference" "$step" "$model" "$css_file" "$merge_reference"
            ;;
        all)
            process_guide "$step" "$model" "$css_file" "$merge_guide"
            echo ""
            process_reference "reference" "$step" "$model" "$css_file" "$merge_reference"
            ;;
        *)
            echo "Error: Invalid target specified: $target"
            show_help
            exit 1
            ;;
    esac
    
    echo ""
    echo "===== BATCH PROCESSING COMPLETE ====="
    echo "All specified targets have been processed."
    echo "Check the translations/pdf directory for output files."
}

# Execute main function
main "$@"