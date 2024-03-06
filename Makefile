KEA_HOST=10.23.0.1
export KEA_SOCKET_PATH=/tmp/kea/dhcp4.sock

console:
	nix develop

mount_socket:
	rm -f ${KEA_SOCKET_PATH}
	ssh -L ${KEA_SOCKET_PATH}:/run/kea-dhcp4.sock ${KEA_HOST} 

deps-update:
	mix deps.update --all
	mix2nix > deps.nix
