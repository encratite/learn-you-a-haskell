require 'nokogiri'
require 'open-uri'
require 'hpricot'
require 'rexml/document'

class LYAHReader
  def initialize(url)
    data = open(url)
    index = REXML::Document.new(data)
    index.elements.each("ol") do |element|
      puts element.inspect
    end
  end
end
