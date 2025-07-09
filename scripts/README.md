# Translation Scripts Documentation

This directory contains scripts for translating and processing the Curse of Strahd: Reloaded content.

## Scripts Overview

### Individual File Processing
- **`run.sh`** - Process individual files from the main campaign guide

### Reference Materials Processing
- **`run_reference.sh`** - Process Chapter folders and Appendices separately
- **`merge_reference_pdfs.sh`** - Merge reference materials into combined PDFs

### Batch Processing
- **`batch_run.sh`** - Process all files listed in files_list.txt
- **`batch_run_all.sh`** - Comprehensive script to process everything
- **`merge_pdfs.sh`** - Merge main campaign guide PDFs

## Translation Workflow

The complete translation workflow follows these steps:

1. **Split** markdown files → `translations/splits/`
2. **Translate** split files → `translations/splits_translated/`
3. **Concatenate** translated files → `translations/translated_grouped/` 
4. **Generate PDFs** from translated files → `translations/pdf/`

## Usage Patterns

### For Individual Processing
```bash
# Process a single campaign file
./run.sh "Act I - Into the Mists/Act I Summary.md"

# Process reference materials
./run_reference.sh chapters
./run_reference.sh appendices
```

### For Batch Processing
```bash
# Process everything
./batch_run_all.sh

# Process only reference materials with combined PDFs
./batch_run_all.sh reference

# Process only the main guide
./batch_run_all.sh guide
```

### For PDF Merging
```bash
# Merge main guide PDFs
./merge_pdfs.sh

# Merge reference materials separately
./merge_reference_pdfs.sh
```

## Output Structure

The scripts create the following output organization:

```
translations/
├── pdf/
│   ├── Campaign Guide Files/
│   │   ├── Act I Summary.pdf
│   │   ├── Arc A - Escape From Death House.pdf
│   │   └── ...
│   └── Reference Files/
│       ├── Character Creation.pdf
│       ├── Session Zero.pdf
│       ├── Amber Shards.pdf
│       └── ...
├── Campaign_Guide_Complete.pdf
├── Reference_Chapters.pdf
└── Reference_Appendices.pdf
```

## Key Features

### Separate Processing
- **Main Guide**: Acts, Arcs, and campaign-specific content
- **Reference Materials**: Chapters (setup/background) and Appendices (reference)
- **Individual Access**: Each section remains available as individual PDFs
- **Combined Access**: Merged PDFs for complete distribution

### Flexible Workflow
- Run only specific steps (split, translate, concat, pdf)
- Process specific targets (guide, chapters, appendices, all)
- Custom output names and styling
- Skip merging if desired

### Quality Control
- Even/odd page handling for professional printing
- Consistent styling across all outputs
- Title pages and table of contents for merged documents
- Error handling and dependency checking

## Individual Python Scripts

You can also use the underlying Python scripts directly if needed:

### app/md_splitter.py
Splits a markdown file into smaller sections based on header levels.
```bash
python app/md_splitter.py <markdown_file>
```

### app/md_translator.py
Translates markdown files from English to French using OpenAI API.
```bash
python app/md_translator.py <input_directory> [output_directory] [model]
```

### app/md_concatenator.py
Reassembles translated split files back into complete documents.
```bash
python app/md_concatenator.py [base_directory]
```

### app/md_to_pdf.py
Converts markdown files to PDF format with optional styling.
```bash
python app/md_to_pdf.py [OPTIONS] input
```

## Dependencies

- Python packages: `openai`, `python-dotenv`, `tqdm`, `markdown`, `weasyprint`
- System tools: `pdftk` (for PDF merging), `wkhtmltopdf` (optional, for better title pages)
- OpenAI API key in `.env` file

## Example Workflows

### Complete Translation Workflow
```bash
# Process everything from start to finish
./batch_run_all.sh

# This creates:
# - All individual PDFs in translations/pdf/
# - Campaign_Guide_Complete.pdf in translations/
# - Reference_Chapters.pdf in translations/
# - Reference_Appendices.pdf in translations/
```

### Reference Materials Only
```bash
# Process and merge chapters separately
./run_reference.sh -o "DM_Setup_Guide" chapters

# Process and merge appendices separately  
./run_reference.sh -o "Player_Reference" appendices
```

### Custom Processing
```bash
# Translate everything but don't merge
./batch_run_all.sh -s translate all

# Later, create PDFs and merge
./batch_run_all.sh -s pdf all
```

This organization allows for flexible distribution:
- Give players just the reference materials
- Share the complete campaign guide with other DMs
- Maintain individual sections for specific use cases