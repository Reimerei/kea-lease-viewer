defmodule KeaLeaseViewer.SocketConnector do
  require Logger

  def get_subnets() do
    {:ok, config} = send_command(%{command: "config-get"})
    %{Dhcp4: %{subnet4: subnets}} = config

    subnets
    |> Enum.map(fn subnet ->
      %{
        prefix: IP.Prefix.from_string!(subnet.subnet),
        id: subnet.id
      }
    end)
  end

  def get_subnets_cached() do
    case Application.fetch_env(:kea_lease_viewer, :subnets) do
      :error ->
        subnets = get_subnets()
        Application.put_env(:kea_lease_viewer, :subnets, subnets)
        subnets

      {:ok, subnets} ->
        subnets
    end
  end

  def get_leases(subnet_id) do
    command = %{
      command: "lease4-get-all",
      arguments: %{subnets: [subnet_id]}
    }

    {:ok, %{leases: leases}} = send_command(command)
    leases
  end

  def send_command(command) when is_map(command) do
    socket_path = Application.fetch_env!(:kea_lease_viewer, :socket_path)
    gen_tcp_opts = [:binary, active: true, reuseaddr: true]

    with {:ok, socket} <- :gen_tcp.connect({:local, socket_path}, 0, gen_tcp_opts),
         {:ok, binary} <- Jason.encode(command),
         :ok <- :gen_tcp.send(socket, binary),
         response <- wait_for_response(socket),
         {:ok, map} <- Jason.decode(response, keys: :atoms) do
      parse_response(map)
    end
  end

  def wait_for_response(socket) do
    receive do
      {:tcp, ^socket, data} ->
        [data | wait_for_response(socket)]

      {:tcp_closed, ^socket} ->
        []

      other ->
        Logger.error("Unexpected message received from socket #{inspect(other)}")
        []
    after
      3000 ->
        Logger.error("Timeout waiting for response from socket")
        []
    end
  end

  defp parse_response(%{arguments: result}), do: {:ok, result}
  defp parse_response(_), do: {:error, :unexpected_kea_response}
end
