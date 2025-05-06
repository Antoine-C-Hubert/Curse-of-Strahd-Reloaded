# Curse of Strahd: Reloaded

A comprehensive, restructured guide for Dungeon Masters running the D&D 5e module "Curse of Strahd" with multilingual support.

## About This Project

Curse of Strahd: Reloaded is a complete reworking of the original adventure module, reorganized into acts and arcs for easier planning and execution. This guide provides DMs with a structured approach to running the campaign, complete with detailed NPCs, locations, and storylines.

## Features

- **Narrative Structure**: Adventure content organized into acts and story arcs
- **Enhanced Content**: Extended storylines, character motivations, and locations
- **DM Resources**: Ready-to-use NPC descriptions, maps, and encounter guidance
- **Translation Support**: Tools for translating content to other languages (currently focusing on French)
- **PDF Generation**: Convert markdown files to professionally formatted PDFs

## Repository Structure

- **Act I-IV folders**: Main adventure content organized chronologically
- **Chapter folders**: Background information and setup materials
- **Appendices**: Reference materials for NPCs, items, and glossary
- **Introduction**: Guide usage information and acknowledgments
- **app**: Python scripts for translation and PDF generation
- **images**: Artwork and maps for the campaign
- **scripts**: Shell scripts for automating workflows
- **translations**: Translation output directories

## Translation Tools

This repository includes tools to translate the adventure content to French:

1. **Split**: Break down markdown files into manageable sections
2. **Translate**: Convert sections to French using OpenAI's API
3. **Concatenate**: Reassemble translated sections
4. **Generate PDF**: Create polished PDF documents from markdown

### Quick Start

The entire translation workflow can be executed with a single command:

```bash
./scripts/run.sh "Act III - The Broken Land/Act III Summary.md"
```

For more detailed information about the translation tools, please see:
- [scripts/README.md](scripts/README.md) - Detailed usage instructions
- [CLAUDE.md](CLAUDE.md) - Comprehensive guide for working with this repository

## Setup

1. Clone this repository
2. Create a `.env` file in the root directory with your OpenAI API key:
   ```
   OPENAI_API_KEY=your-api-key-here
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Usage

The guide is designed to be read in Markdown viewers like Obsidian. To use:

1. Browse content by act and story arc
2. Use the translation tools to generate content in your preferred language
3. Generate PDFs for printing or distribution

## Contributing

Contributions to improve the guide or translation tools are welcome. Please maintain the established formatting conventions and code style.

## License

This project is an enhancement of the official "Curse of Strahd" adventure by Wizards of the Coast. The original content is subject to the Wizards of the Coast Fan Content Policy. The additional content and tools are provided for non-commercial use by DMs running the adventure.