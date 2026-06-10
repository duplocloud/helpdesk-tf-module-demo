resource "random_password" "main" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

moved {
  from = time_sleep.wait_20s
  to   = time_sleep.wait
}

resource "time_sleep" "wait" {
  create_duration = var.sleep_duration
}
