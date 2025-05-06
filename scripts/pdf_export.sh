#!/bin/bash

# pdf_export.sh - A script to convert markdown files to PDFs for Curse of Strahd Reloaded

set -e  # Exit immediately if a command exits with a non-zero status

# Display help message
show_help() {
    echo "Curse of Strahd Reloaded - PDF Export Tool"
    echo "----------------------------------------"
    echo "Usage: ./pdf_export.sh [OPTIONS] <file or directory>"
    echo ""
    echo "Options:"
    echo "  -h, --help                Show this help message"
    echo "  -o, --output PATH         Specify output file or directory"
    echo "  -s, --style CSS_FILE      Specify a CSS stylesheet for PDF styling"
    echo "  -r, --recursive           Process directories recursively"
    echo "  -m, --merge               Merge all input files into a single PDF"
    echo "  -a, --all                 Export all content to PDFs (organized by section)"
    echo "  -f, --french              Process French translations instead of English originals"
    echo ""
    echo "Examples:"
    echo "  # Convert a single file to PDF:"
    echo "  ./pdf_export.sh \"Act I Summary.md\""
    echo ""
    echo "  # Convert all files in a directory to PDFs:"
    echo "  ./pdf_export.sh \"Act I - Into the Mists\""
    echo ""
    echo "  # Convert all files in a directory and all subdirectories:"
    echo "  ./pdf_export.sh -r \"Act I - Into the Mists\""
    echo ""
    echo "  # Merge all files in a directory into a single PDF:"
    echo "  ./pdf_export.sh -m -o \"act1.pdf\" \"Act I - Into the Mists\""
    echo ""
    echo "  # Export the entire guide as organized PDFs:"
    echo "  ./pdf_export.sh -a"
    echo ""
    echo "  # Export using a custom stylesheet:"
    echo "  ./pdf_export.sh -s \"custom_style.css\" \"Act I Summary.md\""
    echo ""
    echo "  # Export French translations:"
    echo "  ./pdf_export.sh -f \"Act I Summary.md\""
    echo ""
    echo "Note: This script requires Python with markdown, weasyprint, and tqdm packages"
}

# Check if dependencies are installed
check_dependencies() {
    python3 -c "import markdown, weasyprint, tqdm" 2>/dev/null || {
        echo "Error: Required Python packages not found."
        echo "Please install them using: pip install -r requirements.txt"
        exit 1
    }
}

# Export all content
export_all() {
    local french=$1
    local style=$2
    local output_dir="pdf_export"
    
    if [ "$french" = true ]; then
        output_dir="pdf_export_french"
    fi
    
    # Create main output directory
    mkdir -p "$output_dir"
    
    # Define the sections to export
    SECTIONS=(
        "Introduction"
        "Chapter 1 - Beginning the Campaign"
        "Chapter 2 - The Land of Barovia"
        "Chapter 3 - Running the Game"
        "Act I - Into the Mists"
        "Act II - The Shadowed Town"
        "Act III - The Broken Land"
        "Act IV - Secrets of the Ancient"
        "Appendices"
    )
    
    # Process each section
    for section in "${SECTIONS[@]}"; do
        echo "===================================================="
        echo "Processing section: $section"
        echo "===================================================="
        
        # Create section directory
        section_dir="$output_dir/$(basename "$section")"
        mkdir -p "$section_dir"
        
        # Create two PDFs for this section:
        # 1. Individual PDF files for each markdown file
        # 2. A combined PDF with all content
        
        # First, determine which directory to use (English or French)
        source_dir="$section"
        if [ "$french" = true ]; then
            # Look for French translations
            if [ -d "translations/${section}_french" ]; then
                source_dir="translations/${section}_french"
            elif [ -d "translations/${section}" ]; then
                source_dir="translations/${section}"
            else
                echo "Warning: No French translation found for $section, skipping..."
                continue
            fi
        fi
        
        # Check if the source directory exists
        if [ ! -d "$source_dir" ]; then
            echo "Warning: Directory $source_dir does not exist, skipping..."
            continue
        fi
        
        # Individual files
        echo "Converting individual files in $source_dir..."
        python3 "$(dirname "$(dirname "$0")")/app/md_to_pdf.py" -r "$source_dir" -o "$section_dir" ${style:+-s "$style"}
        
        # Combined PDF
        section_base=$(basename "$section")
        echo "Creating combined PDF for $section_base..."
        python3 "$(dirname "$(dirname "$0")")/app/md_to_pdf.py" -r -m "$source_dir" -o "$section_dir/${section_base}_Complete.pdf" ${style:+-s "$style"}
        
        echo "Completed section: $section"
        echo ""
    done
    
    echo "PDF export complete! Files are in $output_dir/"
}

# Main script execution
main() {
    local output=""
    local style=""
    local recursive=false
    local merge=false
    local all=false
    local french=false
    local target=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -o|--output)
                output="$2"
                shift 2
                ;;
            -s|--style)
                style="$2"
                shift 2
                ;;
            -r|--recursive)
                recursive=true
                shift
                ;;
            -m|--merge)
                merge=true
                shift
                ;;
            -a|--all)
                all=true
                shift
                ;;
            -f|--french)
                french=true
                shift
                ;;
            *)
                if [[ -z "$target" ]]; then
                    target="$1"
                    shift
                else
                    echo "Error: Unexpected argument: $1"
                    show_help
                    exit 1
                fi
                ;;
        esac
    done
    
    # Check dependencies
    check_dependencies
    
    # Process all content if requested
    if [ "$all" = true ]; then
        export_all "$french" "$style"
        exit 0
    fi
    
    # Check if a target was provided
    if [[ -z "$target" ]]; then
        echo "Error: No target file or directory specified."
        show_help
        exit 1
    fi
    
    # Build arguments for the Python script
    args=()
    
    if [ -n "$output" ]; then
        args+=("-o" "$output")
    fi
    
    if [ -n "$style" ]; then
        args+=("-s" "$style")
    fi
    
    if [ "$recursive" = true ]; then
        args+=("-r")
    fi
    
    if [ "$merge" = true ]; then
        args+=("-m")
    fi
    
    # Process French translations if requested
    if [ "$french" = true ]; then
        # Check if the target is a file or directory
        if [ -f "$target" ]; then
            # Determine base file name without extension
            filename=$(basename -- "$target")
            base_name="${filename%.*}"
            dir_name=$(dirname "$target")
            
            # Look for French translation
            if [ -f "translations/${base_name}_french.md" ]; then
                target="translations/${base_name}_french.md"
            elif [ -f "translations/${dir_name}/${base_name}_french.md" ]; then
                target="translations/${dir_name}/${base_name}_french.md"
            else
                echo "Warning: No French translation found for $target"
            fi
        elif [ -d "$target" ]; then
            # Look for French translation directory
            if [ -d "translations/${target}_french" ]; then
                target="translations/${target}_french"
            elif [ -d "translations/${target}" ]; then
                target="translations/${target}"
            else
                echo "Warning: No French translation directory found for $target"
            fi
        fi
    fi
    
    # Execute the Python script
    echo "Running PDF export with: $target ${args[@]}"
    python3 "$(dirname "$(dirname "$0")")/app/md_to_pdf.py" "${args[@]}" "$target"
}

# Execute main function
main "$@"