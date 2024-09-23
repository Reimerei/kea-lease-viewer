KEA_HOST=router.lif.lol
export KEA_SOCKET_PATH=/tmp/kea/dhcp4.sock
export ADMIN_SUBNETS=127.0.0.1/24, 10.5.0.0/16

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
