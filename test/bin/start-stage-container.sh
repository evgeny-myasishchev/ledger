docker run -it --rm \
    --log-driver syslog --log-opt syslog-address=udp://localhost:15140 --log-opt syslog-format=rfc3164 \
    --log-opt tag="passenger.json.staging.ledger.web" \
    --env-file app.env --net ledger-stage \
    --name ledger-stage-web -p 3000:3000 evgenymyasishchev/ledger
