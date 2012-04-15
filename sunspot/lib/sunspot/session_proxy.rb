module Sunspot
  # 
  # This module contains several Session Proxy implementations, which can be
  # used to decorate one or more Session objects and add extra functionality.
  # The user can also implement their own Session Proxy classes; a Session Proxy
  # must simply implement the same public API as the Sunspot::Session class.
  #
  # When implementing a session proxy, some methods of Session may not be
  # practical, or even logical, to implement. In this case, the method should
  # raise a Sunspot::SessionProxy::NotSupportedError (several methods in the
  # built-in session proxies raise this error).
  #
  # To use a session proxy in normal Sunspot usage, you can use the
  # Sunspot.session= method, which will cause Sunspot to delegate all of its
  # session-related class methods (most of them) to the proxy. Session proxies
  # can also easily be chained, although the details of chaining depend on the
  # proxy implementation.
  #
  # ===== Example: Chain a MasterSlaveSessionProxy with a ThreadLocalSessionProxy
  #
  #   master_session = Sunspot::SessionProxy::ThreadLocalSessionProxy.new
  #   slave_session = Sunspot::SessionProxy::ThreadLocalSessionProxy.new
  #   master_session.config.solr.url = 'http://master-solr.local:9080/solr'
  #   slave_session.config.solr.url = 'http://slave-solr.local:9080/solr'
  #   Sunspot.session = Sunspot::SessionProxy::MasterSlaveSessionProxy.new(master_session, slave_session)
  #
  module SessionProxy
    NotSupportedError = Class.new(StandardError)

    autoload(
      :AbstractSessionProxy,
      File.join(
        File.dirname(__FILE__),
        'session_proxy',
        'abstract_session_proxy'
      )
    )
    autoload(
      :ThreadLocalSessionProxy,
      File.join(
        File.dirname(__FILE__),
        'session_proxy',
        'thread_local_session_proxy'
      )
    )
    autoload(
      :MasterSlaveSessionProxy,
      File.join(
        File.dirname(__FILE__),
        'session_proxy',
        'master_slave_session_proxy'
      )
    )
    autoload(
      :ShardingSessionProxy,
      File.join(
        File.dirname(__FILE__),
        'session_proxy',
        'sharding_session_proxy'
      )
    )
    autoload(
      :ClassShardingSessionProxy,
      File.join(
        File.dirname(__FILE__),
        'session_proxy',
        'class_sharding_session_proxy'
      )
    )
    autoload(
      :IdShardingSessionProxy,
      File.join(
        File.dirname(__FILE__),
        'session_proxy',
        'id_sharding_session_proxy'
      )
    )
    autoload(
      :SilentFailSessionProxy,
      File.join(
        File.dirname(__FILE__),
        'session_proxy',
        'silent_fail_session_proxy'
      )
    )
    autoload(
      :Retry5xxSessionProxy,
      File.join(
        File.dirname(__FILE__),
        'session_proxy',
        'retry_5xx_session_proxy'
      )
    )
  end
end
