require 'uri'
require 'fileutils'
require 'rubygems'
require 'dotenv'
require 'pdfkit'
require 'mini_exiftool'
require './instapaper'

Dotenv.load

# These options are passed directly to `wkhtmltopdf`, but with underscores
# turned into hyphens. See all options here:
# https://wkhtmltopdf.org/usage/wkhtmltopdf.txt
PAGE_OPTIONS =
  {
    page_width: '5in',
    page_height: '7in',
    margin_top: '0.25in',
    margin_bottom: '0.25in',
    margin_left: '0.125in',
    margin_right: '0.125in'
  }

# Whatever's returned from this method is prepended to the HTML returned from
# Instapaper before generating a PDF
def article_preamble(bookmark)
  <<-HTML
  <style>
    html {
      font-family: Georgia;
      font-size: 14pt;
      line-height: 1.5
    }

    img {
      display: block;
      max-width: 4.75in;
      margin-bottom: 1em;
    }
  </style>
  <h1>#{bookmark[:title]}</h1>
  <p>
    <i>
      <a href="#{bookmark[:url]}">
        #{bookmark[:host]}
      </a>
    </i>
  </p>
  <hr>
  HTML
end

instapaper = Instapaper.new(ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET'])

if ENV['OAUTH_TOKEN']
  instapaper.set_oauth(ENV['OAUTH_TOKEN'], ENV['OAUTH_TOKEN_SECRET'])
else
  instapaper.authorize(ENV['INSTAPAPER_USERNAME'], ENV['INSTAPAPER_PASSWORD'])
end

Dir.mkdir(File.join(Dir.pwd, 'exports')) unless File.directory?(File.join(Dir.pwd, 'exports'))

bookmarks = instapaper.bookmarks(100)

bookmarks[:bookmarks].each do |bookmark|
  bookmark[:title] = bookmark[:url] if bookmark[:title].to_s.strip.size == 0
  puts bookmark[:title]

  path = File.join(Dir.pwd, 'exports', "#{bookmark[:bookmark_id]}.pdf")

  next if Dir.glob(File.join(Dir.pwd, 'exports', "#{bookmark[:bookmark_id]}*.pdf")).size > 0

  bookmark[:host] = URI.parse(bookmark[:url]).host.sub(/^www\./, '')

  html = article_preamble(bookmark) + instapaper.get_text(bookmark[:bookmark_id])

  PDFKit
    .new(html, PAGE_OPTIONS.merge(title: bookmark[:title]))
    .to_file(path)

  begin
    `exiftool -PDF:Author="#{bookmark[:host]}" -overwrite_original_in_place #{path}`
  rescue
    puts 'tag update with exiftool failed'
  end
end
