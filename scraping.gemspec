# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "scraping/version"

Gem::Specification.new do |s|
  s.name        = 'scraping'
  s.version     = Scraping::VERSION
  s.platform    = Gem::Platform::RUBY
  s.date        = '2016-05-21'
  s.summary     = "Ruby web scraping and web crawling framework"
  s.description = "Ruby web scraping and web crawling framework"
  s.authors     = ["Matt Francois"]
  s.email       = 'info@mattfrancois.com'

  s.files         = `git ls-files`.split("\n") - ["scraping-#{Scraping::VERSION}.gem"]

  s.require_paths = ["lib"]

  s.add_runtime_dependency 'bloomfilter-rb'
  s.add_runtime_dependency 'mechanize', '~> 2.6'
  s.add_runtime_dependency 'typhoeus'
  s.add_runtime_dependency 'activerecord'
end