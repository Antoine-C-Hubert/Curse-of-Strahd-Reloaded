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

## Translation Scripts

The repository includes several scripts in the `/scripts` directory for different translation workflows:

### Main Campaign Guide Script

The `run.sh` script provides a unified interface for processing individual files from the main campaign guide:

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

### Reference Materials Script

The `run_reference.sh` script handles Chapter folders and Appendices separately from the main guide:

```bash
Usage: ./scripts/run_reference.sh [OPTIONS] [TARGET]

Targets:
  chapters                 Process all Chapter folders
  appendices              Process all Appendices
  all                     Process both chapters and appendices (default)

Options:
  -h, --help               Show this help message
  -s, --step STEP          Specify which step to run (split,translate,concat,pdf,all)
  -m, --model MODEL        Specify OpenAI model (default: gpt-4o)
  -c, --css FILE           Specify CSS file for PDF styling
  -o, --output FILE        Specify output PDF file name (creates combined PDF)
```

### Comprehensive Batch Processing

The `batch_run_all.sh` script processes everything in one go:

```bash
Usage: ./scripts/batch_run_all.sh [OPTIONS] [TARGET]

Targets:
  guide                   Process main campaign guide files (using files_list.txt)
  chapters                Process all Chapter folders
  appendices              Process all Appendices
  reference               Process both chapters and appendices
  all                     Process everything (default)

Options:
  --no-guide-merge        Skip merging the main guide into a single PDF
  --no-reference-merge    Skip merging reference materials into combined PDFs
```

## Workflow Examples

### Processing Individual Files

```bash
# Complete workflow for a single file
./scripts/run.sh "Act III - The Broken Land/Act III Summary.md"

# Only translate a file (requires previous split)
./scripts/run.sh -s translate "Act III - The Broken Land/Act III Summary.md"

# Generate PDF with custom styling
./scripts/run.sh -s pdf -c publish.css "Act III - The Broken Land/Act III Summary.md"
```

### Processing Reference Materials

```bash
# Process all reference materials
./scripts/run_reference.sh

# Process only chapters with combined PDF output
./scripts/run_reference.sh -o "Chapters_Guide" chapters

# Only translate appendices
./scripts/run_reference.sh -s translate appendices
```

### Batch Processing Everything

```bash
# Process everything with default settings
./scripts/batch_run_all.sh

# Process only the main guide
./scripts/batch_run_all.sh guide

# Process everything but skip PDF merging
./scripts/batch_run_all.sh --no-guide-merge --no-reference-merge all
```

### PDF Merging

```bash
# Merge main guide PDFs into complete guide
./scripts/merge_pdfs.sh

# Merge reference materials separately
./scripts/merge_reference_pdfs.sh

# Create custom reference merge
./scripts/merge_reference_pdfs.sh -o "Custom_Reference" chapters
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

## Output Files

The translation process creates several types of output files:

### Individual PDFs
- Each markdown file produces a separate PDF in `translations/pdf/`
- Individual Chapter files: `Character Creation.pdf`, `Session Zero.pdf`, etc.
- Individual Appendices files: `Amber Shards.pdf`, `Glossary.pdf`, etc.
- Campaign guide files: `Act I Summary.pdf`, `Arc A - Escape From Death House.pdf`, etc.

### Merged PDFs (stored in `translations/`)
- **Campaign_Guide_Complete.pdf** - Complete main campaign guide (from `merge_pdfs.sh`)
- **Reference_Chapters.pdf** - All Chapter materials combined (from `merge_reference_pdfs.sh`)
- **Reference_Appendices.pdf** - All Appendices combined (from `merge_reference_pdfs.sh`)
- Custom named PDFs when using the `-o` option with various scripts

This separation allows you to:
- Distribute the main campaign guide separately from reference materials
- Provide players with just the reference materials they need
- Maintain modular access to individual sections

## Python Formatting

- Keep all imports at the top
- direct 'import' first, each in alphabetical order
- then 'from ... import ...', each in alphabetical order

## Git Rules
- Never commit yourself
- Instead, only propose a commit message when the task is done

## Additional Notes

- When translating content, be careful to preserve markdown formatting, character names, and D&D terminology
- Follow the French translation system prompt guidelines in `md_translator.py` for consistent translations
- The guide is designed to be read in Obsidian or similar markdown viewers
- Use the unified `run.sh` script for the most efficient workflow