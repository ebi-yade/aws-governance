locals {
  managed_policy = {
    base_arn = "arn:aws:iam::aws:policy/"

    name = {
      admin     = "AdministratorAccess"
      read_only = "ReadOnlyAccess"
    }
  }
}
