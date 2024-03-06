defmodule KeaLeaseViewer.Application do
  use Application

  @impl true
  def start(_type, _args) do
    port = Application.fetch_env!(:kea_lease_viewer, :port)
    children = [{Bandit, plug: KeaLeaseViewer.Webserver, scheme: :http, port: port}]
    opts = [strategy: :one_for_one, name: KeaLeaseViewer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
