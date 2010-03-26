require 'yaml'
require 'ostruct'

config_defaults = {
  'auth' => {
    'enabled' => false,
    'login' => 'admin',
    'password' => '21232f297a57a5a743894a0e4a801fc3',
  },
  'pages' => {
    'disabled' => [],
  },
  'contacts' => {
    'link' => 'mailto:sibprogrammer@gmail.com',
  }
}

def hashes2ostruct(object)
  return case object
  when Hash
    object = object.clone
    object.each do |key, value|
      object[key] = hashes2ostruct(value)
    end
    OpenStruct.new(object)
  when Array
    object = object.clone
    object.map! { |i| hashes2ostruct(i) }
  else
    object
  end
end

config_file_name = "#{Rails.root}/config/config.yml"
config = File.exist?(config_file_name) ? (YAML.load_file(config_file_name) || {}) : {}
AppConfig = hashes2ostruct(config_defaults.merge(config))
