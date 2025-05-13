output "public_vm_name" {
  description = "Name of the public VM instance"
  value       = google_compute_instance.public_vm.name
}

output "public_vm_external_ip" {
  description = "External IP address of the public VM instance"
  value       = google_compute_address.static_ip.address
}

output "public_vm_internal_ip" {
  description = "Internal IP address of the public VM instance"
  value       = google_compute_instance.public_vm.network_interface[0].network_ip
}

output "private_vm_names" {
  description = "Names of the private VM instances"
  value       = google_compute_instance.private_vm[*].name
}

output "private_vm_internal_ips" {
  description = "Internal IP addresses of the private VM instances"
  value       = google_compute_instance.private_vm[*].network_interface[0].network_ip
}

output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr" {
  description = "CIDR range of the subnet"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}
