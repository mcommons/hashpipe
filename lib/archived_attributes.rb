require File.expand_path(File.join(File.dirname(__FILE__), %w[archived_attributes archived_attribute] ))

module ArchivedAttributes

  def self.included(base)
    base.extend(SingletonMethods)
  end

  module SingletonMethods

    def archived_attribute(*args)
      before_save :save_archived_attributes
      # before_destroy :destroy_attached_files

      attribute = args.first

      options = args.extract_options!
      options.reverse_merge! :marshalled => false

      write_inheritable_attribute(:archived_attribute_definitions, {}) if archived_attribute_definitions.nil?
      archived_attribute_definitions[attribute] = options

      self.__send__(:include, InstanceMethods)

      define_method attribute do
        archive_stash_for(attribute).value
      end

      define_method "#{attribute}=" do |value|
        archive_stash_for(attribute).value = value
      end
    end

    # Returns the attachment definitions defined by each call to
    # has_attached_file.
    def archived_attribute_definitions
      read_inheritable_attribute(:archived_attribute_definitions)
    end

    private

    def archived_attribute_configuration
      YAML.load_file(
        File.join( RAILS_ROOT, 'config', 'archived_attributes.yml' )
      )[RAILS_ENV]
    end

  end

  module InstanceMethods
    def archive_stash_for(model)
      @_archived_attribute_stashes ||= {}
      @_archived_attribute_stashes[model] ||= ArchivedAttribute.new(
        model, self, self.class.archived_attribute_definitions[model]
      )
    end

    def each_archived_stash
      self.class.archived_attribute_definitions.each do |name, definition|
        yield(name, archive_stash_for(name))
      end
    end

    def save_archived_attributes
      each_archived_stash do |name, stash|
        stash.__send__(:save)
      end
    end

  end
end