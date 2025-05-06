# Curse of Strahd Reloaded Scripts

This directory contains utility scripts for working with the Curse of Strahd Reloaded project.

## Translation and PDF Generation Workflow

The complete translation workflow follows these steps:

1. **Split** markdown files → `translations/splits/`
2. **Translate** split files → `translations/splits_translated/`
3. **Concatenate** translated files → `translations/translated_grouped/` 
4. **Generate PDFs** from translated files → `translations/pdf/`

You can use individual Python scripts for each step or the unified shell scripts.

## Python Scripts (Direct Use)

### app/md_splitter.py

Splits a markdown file into smaller sections based on header levels.

```bash
Usage: python app/md_splitter.py <markdown_file> <output_directory>
```

**Example workflow**:
```bash
# Create required directories
mkdir -p translations/splits/

# Split a markdown file (e.g., from Act IV)
python app/md_splitter.py "Act IV - Secrets of the Ancient/Arc S - A Sword of Sunlight.md" "translations/splits/"

# This creates:
# - translations/splits/Arc S - A Sword of Sunlight_split/ (directory with all split files)
# - Each file is numbered and organized by headers
```

### app/md_translator.py

Translates markdown files from English to French using OpenAI API.

```bash
Usage: python app/md_translator.py <input_directory> [output_directory]
```

**Example workflow**:
```bash
# Create required directories
mkdir -p translations/splits_translated/

# Translate the split files
python app/md_translator.py "translations/splits/Arc S - A Sword of Sunlight_split" "translations/splits_translated/"

# This creates:
# - translations/splits_translated/Arc S - A Sword of Sunlight_split/ (with translated files)
# - Each file maintains the same structure but with French content
```

### app/md_concatenator.py

Reassembles translated split files back into complete documents.

```bash
Usage: python app/md_concatenator.py <input_directory> [output_directory]
```

**Example workflow**:
```bash
# Create required directories
mkdir -p translations/translated_grouped/

# Concatenate the translated files
python app/md_concatenator.py "translations/splits_translated/" "translations/translated_grouped/"

# This creates:
# - translations/translated_grouped/Arc S - A Sword of Sunlight_french.md (assembled translation)
```

### app/md_to_pdf.py

Converts markdown files to PDF format with optional styling.

```bash
Usage: python app/md_to_pdf.py [OPTIONS] input

Options:
  -h, --help                Show this help message
  -o, --output OUTPUT       Output PDF file or directory
  -s, --style STYLE         CSS stylesheet for PDF styling
  -r, --recursive           Process directories recursively
  -m, --merge               Merge all input files into a single PDF
```

**Example workflow**:
```bash
# Create required directories
mkdir -p translations/pdf/

# Convert a translated file to PDF
python app/md_to_pdf.py -s publish.css "translations/translated_grouped/Arc S - A Sword of Sunlight_french.md" -o "translations/pdf/Arc_S_french.pdf"

# Convert a directory of translated files to PDFs
python app/md_to_pdf.py -s publish.css "translations/translated_grouped/" -o "translations/pdf/" -r

# Create a merged PDF from all files in a translated directory
python app/md_to_pdf.py -s publish.css "translations/splits_translated/Arc S - A Sword of Sunlight_split" -o "translations/pdf/Arc_S_french_merged.pdf" -r -m
```

## Shell Scripts (Simplified Use)

### translate_all.sh

A comprehensive script that handles the entire translation workflow.

```bash
Usage: ./scripts/translate_all.sh [OPTIONS] <file or directory>

Options:
  -h, --help                Show this help message
  -s, --split-only          Only split the markdown file(s)
  -t, --translate-only      Only translate the split files
  -c, --concatenate-only    Only concatenate the translated files
  -m, --model MODEL         Specify OpenAI model (default: gpt-4o)
  -o, --output-dir DIR      Specify output directory for translated files
```

**Example workflow**:
```bash
# Complete translation workflow (split, translate, concatenate)
./scripts/translate_all.sh "Act IV - Secrets of the Ancient/Arc S - A Sword of Sunlight.md"

# Only split a markdown file (output to translations/splits/)
./scripts/translate_all.sh -s "Act IV - Secrets of the Ancient/Arc S - A Sword of Sunlight.md"

# Only translate already split files 
./scripts/translate_all.sh -t "translations/splits/Arc S - A Sword of Sunlight_split"

# Only concatenate already translated files
./scripts/translate_all.sh -c "translations/splits_translated/"
```

### pdf_export.sh

Converts markdown files to PDF format.

```bash
Usage: ./scripts/pdf_export.sh [OPTIONS] <file or directory>

Options:
  -h, --help                Show this help message
  -o, --output PATH         Specify output file or directory
  -s, --style CSS_FILE      Specify a CSS stylesheet for PDF styling
  -r, --recursive           Process directories recursively
  -m, --merge               Merge all input files into a single PDF
  -a, --all                 Export all content to PDFs (organized by section)
  -f, --french              Process French translations instead of English originals
```

**Example workflow**:
```bash
# Convert a translated markdown file to PDF
./scripts/pdf_export.sh -f "translations/translated_grouped/Arc S - A Sword of Sunlight_french.md" -o "translations/pdf/Arc_S_french.pdf"

# Convert all files in a translated directory to PDFs
./scripts/pdf_export.sh -f "translations/translated_grouped/" -o "translations/pdf/" -r

# Merge all files in a translated directory into a single PDF
./scripts/pdf_export.sh -f -m "translations/translated_grouped/" -o "translations/pdf/All_Translations.pdf"

# Export all French translations to PDFs (organized by section)
./scripts/pdf_export.sh -f -a
```

## Complete End-to-End Example

Here's a complete workflow for translating and generating PDFs from an Act IV file:

```bash
# 1. Ensure required directories exist
mkdir -p translations/splits/ translations/splits_translated/ translations/translated_grouped/ translations/pdf/

# 2. Split the markdown file
python app/md_splitter.py "Act IV - Secrets of the Ancient/Arc S - A Sword of Sunlight.md" "translations/splits/"

# 3. Translate the split files
python app/md_translator.py "translations/splits/Arc S - A Sword of Sunlight_split" "translations/splits_translated/"

# 4. Concatenate the translated files
python app/md_concatenator.py "translations/splits_translated/" "translations/translated_grouped/"

# 5. Generate PDF from the translated file
python app/md_to_pdf.py -s publish.css "translations/translated_grouped/Arc S - A Sword of Sunlight_french.md" -o "translations/pdf/Arc_S_french.pdf"

# OR use the shell scripts for a simpler workflow:

# Steps 1-4 (split, translate, concatenate)
./scripts/translate_all.sh "Act IV - Secrets of the Ancient/Arc S - A Sword of Sunlight.md"

# Step 5 (generate PDF)
./scripts/pdf_export.sh -f "translations/translated_grouped/Arc S - A Sword of Sunlight_french.md" -o "translations/pdf/Arc_S_french.pdf"
```

## Required Dependencies

Install all required dependencies:

```bash
pip install -r requirements.txt
```

For the translation script, you'll need to create a `.env` file in the project root with your OpenAI API key:

```
OPENAI_API_KEY=your-api-key-here
```

Required Python packages:
- For translation: `openai`, `python-dotenv`, `tqdm`
- For PDF generation: `markdown`, `weasyprint`, `tqdm`