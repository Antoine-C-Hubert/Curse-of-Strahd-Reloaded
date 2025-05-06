# Curse of Strahd Reloaded Scripts

This directory contains utility scripts for working with the Curse of Strahd Reloaded project.

## Translation and PDF Generation Workflow

The complete translation workflow follows these steps:

1. **Split** markdown files → `translations/splits/`
2. **Translate** split files → `translations/splits_translated/`
3. **Concatenate** translated files → `translations/translated_grouped/` 
4. **Generate PDFs** from translated files → `translations/pdf/`

## Unified Script: run.sh

The `run.sh` script provides a single, unified interface for handling the entire translation workflow from markdown to PDF generation.

```bash
Usage: ./scripts/run.sh [OPTIONS] <markdown_file>

Options:
  -h, --help               Show this help message
  -s, --step STEP          Specify which step to run (split,translate,concat,pdf,all)
                           Default: all
  -m, --model MODEL        Specify OpenAI model (default: gpt-4o)
  -c, --css FILE           Specify CSS file for PDF styling (default: publish.css)
  -o, --output FILE        Specify output PDF file name (without extension)
```

### Examples

**Complete workflow** (split, translate, concatenate, PDF generation):

```bash
./scripts/run.sh "Act III - The Broken Land/Act III Summary.md"
```

**Run specific steps**:

```bash
# Only split the file
./scripts/run.sh -s split "Act III - The Broken Land/Act III Summary.md"

# Only translate (requires previous split)
./scripts/run.sh -s translate "Act III - The Broken Land/Act III Summary.md"

# Only concatenate (requires previous translation)
./scripts/run.sh -s concat "Act III - The Broken Land/Act III Summary.md"

# Only generate PDF (requires previous concatenation)
./scripts/run.sh -s pdf "Act III - The Broken Land/Act III Summary.md"
```

**Custom options**:

```bash
# Use a different translation model
./scripts/run.sh -m gpt-3.5-turbo "Act III - The Broken Land/Act III Summary.md"

# Use a custom CSS file for PDF styling
./scripts/run.sh -c custom.css "Act III - The Broken Land/Act III Summary.md"

# Specify a custom output name for the PDF
./scripts/run.sh -o "ActIII_French" "Act III - The Broken Land/Act III Summary.md"
```

## Individual Python Scripts

You can also use the underlying Python scripts directly if needed:

### app/md_splitter.py

Splits a markdown file into smaller sections based on header levels.

```bash
python app/md_splitter.py <markdown_file>
```

Files are saved to `translations/splits/<filename>/`.

### app/md_translator.py

Translates markdown files from English to French using OpenAI API.

```bash
python app/md_translator.py <input_directory> [output_directory] [model]
```

By default, reads from `translations/splits/` and outputs to `translations/splits_translated/`.

### app/md_concatenator.py

Reassembles translated split files back into complete documents.

```bash
python app/md_concatenator.py [base_directory]
```

By default, reads from `translations/splits_translated/` and outputs to `translations/translated_grouped/`.

### app/md_to_pdf.py

Converts markdown files to PDF format with optional styling.

```bash
python app/md_to_pdf.py [OPTIONS] input

Options:
  -o, --output OUTPUT       Output PDF file or directory
  -s, --style STYLE         CSS stylesheet for PDF styling
  -r, --recursive           Process directories recursively
  -m, --merge               Merge all input files into a single PDF
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