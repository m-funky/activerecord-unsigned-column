module ActiveRecord
  module ConnectionAdapters
    class TableDefinition
      ['unsigned', 'unsigned_d'].map do |method|
        define_method "#{method}" do |*args|
          options = args.extract_options!
          column_names = args
          type = method.to_sym
          column_names.each { |name| column(name, type, options) }
        end
      end
    end

    class Table
      def unsigned
        options = args.extract_options!
        column_names = args
        type = :unsigned
        column_names.each do |name|
          column = ColumnDefinition.new(@base, name, type)
          if options[:limit]
            column.limit = options[:limit]
          elsif native[type].is_a?(Hash)
            column.limit = native[type][:limit]
          end
          @base.add_column(@table_name, name, column.sql_type, options)
        end
      end

      def unsigned_d
        options = args.extract_options!
        column_names = args
        type = :unsigned_d
        column_names.each do |name|
          column = ColumnDefinition.new(@base, name, type)
          if options[:precision]
            column.precision = options[:precision]
          elsif native[type].is_a?(Hash)
            column.precision = native[type][:precision]
          end

          if options[:scale]
            column.scale = options[:scale]
          elsif native[type].is_a?(Hash)
            column.scale = native[type][:scale]
          end
          @base.add_column(@table_name, name, column.sql_type, options)
        end
      end
    end

    class AbstractMysqlAdapter
      class Column
        def simplified_type_with_unsigned(field_type)
          if field_type =~ /unsigned/i
            if field_type =~ /int/i
              :unsigned
            elsif field_type =~ /decimal/i
              :unsigned_d
            else
              simplified_type_without_unsigned(field_type)
            end
          else
            simplified_type_without_unsigned(field_type)
          end
        end
        alias_method_chain :simplified_type, :unsigned

        def type_cast(value)
          if type == :unsigned
            return nil if value.nil?
            return coder.load(value) if encoded?
            value.to_i rescue value ? 1 : 0
          else
            super
          end
        end
      end

      def type_to_sql_with_unsigned(type, limit = nil, precision = nil, scale = nil)
        if type == :unsigned_d
          type_to_sql_without_unsigned(:decimal, limit, precision, scale) << " unsigned"
        elsif type == :unsigned
          case limit
          when 1; 'tinyint unsigned'
          when 2; 'smallint unsigned'
          when 3; 'mediumint unsigned'
          when nil, 4, 10; 'int(10) unsigned'
          when 5..8; 'bigint unsigned'
          else raise(ActiveRecordError, "No integer type has byte size #{limit}")
          end
        else
          type_to_sql_without_unsigned(type, limit, precision, scale)
        end
      end
      alias_method_chain :type_to_sql, :unsigned

      NATIVE_DATABASE_TYPES.merge!(
        :unsigned => { :name => 'int(10) unsigned', :limit => 4 },
        :unsigned_d => { :name => 'decimal(10,2) unsigned', :precision => 10, :scale => 2}
      )
    end
  end
end
