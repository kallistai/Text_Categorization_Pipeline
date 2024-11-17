# Install necessary packages if not already installed
if(!require(httr)) install.packages("httr")
if(!require(readr)) install.packages("readr")
if(!require(dplyr)) install.packages("dplyr")

library(httr)
library(readr)
library(dplyr)

# Set up the OpenAI API key (users must provide their own key here)
api_key <- "YOUR_API_KEY_HERE"  # Replace with your API key

# Function to send text and single category to the LLM for semantic matching
semantic_matching_with_llm_single_category <- function(comment_id, text, category, description, attempt = 1) {
  messages <- list(
    list(role = "system", content = "You are an assistant specialized in categorizing text into predefined categories."),
    list(role = "user", content = paste(
      "Determine if the following statement aligns with the given category.",
      "\n\nCategory:", category,
      "\nDescription:", description,
      "\n\nText:", text,
      "\n\nRespond with 'True', 'False', or 'Uncertain'. Do not include explanations."
    ))
  )
  
  response <- tryCatch({
    POST(
      url = "https://api.openai.com/v1/chat/completions",
      add_headers(Authorization = paste("Bearer", api_key)),
      body = list(
        model = "gpt-3.5-turbo",
        messages = messages,
        max_tokens = 5,
        temperature = 0.5
      ),
      encode = "json"
    )
  }, error = function(e) {
    return(NULL)  # Return NULL on error to allow retries
  })
  
  if (is.null(response) && attempt < 3) {
    Sys.sleep(runif(1, 1, 5))  # Random delay before retrying
    return(semantic_matching_with_llm_single_category(comment_id, text, category, description, attempt + 1))
  }
  
  if (!is.null(response) && http_status(response)$category == "Success") {
    content_response <- content(response)
    if (!is.null(content_response$choices) && length(content_response$choices) > 0) {
      result <- trimws(tolower(content_response$choices[[1]]$message$content))
      first_word <- strsplit(result, "[[:space:]]+")[[1]][1]
      if (first_word %in% c("true", "false", "uncertain")) {
        return(first_word)
      }
    }
  }
  return(NA)  # Default to NA for failures
}

# Load categories and text data from user-selected CSV files
categories_file <- file.choose()  # Choose Categories CSV
text_file <- file.choose()  # Choose Text CSV

categories_df <- read_csv(categories_file, show_col_types = FALSE)
text_df <- read_csv(text_file, show_col_types = FALSE)

if ("Comment ID" %in% names(text_df)) {
  colnames(text_df)[colnames(text_df) == "Comment ID"] <- "CommentID"
}
text_df <- text_df %>% mutate(CommentID = as.character(CommentID))

# Check for necessary columns in input files
if (!all(c("CatName", "CatDescription") %in% names(categories_df))) {
  stop("Categories file must contain 'CatName' and 'CatDescription' columns.")
}
if (!all(c("CommentID", "TextStrings") %in% names(text_df))) {
  stop("Text file must contain 'CommentID' and 'TextStrings' columns.")
}

# Initialize output storage
output_list <- list()

# Loop through each text entry and evaluate categories
for (i in seq_len(nrow(text_df))) {
  comment_id <- as.character(text_df$CommentID[i])
  text <- text_df$TextStrings[i]
  
  row_results <- setNames(
    data.frame(matrix(ncol = length(categories_df$CatName) + 2, nrow = 1,
                      dimnames = list(NULL, c("CommentID", "TextStrings", categories_df$CatName))), 
               stringsAsFactors = FALSE), 
    c("CommentID", "TextStrings", categories_df$CatName)
  )
  row_results$CommentID <- comment_id
  row_results$TextStrings <- text
  row_results[3:ncol(row_results)] <- NA
  
  for (j in seq_len(nrow(categories_df))) {
    category <- categories_df$CatName[j]
    description <- categories_df$CatDescription[j]
    match_result <- tryCatch({
      semantic_matching_with_llm_single_category(comment_id, text, category, description)
    }, error = function(e) {
      return(NA)
    })
    if (match_result %in% c("true", "false", "uncertain")) {
      row_results[[category]] <- match_result
    }
  }
  output_list[[i]] <- row_results
}

# Combine results and save to an output file
output_df <- do.call(bind_rows, output_list)
write_csv(output_df, "output.csv")
print("Processing complete! Results saved to output.csv.")
