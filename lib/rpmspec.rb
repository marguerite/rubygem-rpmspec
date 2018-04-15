dir = File.basename(__FILE__).sub('.rb', '')
path = File.join(File.dirname(File.expand_path(__FILE__)), dir)
Dir.glob(path + '/*').each do |i|
  require dir + '/' + File.basename(i) if File.basename(i) =~ /\.rb/
end
require 'ostruct'

def form_result(**args)
  hash = {}
  method(__method__).parameters.map do |_, name|
    hash = binding.local_variable_get(name) if name == :args
  end
  # reject nil values
  hash = hash.reject { |_k, v| v.nil? }

  return hash.values[0] if hash.values.size == 1

  OpenStruct.new(hash.each_with_object({}) do |(k, v), m|
    m[k] = v
  end)
end
