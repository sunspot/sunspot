module Sunspot
  module SessionProxy
    NotSupportedError = Class.new(Exception)

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
  end
end
