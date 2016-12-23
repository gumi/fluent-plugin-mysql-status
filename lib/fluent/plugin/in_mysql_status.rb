require 'mysql2'

module Fluent
  class MySQLStatusInput < Input
    Plugin.register_input('mysql_status', self)

    config_param :tag, :string

    config_param :host, :string, :default => 'localhost'
    config_param :port, :integer, :default => 3306
    config_param :username, :string, :default => 'root'
    config_param :password, :string, :default => nil
    config_param :database, :string, :default => nil
    config_param :encoding, :string, :default => 'utf8'

    config_param :comment, :string, :default => 'Fluent::MySQLStatusInput'

    attr_reader :queries

    def initialize
      super
      @queries = []
    end

    def configure(conf)
      super

      conf.elements.select {|element|
        element.name == 'query'
      }.each do |element|
        tag = element['tag'] or raise ConfigError, "Missing 'tag' parameter on <query> directive"
        string, default = configure_query_string(element)
        interval = element['interval'] || 10

        omit_variable_name_from_record, clump_records = [
          'omit_variable_name_from_record', 'clump_records',
        ].map do |key|
          configure_query_format_flag(element, key, default)
        end

        clumped_records_key = element['clumped_records_key'] || 'records'

        @queries << {
          :tag => tag,
          :string => string,
          :interval => Integer(interval),
          :omit_variable_name_from_record => omit_variable_name_from_record,
          :clump_records => clump_records,
          :clumped_records_key => clumped_records_key,
        }
      end
    end

    def start
      @watcher = Thread.new(&method(:watch))
    end

    def shutdown
      @watcher.kill
    end

    def watch
      client = ensure_connect()
      counter = generate_counter()
      loop do
        begin
          emit_queries(client, counter.next())
        rescue => e
          $log.error e.message
          client = ensure_connect()
        end
        sleep 1
      end
    end

    private

    def configure_query_string(conf)
      type = conf['type']
      path = conf['path']
      string = conf['string']

      if type and path or type and string or path and string
        raise ConfigError, "'type', 'path' and 'string' parameter can't be defined together."
      end

      if type
        return case type
        when 'processlist'
          ['SHOW FULL PROCESSLIST', false]
        when 'open_tables'
          ['SHOW OPEN TABLES', false]
        when 'status'
          ['SHOW /*!50002 GLOBAL */ STATUS', true]
        else
          raise ConfigError, "Missing 'type' parameter on <query> directive"
        end
      elsif path
        return [File.read(path), false]
      elsif string
        return [string, false]
      else
        raise ConfigError, "Missing 'type' parameter on <query> directive"
      end
    end

    def configure_query_format_flag(conf, key, default)
      case conf[key]
      when nil
        default
      when 'true'
        true
      else
        false
      end
    end

    def ensure_connect
      intervals = generate_intervals()
      begin
        return Mysql2::Client.new({
          :host => @host,
          :port => @port,
          :username => @username,
          :password => @password,
          :database => @database,
          :encoding => @encoding,
          # :reconnect => true,
        })
      rescue => e
        $log.error e.message
        sleep intervals.next()
        retry
      end
    end

    def generate_intervals
      return Enumerator.new do |yielder|
        temp, interval = 0, 1
        loop do
          if 55 <= interval
            yielder << 60
          else
            temp, interval = interval, temp + interval
            yielder << interval
          end
        end
      end
    end

    def generate_counter
      return Enumerator.new do |yielder|
        counter = 0
        loop do
          counter += 1
          yielder << counter
          if 86400 <= counter
            counter = 0
          end
        end
      end
    end

    def emit_queries(client, counter)
      @queries.each do |query|
        next unless can_emit?(counter, query[:interval])
        result = run_query(client, query[:string]) or next
        if query[:omit_variable_name_from_record]
          omit_and_emit(query, result)
        else
          emit(query, result)
        end
      end
    end

    def can_emit?(counter, interval)
      return counter % interval == 0
    end

    def run_query(client, query)
      begin
        return client.query("#{query} /* #{@comment} */", :cast => false, :cache_rows => false)
      rescue Mysql2::Error => e
        raise if [nil, 1040, 1053, 2002, 2003, 2006, 2013].include?(e.error_number)
        $log.error %Q(query: "#{query}" reason: "#{e.message}")
        return nil
      end
    end

    def emit(query, result)
      tag = make_tag(query[:tag])
      time = Engine.now

      records = []
      result.each do |row|
        record = {}
        row.each do |key, value|
          record[key] = format(value)
        end

        if query[:clump_records]
          records << record
        else
          router.emit(tag, time, record)
        end
      end

      if query[:clump_records]
        router.emit(tag, time, {query[:clumped_records_key] => records})
      end
    end

    def omit_and_emit(query, result)
      tag = make_tag(query[:tag])
      time = Engine.now

      record = {}
      result.each do |row|
        key = row.fetch('Variable_name')
        value = format(row.fetch('Value'))

        if query[:clump_records]
          record[key] = value
        else
          emit_tag = [tag, key].join('.')
          router.emit(emit_tag, time, value)
        end
      end

      if query[:clump_records]
        router.emit(tag, time, record)
      end
    end

    def make_tag(tag_suffix)
      return [@tag, tag_suffix].join('.')
    end

    def format(value)
      return Integer(value) rescue Float(value) rescue value
    end
  end
end
