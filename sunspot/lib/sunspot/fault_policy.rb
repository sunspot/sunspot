require 'logger'

module Sunspot

  #
  # Implement Fault Policy:
  # Takes server using a Round Robin policy from the current live nodes
  #
  module FaultPolicy
    attr_reader :host_index, :current_hostname

    #
    # Get hostname (using RR policy)
    #
    def take_hostname
      # takes all the configured nodes + that one that are derived by solr live config
      hostnames = self.solr.live_nodes.dup
                  .concat(seed_hosts)
                  .uniq
                  .reject { |h| is_faulty(h) }
                  .sort

      # round robin policy
      # hostname format: <ip|hostname> | <ip|hostname>:<port>
      @current_hostname = hostnames[@host_index]
      current_host = @current_hostname.split(':')
      @host_index = (@host_index + 1) % hostnames.size
      if current_host.size == 2
        [current_host.first, current_host.last.to_i]
      else
        current_host + [self.config.port]
      end
    end

    #
    # Return true if an host is in fault state
    # An host is in fault state if and only if:
    # - #number of fault >= 3
    # - time in fault state is >= 1h
    #
    def is_faulty(hostname)
      @faulty_hosts.key?(hostname) &&
        @faulty_hosts[hostname].first >= 3 &&
        (Time.now - @faulty_hosts[hostname].last).to_i >= 3600
    end

    def reset_counter_faulty(hostname)
      @faulty_hosts.delete(hostname)
    end

    def update_faulty_host(hostname)
      @faulty_hosts[hostname]   ||= [0, Time.now]
      @faulty_hosts[hostname][0] += 1
      @faulty_hosts[hostname][1]  = Time.now

      if is_faulty(hostname)
        logger.error "Putting #{hostname} in fault state"
      end
    end

    def seed_hosts
      # uniform seed host
      @seed_hosts ||= self.config.hostnames.map do |h|
        h = h.split(':')
        if h.size == 2
          "#{h.first}:#{h.last.to_i}"
        else
          "#{h.first}:#{self.config.port}"
        end
      end
    end

    #
    # Wrap the solr call and retries in case of ConnectionRefused or Http errors
    #
    def with_exception_handling
      retries = 0
      max_retries = 3
      begin
        yield
        # reset counter of faulty_host for the current host
        reset_counter_faulty(@current_hostname)
      rescue RSolr::Error::ConnectionRefused, RSolr::Error::Http => e
        logger.error "Error connecting to Solr #{e.message}"

        # update the map of faulty hosts
        update_faulty_host(@current_hostname)

        if retries < max_retries
          retries += 1
          sleep_for = 2**retries
          logger.error "Retrying Solr connection in #{sleep_for} seconds... (#{retries} of #{max_retries})"
          sleep(sleep_for)
          retry
        else
          logger.error 'Reached max Solr connection retry count.'
          raise e
        end
      end
    rescue StandardError => e
      logger.error "Exception: #{e.inspect}"
      raise e
    end

    def logger
      @logger ||= ::Rails.logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end