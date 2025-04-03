defmodule KeaLeaseViewer.Webserver do
  use Plug.Router
  require EEx
  require Logger

  plug RemoteIp, clients: ~w[10.0.0.0/8]

  plug Plug.Parsers,
    parsers: []

  plug Plug.Logger, log: :debug

  plug :match
  plug :dispatch

  @columns [
    {:"ip-address", "IP"},
    {:"subnet-id", "Subnet"},
    {:hostname, "Hostname"},
    {:"hw-address", "Mac"},
    {:vendor, "Vendor"},
    {:starts, "Starts"},
    {:ends, "Ends"}
  ]


  EEx.function_from_file(:def, :render, "lib/kea_lease_viewer/templates/index.html.eex", [:leases, :sort_by, :columns])

  get "/" do
    page =
      try do
        Logger.debug("Request from #{inspect(conn.remote_ip)}")

        sort_by = parse_sort_params(conn.params)

        get_leases_for_ip(conn.remote_ip)
        |> render_page(sort_by)
      catch
        error ->
          msg = "Error rendering page: #{inspect(error)}"
          Logger.error(msg)
          msg
      end

    conn
    |> send_resp(200, page)
  end

  get "/all" do
    page =
      try do
        Logger.debug("Admin Request from #{inspect(conn.remote_ip)}")

        sort_by = parse_sort_params(conn.params)

        KeaLeaseViewer.SocketConnector.get_leases()
        |> render_page(sort_by)
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

  def render_page(leases, sort_by) do
    leases
    |> Enum.filter(&lease_expired?/1)
    |> Enum.map(&mac_vendor_lookup/1)
    |> Enum.map(&parse_timestamps/1)
    |> sort_leases(sort_by)
    |> render(sort_by, @columns)
  end

  def get_leases_for_ip(ip_tuple) do
    if is_disabled?(ip_tuple) do
      []
    else
      get_subnet_leases(ip_tuple)
    end
  end

  defp get_subnet_leases(ip_tuple) do
    ip = IP.Address.from_tuple!(ip_tuple)

    KeaLeaseViewer.SocketConnector.list_subnets_cached()
    |> Enum.find(fn subnet -> IP.Prefix.contains_address?(subnet.prefix, ip) end)
    |> case do
      nil ->
        Logger.error("No subnets found for IP: #{inspect(ip_tuple)}")
        []

      %{id: id} ->
        KeaLeaseViewer.SocketConnector.get_leases_for_subnet(id)
    end
  end

  defp is_disabled?(ip_tuple) do
    disabled_subnets = Application.fetch_env!(:kea_lease_viewer, :disabled_subnets)

    disabled_subnets
    |> Enum.any?(fn subnet ->
      IP.Prefix.contains_address?(subnet, IP.Address.from_tuple!(ip_tuple))
    end)
  end

  defp lease_expired?(%{state: 0}), do: true
  defp lease_expired?(_), do: false

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

  defp sort_leases(leases, {sort_field, direction}) when is_atom(sort_field) and is_atom(direction) do
    case sort_field do
      :"ip-address" ->
        Enum.sort_by(leases, &(IP.Address.from_string!(&1[:"ip-address"]).address), direction)
      field ->
        Enum.sort_by(leases, fn lease ->
          {lease[field], IP.Address.from_string!(lease[:"ip-address"]).address}
        end, direction)
    end
  end

  defp parse_sort_params(%{"sort" => field, "dir" => direction}) do
    {String.to_existing_atom(field), String.to_existing_atom(direction)}
  end

  defp parse_sort_params(_) do
    {:"subnet-id", :asc}
  end

end
