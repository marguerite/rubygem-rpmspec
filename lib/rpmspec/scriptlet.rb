module RPMSpec
  class Scriptlet
    def initialize(text)
      @text = text
      @arr = @text.split("\n")
      @block = scriptlets_block
      @struct = Struct.new(:name, :content, :conditionals)
    end

    def scriptlets?
      @text.scan(/^%(pre$|preun|post)/).empty? ? false : true
    end

    def scriptlets
      scriptlets = []
      text = format(scriptlet_texts)
      RPMSpec::Conditional.new(text).parse.each do |s|
        name = s.name.split(/\s+/)[0]
        content = s.name.sub(name, '').strip
        conditionals = s.conditionals.empty? ? nil : s.conditionals
        scriptlets << @struct.new(name, content, conditionals)
      end
      scriptlets
    end

    def strip
      unpaired = unpaired_conditionals
      if_counts = find_if_counts(unpaired)
      endif_counts = find_endif_counts(unpaired)
      last_if = @arr.index(beginning_ifs(if_counts)[-1])
      last_endif = furthest_endif(endif_counts)
      if @arr[last_if..first_tag].reject!(&:empty?).size > 2
        before = arr_to_s(@arr[0..first_tag - 1])
        after = arr_to_s(@arr[last_endif + 1..-1])
        before + print_n_endif(if_counts) + after
      else
        @text
      end
    end

    def self.to_s(arr)
      str = ''
      arr.each do |s|
        if s.conditionals.nil?
          str << if s.content.start_with?('-n')
                   s.name + "\s" + s.content + "\n"
                 else
                   s.name + "\n" + s.content + "\n"
                 end
        else
          s.conditionals.each do |i|
            str << "%if\s" + i + "\n"
          end
          str << if s.content.start_with?('-n')
                   s.name + "\s" + s.content + "\n"
                 else
                   s.name + "\n" + s.content + "\n"
                 end
          s.conditionals.size.times { str << "%endif\n" }
        end
      end
      str
    end

    private

    def scriptlet_texts
      unpaired = unpaired_conditionals
      if_counts = find_if_counts(unpaired)
      endif_counts = find_endif_counts(unpaired)
      before = arr_to_s(beginning_ifs(if_counts))
      after = tailing_block(endif_counts)
      before + arr_to_s(@block) + after
    end

    # format the scriptlet texts for conditionals parsing
    def format(text)
      newarr = []
      arr = text.split("\n")
      arr.each_with_index do |i, j|
        newarr << i if i =~ /^%(if|else|endif)/
        if i =~ /^%(pre$|preun|post)/
          if j == arr.size - 1
            newarr << i
          else
            str = i
            n = 0
            unless arr[j + 1 + n] =~ /^%(pre$|preun|post)/
              str << "\s" + arr[j + 1 + n]
            end
            newarr << str
          end
        end
      end
      arr_to_s(newarr)
    end

    # print n '%endif's
    def print_n_endif(n)
      str = ''
      n.times { str << "%endif\n" }
      str
    end

    # concat array items to a string
    def arr_to_s(arr)
      str = ''
      arr.each { |i| str << i + "\n" }
      str
    end

    # the first tag's line number
    def first_tag
      index = 0
      @arr.each_with_index do |i, j|
        if i =~ /^%(pre$|preun|post)/
          index = j
          break
        end
      end
      index
    end

    # the last tag's line number
    def last_tag
      index = 0
      @arr.reverse.each_with_index do |i, j|
        if i =~ /^%(pre$|preun|post)/
          index = @arr.size - 1 - j
          break
        end
      end
      index
    end

    # find the text between the first tag and the last tag
    def scriptlets_block
      @arr[first_tag..last_tag]
    end

    # filter the conditionals from an array
    def conditionals_filter(arr)
      conditionals = []
      arr.each do |i|
        conditionals << i if i =~ /^%(if|else|endif)/
      end
      conditionals
    end

    # find the unpaired conditionals from a conditional array
    def unpaired_conditionals(arr = nil)
      arr ||= conditionals_filter(@block)
      paired = []
      unpaired = []
      arr.each_with_index do |i, j|
        # the last is if, unpaired
        if j != arr.size - 1 && i.start_with?('%if')
          if arr[j + 1].start_with?('%else')
            # the second last is if, the last is else, unpaired
            if !arr[j + 2].nil? && arr[j + 2].start_with?('%endif')
              paired << j
              paired << j + 1
              paired << j + 2
            end
          elsif arr[j + 1].start_with?('%endif')
            paired << j
            paired << j + 1
          end
        end
      end
      arr.each_with_index { |i, j| unpaired << i unless paired.include?(j) }
      unpaired
    end

    # find how many 'if's we need to close the unclosed conditionals
    def find_if_counts(arr)
      counts = 0
      arr.each_with_index do |i, j|
        counts += 1 if i.start_with?('%endif')
        # avoid duplicate counts
        if i.start_with?('%else')
          if j == arr.size - 1
            # the last is else, without if in front of it
            # needs an if
            counts += 1 unless arr[j - 1].start_with?('%if')
          elsif j.zero?
            # the beginning else without following endif needs an if
            counts += 1 unless arr[j + 1].start_with?('%endif')
          elsif arr[j - 1].start_with?('%if')
            # do nothing because an if has been given
          elsif arr[j + 1].start_with?('%endif')
            # do nothing count the following endif instead
          else
                counts += 1
          end
        end
      end
      counts
    end

    # find how many 'endif's we need to close the unclosed conditionals
    def find_endif_counts(arr)
      counts = 0
      arr.each_with_index do |i, j|
        counts += 1 if i.start_with?('%if')
        # avoid duplicate counts
        if i.start_with?('%else')
          # the last is if, needs an endif
          if j == arr.size - 1
            counts += 1
          elsif !j.zero? && arr[j - 1].start_with?('%if')
            # do nothing count the if instead
          elsif arr[j + 1].start_with?('%endif')
            # do nothing, an endif has been given
          else
            counts += 1
          end
        end
      end
      counts
    end

    # find the N ifs before scriptlet_block
    def beginning_ifs(counts)
      ifs = []
      @arr[0..first_tag].reverse.each do |i|
        break if counts.zero?
        if i.start_with?('%if')
          ifs << i
          counts -= 1
        end
      end
      ifs.reverse
    end

    # the texts between the last tag and the furthest endif
    def tailing_block(counts)
      tag = last_tag
      endif = furthest_endif(counts)
      tag < endif ? arr_to_s(@arr[tag..endif]) : ''
    end

    # the furthest endif's line number
    def furthest_endif(counts)
      index = 0
      @arr[last_tag..-1].each_with_index do |i, j|
        if i.start_with?('%endif')
          index = j if counts == 1
          counts -= 1
        end
      end
      last_tag + index
    end
  end
end
