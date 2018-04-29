dir = File.basename(__FILE__).sub('.rb', '')
path = File.join(File.dirname(File.expand_path(__FILE__)), dir)
Dir.glob(path + '/*').each do |i|
  require dir + '/' + File.basename(i) if File.basename(i) =~ /\.rb/
end
require 'ostruct'

def item_new(**args)
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

def confident_return_name(name)
  name.instance_of?(OpenStruct) ? name.name : name
end

def confident_escape_name(name)
  name.nil? ? '' : Regexp.escape(name)
end

def find_description(text, name)
  text.match(/^%description(\s+)?(-n\s+)?#{confident_escape_name(name)}\n(((?!%prep)(?!%package).)*)\n(\s+)?\n/m)
end

def find_tags(text, args)
  hash = {}
  RPMSpec::TAGS.map(&proc { |i| i.downcase.to_sym }).each do |j|
    tag = RPMSpec::Tag.new(text, **args).send(j)
    hash[j] = if tag.nil? || tag.size > 1
                tag
              else
                tag[0]
              end
  end
  hash
end
