provider "aws" {
  region = "us-west-2"
}

module "my_vpc" {
  source = "../modules/networking"

  vpc_cidr = "198.168.0.0/16"
  tenancy = "default"
  vpc_id = "${module.my_vpc.vpc_id}"
  subnet_cidr_1 = "198.168.1.0/24"
  subnet_cidr_2 = "198.168.2.0/24"
  private_subnet_cidr = "10.0.2.0/24"
}