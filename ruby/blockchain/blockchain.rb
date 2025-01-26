require 'digest'

class Block
  attr_reader :data
  attr_reader :hash

  def initialize(data)
    @data = data
    @hash = Digest::SHA256.hexdigest(data)
  end
end

pp Block.new('data 1')
pp Block.new('data 2')
pp Block.new('data 3')
pp Block.new('data 4')