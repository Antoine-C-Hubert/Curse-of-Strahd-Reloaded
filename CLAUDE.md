# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains "Curse of Strahd: Reloaded" - a comprehensive guide for Dungeon Masters running the D&D 5e module "Curse of Strahd". The guide is primarily written in Markdown and organized into acts, arcs, and chapters.

The repository also includes translation scripts that help convert the English content to French.

## Translation Tools

The repository contains four main Python scripts in the `/app` directory for handling markdown translation and PDF generation:

1. **md_splitter.py**: Splits large markdown files into smaller sections based on header levels
   - Usage: `python app/md_splitter.py <markdown_file>`
   - Files are saved to `translations/splits/<filename>/`

2. **md_translator.py**: Translates markdown files from English to French using OpenAI API
   - Usage: `python app/md_translator.py <input_directory> [output_directory] [model]`
   - By default, reads from `translations/splits/` and outputs to `translations/splits_translated/`
   - Requires an OpenAI API key set as `OPENAI_API_KEY` environment variable

3. **md_concatenator.py**: Reassembles translated split files back into complete documents
   - Usage: `python app/md_concatenator.py [base_directory]`
   - By default, reads from `translations/splits_translated/` and outputs to `translations/translated_grouped/`

4. **md_to_pdf.py**: Converts markdown files to PDF format with optional styling
   - Usage: `python app/md_to_pdf.py [OPTIONS] input`
   - Options:
     - `-o, --output OUTPUT`: Output PDF file or directory
     - `-s, --style STYLE`: CSS stylesheet for PDF styling (in the templates directory)
     - `-r, --recursive`: Process directories recursively
     - `-m, --merge`: Merge all input files into a single PDF

## Unified Script

The repository includes a `run.sh` script in the `/scripts` directory that provides a single, unified interface for handling the entire translation workflow:

```bash
Usage: ./scripts/run.sh [OPTIONS] <markdown_file>

Options:
  -h, --help               Show this help message
  -s, --step STEP          Specify which step to run (split,translate,concat,pdf,all)
                           Default: all
  -m, --model MODEL        Specify OpenAI model (default: gpt-4o)
  -c, --css FILE           Specify CSS file for PDF styling (default: templates/publish_two_columns.css)
  -o, --output FILE        Specify output PDF file name (without extension)
```

### Complete workflow example:

```bash
./scripts/run.sh "Act III - The Broken Land/Act III Summary.md"
```

### Run specific steps:

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

### PDF generation with different layouts:

```bash
# Generate PDF with default two-column layout
./scripts/run.sh -s pdf "Act III - The Broken Land/Act III Summary.md"

# Generate single-column PDF (override default)
./scripts/run.sh -s pdf -c publish.css "Act III - The Broken Land/Act III Summary.md"

# Generate PDF for multiple files with custom output name
./scripts/run.sh -s pdf -o "Complete_Campaign_Guide" "Act I - Into the Mists/Act I Summary.md" "Act II - The Shadowed Town/Act II Summary.md"
```

The CSS files for styling are stored in the `templates/` directory:
- `publish_two_columns.css` - Default two-column layout styling
- `publish.css` - Single-column styling (use with `-c publish.css` option)

## Environment Setup

1. Create a `.env` file in the root directory with your OpenAI API key:
   ```
   OPENAI_API_KEY=your-api-key-here
   ```

2. Install the required Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

Required Python packages:
- For translation: `openai`, `python-dotenv`, `tqdm`
- For PDF generation: `markdown`, `weasyprint`, `tqdm`

## Repository Structure

The repository is organized into:

- **Act folders** (Act I - Into the Mists, Act II - The Shadowed Town, etc.) which contain individual adventure arcs
- **Chapter folders** with background information and setup materials
- **Appendices** with reference materials like NPCs and items
- **Introduction** with guide usage information and acknowledgments
- **app** containing Python scripts for the translation and PDF generation workflow
- **images** containing artwork for the campaign
- **scripts** containing shell scripts like `run.sh` for automating workflows
- **templates** containing CSS stylesheets for PDF generation
- **translations** containing the following subdirectories:
  - **splits** - Original content split into smaller files for translation
  - **splits_translated** - Translated versions of the split files
  - **translated_grouped** - Reassembled translated files
  - **pdf** - Final PDF outputs

## Translation Workflow

The complete translation workflow follows these steps:

1. **Split** markdown files → `translations/splits/`
2. **Translate** split files → `translations/splits_translated/`
3. **Concatenate** translated files → `translations/translated_grouped/` 
4. **Generate PDFs** from translated files → `translations/pdf/`

## Python Formatting

- Keep all imports at the top
- direct 'import' first, each in alphabetical order
- then 'from ... import ...', each in alphabetical order

## Additional Notes

- When translating content, be careful to preserve markdown formatting, character names, and D&D terminology
- Follow the French translation system prompt guidelines in `md_translator.py` for consistent translations
- The guide is designed to be read in Obsidian or similar markdown viewers
- Use the unified `run.sh` script for the most efficient workflow