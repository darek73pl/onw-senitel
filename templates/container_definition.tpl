[
  {
    "name": "${name}",
    "image": "${image}",
    "cpu": ${cpu},
    "memory": ${memory},
    "memoryReservation": ${memory},
    "essential": true,
    "portMappings" : [
        {
          "containerPort" : 80
        }
      ]
  }
]