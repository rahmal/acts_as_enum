class Object

  ##
  #   @person ? @person.name : nil
  # vs
  #   @person.try(:name)
  def try(method)
    send method if respond_to? method
  end

  ##
  # Find matching type object (i.e. PhoneType, for PhoneNumber).
  # If it exists, override type method, to return it.
  #
  def type
    parts = self.class.to_s.underscore.split('_')
    method = ''
    parts.each do |part|
      method += "#{part}_"
      type_method = method + 'type'
      next unless self.respond_to?(type_method)
      return self.send(type_method)
    end
    super
  end

end
