# Tried desperately to monkeypatch the polymorphic connection object,
# but rails autoloading is too clever by half. Pull requests are welcome.

# Think of this module as a hipster, using "case" ironically.

require 'with_advisory_lock/base'
require 'with_advisory_lock/mysql'
require 'with_advisory_lock/postgresql'
require 'with_advisory_lock/flock'
require 'active_support/concern'

module WithAdvisoryLock
  module Concern
    extend ActiveSupport::Concern

    def with_advisory_lock(lock_name, timeout_seconds=nil, &block)
      self.class.with_advisory_lock(lock_name, timeout_seconds, &block)
    end

    def acquire_advisory_lock(lock_name)
      self.class.acquire_advisory_lock(lock_name)
    end

    def release_advisory_lock(lock_name)
      self.class.release_advisory_lock(lock_name)
    end

    module ClassMethods

      def with_advisory_lock(lock_name, timeout_seconds=nil, &block)
        impl = impl_class.new(connection, lock_name, timeout_seconds)
        impl.with_advisory_lock_if_needed(&block)
      end

      def acquire_advisory_lock(lock_name)
        impl = impl_class.new(connection, lock_name, nil)
        res = impl.try_lock
        puts "Acquire: #{res}"
        res
      end

      def release_advisory_lock(lock_name)
        impl = impl_class.new(connection, lock_name, nil)
        res = impl.release_lock
        puts "Release: #{res}"
        res
      end

      private

      def impl_class
        case (connection.adapter_name.downcase)
        when "postgresql"
          WithAdvisoryLock::PostgreSQL
        when "mysql", "mysql2"
          WithAdvisoryLock::MySQL
        else
          WithAdvisoryLock::Flock
        end
      end

    end
  end
end
