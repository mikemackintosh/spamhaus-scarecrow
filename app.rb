require 'sinatra'
require 'json'
require 'ipaddress'
require 'net/dns'

# Set DNS Server IP
DNS_SERVER = "10.1.1.1"

###### Sinatra ###### 
set :port, 8000
set :environment, :production

# Set Return Message
$return_message = {} 

# Create block reasons
$block_reasons = {
  "127.0.0.2"   => { :message => "spam", :code => 2},
  "127.0.1.102" => { :message => "spam", :code => 2},

  "127.0.0.3"   => { :message => "botnet", :code => 3},
  "127.0.1.103" => { :message => "botnet", :code => 3},
  "127.0.1.106" => { :message => "botnet", :code => 3},

  "127.0.0.4"   => { :message => "brute-force", :code => 4},
  "127.0.1.104" => { :message => "redirector", :code => 4},

  "127.0.0.5"   => { :message => "malware", :code => 5},
  "127.0.1.105" => { :message => "malware", :code => 5},

  "127.0.0.6"   => { :message => "botnet", :code => 6},
}

def query(query)
  response = []

  # Reverse for DNS PTR purposes
  address = query.split('.').reverse!.join('.')
  res = Net::DNS::Resolver.new(:nameservers => DNS_SERVER, :udp_timeout => 3)
  answer = res.search("#{address}.any.dnsbl")

  answer.each_address do |ip|
    if $block_reasons.has_key?(ip.to_s)
      response.push($block_reasons[ip.to_s])
    end
  end

  if response.length == 0
    response = [{ :message => "not found", :code => 0}]
  end

  response
end

# Add join to Hash
class Hash
  def join(keyvaldelim=$,, entrydelim=$,) # $, is the global default delimiter
    map {|e| e.join(keyvaldelim) }.join(entrydelim)
  end
end

# Before
before do
  content_type 'application/json'
  $return_message[:search_for] = ''
  $return_message[:message] = "Please submit a valid request"
  $return_message[:code] = -1  
  $return_message[:errors] = []
end

get '/' do
  status 200
  $return_message[:message] = "Please submit a valid request"
  $return_message[:errors] = "Please submit a valid request"
  $return_message.to_json 
end

not_found do
  status 200
  $return_message[:message] = 'Not found'
  $return_message[:code] = 0
  $return_message[:errors] = 'Not found'
  $return_message.to_json 
end

get '/:name' do
  $return_message[:search_for] = params[:name]
  
  # status 404 # Not Found
  # status 302 # Bad
  # status 200 # Ok
  
  query_result = query(params[:name])
  $return_message[:result] = query_result
  $return_message[:message] = query_result.first[:message]
  $return_message[:code] = query_result.first[:code]

  if query_result.first[:code].to_i.eql? 0
      status 404
  elsif query_result.first[:code].to_i.eql? 1
      status 200
  else  
      status 417
  end

  $return_message.to_json   
end
