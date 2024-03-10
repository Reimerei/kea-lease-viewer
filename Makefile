KEA_HOST=10.23.0.1
export KEA_SOCKET_PATH=/tmp/kea/dhcp4.sock

run:
	nix develop

deps-update:
	mix deps.update --all
	mix2nix > deps.nix

update-mac-vendors:
	wget wget https://www.wireshark.org/download/automated/data/manuf -O priv/mac_vendors.txt

mount_socket:
	rm -f ${KEA_SOCKET_PATH}
	ssh -L ${KEA_SOCKET_PATH}:/run/kea-dhcp4.sock ${KEA_HOST} 
