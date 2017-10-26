variable "access_key" {
  default = ""
}
variable "secret_key" {
  default = ""
}

variable "gitlab-pem-path" {
  default = ""
  description = "pem file for aws"
}


provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "eu-central-1"
}


resource "aws_iam_instance_profile" "config_template_role" {
  name = "config_template_role"
}



resource "aws_instance" "gitlab-runner" {
  ami           = "ami-060cde69"
  instance_type = "t2.medium"
  iam_instance_profile = "${aws_iam_instance_profile.config_template_role.id}"
  root_block_device {
    volume_size = 16
  }
  provisioner "file" {
    source      = "stacks/gitlab-runner/gitlab-runner.sh"
    destination = "/tmp/script.sh"

    connection {
      user = "ubuntu"
      private_key = "${file("gitlab-pem-path")}"

    }
  }

  # tokens.txt should contain one registration token per line,
  # found in /settings/ci_cd under your projects
  provisioner "file" {
    source      =  "tokens.txt"
    destination = "/tmp/tokens"

    connection {
      user = "ubuntu"
      private_key = "${file("gitlab-pem-path")}"

    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cat /tmp/tokens",
      "sudo chmod +x /tmp/script.sh",
      "sudo /tmp/script.sh /tmp/tokens",
      "sudo rm /tmp/tokens",
    ]

    connection {
      user = "ubuntu"
      private_key = "${file("gitlab-pem-path")}"

    }
  }

  provisioner "file" {
    source = "secrets/finleap/inventory-checker-credentials"
    destination = "/home/ubuntu/credentials"

    connection {

      user = "ubuntu"
      private_key = "${file("gitlab-pem-path")}"

    }
  }

  provisioner "remote-exec" {
    when = "destroy"
    inline = ["sudo gitlab-runner unregister --all-runners"]

    connection {
      user = "ubuntu"
      private_key = "${file("gitlab-pem-path")}"
      host = "${aws_instance.gitlab-runner.public_ip}"

      }
  }

  tags {
    Name = "terraform-loves-gitlab"
  }
}


output "ip" {
    value = ""
    value = "${aws_instance.gitlab-runner.public_ip}"


  }
