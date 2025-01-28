# Blockchain

A simple blockchain implementation written in Ruby, inspired by the concepts outlined in this [guide](https://github.com/yukimotopress/programming-blockchains-step-by-step).

## Usage

### Create a blockchain

```ruby
block_1 = Blockchain::Block.new('data 1', Blockchain::GENESIS)
block_2 = Blockchain::Block.new('data 2', block_1.hash)
block_3 = Blockchain::Block.new('data 2', block_2.hash)
[block_1, block_2, block_3] # blockchain
```
