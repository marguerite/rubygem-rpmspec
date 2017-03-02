module RPMSpec
  class Stage
    def initialize(structs)
      @structs = structs
    end

    def create_stages
      @structs.each do |struct|
        create_stage(struct.class, struct.regex, struct.text)
      end
    end

    def create_stage(name, regex, text)
      Object.const_set(name.capitalize,
        Class.new do
          define_method :parse do
            arr = ['%' + name]
            text.split("\n")[arr_start + 1..-1].each do |i|
              break if i =~ regex
              arr << i
            end
            return if arr.reject(&:empty?).empty?
            RPMSpec.arr_to_s(arr)
          end

          define_method :strip do
            str = parse.nil? ? '' : parse
            text.sub(str, '')
          end

          define_method :arr_start do
            index = 0
            text.split("\n").each_with_index do |i, j|
              if i.start_with?('%' + name)
                index = j
                break
              end
            end
            index
          end
        end
      )
    end
  end
end
