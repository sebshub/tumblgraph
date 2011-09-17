class User
  include MongoMapper::Document
  
  key :token, String
  key :secret, String
  key :avatar, String
  key :primary, String
  key :following, Array #This is an array of hashes
end
