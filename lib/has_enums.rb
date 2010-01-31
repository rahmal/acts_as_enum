##
# Extends Object to add support to create
# enumerations from a Hash or Yaml file
# This is a great solution when a lookup
# table like pattern would be useful, but
# perhaps a bit weighty for a given situation.
# 
# For example, an address table may have a
# type field that has several valid values
# i.e. home, office, etc. Enumerations for
# those values can be declared as a hash,
# or even stored in a yaml file, and then
# calling has_enums for that field will
# create accessors that ensure only those 
# values can used. It also creates special
# validation and comparator methods for
# the field.
#
# This can be use by ActiveRecord and
# plain ruby objects.  
#
# It also has support for creating select 
# options for bound attribute.
#
# Examples:
#
#     # Values can be a simple array
#     has_enums :address_type, 
#               :values => ['home', 'office', 'shipping', 'billing']
#
#     # Values can be a hash
#     has_enums :address_type, 
#               :values => [1 => 'Home', 2 => 'Office', 3 => 'Shipping', 4 => 'billing']
#
#     # Or Specify a yaml to get values from
#     has_enums :address_type, 
#               :file => "#{RAILS_ROOT}/config/enums.yml",
#               :key  => :address_enums  # Optional: Defaults to attribute name.
#
module HasEnums

  module MacroMethods
  
    def has_enums field, options = {}
  
      include HasEnums::InstanceMethods
      extend  HasEnums::ClassMethods  
    end
  end
  
  module ClassMethods
  end
  
  module InstanceMethods
  end
  
end
Object.class_eval { extend HasEnums::MacroMethods }
