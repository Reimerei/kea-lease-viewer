defmodule KeaLeaseViewer.Application do
  use Application

  @impl true
  def start(_type, _args) do
    set_timezone()

    listen_address =
      Application.fetch_env!(:kea_lease_viewer, :listen_address)
      |> IP.Address.from_string!()
      |> IP.Address.to_tuple()

    port = Application.fetch_env!(:kea_lease_viewer, :port)

    children = [
      {Bandit, plug: KeaLeaseViewer.Webserver, scheme: :http, port: port, ip: listen_address}
    ]

    opts = [strategy: :one_for_one, name: KeaLeaseViewer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp set_timezone() do
    {zone_str, 0} = System.cmd("date", ["+%Z"])
    zone = String.trim(zone_str)
    Application.put_env(:kea_lease_viewer, :timezone, zone)
  end
end
