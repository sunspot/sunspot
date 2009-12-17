module Sunspot
  module SessionProxy
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
  end
end
