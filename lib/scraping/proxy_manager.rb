require_relative '../models/proxy'
require 'typhoeus'

module Scraping
  class ProxyManager
    # include Loggable

    def initialize
      @current_proxy = nil
      @current_proxy_request_count = 0
      @proxy_requests = {}
      @proxy_cookies = {}
      @proxy_blacklist = []
      Proxy.all.each {|proxy| @proxy_requests[proxy.id] = 0 }
      Proxy.all.each {|proxy| @proxy_cookies[proxy.id] = [] }
    end

    # Make sure this proxy is not used
    def blacklist_proxy(proxy)
      @proxy_blacklist << proxy.id
    end

    def use_new_proxy!
      # TODO This could randomly choose the same proxy over and over
      # Maybe make it choose one with no requests?

      # Record proxy requests before switching
      if has_current_proxy?
        @proxy_requests[@current_proxy.id] += @current_proxy_request_count
      end

      random_proxy = get_random_proxy(true)
      raise "No proxies available" unless random_proxy.present?

      @current_proxy = random_proxy
      @current_proxy_request_count = 0

      @current_proxy
    end

    def get_random_proxy(cant_be_current=false)
      proxy = Proxy.order("RANDOM()")
      proxy = proxy.where.not(id: @current_proxy.id) if has_current_proxy? && cant_be_current
      proxy = proxy.where.not(id: @proxy_blacklist) if @proxy_blacklist.size > 0
      proxy = proxy.limit(1).first
    end

    def set_current_proxy_to(proxy)
      raise "Proxy is in blacklist" if @proxy_blacklist.size > 0 && @proxy_blacklist.include?(proxy.id)
      # Record proxy requests before switching
      if has_current_proxy?
        @proxy_requests[@current_proxy.id] += @current_proxy_request_count
      end

      @current_proxy = proxy
      @current_proxy_request_count = 0

      @current_proxy
    end

    def get_current_proxy_cookies
      @proxy_cookies[get_current_proxy.id] if has_current_proxy?
    end

    def set_current_proxy_cookies(cookies)
      @proxy_cookies[get_current_proxy.id] = cookies if has_current_proxy?
    end

    def has_current_proxy?
      @current_proxy.present?
    end

    def get_current_proxy
      @current_proxy
    end

    def get_current_proxy_request_count
      @current_proxy_request_count
    end

    def get_all_proxies_requests
      @proxy_requests
    end

    def increment_request_count_by(amount)
      @current_proxy_request_count += amount if has_current_proxy?
    end

  end
end