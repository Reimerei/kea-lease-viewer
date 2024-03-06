defmodule KeaLeaseViewer.Webserver do
  require Logger

  def init(options), do: options

  def call(conn, _opts) do
    leases = get_leases(conn.remote_ip)
    content = EEx.eval_file("lib/kea_lease_viewer/index.html.eex", leases: leases)

    conn
    |> Plug.Conn.send_resp(200, content)
  end

  defp get_leases(ip_tuple) do
    ip = IP.Address.from_tuple!(ip_tuple)

    KeaLeaseViewer.SocketConnector.get_subnets_cached()
    |> Enum.find(fn subnet -> IP.Prefix.contains_address?(subnet.prefix, ip) end)
    |> case do
      nil ->
        Logger.error("No leases found for IP: #{inspect(ip_tuple)}")
        []

      %{id: id} ->
        KeaLeaseViewer.SocketConnector.get_leases(id)
    end
  end
end
