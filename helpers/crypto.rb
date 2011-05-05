require 'rubygems'
require 'crypt/rijndael'

class Crypto
  @@rijndael = Crypt::Rijndael::new( "#{CONFIG[:crypt_key]}" )
  
  def self.encrypt( value )
    ap "Begin encrypt"
    
    encryptedValue = @@rijndael.encrypt_string( value )
    
    ap "Returning from encrypt"
    
    return encryptedValue
  end # self.encrypt
  
  def self.decrypt( value )
    decryptedValue = @@rijndael.decrypt_string( value )
    
    return decryptedValue
  end # self.decrypt
  
end # module Crypto