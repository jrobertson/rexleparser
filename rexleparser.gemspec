Gem::Specification.new do |s|
  s.name = 'rexleparser'
  s.version = '0.9.7'
  s.summary = 'Rexleparser is an XML parser used by the Rexle gem'
  s.authors = ['James Robertson']
  s.files = Dir['lib/rexleparser.rb'] 
  s.signing_key = '../privatekeys/rexleparser.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/rexleparser'
  s.required_ruby_version = '>= 2.1.2'
end
