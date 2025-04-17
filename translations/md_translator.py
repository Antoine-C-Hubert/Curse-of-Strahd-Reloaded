#!/usr/bin/env python3

import os
import sys
import glob
import time
import json
from pathlib import Path
import openai
from tqdm import tqdm
from dotenv import load_dotenv

# Set your OpenAI API key from environment variable
# export OPENAI_API_KEY="your-api-key"

load_dotenv('.env')

def translate_markdown_files(input_dir, output_dir=None, model="gpt-4o"):
    """
    Translate markdown files from English to French using OpenAI's API.
    
    Args:
        input_dir (str): Directory containing the markdown files to translate
        output_dir (str, optional): Directory to save the translated files
        model (str, optional): OpenAI model to use for translation
    """
    # Create output directory if it doesn't exist
    if output_dir is None:
        output_dir = input_dir + "_french"
    
    os.makedirs(output_dir, exist_ok=True)
    
    # Get all markdown files sorted alphabetically
    markdown_files = sorted(glob.glob(os.path.join(input_dir, "*.md")))
    
    if not markdown_files:
        print(f"No markdown files found in {input_dir}")
        return
    
    print(f"Found {len(markdown_files)} markdown files to translate")
    
    # Get API key from environment
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        print("Error: OPENAI_API_KEY environment variable not set")
        print("Please set it with: export OPENAI_API_KEY='your-api-key'")
        sys.exit(1)
    
    # Initialize OpenAI client
    client = openai.OpenAI(api_key=api_key)
    
    # Translate each file
    for file_path in tqdm(markdown_files, desc="Translating files"):
        # Get the filename
        file_name = os.path.basename(file_path)
        output_file_path = os.path.join(output_dir, file_name)
        
        # Skip if output file already exists (for resuming interrupted translations)
        if os.path.exists(output_file_path):
            print(f"Skipping {file_name} (already translated)")
            continue
        
        # Read the markdown content
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Skip empty files
        if not content.strip():
            print(f"Skipping empty file: {file_name}")
            with open(output_file_path, 'w', encoding='utf-8') as f:
                f.write("")
            continue
        
        # Prepare the translation prompt
        system_prompt = """
        You are a professional translator specialized in translating English to French in Dungeon and Dragon 5e context.
        This specific campaign is called "Curse of Strahd Reloaded" and is in a gothic vampire theme.
        You are translating a markdown file containing the text of the campaign and aimed at DMs.
        
        Translate the provided markdown text from English to French, maintaining:
        1. Exactly the same markdown formatting (headers, lists, bold, italics, etc.)
        2. Exactly the same line breaks
        3. All HTML tags and formatting untouched
        4. Keep proper names, places, and character names unchanged
        5. Keep URLs unchanged
        6. Keep code blocks and inline code unchanged
        
        Return ONLY the translated text, with no explanations or notes.
        """
        
        user_prompt = f"Translate this English markdown text to French, preserving all formatting:\n\n{content}"
        
        # Call the OpenAI API with exponential backoff for rate limiting
        max_retries = 5
        backoff_factor = 2
        for attempt in range(max_retries):
            try:
                response = client.chat.completions.create(
                    model=model,
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt}
                    ],
                    temperature=0.1,  # Lower temperature for more consistent translations
                )
                
                # Extract the translated text
                translated_content = response.choices[0].message.content
                
                # Save the translated content
                with open(output_file_path, 'w', encoding='utf-8') as f:
                    f.write(translated_content)
                
                # Avoid hitting rate limits
                time.sleep(1)
                break
                
            except (openai.RateLimitError, openai.APIError) as e:
                wait_time = backoff_factor ** attempt
                if attempt < max_retries - 1:
                    print(f"API error: {e}. Retrying in {wait_time} seconds...")
                    time.sleep(wait_time)
                else:
                    print(f"Failed to translate {file_name} after {max_retries} attempts")
                    raise
    
    print(f"All files translated and saved to {output_dir}")
    return output_dir


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <input_directory> [output_directory] [output_file]")
        print(f"Example: {sys.argv[0]} 'Arc_C_-_Into_the_Valley_split'")
        sys.exit(1)
    
    input_dir = sys.argv[1]
    
    if not os.path.isdir(input_dir):
        print(f"Error: Directory '{input_dir}' does not exist.")
        sys.exit(1)
    
    # Get output directory (optional)
    output_dir = None
    if len(sys.argv) > 2:
        output_dir = sys.argv[2]
    
    # Translate all files
    french_dir = translate_markdown_files(input_dir, output_dir)
    