# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains "Curse of Strahd: Reloaded" - a comprehensive guide for Dungeon Masters running the D&D 5e module "Curse of Strahd". The guide is primarily written in Markdown and organized into acts, arcs, and chapters.

The repository also includes translation scripts that help convert the English content to French.

## Translation Tools

The repository contains three main Python scripts in the `/translations` directory for handling markdown translation:

1. **md_splitter.py**: Splits large markdown files into smaller components for easier translation
   - Usage: `python md_splitter.py <markdown_file>`
   - Creates a directory named `<filename>_split` containing the split files

2. **md_translator.py**: Translates markdown files from English to French using OpenAI API
   - Usage: `python md_translator.py <input_directory> [output_directory]`
   - Requires an OpenAI API key set as `OPENAI_API_KEY` environment variable
   - Creates an output directory named `<input_directory>_french` by default

3. **md_concatenator.py**: Reassembles split files into complete documents
   - Usage: `python md_concatenator.py [base_directory]`
   - Finds folders starting with "Act" or "Arc" and combines their markdown files

## Environment Setup

1. Create a `.env` file in the root directory with your OpenAI API key:
   ```
   OPENAI_API_KEY=your-api-key-here
   ```

2. Install the required Python dependencies:
   ```bash
   pip install openai python-dotenv tqdm
   ```

## Translation Workflow

1. **Split a markdown file into smaller parts**:
   ```bash
   python translations/md_splitter.py "Act II Summary.md"
   ```

2. **Translate the split files**:
   ```bash
   python translations/md_translator.py "Act II Summary_split"
   ```

3. **Reassemble the translated files** (if needed):
   ```bash
   python translations/md_concatenator.py "translations"
   ```

## Repository Structure

The repository is organized into:

- **Act folders** (Act I - Into the Mists, Act II - The Shadowed Town, etc.) which contain individual adventure arcs
- **Chapter folders** with background information and setup materials
- **Appendices** with reference materials like NPCs and items
- **Introduction** with guide usage information and acknowledgments
- **images** containing artwork for the campaign
- **translations** containing scripts and translated content

## Git Workflow

When working on translations:
1. Make changes on a feature branch (e.g., `french-translation`)
2. Push changes regularly
3. Create PRs targeting the `main` branch when complete

## Python Formating

- Keep all imports at the top, 'import' first and then 'from' imports, in alphabetical order

## Additional Notes

- When translating content, be careful to preserve markdown formatting, character names, and D&D terminology
- Follow the French translation system prompt guidelines in `md_translator.py` for consistent translations
- The guide is designed to be read in Obsidian or similar markdown viewers