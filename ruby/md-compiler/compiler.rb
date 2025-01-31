require 'json'

module Compiler
  class << self
    def compile(md)
      tks = Lexer.new(md).tokenize
      ast = Parser.new(tks).parse
      CodeGen.new(ast).gen
    end
  end

  class Lexer

    Token = Struct.new(:type, :attrs)

    def initialize(md)
      @md = String.new(md)
    end

    def tokenize
      tks = []

      @md.lstrip!
      while !@md.empty?
        if @md =~ /\A((?:######|#####|####|###|##|#) .+)/
          text = $1
          size = 0
          while text[0] == '#'
            size += 1
            text.slice!(0, text[1] == ' ' ? 2 : 1)
          end
          tks.push Token.new(:header, {size:, text:})
          @md.slice!(0, $1.size)
        elsif @md =~ /\A(=+|-+) *$/
          size = $1.include?('=') ? 1 : 2
          tks.push Token.new(:header_alt, {size:})
          @md.slice!(0, $1.size)
        elsif @md =~ /\A\n/
          tks.push Token.new(:newl)
          @md.slice!(0, 1)
        else
          line = String.new
          @md.each_char { it == "\n" ? break : line << it }
          @md.slice!(0, line.size)

          curr = String.new
          curr_push = lambda { tks.push Token.new(:text, {text: curr}) }

          while !line.empty?
            if (line.start_with?('*') || line.start_with?('_')) && line =~ /\A(\*\*.+?\*\*|__.+?__)/ # bold
              curr_push.call if !curr.empty?
              bold = line.match(/\A(\*\*.+?\*\*|__.+?__)/).captures.first
              tks.push Token.new(:bold, {text: bold.gsub(/[\*_]/, '')})
              line.slice!(0, bold.size)
            elsif line.start_with?('[') && line =~ /\A(?:\[(.+?)\]\((.*?)\))/ # link
              curr_push.call if !curr.empty?
              tks.push Token.new(:link, {text: $1, href: $2})
              line.slice!(0, $1.size + $2.size + 4) # []() = 4
            else
              curr << line[0]
              line.slice!(0, 1)
            end
          end

          curr_push.call if !curr.empty?
        end

        @md.rstrip!
      end
        
      if tks.last && tks.last.type != :newl
        tks.push Token.new(:newl)
      end

      tks
    end
  end

  class Parser
    
    NodeRoot   = Struct.new(:children)
    NodeHeader = Struct.new(:size, :text)
    NodePara   = Struct.new(:children)
    NodeText   = Struct.new(:text, :bold)
    NodeLink   = Struct.new(:text, :href)

    def initialize(tks)
      @tks = tks
    end

    def parse
      ast = NodeRoot.new(children: [])
      
      while !@tks.empty?
        ast.children << (
          if peek(:header)
            parse_header
          elsif peek(:text) && peek(:newl, 2) && peek(:header_alt, 3)
            parse_header_alt
          elsif peek(:link)
            parse_link
          elsif peek_any(:text, :bold)
            parse_paragraph
          else
            raise RuntimeError, "Unable to parse tokens:\n#{JSON.pretty_generate(@tks)}"
          end
        )
      end

      ast
    end

    private

    def parse_header
      token = consume(:header)
      consume(:newl)
      NodeHeader.new(size: token.attrs[:size], text: token.attrs[:text])
    end

    def parse_header_alt
      text = consume(:text).attrs[:text]
      consume(:newl)
      size = consume(:header_alt).attrs[:size]
      consume(:newl)
      NodeHeader.new(size:, text:)
    end

    def parse_paragraph
      para = NodePara.new(children: [])

      while peek_any(:text, :bold, :link)
        para.children << (
          if peek(:text)
            NodeText.new(text: consume(:text).attrs[:text])
          elsif peek(:bold)
            NodeText.new(text: consume(:bold).attrs[:text], bold: true)
          elsif peek(:link)
            parse_link
          else
            raise "Unexpected next token: \n#{JSON.pretty_generate(@tks)}"
          end
        )
      end
      consume(:newl)
      
      para
    end

    def parse_link
      link = consume(:link)
      consume(:newl)
      NodeLink.new(text: link.attrs[:text], href: link.attrs[:href])
    end

    def peek_any(*types)
      types.each { return true if peek it }
      return false
    end

    def peek(type, depth = 1)
      (token = @tks[depth - 1]) && token.type == type
    end

    def consume(type)
      token = @tks.shift
      if token.nil?
        raise RuntimeError, "Expected to find token type #{type} but did not find a token"
      elsif token.type != type
        raise RuntimeError, "Expected to find token type #{type} but found #{token.type}"
      end
      token
    end
  end

  class CodeGen
    def initialize(ast)
      @ast = ast
    end

    def gen
      html = String.new

      @ast.children.each do |node|
        html << (
          case node
          when Parser::NodeHeader
            gen_header(node)
          when Parser::NodeLink
            gen_link(node)
          when Parser::NodePara
            gen_paragraph(node)
          else
            raise RuntimeError, "Invalid node: #{node}"
          end
        )
      end

      html
    end

    private

    def gen_header(node)
      "<h#{node.size}>#{node.text}</h#{node.size}>"
    end

    def gen_paragraph(node)
      html = String.new('<p>')

      node.children.each do |child|
        html << (
          case child
          when Parser::NodeText
            gen_text(child)
          when Parser::NodeLink
            gen_link(child)
          else
            raise "Invalid node: #{child}"
          end
        )
      end

      html << '</p>'
    end

    def gen_link(node)
      "<a href=\"#{node.href}\">#{node.text}</a>"
    end

    def gen_text(node)
      node.bold ? "<em>#{node.text}</em>" : node.text
    end
  end
end