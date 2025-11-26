all:
  children:
    talos_control_plane:
      hosts:
%{ for i, node in control_nodes ~}
        ${node.name}:
          ansible_host: ${node.actual_ip != "" ? node.actual_ip : node.expected_ip}
          vmid: ${node.vmid}
          expected_ip: ${node.expected_ip}
          actual_ip: ${node.actual_ip}
          mac_address: ${node.mac}
          node_type: control
%{ endfor ~}
    talos_workers:
      hosts:
%{ for i, node in worker_nodes ~}
        ${node.name}:
          ansible_host: ${node.actual_ip != "" ? node.actual_ip : node.expected_ip}
          vmid: ${node.vmid}
          expected_ip: ${node.expected_ip}
          actual_ip: ${node.actual_ip}
          mac_address: ${node.mac}
          node_type: worker
%{ endfor ~}
  vars:
    ansible_connection: local
    ansible_python_interpreter: /usr/bin/python3
    cluster_name: ${cluster_name}
    cluster_vip: ${cluster_vip}
    gateway: ${gateway}
    nameservers:
%{ for ns in nameservers ~}
      - ${ns}
%{ endfor ~}
    talos_version: v1.11.5
    kubernetes_version: ${kubernetes_version}