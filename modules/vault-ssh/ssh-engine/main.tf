resource "vault_mount" "ssh" {
    count = "${var.enabled ? 1 : 0}"

    path = "${var.path}"
    type = "ssh"
    description = "SSH Key signer for ${var.description}"
}

resource "vault_generic_secret" "ssh_ca" {
    count = "${var.enabled ? 1 : 0}"
    depends_on = ["vault_mount.ssh"]

    lifecycle {
        # This is a hack. Reconfiguring this will overwrite the CA
        ignore_changes = ["*"]
    }

    path = "${var.path}/config/ca"

    data_json = <<EOF
{
    "generate_signing_key": true
}
EOF
}

data "template_file" "role" {
    template = "${file("${path.module}/templates/role.json")}"

    vars {
        ssh_user = "${var.ssh_user}"
        ttl = "${var.ttl}"
        max_ttl = "${var.ttl}"
    }
}

resource "vault_generic_secret" "ssh" {
    count = "${var.enabled ? 1 : 0}"
    depends_on = ["vault_mount.ssh"]

    path = "${var.path}/roles/${var.role_name}"
    data_json = "${data.template_file.role.rendered}"
}
