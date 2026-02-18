defmodule KeaLeaseViewer.SocketConnector do
  require Logger

  def list_commands() do
    {:ok, commands} = send_command(%{command: "list-commands"})
    commands
  end

  def get_config() do
    send_command(%{command: "config-get"})
  end

  def get_status() do
    {:ok, config} = send_command(%{command: "status-get"})
    config
  end

  def list_subnets() do
    with {:ok, %{Dhcp4: %{subnet4: subnets}}} <- get_config() do
      {:ok,
       Enum.map(subnets, fn subnet ->
         %{
           prefix: IP.Prefix.from_string!(subnet.subnet),
           id: subnet.id
         }
       end)}
    end
  end

  def list_subnets_cached() do
    case Application.fetch_env(:kea_lease_viewer, :subnets) do
      :error ->
        with {:ok, subnets} <- list_subnets() do
          Application.put_env(:kea_lease_viewer, :subnets, subnets)
          {:ok, subnets}
        end

      {:ok, subnets} ->
        {:ok, subnets}
    end
  end

  def get_leases_for_subnet(subnet_id) do
    command = %{
      command: "lease4-get-all",
      arguments: %{subnets: [subnet_id]}
    }

    with {:ok, %{leases: leases}} <- send_command(command) do
      {:ok, leases}
    end
  end

  def get_leases() do
    with {:ok, subnets} <- list_subnets_cached(),
         subnet_ids = Enum.map(subnets, & &1.id),
         command = %{command: "lease4-get-all", arguments: %{subnets: subnet_ids}},
         {:ok, %{leases: leases}} <- send_command(command) do
      {:ok, leases}
    end
  end

  def delete_lease(ip_address) when is_binary(ip_address) do
    command = %{
      command: "lease4-del",
      arguments: %{"ip-address": ip_address}
    }

    send_command(command)
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

  defp parse_response(%{text: "IPv4 lease deleted.", result: 0}), do: {:ok, :deleted}
  defp parse_response(%{text: "IPv4 lease not found.", result: 3}), do: {:error, :not_found}

  defp parse_response(other) do
    Logger.error("Unexpected response from Kea: #{inspect(other)}")
    {:error, :unexpected_kea_response}
  end
end
