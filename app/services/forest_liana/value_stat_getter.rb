module ForestLiana
  class ValueStatGetter < StatGetter
    attr_accessor :record

    def perform
      return if @params[:aggregator].blank?
      resource = optimize_record_loading(@resource, get_resource)

      filters = ForestLiana::ScopeManager.append_scope_for_user(@params[:filter], @user, @resource.name)

      unless filters.blank?
        filter_parser = FiltersParser.new(filters, resource, @params[:timezone], @params)
        resource = filter_parser.apply_filters
        raw_previous_interval = filter_parser.get_previous_interval_condition

        if raw_previous_interval
          previous_value = filter_parser.apply_filters_on_previous_interval(raw_previous_interval)
        end
      end

      @record = Model::Stat.new(value: {
        countCurrent: count(resource),
        countPrevious: previous_value ? count(previous_value) : nil
      })
    end

    private

    def count(value)
      uniq = @params[:aggregator].downcase == 'count'

      if Rails::VERSION::MAJOR >= 4
        if uniq
          # NOTICE: uniq is deprecated since Rails 5.0
          value = Rails::VERSION::MAJOR >= 5 ? value.distinct : value.uniq
        end
        value.send(@params[:aggregator].downcase, aggregate_field)
      else
        value.send(@params[:aggregator].downcase, aggregate_field, distinct: uniq)
      end
    end

    def aggregate_field
      @params[:aggregateFieldName] || @resource.primary_key
    end

  end
end
