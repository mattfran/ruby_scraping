require 'mechanize'
require 'typhoeus'

module Scraping
  class Scraper
    # include Loggable

    def initialize
      @connect_timeout = 15
      @read_timeout = 15
      @proxy_manager = ProxyManager.new
      @agent = Mechanize.new
      @agent.open_timeout = @connect_timeout
      @agent.read_timeout = @read_timeout
      @agent.redirect_ok = false
      @agent.follow_meta_refresh = false
      @parallel_agent = Typhoeus::Hydra.new(max_concurrency: 100)
      @request_count = 0
      @print = false
    end

    # TODO Make a better logger
    def log(message)
      puts message
    end

    def blacklist_proxy(proxy)
      @proxy_manager.blacklist_proxy(proxy)
    end

    def use_new_proxy!(use_cookies=false)
      @proxy_manager.set_current_proxy_cookies(get_cookies) # Save cookies for later
      if new_proxy = @proxy_manager.use_new_proxy!
        @agent.user_agent = new_proxy.user_agent
        @agent.set_proxy new_proxy.host, new_proxy.port
        @agent.cookie_jar.clear! # Clear cookies
        if use_cookies # Use any previously saved cookies
          set_cookies @proxy_manager.get_current_proxy_cookies
        end
      end
    end

    def get_random_proxy(cant_be_current=false)
      @proxy_manager.get_random_proxy(cant_be_current)
    end

    def set_current_proxy_to(proxy, use_cookies=false)
      @proxy_manager.set_current_proxy_cookies(get_cookies) # Save cookies for later
      if new_proxy = @proxy_manager.set_current_proxy_to(proxy)
        @agent.user_agent = new_proxy.user_agent
        @agent.set_proxy new_proxy.host, new_proxy.port
        @agent.cookie_jar.clear! # Clear cookies
        if use_cookies # Use any previously saved cookies
          set_cookies @proxy_manager.get_current_proxy_cookies
        end
      end
    end

    def get_page_at(url, must_contain = nil)
      raise "No proxy provided" if @agent.proxy_addr.nil?
      raise "No user agent provided" if  @agent.user_agent.include? "Mechanize"

      begin
        document = @agent.get(url)
        increment_request_count_by(1)

        # Follow redirects, but allow us to detect them
        while document.code[/30[12]/]
          # If a redirect happens, the new URL must still contain this
          if must_contain.present? && !document.header['location'].downcase.include?(must_contain.downcase)
            log "TRIED TO REDIRECT #{url} TO #{document.header['location']} BUT IT DOESN'T CONTAIN #{must_contain}"
            return nil
          end
          document = @agent.get(document.header['location'])
          increment_request_count_by(1)
        end

        document
      rescue => e
        log "ERROR GETTING URL #{url}, MESSAGE: #{e.message}, #{e.backtrace.join("\n")}"
        log "RESPONSE CODE #{e.response_code}" if defined?(e.response_code)
        nil
      end
    end

    def queue_parallel_request(url, extra_headers = {})
      raise "No proxy provided" if !@proxy_manager.has_current_proxy?

      request_hash = {
        connecttimeout: @connect_timeout,
        timeout: @read_timeout,
        method: :get,
        followlocation: true,
        accept_encoding: "gzip",
        headers: {
          'Cookie' => get_cookies.join('; ')
        }.merge(extra_headers)
      }
      if @proxy_manager.has_current_proxy?
        request_hash[:proxy] = "#{@proxy_manager.get_current_proxy.host}:#{@proxy_manager.get_current_proxy.port}"
        request_hash[:headers]['User-Agent'] = @proxy_manager.get_current_proxy.user_agent
      end

      # Queue request
      request = Typhoeus::Request.new(url, request_hash)
      @parallel_agent.queue request

      # Count requests
      increment_request_count_by(1)

      request
    end

    def run_parallel_request
      @parallel_agent.run # Blocks until complete
    end

    def get_request_count
      @request_count
    end

    def increment_request_count_by(amount)
      @proxy_manager.increment_request_count_by(amount)
      @request_count += amount
    end

    def get_cookies
      @agent.cookies
    end

    def set_cookies(cookies)
      cookies.each do |cookie|
        @agent.cookie_jar << cookie
      end
    end

    # def print?
    #   @print
    # end

  end
end