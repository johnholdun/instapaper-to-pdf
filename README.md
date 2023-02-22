# Instapaper to PDF

Turns your 25 most-recently-saved Instpaper articles into PDFs.

Requires a Premium subscription I think, and also an API key.

## Usage

1. `brew install exiftool`
1. `brew install --cask wkhtmltopdf`
1. Copy `.env.example` to `.env` and fill in your details
2. `bundle install`
3. `bundle exec ruby main.rb`
4. 100 PDFs will be written to `exports/`
5. PDFs that have already been generated will not be re-created. To regenerate a bad PDF, just delete the exported file.

## TODO

- Better onboarding
- Make this a hosted service?
