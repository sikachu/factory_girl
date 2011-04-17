module FactoryGirlStepHelpers

  def convert_association_string_to_instance(factory_name, assignment)
    attribute, value = assignment.split(':', 2)
    return if value.blank?
    factory = FactoryGirl.find(factory_name)
    attributes = convert_human_hash_to_attribute_hash({attribute => value.strip}, factory.associations)
    attributes_find = {}
    attributes.each do |k, v|
      k = "#{k}_id" if v.is_a? ActiveRecord::Base
      attributes_find[k] = v
    end
    model_class = factory.build_class
    model_class.find(:first, :conditions => attributes_find) or
      FactoryGirl.create(factory_name, attributes)
  end

  def convert_human_hash_to_attribute_hash(human_hash, associations = [])
    human_hash.inject({}) do |attribute_hash, (human_key, value)|
      key = human_key.downcase.gsub(' ', '_').to_sym
      if association = associations.detect {|association| association.name == key }
        value = convert_association_string_to_instance(association.factory, value)
      end
      attribute_hash.merge(key => value)
    end
  end
end

World(FactoryGirlStepHelpers)

FactoryGirl.registry.each do |name, factory|
  Given /^the following (?:#{factory.human_name}|#{factory.human_name.pluralize}) exists?:$/ do |table|
    table.hashes.each do |human_hash|
      attributes = convert_human_hash_to_attribute_hash(human_hash, factory.associations)
      factory.run(FactoryGirl::Proxy::Create, attributes)
    end
  end

  Given /^an? #{factory.human_name} exists$/ do
    FactoryGirl.create(factory.name)
  end

  Given /^(\d+) #{factory.human_name.pluralize} exist$/ do |count|
    count.to_i.times { FactoryGirl.create(factory.name) }
  end

  factory_columns = []
  if factory.build_class.respond_to?(:columns)
    factory_columns = factory.build_class.columns.map{ |c| c.name }
  elsif factory.build_class.respond_to?(:fields)
    factory_columns = factory.build_class.fields.keys
  end

  factory_columns.each do |column_name|
    human_column_name = column_name.downcase.gsub('_', ' ')
    Given /^an? #{factory.human_name} exists with an? #{human_column_name} of "([^"]*)"$/i do |value|
      FactoryGirl.create(factory.name, column_name => value)
    end

    Given /^(\d+) #{factory.human_name.pluralize} exist with an? #{human_column_name} of "([^"]*)"$/i do |count, value|
      count.to_i.times { FactoryGirl.create(factory.name, column_name => value) }
    end
  end
end

