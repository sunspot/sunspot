class SunspotGenerator < Rails::Generator::Base
  
  def manifest
    record do |m|
      m.template 'sunspot.yml', 'config/sunspot.yml'
    end
  end
  
end
