# Text Categorization Pipeline

This repository contains a script for semantic matching of open-text responses with predefined categories using OpenAI's GPT model. The pipeline is designed to support qualitative researchers and data analysts in efficiently categorizing text data into structured formats.

## Features
- Semantic matching of text to predefined categories.
- Outputs results in a structured CSV file.
- Handles retries and rate limits for OpenAI's API.

## Requirements
- **R (version >= 4.0)**
- Installed R packages:
  - `httr`
  - `readr`
  - `dplyr`

## Usage
1. **Clone this repository** or download the script.
2. **Open the script** in RStudio or your preferred R environment.
3. **Set up your own OpenAI API key**:
   - Open the script and replace `YOUR_API_KEY_HERE` with your actual OpenAI API key:
     ```r
     api_key <- "YOUR_API_KEY_HERE"
     ```
4. **Run the script**:
   - Follow the prompts to select your input files:
     - **Categories File**: A CSV with `CatName` and `CatDescription` columns.
     - **Text File**: A CSV with `CommentID` and `TextStrings` columns.
5. **Review the output**:
   - Processed results will be saved as `output.csv` in the working directory.

## Acknowledgments
- Script developed by **Zach Pease** and **Andrea G. Buchwald, PhD**.
- Semantic matching powered by OpenAI's GPT model.


## License
This project is licensed under the [GNU Affero General Public License v3.0](https://www.gnu.org/licenses/agpl-3.0.html).