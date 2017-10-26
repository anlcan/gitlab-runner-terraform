variable "access_key" {
  default = ""
}
variable "secret_key" {
  default = ""
}


provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "eu-central-1"
}


# Create an IAM role for the Web Servers.
resource "aws_iam_role" "config_templates_bucket_role" {
  name = "config_templates_bucket_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "config_template_role" {
  name = "config_template_role"
  role = "${aws_iam_role.config_templates_bucket_role.name}"
}

resource "aws_iam_role_policy" "config_template_role_policy" {
  name = "config_template_role_policy"
  role = "${aws_iam_role.config_templates_bucket_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [

    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:HeadObject",
        "s3:DeleteObject"
      ],
      "Resource": [
      "arn:aws:s3:::configuration-templates/*",
      "arn:aws:s3:::configuration-client-secrets/*"
      ]
    }
  ]
}
EOF
}

// bucket is created separetly
//resource "aws_s3_bucket" "config_template_bucket" {
//  bucket = "config_template_bucket"
//  acl = "private"
//  versioning {
//    enabled = true
//  }
//  tags {
//    Name = "bucket-name"
//  }
//}



resource "aws_instance" "gitlab-runner" {
  ami           = "ami-060cde69"
  instance_type = "t2.medium"
  key_name      = "finleap-dev"
  iam_instance_profile = "${aws_iam_instance_profile.config_template_role.id}"
  root_block_device {
    volume_size = 16
  }
  provisioner "file" {
    source      = "stacks/gitlab-runner/gitlab-runner.sh"
    destination = "/tmp/script.sh"

    connection {
      user = "ubuntu"
      private_key = "${file("secrets/finleap/finleap-dev.pem")}"

    }
  }

  provisioner "file" {
    source      = "stacks/gitlab-runner/build-script.sh"
    destination = "/tmp/build-script.sh"

    connection {
      user = "ubuntu"
      private_key = "${file("secrets/finleap/finleap-dev.pem")}"

    }
  }

  provisioner "file" {
    source      =  "secrets/finleap/tokens.txt"
    destination = "/tmp/tokens"

    connection {
      user = "ubuntu"
      private_key = "${file("secrets/finleap/finleap-dev.pem")}"

    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cat /tmp/tokens",
      "sudo chmod +x /tmp/script.sh",
      "sudo /tmp/script.sh /tmp/tokens",
      "sudo rm /tmp/tokens",
      "sudo cp /tmp/build-script.sh  /home/gitlab-runner/build-script.sh",
      "sudo chown gitlab-runner /home/gitlab-runner/build-script.sh"
    ]

    connection {
      user = "ubuntu"
      private_key = "${file("secrets/finleap/finleap-dev.pem")}"

    }
  }

  provisioner "file" {
    source = "secrets/finleap/inventory-checker-credentials"
    destination = "/home/ubuntu/credentials"

    connection {

      user = "ubuntu"
      private_key = "${file("secrets/finleap/finleap-dev.pem")}"

    }
  }

  # find . -maxdepth 3 -name '*-ssh.pem' | zip -j secrets/finleap/ssh_keys -@
  provisioner "local-exec" {
    command = "find . -maxdepth 3 -name '*-ssh.pem' | zip -j secrets/finleap/ssh_keys.zip -@"
  }

  provisioner "file" {
    source = "secrets/finleap/ssh_keys.zip"
    destination = "/home/ubuntu/ssh_keys.zip"

    connection {
      user = "ubuntu"
      private_key = "${file("secrets/finleap/finleap-dev.pem")}"

    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /home/gitlab-runner/.aws/",
      "sudo chown gitlab-runner /home/gitlab-runner/.aws/",

      "sudo mkdir /home/gitlab-runner/.ssh/",
      "sudo chown gitlab-runner /home/gitlab-runner/.ssh/",

      "sudo mv /home/ubuntu/credentials /home/gitlab-runner/.aws/credentials",
      "sudo chown gitlab-runner  /home/gitlab-runner/.aws/credentials",
      "sudo mv /home/ubuntu/ssh_keys.zip /home/gitlab-runner/.ssh/ssh_keys.zip",

      "sudo unzip /home/gitlab-runner/.ssh/ssh_keys.zip -d /home/gitlab-runner/.ssh/",
      "sudo chown gitlab-runner  /home/gitlab-runner/.ssh/*",
      "sudo chmod 400 /home/gitlab-runner/.ssh/*"
    ]

    connection {
      user = "ubuntu"
      private_key = "${file("secrets/finleap/finleap-dev.pem")}"

    }
  }

  provisioner "remote-exec" {
    when = "destroy"
    inline = ["sudo gitlab-runner unregister --all-runners"]

    connection {
      user = "ubuntu"
      private_key = "${file("secrets/finleap/finleap-dev.pem")}"
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
