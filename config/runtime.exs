import Config

config :kea_lease_viewer,
  port: System.fetch_env!("PORT") |> String.to_integer(),
  listen_address: System.fetch_env!("LISTEN_ADDRESS"),
  socket_path: System.fetch_env!("KEA_SOCKET_PATH"),
  timezone: "Europe/Berlin"
