require 'mechanize'
require 'uri/http'
require 'bloomfilter-rb'

module Scraping
  class Spider

    def initialize(start_page, cookies = nil)
      @start_page = start_page
      uri = URI.parse(@start_page)
      @main_host = uri.host
      @main_scheme = uri.scheme
      @cookies = cookies || []
      @scraper = Scraping::Scraper.new
      @to_visit = []
      @requests = []
      @visited = BloomFilter::Native.new(:size => 1000, :hashes => 2, :seed => 1, :bucket => 3, :raise => false)
      @max_parallel_requests = 100
    end

    def run
      # TODO Only use one proxy for the whole thing?
      # TODO Use the same proxy for login
      # @scraper.set_current_proxy_to(proxy, true) # Only use one proxy

      @scraper.use_new_proxy!(true) # Only use one proxy
      @to_visit.push(@start_page) # Add start page to queue
      while !@to_visit.empty?

        # Take MAX 100 pages off the queue and schedule parallel request for them
        # TODO Merging in cookies here is awkward, should be part of @scraper API
        i = 0
        while !@to_visit.empty? && i < @max_parallel_requests
          url = @to_visit.shift # Take next page off of queue
          extra_cookies = @cookies.empty? ? {} : { 'Cookie' => @cookies.join('; ') }
          @requests << @scraper.queue_parallel_request(url, extra_cookies)
          i += 1
        end
        
        # Run the requests, handle the responses
        @scraper.run_parallel_request
        @requests.delete_if do |request|
          if request.response.success?
            # Add this URL to visited list
            @visited.insert(request.url)
            
            # Extract links, add link urls to queue ONLY if they haven't been visited yet
            document = Nokogiri::HTML(request.response.response_body) { |config| config.nonet }
            document.xpath('//a[@href]').each do |link|
              # Filter out links to other domains
              full_link = link['href']
              host = URI.parse(full_link).host rescue nil
              if !host
                # Try again, by prepending the domain
                full_link = "#{@main_scheme}://#{@main_host}#{full_link}"
                host = URI.parse(full_link).host rescue nil
              end
              if host == @main_host && !@visited.include?(full_link) && !@to_visit.include?(full_link) 
                @to_visit.push(full_link)
              end
            end

            # Custom block for business logic
            yield(request.url, document)
            
          else
            # TODO Add unsuccessful requests back to queue? What if the page will never work?
            # TODO Have number of retries? How to store this efficiently?
            # @to_visit.push(request.url)
          end

          # Remove this request from the array since we're done with it
          true
        end

        # Pause for 1 second between request batches
        sleep 1

      end

    end

  end
end