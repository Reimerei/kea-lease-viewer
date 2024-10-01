import Config

config :logger,
  backends: [
    {ExSyslogger, :ex_syslogger}
  ]

config :logger, :ex_syslogger,
  level: :debug,
  format: "$message",
  ident: "KeaLeaseViewer"
