# == Schema Information
#
# Table name: proxies
#
#  id         :integer          not null, primary key
#  host       :string(255)
#  port       :integer
#  user_agent :string(255)
#  created_at :datetime
#  updated_at :datetime
#
require 'active_record'

class Proxy < ActiveRecord::Base

  before_save :assign_random_user_agent

  # Assign a random user agent
  def assign_random_user_agent
    self.user_agent = File.readlines(File.expand_path("../../../data/user_agents.txt", __FILE__)).sample.strip if self.user_agent.blank?
  end

  # Load proxies from a text file
  # TODO Eventually get new proxies from server automatically
  # I think they change every month
  def self.load_from_file
    File.readlines(File.expand_path("../../../data/proxies.txt", __FILE__)).each do |line|
      host, port = line.strip.split(':')
      Proxy.where(host: host, port: port).first_or_create
    end
  end

end