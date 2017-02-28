module RPMSpec
  class Scriptlet
    def initialize(text)
      @text = text
    end

    def scriptlet_texts(text)
      return unless has_scriptlets?(text)
      arr = text.split("\n").reject!(&:empty?)
      scriptlets = []
      # must with index because there may be many such
      # tags in the whole specfile, not able to find
      # the correct index later.
      arr.each_with_index do |l, index|
        next unless l =~ /^(%pre$|%preun|%post)/
        # if unclosed, we need to include the conditional
        # '%if' '%else' '%endif'
        if unclosed?(index, arr)
          previous_if = scriptlet_if_content(index, arr)
          scriptlets << previous_if unless scriptlets.include?(previous_if)
          scriptlets << l
          next_endif = scriptlet_endif_content(index, arr)
          next_endif.each { |i| scriptlets << i }
        else
          # we just need to find the text after the scriptlet
          # indicator.
          scriptlets << scriptlet_content(l, text)
        end
      end
      scriptlets
    end

    private

    def has_scriptlets?(text)
      text.scan(/(%pre|%preun|%post|%postun)/).empty? ? false : true
    end

    def scriptlet_endif_content(index, arr)
      # find the nearest 'else' or 'endif'
      nearest = 0
      arr[index..arr.size - 1].each do |i|
        if i.start_with?('%else', '%endif')
          nearest = index + arr[index..arr.size - 1].index(i)
        end
      end

      # exclude itself
      if arr[(index + 1)..nearest].select { |i| i =~ /^%(pre$|preun|post)/ }.empty?
        arr[index + 1..nearest]
      else
        # find the next tag
        newindex = 0
        arr[(index + 1)..nearest].each do |i|
          if i =~ /^%(pre$|preun|post)/
            newindex = index + 1 + arr[(index + 1)..nearest].index(i)
            break
          end
        end
        # exclude the next tag
        arr[index + 1..newindex - 1]
      end
    end

    def scriptlet_if_content(index, arr)
      # [0,1,2,3,4]
      # [0,1,2]
      # [2,1,0]
      # i = 0, j = 2
      # i = 1, j = 1
      # i = 2, j = 0
      # j = size - 1 - i
      array = arr[0..index].reverse
      nearest = 0
      # find the nearest if
      array.each do |i|
        if i.start_with?('%if')
          nearest = arr[0..index].size - 1 - array.index(i)
          break
        end
      end
      # if there's endif in this range, then the if we found
      # is closed, we need find the previous if and test again
      unclosed = arr[nearest..index].select! { |i| i == '%endif' }.empty?
      return arr[nearest] if unclosed
      endif_index = 0
      arr[nearest..index].each do |i|
        if i == '%endif'
          endif_index = nearest + arr[nearest..index].index(i)
          break
        end
      end
      # delete the pair of closed if/endif and start over again
      newarr = arr.delete_if do |i|
        arr.index(i) == nearest || arr.index(i) == endif_index
      end
      scriptlet_if_content(index, newarr)
    end

    def scriptlet_content(line, text)
      # match the block below line
      text = text.match(/#{line}.*?\n\n/m)[0]
      arr = text.split("\n")
      index = arr.index(line)
      if arr.size == 1
        line
      elsif arr[index + 1] =~ /^%(pre$|preun|post)/
        line
      else
        text
      end
    end

    def unclosed?(index, arr)
      array = arr[index..arr.size - 1]
      nearest = 0
      # narrow the array to the nearest 'else' or 'endif'
      array.each do |i|
        if i.start_with?('%else', '%endif')
          nearest = index + array.index(i)
          break
        end
      end
      # if there's '%if' in this range, then the thing we found
      # is closed.
      arr[index..nearest].select! { |i| i.start_with?('%if') }.empty?
    end
  end
end
