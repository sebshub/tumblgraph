class User
  include MongoMapper::Document
  
  key :token, String
  key :secret, String
  key :avatar, String
  key :primary, String
  key :following, Array #This is an array of hashes
  
  def self.get_all_primaries
    users = User.all
    nodes = []
    for user in users
        nodes << user.primary
    end
    nodes
  end

  def self.get_all_links nodes
    #Given a list of nodes bring me back
    #all our connections
    #
    #Note there have to be WAY better ways to do this. Just get it working.
    connections = []
    for node in nodes
        object = User.where(:primary => node).first
        node_index = nodes.index(node)
        for blogger in object.following
            connections << {:source => node_index, :target => nodes.index(blogger), :value => rand(10)}
        end
    end
    connections
  end
end
