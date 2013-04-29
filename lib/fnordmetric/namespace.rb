class FnordMetric::Namespace

  attr_reader :handlers, :gauges, :opts, :key

  @@opts = [:event, :gauge, :widget, :set_title]

  @@multi_gauges = [:timeseries_gauge, :toplist_gauge, :distribution_gauge]

  def initialize(key, opts)
    @gauges = Hash.new
    @handlers = Hash.new.with_indifferent_access
    @title = key
    @opts = opts
    @key = key

    #@flags = {
    #  :hide_active_users => (FnordMetric.options[:enable_active_users] == false),
    #  :hide_gauge_explorer => (FnordMetric.options[:enable_gauge_explorer] == false)
    #}
  end

  def ready!(redis, sync_redis = nil)
    @redis = redis
    @sync_redis = sync_redis
    load_gauges
    self
  end

  def announce(event)
    if !@flags[:hide_active_users]
      announce_to_timeline(event)
      announce_to_typelist(event)
    end

    if event[:_session]
      event[:_session_key] = announce_to_session(event).session_key 
    end

    if event[:_type].to_sym == :_enterprise
      ctx = FnordMetric::Context.new(opts, FnordMetric::Enterprise::CompatibilityHandler)
      ctx.call(event, @redis, self)
      return self
    end

    if FnordMetric::ZeroConfigGauge::TYPES.include?(event[:_type].to_sym)
      ctx = FnordMetric::Context.new(opts, FnordMetric::ZeroConfigGauge::Handler)
      ctx.call(event, @redis, self)
      return self
    end

    res = [
      @handlers[event[:_type].to_s],
      @handlers["*"]
    ].flatten.compact.each do |context|
      context.call(event, @redis, self)
    end.size

    if res == 0
      FnordMetric.error("no handler for event-type: #{event[:_type]}")
    end

    self
  end

  def announce_to_session(event)
    FnordMetric::Session.create(@opts.clone.merge(
      :namespace_key => @key,
      :namespace_prefix => key_prefix,
      :redis => @redis,
      :event => event
    ))
  end

  def announce_to_timeline(event)
    timeline_key = key_prefix(:timeline)
    @redis.zadd(timeline_key, event[:_time], event[:_eid])
  end

  def announce_to_typelist(event)
    typelist_key = key_prefix("type-#{event[:_type]}")
    @redis.lpush(typelist_key, event[:_eid])
  end


  def key_prefix(append=nil)
    [@opts[:redis_prefix], @key, append].compact.join("-")
  end

  def token
    @key
  end

  def title
    @title
  end

  #def dashboards(name=nil, opts = {})
  #  return @dashboards unless name
  #  dash = FnordMetric::Dashboard.new(opts.merge(:title => name))
  #  @dashboards[dash.token.to_s] ||= dash
  #end

  def sessions(_ids, opts={})
    return FnordMetric::Session.all(extend_opts(opts)) if _ids == :all
  end

  def events(_ids, opts={})
    return FnordMetric::Event.all(extend_opts(opts)) if _ids == :all
    return FnordMetric::Event.by_type(opts.delete(:type), extend_opts(opts)) if _ids == :by_type
    return FnordMetric::Event.by_session_key(opts.delete(:session_key), extend_opts(opts)) if _ids == :by_session_key
  end

  def method_missing(m, *args, &block)
    return send(:opt_multigauge, *args.unshift(m), &block) if @@multi_gauges.include?(m)
    raise "unknown option: #{m}" unless @@opts.include?(m)
    send(:"opt_#{m}", *args, &block)
  end

  #def opt_hide_active_users
  #  @flags[:hide_active_users] = true
  #end

  #def opt_hide_gauge_explorer
  #  @flags[:hide_gauge_explorer] = true
  #end

  #def opt_hide_overview
  #  @flags[:hide_overview] = true
  #end

  def opt_set_title(title)
    @title = title
  end

  def opt_event(event_type, opts={}, &block)
    FnordMetric::Context.new(opts, block).tap do |context|
      @handlers[event_type.to_s] ||= []
      @handlers[event_type.to_s] << context
    end
  end

  def opt_gauge(gauge_key, opts={})
    opts.merge!(:key => gauge_key)
    store_gauge(gauge_key, opts) if opts[:zero_config]
    opts.merge!(:key_prefix => key_prefix)
    klass = "FnordMetric::#{(opts[:type] || "").to_s.camelize}Gauge".constantize
    @gauges[gauge_key] ||= klass.new(opts)
  end

  def opt_multigauge(gauge_type, gauge_key, opts={})
    opts.merge!(:key => gauge_key, :key_prefix => key_prefix)
    klass = "FnordMetric::#{gauge_type.to_s.camelize}"
    @gauges[gauge_key] ||= klass.constantize.new(opts)   
  end

  #def opt_widget(dashboard, widget)
  #  widget = build_widget(widget) if widget.is_a?(Hash)
  #  dashboards(dashboard).add_widget(widget)
  #end

  #def opt_dashboard(dashboard, opts)
  #  dashboards(dashboard, opts)
  #end

  #def build_widget(opts)
  #  _gauges = [opts[:gauges]].flatten.map do |g|
  #    @gauges[g] || FnordMetric::ZeroConfigGauge.new(g, self)
  #  end
  #  widget_klass = "FnordMetric::#{opts.fetch(:type).to_s.capitalize}Widget"
  #  widget_klass.constantize.new(opts.merge(:gauges => _gauges))
  #end

  def store_gauge(gauge_key, opts)
    gaugelist_key = key_prefix("zero-config-gauges")
    sync_redis.hset(gaugelist_key, gauge_key, opts.to_json)
  end

  def load_gauges
    gaugelist_key = key_prefix("zero-config-gauges")
    sync_redis.hgetall(gaugelist_key).each do |gauge_key, gauge_opts|
      gopts = JSON.parse(gauge_opts).symbolize_keys
      gopts.delete(:zero_config)
      opt_gauge(gauge_key.to_sym, gopts)
    end
  end

  def sync_redis
    @sync_redis || @redis
  end

  def extend_opts(opts)
    opts.merge(
      :namespace_prefix => key_prefix,
      :redis_prefix => @opts[:redis_prefix],
      :redis => @redis
    )
  end

  def to_json
    flags.merge(
      :token => token,
      :title => title
    ).to_json
  end

end
