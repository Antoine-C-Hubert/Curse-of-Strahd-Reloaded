# Curse of Strahd Reloaded Scripts

This directory contains utility scripts for working with the Curse of Strahd Reloaded project.

## Translation Tools

### translate_all.sh

A comprehensive script for translating markdown files from English to French.

```bash
Usage: ./translate_all.sh [OPTIONS] <file or directory>

Options:
  -h, --help                Show this help message
  -s, --split-only          Only split the markdown file(s)
  -t, --translate-only      Only translate the split files
  -c, --concatenate-only    Only concatenate the translated files
  -m, --model MODEL         Specify OpenAI model (default: gpt-4o)
  -o, --output-dir DIR      Specify output directory for translated files
```

Examples:
```bash
# Translate a single file
./translate_all.sh "Act I Summary.md"

# Only split a markdown file
./translate_all.sh -s "Act II Summary.md"

# Only translate already split files
./translate_all.sh -t "Act II Summary_split"
```

### md_splitter.py

A Python script that splits markdown files into smaller sections based on header levels. 
The script creates a new directory with the same name as the original file plus "_split" and places all split files there.

```bash
Usage: python app/md_splitter.py <markdown_file>
```

When called from the project root, the script:
1. Creates a directory named `<filename>_split` in the same location as the input file
2. Splits the file at each level 1 (`# Title`) and level 2 (`## Subtitle`) header
3. Creates an introduction file if there's content before the first header
4. Creates numbered files with sanitized titles for proper ordering

Examples:
```bash
# Split a markdown file into smaller parts
python app/md_splitter.py "Act I - Into the Mists/Arc A - Escape From Death House.md"

# The result will be a directory:
# Act I - Into the Mists/Arc A - Escape From Death House_split/
# containing the split files

# To split and use for translation:
# 1. Split the file
python app/md_splitter.py "Act IV - Secrets of the Ancient/Act IV Summary.md"

# 2. Manually copy files to translations if needed
cp -r "Act IV - Secrets of the Ancient/Act IV Summary_split" "translations/splits/"
```

Requirements:
- Python 3
- OpenAI API key in a `.env` file in the project root
- Python packages: `openai`, `python-dotenv`, `tqdm`

## PDF Export Tools

### pdf_export.sh

A script for converting markdown files to PDF format.

```bash
Usage: ./pdf_export.sh [OPTIONS] <file or directory>

Options:
  -h, --help                Show this help message
  -o, --output PATH         Specify output file or directory
  -s, --style CSS_FILE      Specify a CSS stylesheet for PDF styling
  -r, --recursive           Process directories recursively
  -m, --merge               Merge all input files into a single PDF
  -a, --all                 Export all content to PDFs (organized by section)
  -f, --french              Process French translations instead of English originals
```

Examples:
```bash
# Convert a single file to PDF
./pdf_export.sh "Act I Summary.md"

# Convert all files in a directory to PDFs
./pdf_export.sh "Act I - Into the Mists"

# Merge all files in a directory into a single PDF
./pdf_export.sh -m -o "act1.pdf" "Act I - Into the Mists"

# Export the entire guide as organized PDFs
./pdf_export.sh -a

# Export French translations
./pdf_export.sh -f "Act I Summary.md"
```

### md_to_pdf.py

A Python script that converts markdown files to PDF format. It can handle individual files or directories of markdown files and can merge multiple files into a single PDF.

```bash
Usage: python app/md_to_pdf.py [OPTIONS] input

Options:
  -h, --help                Show this help message
  -o, --output OUTPUT       Output PDF file or directory
  -s, --style STYLE         CSS stylesheet for PDF styling
  -r, --recursive           Process directories recursively
  -m, --merge               Merge all input files into a single PDF
```

Examples:
```bash
# Convert a single markdown file to PDF
python app/md_to_pdf.py -s publish.css "translations/Act I Summary_split_french.md" -o "translations/pdf/Act_I_Summary_french.pdf"

# Convert all files in a directory to individual PDFs
python app/md_to_pdf.py -s publish.css "translations/Act I Summary_split_french" -o "translations/pdf/act_i_summary_split" -r

# Merge all files in a directory into a single PDF
python app/md_to_pdf.py -s publish.css "translations/Act I Summary_split_french" -o "translations/pdf/Act_I_Summary_french_merged.pdf" -r -m

# Using pdf_export.sh is recommended for most use cases, as it handles paths and French translation detection
```

Using the script directly from the project root allows you to:
1. Generate PDFs from individual markdown files
2. Apply custom CSS styling to the PDFs
3. Process entire directories of markdown files
4. Merge multiple files into a single comprehensive PDF

Requirements:
- Python 3
- Python packages: `markdown`, `weasyprint`, `tqdm`

## Installation

Install all required dependencies using the requirements.txt file:

```bash
pip install -r requirements.txt
```

For the translation script, you'll need to create a `.env` file in the project root with your OpenAI API key:

```
OPENAI_API_KEY=your-api-key-here
```