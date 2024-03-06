defmodule KeaLeaseViewer.MacVendorParser do
  # Heavily inspired by https://github.com/ephe-meral/mac

  def build_lookup_table(wireshark_file) do
    wireshark_file
    |> parse_wireshark_file()
    |> Enum.reduce(%{}, fn
      {bit_mac, vendor}, acc when bit_size(bit_mac) == 24 ->
        acc
        |> Map.update(bit_mac, vendor, fn
          sub_match when not is_binary(sub_match) -> sub_match
          _ -> vendor
        end)

      {<<key::bits-size(24), _::bits>> = bit_mac, vendor} = tuple, acc ->
        key_bitsize = bit_size(bit_mac)

        acc
        |> Map.update(key, {key_bitsize, %{bit_mac => vendor}}, fn
          sub_match when not is_binary(sub_match) -> update_sub_match_map(sub_match, tuple)
          _ -> {key_bitsize, %{bit_mac => vendor}}
        end)
    end)
  end

  def update_sub_match_map({key_bitsize, map}, {bit_mac, vendor})
      when bit_size(bit_mac) == key_bitsize do
    {key_bitsize, map |> Map.put(bit_mac, vendor)}
  end

  def update_sub_match_map({key_bitsize, _} = given, {bit_mac, _vendor})
      when bit_size(bit_mac) < key_bitsize do
    given
  end

  def update_sub_match_map(given, _), do: given

  def parse_wireshark_file(text) do
    text
    |> String.split("\n", trim: true)
    |> Enum.map(fn line -> String.trim(line) end)
    |> Enum.filter(fn line -> not String.starts_with?(line, "#") end)
    |> Enum.map(&parse_wireshark_line/1)
    |> Enum.filter(fn x -> not is_nil(x) end)
  end

  def parse_wireshark_line(line, min_bit_size \\ 24) do
    case String.split(line, ~r/\s+/) do
      [mac, _name | details] -> {mac |> to_bitstring, Enum.join(details, " ")}
      _ -> nil
    end
    |> case do
      {<<_::bits>> = bit_mac, _} = result
      when bit_size(bit_mac) >= min_bit_size ->
        result

      _ ->
        nil
    end
  end

  def to_bitstring(mac) do
    filtered_mac = mac |> String.replace(~r([^a-fA-F\d/]), "") |> String.upcase()

    case Regex.run(~r[(\w*)/?(\w*)], filtered_mac) do
      [_, hex_mac, ""] -> hex_to_bitstring(hex_mac)
      [_, hex_mac, mask] -> hex_to_bitstring(hex_mac, mask |> String.to_integer())
    end
  end

  def hex_to_bitstring(hex, take \\ nil) do
    take = take || String.length(hex) * 4

    case Base.decode16(hex) do
      {:ok, <<val::bits-size(take), _::bits>>} -> val
      _ -> nil
    end
  end
end
