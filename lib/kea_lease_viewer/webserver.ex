defmodule KeaLeaseViewer.Webserver do
  require EEx
  require Logger

  EEx.function_from_file(:def, :render, "lib/kea_lease_viewer/templates/index.html.eex", [:leases])

  def init(options), do: options

  def call(conn, _opts) do
    page =
      get_leases(conn.remote_ip)
      |> render()

    conn
    |> Plug.Conn.send_resp(200, page)
  end

  defp get_leases(ip_tuple) do
    ip = IP.Address.from_tuple!(ip_tuple)

    KeaLeaseViewer.SocketConnector.get_subnets_cached()
    |> Enum.find(fn subnet -> IP.Prefix.contains_address?(subnet.prefix, ip) end)
    |> case do
      nil ->
        Logger.error("No subnets found for IP: #{inspect(ip_tuple)}")
        []

      %{id: id} ->
        KeaLeaseViewer.SocketConnector.get_leases(id)
        |> Enum.map(&mac_vendor_lookup/1)
    end
  end

  defp mac_vendor_lookup(%{"hw-address": mac} = lease) do
    case KeaLeaseViewer.MacVendor.vendor_lookup(mac) do
      {:ok, vendor} ->
        Map.put(lease, :vendor, vendor)

      :error ->
        Map.put(lease, :vendor, "")
    end
  end
end
