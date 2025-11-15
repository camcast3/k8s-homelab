all:
  children:
    talos_control_plane:
      hosts:
%{ for node in control_nodes ~}
        ${node.name}:
          ansible_host: ${node.ip}
          talos_static_ip: ${node.ip}
          mac_address: ${node.mac}
%{ endfor ~}
    talos_workers:
      hosts:
%{ for node in worker_nodes ~}
        ${node.name}:
          ansible_host: ${node.ip}
          talos_static_ip: ${node.ip}
          mac_address: ${node.mac}
%{ endfor ~}
  vars:
    ansible_connection: local
    cluster_name: ${cluster_name}
    cluster_vip: ${cluster_vip}
    gateway: ${gateway}
    nameservers:
%{ for ns in nameservers ~}
      - ${ns}
%{ endfor ~}
    talos_version: v1.11.5
