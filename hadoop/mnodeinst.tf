/* set up a Hadoop cluster node */
resource "aws_instance" "mnode" {

  /* set the initial key for the instance */
  key_name = "${var.keypair}"

  /* select the appropriate AMI */
  ami = "${lookup(var.ami, var.region.primary)}"
  instance_type = "t2.medium"

  /* delete the volume on termination, make it big enough for Hadoop */
  root_block_device {
    delete_on_termination = true
    volume_size = 40
  }

  /* provide S3 access to the system */
  iam_instance_profile = "S3FullAccess"

  /* add to the security group */
  vpc_security_group_ids = ["${aws_security_group.sg_cluster_access.id}", "${aws_security_group.sg_clus_clus_access.id}"]

  tags {
    Name = "${lookup(var.master_nodes, count.index)}"
    Platform = "${var.ami.platform}"
    Tier = "cluster"
  }

  # cluster size
  count = "${var.count.mnodes}"

  /* copy up and execute the user data script */
  provisioner "file" {
    source = "scripts/mnode_bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
    connection {
      type = "ssh"
      user = "centos"
      key_file = "${var.keyfile}"
    }
  }
  provisioner "remote-exec" {
    inline = [
    "chmod +x /tmp/bootstrap.sh",
    "sudo /tmp/bootstrap.sh"
    ]
    connection {
      type = "ssh"
      user = "centos"
      key_file = "${var.keyfile}"
    }
  }
}

/* output the instance address */
output "mnode_private_dns" {
  value = "${join(",", aws_instance.mnode.*.private_dns)}"
}