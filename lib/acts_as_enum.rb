##
#
# Copyright (c) 2009 Rahmal Conda <rahmal@gmail.com>
#
# Extends ActiveRecord::Base to create enumerations
# from lookup tables when acts_as_enum is declared.
# All enumerations are cached, so this is a solution 
# for relative small tables. Mainly, lookup tables
# such as state, zip code, and others that might be 
# used in similar id/name patterns within web apps.
#
# Class accessors:
#
# ## id_attribute ##
# Custom id method, use this if you want to specify
# an id column that is not called 'id'. By default
# this code expects ar objects based on lookup
# tables with id/name column pairs.
#
# ## name_attribute ##
# Custom name method, use this if you want to specify
# and name column that is not called 'name'. By default
# this code expects ar objects based on lookup tables 
# with id/name column pairs.
#
# ## primary_key ##
# Use this if the id column is not the primary key. 
# By default it is set to true, and assumes the id
# attribute is the primary key.
#
# ## prefix ##
# Use this to specify a prefix when naming the enum
# constants.  By default the names are used. i.e.
# CALIFORNIA = State.new(:id => 'CA', :name => 'California')
#
# But if you wish to create a constant for a table like 
# zip_codes, you can use a prefix, i.e.
# ZIP60601 = ZipCode.new(:id => 60601, :name => '60601', :city ...)
#
# ## enums ##
# An array of all the instances of the created enums.
#
module ActsAsEnum

  module MacroMethods

    def acts_as_enum id_attr = :id, name_attr = :name, options = {}
      cattr_accessor :id_attribute, :name_attribute, 
                     :enums, :primary_key, :prefix
                     
      id_attribute, name_attribute = id_attr, name_attr
      
      primary_key = options[:primary_key].nil? ? true : options[:primary_key] # default to true
      prefix = options[:prefix] # use specified prefix on name, but strip it on search.
      
      enums = []            
      @@enum_by_id = {}  # not accessible outside the class
      @@enum_by_nm = {}  # this one too

      rows = find(:all)
      rows.each do |row|        
        id = row.send(self.id_attribute)
        name = row.send(name_attribute)
        id_is_name = false        
        
        if name.blank? # cound have no name i.e. ZipCode
          name = row.send(id_attribute)
          id_is_name = true
        end  
        
        # Still no name? Nothing we can do.
        raise ArgumentError, "Unable to retrieve suitable name" if name.blank?
                
        make_constant name, prefix # i.e. State::ILLINOIS or PhoneType::HOME
        
        # make enums from id as well, i.e. State::IL
        # use prefix for numeric ids, i.e. ZipCode::ZIP60601
        # if id is name, then enum is already created.
        make_constant id, prefix if options[:make_id_enum] && !id_is_name
                  
        # Cache the rows for access and searching          
        self.enums << row
        @@enums_by_id[scrub(id)] = row
        @@enums_by_nm[scrub(name)] = row
      end

      # No changing these!      
      self.enums.freeze
      @@enums_by_id.freeze
      @@enums_by_nm.freeze              
    
      include ActsAsEnum::InstanceMethods
      extend  ActsAsEnum::ClassMethods
    end
    
    # Always returns false: class does not become an enum without calling acts_as_enum.
    def enum?
      false
    end    
    
    private # helper methods
    
    def make_constant name, prefix=nil
      name = prefix + name.to_s unless prefix.blank?
      name = scrub(name)
      class_eval "#{name.upcase} = row unless defined? #{name.upcase}"          
    end
    
    def scrub name
      name.to_s.gsub(/\s/, '_').gsub(/\W/, '').downcase
    end
        
  end
    
  module ClassMethods
  
    def find_by_id(id)
      @@enums_by_id[id.to_s.downcase]
    end
    
    def find_by_name(name)
      @@enums_by_nm[name.to_s.downcase]
    end
  
    def [] enum
      find_by_id(enum) || find_by_id(enum)
    end
    
    # Always returns true: This class is an enum since it
    # has included this method by calling acts_as_enum
    def enum?
      true
    end

    # Does the given obj exist in the cache of enums for this class?
    def exists? obj
      not [obj].nil?
    end
    alias_method :exist?, :exists?
    alias_method :include?, :exists?
    
    # Is the id column the primary key?
    def primary_key?
      self.primary_key
    end

    # All the values for enums given id attribute 
    # i.e. State.ids => ['ny', 'il', 'ca' ...] or EmailType.ids => [1, 2, 3, ...]
    def ids
      @@enums_by_id.keys
    end
    
    # All the values for enums given name attribute i.e. PhoneType.names => ['home', 'work', 'fax' ...]
    def names
      @@enums_by_nm.keys
    end
    
    def to_select_options
      enums.map do |enum|
        [enum.id_value, enum.name_value]
      end
    end

  end
    
  module InstanceMethods
  
    # Whether or not this enum is equal to the given value. If the value is
    # an ActiveRecord then the default equality comparator is used.
    # Otherwise, compare against the id and/or name attributes.
    # i.e EmailType::PERSONAL == 'peronal' => true
    #     EmailType::WORK == EmailType[:personal] => fale
    def ==(other)
      if other.nil? || other.is_a?(self.class)
        super
      elsif other.is_a?(Integer) && self.class.primary_key?
        other == self.send(self.class.id_attribute)
      else
        other = other.to_s.downcase
        id = id_value.to_s.downcase
        nm = self.send(self.class.name_attribute).to_s.downcase
        other == id || othe == nm
      end
    end

    # Returns the value from the column specified as the id_attribute,
    # even if the column is not self.id
    def id_value
      send(self.class.id_attribute)
    end
    
    # Returns the value from the column specified as the name_attribute,
    # even if the column is not self.name
    def name_value
      send(self.class.name_attribute)
    end
    
    # String representation of this enum instance, i.e. State::NEW_YORK.to_s => "New York"
    def to_s
      name_value.titleize
    end
  
  end

end
ActiveRecord::Base.class_eval { extend ActsAsEnum::MacroMethods }

