require 'pg'
require 'scraping'

# Database settings
ActiveRecord::Base.establish_connection(
  adapter:  'postgresql',
  host:     'localhost',
  database: 'db_name',
  username: 'db_user',
  password: 'db_password'
)

spider = Scraping::Spider.new("https://example.com")
spider.run do |url, document|
  # TODO Extract links, data etc here
  puts url
end