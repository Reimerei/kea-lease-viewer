import Config

config :kea_lease_viewer,
  port: System.fetch_env!("PORT") |> String.to_integer(),
  socket_path: System.fetch_env!("KEA_SOCKET_PATH")
