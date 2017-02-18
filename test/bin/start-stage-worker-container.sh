docker run -it --rm \
    --log-driver syslog --log-opt syslog-address=udp://localhost:15140 --log-opt syslog-format=rfc5424 \
    --log-opt tag="passenger.json-message.staging.ledger.worker" \
    --env-file app.env --net ledger-stage \
    --name ledger-stage-worker evgenymyasishchev/ledger backburner
