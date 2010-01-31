##
#
# Copyright (c) 2009 Rahmal Conda <rahmal@gmail.com>
#
# Extends ActiveRecord::Base to create enumerable
# Lookup tables when acts_as_enum is declared.
#
# Fields:
#
# ## id_column ##
# Custom id column, use this if you want to specify
# and id column that is not called 'id'. By default
# this code expects ar objects based on lookup
# tables with id/name column pairs.
#
# ## nm_column ##
# Custom name column, use this if you want to specify
# and name column that is not called 'name'. By default
# this code expects ar objects based on lookup tables 
# with id/name column pairs.
#
# ## id_string ##
# Use this if the id column is a string. This is
# used in the [] method, to determine whether id 
# column should be checked even though a string 
# was passed.
# Example:
#   @@id_column = :abbr, for state lookup table.
#
# ## enums ##
# An array of all the names of the created enums.
#
module ActiveRecord
  class Base

    ##
    # Call this meta-programming method in a class
    # descended from ActiveRecord:Base.
    # Example:
    #   acts_as_enum  #--> default args
    #   acts_as_enum :abbr, :state_name, true #--> override for U.S. state lookup table
    #
    def self.acts_as_enum *args
      id, nm, id_str = args
      @@id_column = (id.blank? ? :id : id)
      @@nm_column = (nm.blank? ? :name : nm)
      @@id_string = (id_str == true)
      @@enums = []

      rows = find(:all)
      rows.each do |row|
        name = row.send(@@nm_column)
        name = row.send(@@id_column) if name.nil? && @@id_string

        next unless name # no name, no enum...

        name = name.gsub(/\s/, '_').gsub(/\W/, '').upcase
        class_eval "#{name} = row unless defined? #{name}"
        @@enums << name
      end
      @@enums.freeze
    end

    def self.[] index
      case index
      when Integer
        find(index)
      else # Instead of when String, so we can call to_s on other ojbects like Symbol, etc.
        nm = index.to_s
        (@@id_string &&
           send("find_by_#{@@id_column}", nm) ||
           send("find_by_#{@@id_column}", nm.upcase) ||
           send("find_by_#{@@id_column}", nm.downcase)) ||
           send("find_by_#{@@nm_column}", nm) ||
           send("find_by_#{@@nm_column}", nm.upcase) ||
           send("find_by_#{@@nm_column}", nm.downcase)
      end
    end

    def self.enums
      @@enums.dup
    end

    def self.enumeration?
      true
    end

    def self.exists? obj
      not [obj].nil?
    end

    class << self
      alias_method :enum?, :enumeration?
      alias_method :exist?, :exists?
    end

    # Whether or not this record is equal to the given value. If the value is
    # a String, then it is compared against the enumerator. Otherwise,
    # ActiveRecord's default equality comparator is used.
    def ==(other)
      if other.nil? || other.is_a?(self.class)
        super
      elsif other.is_a?(Integer) && !id_str
        other == self.send(@@id_column)
      else
        other = other.to_s.downcase
        id = self.send(@@id_column).to_s.downcase
        nm = self.send(@@nm_column).to_s.downcase
        other == id || othe == nm
      end
    end

    # Determines whether this enum instance is in the given list.
    def in? *list
      list.any? {|item| self === item}
    end

    # String representation of this enum instance, i.e. the name column
    def to_s
      send @@nm_column
    end

  end
end
