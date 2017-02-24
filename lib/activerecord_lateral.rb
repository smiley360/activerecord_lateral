ActiveRecord::Associations::Builder::Association.class_eval do
  VALID_OPTIONS = [:class_name, :anonymous_class, :foreign_key, :validate, :lateral]

  def self.valid_options(options)
    VALID_OPTIONS + ActiveRecord::Associations::Builder::Association.extensions.flat_map(&:valid_options)
  end
end

ActiveRecord::Associations::Preloader::Association.class_eval do
  def records_for(ids)
    if reflection.options[:lateral]
      relation = scope.where(association_key.eq(Arel.sql('ids.id')))

      # TODO escape or VALUES
      klass.unscoped.
        from("(SELECT unnest(ARRAY[#{ids.join(' ,')}]) id) ids, LATERAL (#{relation.to_sql}) #{klass.table_name}")
    else
      scope.where(association_key.in(ids))
    end
  end
end

ActiveRecord::Associations::Preloader::CollectionAssociation.class_eval do
  def build_scope
    if reflection.options[:lateral]
      super.order(preload_scope.values[:order] || reflection_scope.values[:order]).
        limit(preload_scope.values[:limit] || reflection_scope.values[:limit])
    else
      super.order(preload_scope.values[:order] || reflection_scope.values[:order])
    end
  end
end

ActiveRecord::Associations::Preloader::HasOne.class_eval do
  def build_scope
    if reflection.options[:lateral]
      super.order(preload_scope.values[:order] || reflection_scope.values[:order]).limit(1)
    else
      super.order(preload_scope.values[:order] || reflection_scope.values[:order])
    end
  end
end
