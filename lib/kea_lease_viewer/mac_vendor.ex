defmodule KeaLeaseViewer.MacVendor do
  alias KeaLeaseViewer.MacVendorParser

  @lookup_table :code.priv_dir(:kea_lease_viewer)
                |> Path.join("/mac_vendors.txt")
                |> File.read!()
                |> MacVendorParser.build_lookup_table()

  def vendor_lookup(mac) when is_binary(mac) do
    {key, bit_mac} =
      case MacVendorParser.to_bitstring(mac) do
        <<key::bits-size(24), _::bits-size(24)>> = bit_mac -> {key, bit_mac}
        _ -> {nil, nil}
      end

    case @lookup_table[key] do
      vendor when is_binary(vendor) ->
        {:ok, vendor}

      {key_bitsize, %{} = sub_match_map} ->
        <<sub_key::bits-size(key_bitsize), _::bits>> = bit_mac

        case sub_match_map[sub_key] do
          vendor when is_binary(vendor) -> {:ok, vendor}
          _ -> :error
        end

      _ ->
        :error
    end
  end
end
