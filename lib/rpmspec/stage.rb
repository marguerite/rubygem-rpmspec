module RPMSpec
  class Stage
    class << self
      def method_missing(stage, *args)
        super unless [:prep, :build, :install, :check].include?(stage)
        regex, text = args
        start = 0
        text_arr = text.split("\n")
        text_arr.each_with_index { |i, j| start = j if i.start_with?('%' + stage.to_s) }
        return if start.zero?
        arr = ['%' + stage.to_s]
        text_arr[start + 1..-1].each do |i|
          break if i =~ regex
          arr << i
        end
        RPMSpec.arr_to_s(arr)
      end

      def respond_to_missing(stage)
        [:prep, :build, :install, :check].include?(stage) || super
      end
    end
  end
end
