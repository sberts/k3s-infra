variable "name" {
  type    = string
  default = "k3s"
}

variable "network" {
  type    = string
  default = "delta"
}

variable "key_pair" {
  type    = string
  default = "key21"
}

variable "master_count" {
  type = number
  default = 3
}
