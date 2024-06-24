FROM flink:1.18

RUN apt-get update -y && \
    apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev libffi-dev liblzma-dev && \
    apt-get install openjdk-8-jdk-headless -qq > /dev/null && \
    wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz && \
    tar -xvf Python-3.10.0.tgz && \
    cd Python-3.10.0 && \
    ./configure --without-tests --enable-shared && \
    make -j6 && \
    make install && \
    ldconfig /usr/local/lib && \
    cd .. && rm -f Python-3.10.0.tgz && rm -rf Python-3.10.0 && \
    ln -s /usr/local/bin/python3 /usr/local/bin/python && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-kafka/3.2.0-1.18/flink-sql-connector-kafka-3.2.0-1.18.jar && \
    wget https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.5.0/kafka-clients-3.5.0.jar
# Retrieve Yandex cert for kafka
ARG KAFKA_SSL_CAFILE=/usr/local/share/ca-certificates/Yandex/YandexInternalRootCA.crt
ENV KAFKA_SSL_CAFILE=${KAFKA_SSL_CAFILE}

RUN mkdir -p /usr/local/share/ca-certificates/Yandex/ && \
    wget "https://storage.yandexcloud.net/cloud-certs/CA.pem" \
     --output-document ${KAFKA_SSL_CAFILE} && \
    chmod 0655 ${KAFKA_SSL_CAFILE}

RUN pip3 install kafka-python clickhouse-driver apache-flink==1.18.0

RUN keytool -importcert -alias YandexCA --file ${KAFKA_SSL_CAFILE} --keystore /opt/flink/ssl --storepass gdpgdp --noprompt
RUN chmod 777 ssl

RUN keytool -importkeystore \
 -srckeystore /opt/flink/ssl \
 -srcstoretype PKCS12 \
 -srcstorepass gdpgdp \
 -destkeystore /opt/flink/ssl.jks \
 -deststoretype jks \
 -deststorepass gdpgdp

RUN openssl x509 -in /usr/local/share/ca-certificates/Yandex/YandexInternalRootCA.crt -out /usr/local/share/ca-certificates/Yandex/YandexInternalRootCA.pem -outform PEM

