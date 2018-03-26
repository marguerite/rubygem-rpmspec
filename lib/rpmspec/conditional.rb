module RPMSpec
  # handles the conditional texts.
  # will break it into an array of structs.
  # the struct is the term's name and the corresponding
  # conditionals that it matches.
  class Conditional
    def initialize(text)
      @text = add_levels(text)
      @struct = Struct.new(:name, :conditionals)
    end

    def conditional?
      !@text.scan('%if').empty?
    end

    # parse conditional texts into an array of '@struct's
    def parse
      items = @text.split("\n").reject! { |i| i.strip =~ /^%(if|else|endif)/ }
      items.map! do |i|
        conditionals = find_conditional(i).map! do |j|
          j.strip.gsub(/%if-level-\d+(.*)/) { Regexp.last_match(1) }.strip
        end
        @struct.new(i, conditionals)
      end
    end

    private

    # we match the unmodified 'tag + modifier' and change it until nothing to do
    def replace(tag, modifier, text)
      copy = text.match(/.*?#{tag}#{modifier}/m) # the shortest/first match
      return text if copy.nil?
      copy = copy[0]
      ifs = copy.scan('%if').size
      endifs = copy.scan('%endif').empty? ? 0 : copy.scan('%endif').size
      # minus 1 because the tag itself was counted
      endifs -= 1 if tag == '%endif'
      # the number of the open 'if's
      level = ifs - endifs
      # use sub! because we just want to replace the 1st match
      text.sub!(copy, copy.dup.sub!(tag + modifier, tag + '-level-' + level.to_s + modifier))
      replace(tag, modifier, text)
    end

    # apprend levels to all the if, else and endifs.
    def add_levels(text = @text)
      text = replace('%if', "\s", text)
      text = replace('%else', "\n", text)
      text = replace('%endif', "\n", text)
      text
    end

    # find the conditionals that matches the item
    def find_conditional(item)
      conditionals = []
      # match every text before the item
      copy = @text.match(/.*#{Regexp.escape(item)}\n/m)[0]
      # break the text into lines
      arr = copy.split("\n")
      # match the nearest condtional before it
      # and test
      nearest = find_nearest_conditional(item, arr)

      # find all remaining conditinals before the item
      remains = arr[0..(nearest - 1)].select! { |i| i.strip =~ /^%(if|else|endif)/ }
      level = find_level(arr[nearest])
      # only the 'if' and 'else' need to insert themselves to conditionals
      # for the 'endif', we know the block before it is finished
      # so only need the smaller levels.
      if arr[nearest].index('%if')
        conditionals << arr[nearest]
      elsif arr[nearest].index('%else')
        conditionals << replace_else_conditional(remains, level)[1]
      end
      remains.each do |r|
        # only the conditionals whose level smaller than
        # the item's may affect it.
        conditionals << r if find_level(r) < level
      end
      # sometimes there's 'else' in the conditionals
      # if 'else' occurs, it indicates the item is
      # in the 'else' part, so the if conditional
      # with the same level as the 'else' has no
      # effects on our item.
      else_levels = find_else_levels(conditionals)
      # guard: no 'else' if else_levels is empty
      return conditionals if else_levels.empty?
      conditionals = replace_else_conditionals(conditionals, else_levels)
      conditionals
    end

    # find the nearest conditional before a text
    def find_nearest_conditional(_item, arr)
      # item is always the last element of arr
      near = 0
      arr[0..-2].reverse.each_with_index do |i, j|
        next unless i.strip =~ /^%(if|else|endif)/
        # because it's reversed
        # [0, 1, 2, 3, 4]
        # arr[0..-2].reverse = [4, 3, 2, 1, 0]
        # j = 0, i = 4
        # j = 1, i = 3
        # j = 2, i = 2
        # j = 3, i = 1
        near = (arr.size - 1 - j).abs - 1
        break
      end
      near
    end

    # find the level of the passed conditional
    def find_level(conditional)
      conditional.match(/%.*-level-(\d+).*/)[1]
    end

    # find the levels of the 'else' condtionals
    # from the passed conditional array
    def find_else_levels(arr)
      levels = []
      arr.each do |conditional|
        if conditional.index('%else')
          levels << conditional.gsub(/%else-level-(\d+).*/) { Regexp.last_match(1) }.to_i
        end
      end
      levels
    end

    # find the term of the 'else' conditional
    # from the passed conditional array by
    # comparing its level with the corresponding
    # 'if' conditional, then remove both
    # and add a new reversed if conditional
    def replace_else_conditional(arr, level)
      conditionals = arr.select { |i| i.index('-level-' + level.to_s) }
      # always use the last one which is near and accurate
      condition = conditionals.select { |i| i.index('%if-level') }[-1]
      ifpart = condition.gsub(/(%if-level-\d+\s).*/) { Regexp.last_match(1) }
      condition = ifpart + reverse_conditions(condition.sub(ifpart, ''))
      [conditionals, condition]
    end

    def replace_else_conditionals(arr, levels)
      newarr = arr.dup
      levels.each do |l|
        conditionals, condition = replace_else_conditional(arr, l)
        newarr = (newarr - conditionals) << condition
      end
      newarr
    end

    # reverse the conditional, for conversion from else to if.
    def reverse_condition(conditional)
      reverse_matrix = { '>' => '<=', '>=' => '<',
                         '<' => '>=', '<=' => '>',
                         '==' => '!=' }
      arr = conditional.strip.split(/\s+/)
      if arr.size > 1
        comparator = arr[1]
        reverse_comparator = reverse_matrix[comparator]
        arr[0] + "\s" + reverse_comparator + "\s" + arr[2]
      else
        "!\s" + arr[0]
      end
    end

    def reverse_comparator(comparator)
      reverse_matrix = { '&&' => '||', '||' => '&&' }
      reverse_matrix[comparator]
    end

    def reverse_conditions(joined)
      if joined.index(/(&&|\|\|)/)
        # break the joined conditional into simple
        # conditionals and comparators
        conditionals, comparators = break_joined(joined)
        conditionals = conditionals.map! { |i| reverse_condition(i) }
        comparators = comparators.map! { |j| reverse_comparator(j) }
        combine_joined(conditionals, comparators)
      else
        reverse_condition(joined)
      end
    end

    def break_joined(text, conditionals = [], comparators = [])
      matched = text.match(/(.*?)(&&|\|\|)/)
      # conditionals always greater in number than comparators
      # so when matched is nil, the left text is still a
      # conditional
      return conditionals << text, comparators if matched.nil?
      conditionals << matched[1]
      comparators << matched[2]
      text.sub!(matched[0], '')
      break_joined(text, conditionals, comparators)
    end

    def combine_joined(conditionals, comparators)
      joined = ''
      conditionals.each_with_index do |i, j|
        joined << if j == conditionals.size - 1
                    i
                  else
                    i + "\s" + comparators[j] + "\s"
                  end
      end
      joined
    end
  end
end
