import Config

defmodule Helper do
  def parse_subnets(ip_str) do
    ip_str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&IP.Prefix.from_string/1)
    |> Enum.filter(&match?({:ok, _}, &1))
    |> Enum.map(fn {:ok, ip} -> ip end)
  end
end

config :kea_lease_viewer,
  port: System.fetch_env!("PORT") |> String.to_integer(),
  listen_address: System.fetch_env!("LISTEN_ADDRESS"),
  socket_path: System.fetch_env!("KEA_SOCKET_PATH"),
  timezone: "Europe/Berlin",
  disabled_subnets: System.get_env("DISABLED_SUBNETS", "") |> Helper.parse_subnets()
