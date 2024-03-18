defmodule KeaLeaseViewer.Webserver do
  use Plug.Router
  require EEx
  require Logger

  plug RemoteIp
  plug :match
  plug :dispatch

  EEx.function_from_file(:def, :render, "lib/kea_lease_viewer/templates/index.html.eex", [:leases])

  get "/" do
    page =
      try do
        # get_leases_for_ip(conn.remote_ip)
        KeaLeaseViewer.SocketConnector.get_all_leases()
        |> Enum.map(&mac_vendor_lookup/1)
        |> Enum.map(&parse_timestamps/1)
        |> Enum.sort_by(fn lease -> {lease."subnet-id", lease."ip-address"} end)
        |> render()
      catch
        error ->
          msg = "Error rendering page: #{inspect(error)}"
          Logger.error(msg)
          msg
      end

    conn
    |> send_resp(200, page)
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  defp get_leases_for_ip(ip_tuple) do
    ip = IP.Address.from_tuple!(ip_tuple)

    KeaLeaseViewer.SocketConnector.get_subnets_cached()
    |> Enum.find(fn subnet -> IP.Prefix.contains_address?(subnet.prefix, ip) end)
    |> case do
      nil ->
        Logger.error("No subnets found for IP: #{inspect(ip_tuple)}")
        []

      %{id: id} ->
        KeaLeaseViewer.SocketConnector.get_leases(id)
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

  defp parse_timestamps(%{"valid-lft": valid_lft, cltt: cltt} = lease) do
    lease
    |> Map.put(:starts, cltt |> unix_time_to_str())
    |> Map.put(:ends, (cltt + valid_lft) |> unix_time_to_str())
  end

  defp unix_time_to_str(unix_time) do
    timezone = Application.fetch_env!(:kea_lease_viewer, :timezone)

    DateTime.from_unix!(unix_time)
    |> DateTime.shift_zone!(timezone, Zoneinfo.TimeZoneDatabase)
    |> Calendar.strftime("%Y-%m-%d %H:%M:%S")
  end
end
