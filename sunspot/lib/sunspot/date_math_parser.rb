module Sunspot
  module Util
    # Based on:
    # https://github.com/apache/lucene-solr/blob/master/solr/core/src/java/org/apache/solr/util/DateMathParser.java
    class DateMathParser
      def initialize(date)
        @date = case date
        when DateTime
          date
        when Time
          date.to_datetime
        when Date
          date.to_datetime
        else
          raise "DateMathParser expects a DateTime got: #{date.class}" 
        end
      end

      def evaluate(gap)
        scanner = StringScanner.new(gap)
        value_stack = [@date]
        op_stack = []

        while !scanner.eos?
          if scanner.scan(/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9.]+Z/)
            value_stack.push(DateTime.parse(scanner.matched))
          elsif scanner.scan(/[0-9]+/)
            value_stack.push(scanner.matched.to_i)
          elsif scanner.scan(/[A-Z]+/)
            value_stack.push(scanner.matched)
          elsif scanner.scan(/\//)
            op_stack.push('round')
          elsif scanner.scan(/\+/)
            op_stack.push('add')
          elsif scanner.scan(/-/)
            op_stack.push('sub')
          else
            throw "Error parsing Date Time Math string in range.gap: #{gap}"
          end
        end

        while !op_stack.empty?
          op = op_stack.pop

          case op
          when 'round'
            unit, value = value_stack.pop, value_stack.pop
            value_stack.push(normalize_date(value, unit))
          when 'add'
            unit, value, date = value_stack.pop, value_stack.pop, value_stack.pop
            value_stack.push(add_date_time(date, value, unit))
          when 'sub'
            unit, value, date = value_stack.pop, value_stack.pop, value_stack.pop
            value_stack.push(sub_date_time(date, value, unit))
          else
            raise "Unrecongnized operator '#{op}' in Date Time Math string in range.gap: #{gap}"
          end
        end

        value_stack.pop
      end

      def normalize_date(date, unit)
        case unit
        when "YEAR", "YEARS"
          DateTime.new(date.year, 1, 1, 0, 0, 0)
        when "MONTH", "MONTHS"
          DateTime.new(date.year, date.month, 1, 0, 0, 0)
        when "DAY", "DAYS"
          DateTime.new(date.year, date.month, date.day, 0, 0, 0)
        when "DATE"
          # not certain how to handle 'DATE' so just pass through date
          date
        when "HOUR", "HOURS"
          DateTime.new(date.year, date.month, date.mday, date.hour, 0, 0)
        when "MINUTE", "MINUTES"
          DateTime.new(date.year, date.month, date.mday, date.hour, date.minute, 0)
        when "SECOND", "SECONDS"
          # Not sure how to truncate to nearest second with only second level
          # accuracy in ruby
          date
        when "MILLI", "MILLIS", "MILLISECOND", "MILLISECONDS"
          # Not sure how to handle milliseconds so just return date
          date
        else
          raise "Unrecognized Date Time Math unit: #{unit}"
        end
      end

      def add_date_time(date, value, unit)
        case unit
        when "YEAR", "YEARS"
          date.next_year(value)
        when "MONTH", "MONTHS"
          date.next_month(value)
        when "DAY", "DAYS"
          date.next_day(value)
        when "DATE"
          # Not certain how to handle 'DATE' so just pass through empty date
          date
        when "HOUR", "HOURS"
          date + Rational(value, 24)
        when "MINUTE", "MINUTES"
          date + Rational(value, 60 * 24)
        when "SECOND", "SECONDS"
          date + Rational(value, 60 * 60 * 24)
        when "MILLI", "MILLIS", "MILLISECOND", "MILLISECONDS"
          date + Rational(value, 1000 * 60 * 60 * 24)
        else
          raise "Unrecognized Date Time Math unit: #{unit}"
        end
      end

      def sub_date_time(date, value, unit)
        case unit
        when "YEAR", "YEARS"
          date.prev_year(value)
        when "MONTH", "MONTHS"
          date.prev_month(value)
        when "DAY", "DAYS"
          date.prev_day(value)
        when "DATE"
          # Not certain how to handle 'DATE' so just pass through empty date
          date
        when "HOUR", "HOURS"
          date - Rational(value, 24)
        when "MINUTE", "MINUTES"
          date - Rational(value, 60 * 24)
        when "SECOND", "SECONDS"
          date - Rational(value, 60 * 60 * 24)
        when "MILLI", "MILLIS", "MILLISECOND", "MILLISECONDS"
          date - Rational(value, 1000 * 60 * 60 * 24)
        else
          raise "Unrecognized Date Time Math unit: #{unit}"
        end
      end
    end
  end
end

