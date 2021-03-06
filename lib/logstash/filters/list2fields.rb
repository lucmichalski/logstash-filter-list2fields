# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::List2fields < LogStash::Filters::Base

  config_name "list2fields"

  # The name of the field which contains the list of key value pairs
  config :source, :validate => :string

  # The name of the field which contains the key inside a list element. If this is set then "value" needs to be set also.
  config :key, :validate => :string, :default => ""

  # The name of the field which contains the value inside a list element. If this is set then "key" needs to be set also.
  config :value, :validate => :string, :default => ""

  # Prefix for the elements that will be added.
  config :prefix, :validate => :string, :default => ""

  # Remove source field after transformation
  config :remove_source, :validate => :boolean, :default => true

  public
  def register
    @access_by_name = !@key.empty? && !@value.empty?
  end # def register

  public
  def filter(event)
    input = event.get(@source)
    unless input.nil?

      if input.is_a? ::Array
        input.each do |entry|
          begin
            if @access_by_name

              if entry.is_a?(::Hash) # see spec file: test case 1
                if !entry[@key].nil?
                  new_key = @prefix.to_s + entry[@key].to_s
                  value = entry[@value]
                  #@logger.debug("Adding new field " + new_key + " with value " + value)
                else # might be a symbol then and we need to convert our keys to :keys
                  new_key = @prefix.to_s + entry[@key.to_sym].to_s
                  value = entry[@value.to_sym]
                  #@logger.debug("Adding new field " + new_key + ", value " + value)
                end
                event.set(new_key, value)
              else # it's an object of some unknown class.
                @logger.warn("Data structure not supported. " + entry.inspect.to_s)
              end # if is hash

            else # access by position, no key / value names provided

              if entry.is_a?(::Hash)  # see spec file: test case 2
                new_key = @prefix.to_s + entry.keys[0].to_s
                event.set(new_key, entry.values[0])

              else # it's an object of some unknown class.
                @logger.warn("Data structure not supported. " + entry.inspect.to_s)
              end # if is hash

            end # acess type
          rescue
            @logger.warn("Could not find key " + @key + " in incoming data, please check your config. ")
          end
        end # each do
      end # is array

      if input.is_a? ::Hash
        input.each do |key, value|
           event.set(key, value)
        end
      end # is Hash

      if @remove_source
        event.remove(@source)
      end
    end # unless
  end # def filter

end # class LogStash::Filters::List2fields


