#!/bin/bash

# translate_all.sh - A script to automate the translation workflow for Curse of Strahd Reloaded

set -e  # Exit immediately if a command exits with a non-zero status

# Display help message
show_help() {
    echo "Curse of Strahd Reloaded - Translation Automation Script"
    echo "------------------------------------------------------"
    echo "Usage: ./translate_all.sh [OPTIONS] <file or directory>"
    echo ""
    echo "Options:"
    echo "  -h, --help                Show this help message"
    echo "  -s, --split-only          Only split the markdown file(s)"
    echo "  -t, --translate-only      Only translate the split files"
    echo "  -c, --concatenate-only    Only concatenate the translated files"
    echo "  -m, --model MODEL         Specify OpenAI model (default: gpt-4o)"
    echo "  -o, --output-dir DIR      Specify output directory for translated files"
    echo ""
    echo "Examples:"
    echo "  # Full workflow - split, translate, and concatenate a single file:"
    echo "  ./translate_all.sh \"Act I Summary.md\""
    echo ""
    echo "  # Full workflow on a directory containing multiple files:"
    echo "  ./translate_all.sh \"Act I - Into the Mists\""
    echo ""
    echo "  # Only split a markdown file:"
    echo "  ./translate_all.sh -s \"Act II Summary.md\""
    echo ""
    echo "  # Only translate already split files:"
    echo "  ./translate_all.sh -t \"Act II Summary_split\""
    echo ""
    echo "  # Only concatenate translated files in the translations directory:"
    echo "  ./translate_all.sh -c \"translations\""
    echo ""
    echo "Note: This script requires an OpenAI API key in a .env file"
}

# Check if .env file exists
check_env_file() {
    # Get the project root directory
    PROJECT_ROOT="$(dirname "$(dirname "$0")")"
    
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        echo "Error: .env file not found in project root."
        echo "Please create one with your OpenAI API key at: $PROJECT_ROOT/.env"
        echo "Example: echo 'OPENAI_API_KEY=your-api-key-here' > $PROJECT_ROOT/.env"
        exit 1
    fi
}

# Check if dependencies are installed
check_dependencies() {
    python3 -c "import openai, dotenv, tqdm" 2>/dev/null || {
        echo "Error: Required Python packages not found."
        echo "Please install them using: pip install -r requirements.txt"
        exit 1
    }
}

# Function to process a single markdown file
process_file() {
    local file="$1"
    local model="$2"
    local output_dir="$3"
    local split_only="$4"
    local translate_only="$5"
    
    # Get absolute path
    file_path=$(realpath "$file")
    file_name=$(basename "$file_path")
    file_dir=$(dirname "$file_path")
    
    # Get file name without extension for split directory
    file_name_no_ext="${file_name%.*}"
    split_dir="${file_dir}/${file_name_no_ext}_split"
    
    # Step 1: Split the file if it's a markdown file and not already split
    if [[ "$file_name" == *.md ]] && [[ "$translate_only" != "true" ]]; then
        echo "Splitting $file_name into manageable chunks..."
        python3 "$(dirname "$(dirname "$0")")/app/md_splitter.py" "$file_path"
        echo "Split complete. Files saved in $split_dir"
    elif [[ "$file_name" != *.md ]] && [[ -d "$file_path" ]]; then
        split_dir="$file_path"
    fi
    
    # Exit if only splitting
    if [[ "$split_only" == "true" ]]; then
        return
    fi
    
    # Step 2: Translate the split files
    if [[ -d "$split_dir" ]]; then
        echo "Translating files in $split_dir..."
        if [[ -n "$output_dir" ]]; then
            python3 "$(dirname "$(dirname "$0")")/app/md_translator.py" "$split_dir" "$output_dir" "$model"
        else
            python3 "$(dirname "$(dirname "$0")")/app/md_translator.py" "$split_dir" "" "$model"
        fi
    else
        echo "Error: Split directory $split_dir not found."
        exit 1
    fi
}

# Function to process a directory
process_directory() {
    local dir="$1"
    local model="$2"
    local output_dir="$3"
    local split_only="$4"
    local translate_only="$5"
    
    # Get absolute path
    dir_path=$(realpath "$dir")
    
    # Find all markdown files in the directory
    find "$dir_path" -maxdepth 1 -name "*.md" | while read -r file; do
        process_file "$file" "$model" "$output_dir" "$split_only" "$translate_only"
    done
}

# Main script execution
main() {
    local split_only=false
    local translate_only=false
    local concatenate_only=false
    local model="gpt-4o"
    local output_dir=""
    local target=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--split-only)
                split_only=true
                shift
                ;;
            -t|--translate-only)
                translate_only=true
                shift
                ;;
            -c|--concatenate-only)
                concatenate_only=true
                shift
                ;;
            -m|--model)
                model="$2"
                shift 2
                ;;
            -o|--output-dir)
                output_dir="$2"
                shift 2
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
    
    # Check if a target was provided
    if [[ -z "$target" ]]; then
        echo "Error: No target file or directory specified."
        show_help
        exit 1
    fi
    
    # Check environment and dependencies
    check_env_file
    check_dependencies
    
    # Handle concatenate-only option
    if [[ "$concatenate_only" == "true" ]]; then
        echo "Concatenating translated files in $target..."
        python3 "$(dirname "$(dirname "$0")")/app/md_concatenator.py" "$target"
        echo "Concatenation complete."
        exit 0
    fi
    
    # Process the target (file or directory)
    if [[ -f "$target" ]]; then
        process_file "$target" "$model" "$output_dir" "$split_only" "$translate_only"
    elif [[ -d "$target" ]]; then
        if [[ "$translate_only" == "true" ]]; then
            # Treat the directory as a split directory to translate
            echo "Translating files in $target..."
            if [[ -n "$output_dir" ]]; then
                python3 "$(dirname "$(dirname "$0")")/app/md_translator.py" "$target" "$output_dir" "$model"
            else
                python3 "$(dirname "$(dirname "$0")")/app/md_translator.py" "$target" "" "$model"
            fi
        else
            # Process each markdown file in the directory
            process_directory "$target" "$model" "$output_dir" "$split_only" "$translate_only"
        fi
    else
        echo "Error: $target is not a valid file or directory."
        exit 1
    fi
    
    # Step 3: Concatenate the translated files (if not split-only or translate-only)
    if [[ "$split_only" != "true" ]] && [[ "$translate_only" != "true" ]]; then
        echo "Concatenating translated files..."
        if [[ -n "$output_dir" ]]; then
            python3 "$(dirname "$(dirname "$0")")/app/md_concatenator.py" "$output_dir"
        else
            # Default to translations directory if no output specified
            python3 "$(dirname "$(dirname "$0")")/app/md_concatenator.py" "$(dirname "$(dirname "$0")")/translations"
        fi
        echo "Translation workflow complete!"
    fi
}

# Execute main function
main "$@"