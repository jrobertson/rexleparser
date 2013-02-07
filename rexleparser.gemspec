Gem::Specification.new do |s|
  s.name = 'rexleparser'
  s.version = '0.4.9'
  s.summary = 'Rexleparser is an XML parser used by the Rexle gem'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb'] 
  s.signing_key = '../privatekeys/rexleparser.pem'
  s.cert_chain  = ['gem-public_cert.pem']
end
