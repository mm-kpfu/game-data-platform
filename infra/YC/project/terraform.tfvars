kafka_topics = [
  {
    topic_name = "game-data"
  }
]

kafka_users = [
  {
    name        = "mm"
    password    = "mm"
    permissions = [
      {
        role   = "ACCESS_ROLE_ADMIN"
        topic_name = "*"
      }
    ]
  }
]

folder_id = "b1gjkor5me1p843e7gkt"
node_service_account_id = "aje7j6umm1eq0k3f0j06"
master_service_account_id = "aje7j6umm1eq0k3f0j06"
