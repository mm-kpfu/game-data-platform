output "users" {
  value = [for u in yandex_mdb_kafka_user.kafka_user: {
    login = u.name
    password = u.password
  }]
}

output "topics" {
  value = [for t in yandex_mdb_kafka_topic.events: t.name]
}

output "hosts" {
  value = {
    for h in yandex_mdb_kafka_cluster.gaming-data-cluster.host: h.zone_id => h.name... if h.role == "KAFKA"
  }
}
