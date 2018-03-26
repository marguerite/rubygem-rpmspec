module RPMSpec
  # parse RPM preamble, like legal notes, authors
  class Preamble
    def initialize(text)
      @text = text
    end

    def parse
      @text.match(/\A((?!^%)(?!^Name).)*/m)[0]
    end
  end
end
