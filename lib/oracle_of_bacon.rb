require 'debugger'              # optional, may be helpful
require 'open-uri'              # allows open('http://...') to return body
require 'cgi'                   # for escaping URIs
require 'nokogiri'              # XML parser
require 'active_model'          # for validations

class OracleOfBacon

  class InvalidError < RuntimeError ; end
  class NetworkError < RuntimeError ; end
  class InvalidKeyError < RuntimeError ; end



  attr_accessor :from, :to
  attr_reader :api_key, :response, :uri

 

  include ActiveModel::Validations
  validates_presence_of :from
  validates_presence_of :to
  validates_presence_of :api_key
  validate :from_does_not_equal_to

  def from_does_not_equal_to
    errors.add(:from, "From cannot be the same as To") if @from == @to
  end

  def initialize(api_key='')
    @api_key = api_key
    @from = 'Kevin Bacon'
    @to = 'Kevin Bacon'
  end

  def find_connections
    make_uri_from_arguments
    begin
      xml = URI.parse(uri).read
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
      Net::ProtocolError => e
      # convert all of these into a generic OracleOfBacon::NetworkError,
      #  but keep the original error message
      
      raise OracleOfBacon::NetworkError
    end
    OracleOfBacon::Response.new(xml)
    
  end

  def make_uri_from_arguments
    # your code here: set the @uri attribute to properly-escaped URI
    #   constructed from the @from, @to, @api_key arguments
    @a = CGI.escape("#{@from}")
    @b = CGI.escape("#{@to}")
    @p = CGI.escape("#{@api_key}")
    @uri = "http://oracleofbacon.org/cgi-bin/xml?p=#{@p}&a=#{@a}&b=#{@b}"

  end    
  class Response
    attr_reader :type, :data
    # create a Response object from a string of XML markup.
    def initialize(xml)
      @doc = Nokogiri::XML(xml)
      parse_response
    end

    private

    def parse_response
      @data = []
      if ! @doc.xpath('/error').empty?
        parse_error_response
      elsif ! @doc.xpath('//actor').empty?
        @type = :graph        
        movies = @doc.xpath('//movie').map {|movie| movie.text}
        actors = @doc.xpath('//actor').map {|actor| actor.text}
        @data = actors.zip(movies).flatten.compact
      elsif ! @doc.xpath('//match').empty?
        @type = :spellcheck
        @data = @doc.xpath('//match').map {|movie| movie.text}
      else
        @type = :unknown
        @data = '/unknown/i'                                          
      end
    end
    def parse_error_response
      @type = :error
      @data = 'Unauthorized access'
    end
  end
end

