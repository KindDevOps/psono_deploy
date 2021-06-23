#!/bin/bash

set -e
INSTALL_DIR='/opt'
export INSTALL_DIR
cd $INSTALL_DIR
export PSONO_DOCKER_PREFIX='psono'

ask_parameters() {

  export PSONO_PROTOCOL="http://"
  export PSONO_VERSION=EE
  export PSONO_EXTERNAL_PORT=80
  export PSONO_EXTERNAL_PORT_SECURE=443
  export PSONO_POSTGRES_PORT=5432
  export PSONO_POSTGRES_PASSWORD='WPBqQpvZEGpDrA3E'
  export PSONO_USERDOMAIN=localhost
  export PSONO_WEBDOMAIN='psono.local'
  export PSONO_POSTGRES_USER=postgres
  export PSONO_POSTGRES_DB=postgres
  export PSONO_POSTGRES_HOST=$PSONO_DOCKER_PREFIX-psono-postgres
  export PSONO_INSTALL_ACME=0

  if [ -f "$INSTALL_DIR/$PSONO_DOCKER_PREFIX/.psonoenv" ]; then
    set -o allexport
    source $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX/.psonoenv
    set +o allexport
  fi

  echo "What version do you want to install? (Usually EE. Potential other choices are CE or DEV)"
  read -p "PSONO_VERSION [default: $PSONO_VERSION]: " PSONO_VERSION_NEW
  if [ "$PSONO_VERSION_NEW" != "" ]; then
    export PSONO_VERSION=$PSONO_VERSION_NEW
  fi

  if [[ ! $PSONO_VERSION =~ ^(DEV|EE|CE)$ ]]; then
    echo "unknown PSONO_VERSION: $PSONO_VERSION" >&2
    exit 1
  fi

  echo "What insecure external port do you want to use? (Usually port 80. Redirects http to https traffic.)"
  read -p "PSONO_EXTERNAL_PORT [default: $PSONO_EXTERNAL_PORT]: " PSONO_EXTERNAL_PORT_NEW
  if [ "$PSONO_EXTERNAL_PORT_NEW" != "" ]; then
    export PSONO_EXTERNAL_PORT=$PSONO_EXTERNAL_PORT_NEW
  fi

  echo "What secure external port do you want to use? (Usually port 443. The actual port serving all the traffic with https.)"
  read -p "PSONO_EXTERNAL_PORT_SECURE [default: $PSONO_EXTERNAL_PORT_SECURE]: " PSONO_EXTERNAL_PORT_SECURE_NEW
  if [ "$PSONO_EXTERNAL_PORT_SECURE_NEW" != "" ]; then
    export PSONO_EXTERNAL_PORT_SECURE=$PSONO_EXTERNAL_PORT_SECURE_NEW
  fi

  echo "What port do you want to use for the postgres? (Usually port 5432. Leave it to 5432 to use the dockered postgres)"
  read -p "PSONO_POSTGRES_PORT [default: $PSONO_POSTGRES_PORT]: " PSONO_POSTGRES_PORT_NEW
  if [ "$PSONO_POSTGRES_PORT_NEW" != "" ]; then
    export PSONO_POSTGRES_PORT=$PSONO_POSTGRES_PORT_NEW
  fi

  echo "What is the postgres DB user you want to use (Defaults to postgres)?"
  read -p "PSONO_POSTGRES_USER [default: $PSONO_POSTGRES_USER]: " PSONO_POSTGRES_USER_NEW
  if [ "$PSONO_POSTGRES_USER_NEW" != "" ]; then
    export PSONO_POSTGRES_USER=$PSONO_POSTGRES_USER_NEW
  fi

  echo "What is the postgres DB you want to use (Defaults to postgres)?"
  read -p "PSONO_POSTGRES_DB [default: $PSONO_POSTGRES_DB]: " PSONO_POSTGRES_DB_NEW
  if [ "$PSONO_POSTGRES_DB_NEW" != "" ]; then
    export PSONO_POSTGRES_DB=$PSONO_POSTGRES_DB_NEW
  fi

  echo "What is the postgres DB address (Leave it as 'postgres' if you wannt to use the dockered postgres DB)?"
  read -p "PSONO_POSTGRES_HOST [default: $PSONO_POSTGRES_HOST]: " PSONO_POSTGRES_HOST_NEW
  if [ "$PSONO_POSTGRES_HOST_NEW" != "" ]; then
    export PSONO_POSTGRES_HOST=$PSONO_POSTGRES_HOST_NEW
  fi

  if [ "$PSONO_POSTGRES_PASSWORD" == "PSONO_IS_THE_BEST_OPEN_SOURCE_PASSWORD_MANAGER" ]; then
    export PSONO_POSTGRES_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  fi
  echo "What password do you want to use for postgres?"
  read -p "PSONO_POSTGRES_PASSWORD [default: $PSONO_POSTGRES_PASSWORD]: " PSONO_POSTGRES_PASSWORD_NEW
  if [ "$PSONO_POSTGRES_PASSWORD_NEW" != "" ]; then
    export PSONO_POSTGRES_PASSWORD=$PSONO_POSTGRES_PASSWORD_NEW
  fi

  echo "What is the 'domain' that you will use to access your installation?"
  read -p "PSONO_WEBDOMAIN [default: $PSONO_WEBDOMAIN]: " PSONO_WEBDOMAIN_NEW
  if [ "$PSONO_WEBDOMAIN_NEW" != "" ]; then
    export PSONO_WEBDOMAIN=$PSONO_WEBDOMAIN_NEW
  fi

  echo "What is the 'domain' that your usernames should end in?"
  read -p "PSONO_USERDOMAIN [default: $PSONO_USERDOMAIN]: " PSONO_USERDOMAIN_NEW
  if [ "$PSONO_USERDOMAIN_NEW" != "" ]; then
    export PSONO_USERDOMAIN=$PSONO_USERDOMAIN_NEW
  fi

  echo "Install ACME script? (This script requires that the server is publicly accessible under $PSONO_WEBDOMAIN_NEW"
  read -p "PSONO_INSTALL_ACME [default: $PSONO_INSTALL_ACME]: " PSONO_INSTALL_ACME_NEW
  if [ "$PSONO_INSTALL_ACME_NEW" != "" ]; then
    export PSONO_INSTALL_ACME=$PSONO_INSTALL_ACME_NEW
  fi

  rm -Rf $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX/.psonoenv

  cat <<EOF > $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX/.psonoenv
PSONO_VERSION='$PSONO_VERSION'
PSONO_EXTERNAL_PORT='$PSONO_EXTERNAL_PORT'
PSONO_EXTERNAL_PORT_SECURE='$PSONO_EXTERNAL_PORT_SECURE'
PSONO_POSTGRES_PORT='$PSONO_POSTGRES_PORT'
PSONO_POSTGRES_PASSWORD='$'PSONO_POSTGRES_PASSWORD'
PSONO_USERDOMAIN='$'PSONO_USERDOMAIN'
PSONO_WEBDOMAIN='$PSONO_WEBDOMAIN'
PSONO_POSTGRES_USER='$PSONO_POSTGRES_USER'
PSONO_POSTGRES_DB='$PSONO_POSTGRES_DB'
PSONO_POSTGRES_HOST='$PSONO_POSTGRES_HOST'
EOF

  mkdir -p $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX || true
  cp $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX/.psonoenv $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX/.env
}


install_acme() {
    if [ "$PSONO_INSTALL_ACME" == "1" ]; then
        echo "Install acme.sh"

        mkdir -p $INSTALL_DIR/psono/html
        curl https://get.acme.sh | sh

        $INSTALL_DIR/.acme.sh/acme.sh --issue -d $PSONO_WEBDOMAIN -w $INSTALL_DIR/psono/html

        $INSTALL_DIR/.acme.sh/acme.sh --install-cert -d $PSONO_WEBDOMAIN \
          --key-file       $INSTALL_DIR/psono/certificates/private.key  \
          --fullchain-file $INSTALL_DIR/psono/certificates/public.crt \
          --reloadcmd     "cd $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX/ && docker-compose restart proxy"

        if ! crontab -l | grep "$INSTALL_DIR/.acme.sh/acme.sh --install-cert"; then
            crontab -l | {
              cat
              echo "0 */12 * * * $INSTALL_DIR/.acme.sh/acme.sh --install-cert -d $PSONO_WEBDOMAIN --key-file $INSTALL_DIR/psono/certificates/private.key --fullchain-file $INSTALL_DIR/psono/certificates/public.crt --reloadcmd \"cd $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX/ && docker-compose restart proxy\" > /dev/null"
            } | crontab -
        fi

        echo "Install acme.sh .. finsihed"
    fi
}


install_base_dependencies () {
    echo "Install dependencies (curl and lsof)..."

    set +e
    apt-get update
    for dep in curl lsof
    do 

      which $dep
      if [ $? -eq 0 ]
      then
        echo "$dep already installed"
      else
        apt-get install -y $dep
      fi
    done
    set -e
    echo "Install curl and lsof ... finished"
}


install_git () {
    echo "Install git"

    apt-get update &> /dev/null
    apt-get install -y git &> /dev/null

    echo "Install git ... finished"
}


install_docker_if_not_exists () {
    echo "Install docker if it is not already installed"

    set +e
    which docker

    if [ $? -eq 0 ]
    then
        set -e
        docker --version | grep "Docker version"
        if [ $? -eq 0 ]
        then
            echo "docker exists"
        else
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh
            rm get-docker.sh
        fi
    else
        set -e
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
    fi
    echo "Install docker if it is not already installed ... finished"
}


install_docker_compose_if_not_exists () {
    echo "Install docker compose if it is not already installed"

    set +e
    which docker-compose

    if [ $? -eq 0 ]
    then
        docker-compose --version | grep "docker-compose version"
        if [ $? -eq 0 ]
        then
            echo "docker-compose exists"
        else
            curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
        fi
    else
        curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi

    set -e

    echo "Install docker compose if it is not already installed ... finished"
}

craft_docker_compose_file () {
    echo "Crafting docker compose file"

    if [ "$PSONO_VERSION" == "EE" ]; then
      cat <<EOF > $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX/docker-compose.yml
version: "2"
services:
  proxy:
    container_name: '${PSONO_DOCKER_PREFIX}-psono-proxy'
    restart: "always"
    image: "nginx:alpine"
    ports:
      - "${PSONO_EXTERNAL_PORT}:80"
      - "${PSONO_EXTERNAL_PORT_SECURE}:443"
    depends_on:
      - psono-server
      - psono-fileserver
      - psono-client
    links:
      - psono-server:${PSONO_DOCKER_PREFIX}-psono-server
      - psono-fileserver:${PSONO_DOCKER_PREFIX}-psono-fileserver
      - psono-client:${PSONO_DOCKER_PREFIX}-psono-server
    volumes:
      - $INSTALL_DIR/psono/html:/var/www/html
      - $INSTALL_DIR/psono/certificates/dhparam.pem:/etc/ssl/dhparam.pem
      - $INSTALL_DIR/psono/certificates/private.key:/etc/ssl/private.key
      - $INSTALL_DIR/psono/certificates/public.crt:/etc/ssl/public.crt
      - $INSTALL_DIR/psono/config/psono_proxy_nginx.conf:/etc/nginx/nginx.conf

  postgres:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-postgres
    restart: "always"
    image: "psono/psono-postgres:latest"
    environment:
      POSTGRES_USER: "${PSONO_POSTGRES_USER}"
      POSTGRES_PASSWORD: "${PSONO_POSTGRES_PASSWORD}"
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    volumes:
      - $INSTALL_DIR/psono/data/postgresql:/var/lib/postgresql/data

  psono-server:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-server
    restart: "always"
    image: "psono/psono-server-enterprise:latest"
    depends_on:
      - postgres
    links:
      - postgres:${PSONO_DOCKER_PREFIX}-psono-postgres
    command: sh -c "sleep 10 && python3 psono/manage.py migrate && python3 psono/manage.py createuser admin@${PSONO_USERDOMAIN} admin admin@example.com && python3 psono/manage.py promoteuser admin@${PSONO_USERDOMAIN} superuser && python3 psono/manage.py createuser demo1@${PSONO_USERDOMAIN} demo1 demo1@example.com && python3 psono/manage.py createuser demo2@${PSONO_USERDOMAIN} demo2 demo2@example.com && /bin/sh /root/configs/docker/cmd.sh"
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    volumes:
      - $INSTALL_DIR/psono/config/settings.yaml:/root/.psono_server/settings.yaml

  psono-fileserver:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-fileserver
    restart: "always"
    image: "psono/psono-fileserver:latest"
    depends_on:
      - psono-server
    links:
      - psono-server:${PSONO_DOCKER_PREFIX}-psono-server
    command: sh -c "sleep 10 && /bin/sh /root/configs/docker/cmd.sh"
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    volumes:
      - $INSTALL_DIR/psono/data/shard:/opt/psono-shard
      - $INSTALL_DIR/psono/config/settings-fileserver.yaml:$INSTALL_DIR/.psono_fileserver/settings.yaml

  psono-client:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-client
    restart: "always"
    image: "psono/psono-client:latest"
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    volumes:
      - $INSTALL_DIR/psono/config/config.json:/usr/share/nginx/html/config.json

  psono-admin-client:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-admin-client
    restart: "always"
    image: "psono/psono-admin-client:latest"
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    volumes:
      - $INSTALL_DIR/psono/config/config.json:/usr/share/nginx/html/portal/config.json

  psono-watchtower:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-watchtower
    restart: "always"
    image: "containrrr/watchtower"
    command: --label-enable --cleanup --interval 3600
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock

EOF
    elif [ "$PSONO_VERSION" == "CE" ]; then
      cat <<EOF > $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX/docker-compose.yml
version: "2"
services:
  proxy:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-proxy
    restart: "always"
    image: "nginx:alpine"
    ports:
      - "${PSONO_EXTERNAL_PORT}:80"
      - "${PSONO_EXTERNAL_PORT_SECURE}:443"
    depends_on:
      - psono-server
      - psono-fileserver
      - psono-client
    links:
      - psono-server:${PSONO_DOCKER_PREFIX}-psono-server
      - psono-fileserver:${PSONO_DOCKER_PREFIX}-psono-fileserver
      - psono-client:${PSONO_DOCKER_PREFIX}-psono-server
    volumes:
      - $INSTALL_DIR/psono/html:/var/www/html
      - $INSTALL_DIR/psono/certificates/dhparam.pem:/etc/ssl/dhparam.pem
      - $INSTALL_DIR/psono/certificates/private.key:/etc/ssl/private.key
      - $INSTALL_DIR/psono/certificates/public.crt:/etc/ssl/public.crt
      - $INSTALL_DIR/psono/config/psono_proxy_nginx.conf:/etc/nginx/nginx.conf

  postgres:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-postgres
    restart: "always"
    image: "psono/psono-postgres:latest"
    environment:
      POSTGRES_USER: "${PSONO_POSTGRES_USER}"
      POSTGRES_PASSWORD: "${PSONO_POSTGRES_PASSWORD}"
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    volumes:
      - $INSTALL_DIR/psono/data/postgresql:/var/lib/postgresql/data

  psono-server:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-server
    restart: "always"
    image: "psono/psono-server:latest"
    depends_on:
      - postgres
    links:
      - postgres:${PSONO_DOCKER_PREFIX}-psono-postgres
    command: sh -c "sleep 10 && python3 psono/manage.py migrate && python3 psono/manage.py createuser admin@${PSONO_USERDOMAIN} admin admin@example.com && python3 psono/manage.py promoteuser admin@${PSONO_USERDOMAIN} superuser && python3 psono/manage.py createuser demo1@${PSONO_USERDOMAIN} demo1 demo1@example.com && python3 psono/manage.py createuser demo2@${PSONO_USERDOMAIN} demo2 demo2@example.com && /bin/sh /root/configs/docker/cmd.sh"
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    volumes:
      - $INSTALL_DIR/psono/config/settings.yaml:/root/.psono_server/settings.yaml

  psono-fileserver:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-fileserver
    restart: "always"
    image: "psono/psono-fileserver:latest"
    depends_on:
      - psono-server
    links:
      - psono-server:${PSONO_DOCKER_PREFIX}-psono-server
    command: sh -c "sleep 10 && /bin/sh /root/configs/docker/cmd.sh"
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    volumes:
      - $INSTALL_DIR/psono/data/shard:/opt/psono-shard
      - $INSTALL_DIR/psono/config/settings-fileserver.yaml:$INSTALL_DIR/.psono_fileserver/settings.yaml

  psono-client:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-client
    restart: "always"
    image: "psono/psono-client:latest"
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    volumes:
      - $INSTALL_DIR/psono/config/config.json:/usr/share/nginx/html/config.json

  psono-admin-client:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-admin-client
    restart: "always"
    image: "psono/psono-admin-client:latest"
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    volumes:
      - $INSTALL_DIR/psono/config/config.json:/usr/share/nginx/html/portal/config.json

  psono-watchtower:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-watchtower
    restart: "always"
    image: "containrrr/watchtower"
    command: --label-enable --cleanup --interval 3600
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock

EOF
    elif [ "$PSONO_VERSION" == "DEV" ]; then
      cat <<EOF > $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX/docker-compose.yml
version: "2"
services:
  proxy:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-proxy
    restart: "always"
    image: "nginx:alpine"
    ports:
      - "${PSONO_EXTERNAL_PORT}:80"
      - "${PSONO_EXTERNAL_PORT_SECURE}:443"
    depends_on:
      - psono-server
      - psono-fileserver
      - psono-client
    links:
      - psono-server:${PSONO_DOCKER_PREFIX}-psono-server
      - psono-fileserver:${PSONO_DOCKER_PREFIX}-psono-fileserver
      - psono-client:${PSONO_DOCKER_PREFIX}-psono-server
    volumes:
      - $INSTALL_DIR/psono/certificates/dhparam.pem:/etc/ssl/dhparam.pem
      - $INSTALL_DIR/psono/certificates/private.key:/etc/ssl/private.key
      - $INSTALL_DIR/psono/certificates/public.crt:/etc/ssl/public.crt
      - $INSTALL_DIR/psono/config/psono_proxy_nginx.conf:/etc/nginx/nginx.conf

  postgres:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-postgres
    restart: "always"
    image: "psono/psono-postgres:latest"
    environment:
      POSTGRES_DB: "${PSONO_POSTGRES_DB}"
      POSTGRES_USER: "${PSONO_POSTGRES_USER}"
      POSTGRES_PASSWORD: "${PSONO_POSTGRES_PASSWORD}"
    volumes:
      - $INSTALL_DIR/psono/data/postgresql:/var/lib/postgresql/data

  psono-server:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-server
    restart: "always"
    image: "psono/psono-server:latest"
    depends_on:
      - postgres
    links:
      - postgres:${PSONO_DOCKER_PREFIX}-psono-postgres
      - mail:${PSONO_DOCKER_PREFIX}-psono-mail
    command: sh -c "sleep 10 && python3 psono/manage.py migrate && python3 psono/manage.py createuser admin@${PSONO_USERDOMAIN} admin admin@example.com && python3 psono/manage.py promoteuser admin@${PSONO_USERDOMAIN} superuser && python3 psono/manage.py createuser demo1@${PSONO_USERDOMAIN} demo1 demo1@example.com && python3 psono/manage.py createuser demo2@${PSONO_USERDOMAIN} demo2 demo2@example.com && /bin/sh /root/configs/docker/cmd.sh"
    volumes:
      - $INSTALL_DIR/psono/psono-server/password_manager_server/static/email:/var/www/html/static/email
      - $INSTALL_DIR/psono/psono-server:/root
      - $INSTALL_DIR/psono/config/settings.yaml:/root/.psono_server/settings.yaml

  psono-fileserver:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-fileserver
    restart: "always"
    image: "psono/psono-fileserver:latest"
    depends_on:
      - psono-server
    links:
      - psono-server:${PSONO_DOCKER_PREFIX}-psono-server
    command: sh -c "sleep 10 && /bin/sh /root/configs/docker/cmd.sh"
    volumes:
      - $INSTALL_DIR/psono/psono-fileserver:$INSTALL_DIR
      - $INSTALL_DIR/psono/data/shard:/opt/psono-shard
      - $INSTALL_DIR/psono/config/settings-fileserver.yaml:$INSTALL_DIR/.psono_fileserver/settings.yaml

  psono-client:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-client
    restart: "always"
    image: "psono/psono-client:latest"
    volumes:
      - $INSTALL_DIR/psono/psono-client/src/common/data:/usr/share/nginx/html
      - $INSTALL_DIR/psono/config/config.json:/usr/share/nginx/html/config.json

  psono-admin-client:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-admin-client
    restart: "always"
    image: "psono/psono-admin-client:latest"
    volumes:
      - $INSTALL_DIR/psono/config/config.json:/usr/share/nginx/html/portal/config.json

  mail:
    container_name: ${PSONO_DOCKER_PREFIX}-psono-mail
    restart: "always"
    image: "digiplant/fake-smtp"
    volumes:
      - $INSTALL_DIR/psono/data/mail:/var/mail

EOF
    fi
    echo "Crafting docker compose file ... finished"
}


stop_container_if_running () {
    echo "Stopping docker container"

    pushd $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX> /dev/null
    docker-compose stop
    popd> /dev/null
    echo "Stopping docker container ... finished"
}


test_if_ports_are_free () {
    echo "Test for port availability"

    if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null ; then
        echo "Port 80 is occupied" >&2
        exit 1
    fi

    if lsof -Pi :443 -sTCP:LISTEN -t >/dev/null ; then
        echo "Port 443 is occupied" >&2
        exit 1
    fi

    echo "Test for port availability ... finished"
}


create_dhparam_if_not_exists() {
    echo "Create DH params if they dont exists"
    mkdir -p $INSTALL_DIR/psono/certificates

    if [ ! -f "$INSTALL_DIR/psono/certificates/dhparam.pem" ]; then
        openssl dhparam -dsaparam -out $INSTALL_DIR/psono/certificates/dhparam.pem 2048
    fi
    echo "Create DH params if they dont exists ... finished"
}


create_openssl_conf () {
    echo "Create openssl config"
    mkdir -p $INSTALL_DIR/psono/certificates
    rm -Rf $INSTALL_DIR/psono/certificates/openssl.conf
    cat <<EOF > $INSTALL_DIR/psono/certificates/openssl.conf
[req]
default_bits       = 2048
default_keyfile    = $INSTALL_DIR/psono/certificates/private.key
distinguished_name = req_distinguished_name
req_extensions     = req_ext
x509_extensions    = v3_ca

[req_distinguished_name]
countryName                 = Country Name (2 letter code)
countryName_default         = US
stateOrProvinceName         = State or Province Name (full name)
stateOrProvinceName_default = New York
localityName                = Locality Name (eg, city)
localityName_default        = Rochester
organizationName            = Organization Name (eg, company)
organizationName_default    = Psono
organizationalUnitName      = organizationalunit
organizationalUnitName_default = Development
commonName                  = Common Name (e.g. server FQDN or YOUR name)
commonName_default          = ${PSONO_WEBDOMAIN}
commonName_max              = 64

[req_ext]
subjectAltName = @alt_names

[v3_ca]
subjectAltName = @alt_names

[alt_names]
DNS.1   = 8.8.8.8
DNS.2   = 8.8.4.4
EOF
    echo "Create openssl config ... finished"
}

create_self_signed_certificate_if_not_exists () {
    echo "Create self signed certificate if it does not exist"
    mkdir -p $INSTALL_DIR/psono/certificates
    if [ ! -f "$INSTALL_DIR/psono/certificates/private.key" ]; then
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $INSTALL_DIR/psono/certificates/private.key -out $INSTALL_DIR/psono/certificates/public.crt -config $INSTALL_DIR/psono/certificates/openssl.conf
    fi
    echo "Create self signed certificate if it does not exist ... finnished"
}

create_config_json () {
    echo "Create config.json"
    mkdir -p $INSTALL_DIR/psono/config
    cat <<EOF > $INSTALL_DIR/psono/config/config.json
{
  "backend_servers": [{
    "title": "Demo",
    "url": "PSONO_PROTOCOLPSONO_WEBDOMAIN/server",
    "domain": "PSONO_USERDOMAIN"
  }],
  "base_url": "PSONO_PROTOCOLPSONO_WEBDOMAIN/",
  "allow_custom_server": true
}
EOF
#    dns_ip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
#    if ifconfig | grep -q $dns_ip
#    then
#       public_url="htpp://$dns_ip:$PSONO_EXTERNAL_PORT";
#    else
#       public_url="$PSONO_PROTOCOL$PSONO_WEBDOMAIN";
#    fi
    sed -i'' -e "s,PSONO_PROTOCOL,$PSONO_PROTOCOL,g" $INSTALL_DIR/psono/config/config.json
    sed -i'' -e "s,PSONO_WEBDOMAIN,$PSONO_WEBDOMAIN,g" $INSTALL_DIR/psono/config/config.json
    sed -i'' -e "s,PSONO_USERDOMAIN,$PSONO_USERDOMAIN,g" $INSTALL_DIR/psono/config/config.json
    echo "Create config.json ... finished"
}

docker_compose_pull () {
    echo "Update docker images"

    pushd $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX> /dev/null
    docker-compose pull postgres
    docker-compose pull psono-server
    docker-compose pull psono-fileserver
    docker-compose pull psono-client
    docker-compose pull psono-admin-client

    if [ "$PSONO_VERSION" == "EE" ]; then

        docker-compose pull psono-watchtower

    elif [ "$PSONO_VERSION" == "CE" ]; then

        docker-compose pull psono-watchtower

    fi
    popd> /dev/null
    echo "Update docker images ... finished"
}

create_settings_server_yaml () {
    echo "Create settings.yml for the server"
    mkdir -p $INSTALL_DIR/psono/config
    cat <<EOF > $INSTALL_DIR/psono/config/settings.yaml

SECRET_KEY: 'SOME SUPER SECRET KEY THAT SHOULD BE RANDOM AND 32 OR MORE DIGITS LONG'
ACTIVATION_LINK_SECRET: 'SOME SUPER SECRET ACTIVATION LINK SECRET THAT SHOULD BE RANDOM AND 32 OR MORE DIGITS LONG'
DB_SECRET: 'SOME SUPER SECRET DB SECRET THAT SHOULD BE RANDOM AND 32 OR MORE DIGITS LONG'
EMAIL_SECRET_SALT: '$2b$12$XUG.sKxC2jmkUvWQjg53.e'
PRIVATE_KEY: '302650c3c82f7111c2e8ceb660d32173cdc8c3d7717f1d4f982aad5234648fcb'
PUBLIC_KEY: '02da2ad857321d701d754a7e60d0a147cdbc400ff4465e1f57bc2d9fbfeddf0b'

WEB_CLIENT_URL: 'http://example.com'

ALLOWED_HOSTS: ['*']
ALLOWED_DOMAINS: ['example.com']
HOST_URL: 'http://example.com/server'

# The email used to send emails, e.g. for activation
EMAIL_FROM: 'the-mail-for-for-example-useraccount-activations@test.com'
EMAIL_HOST: 'localhost'
EMAIL_HOST_USER: ''
EMAIL_HOST_PASSWORD : ''
EMAIL_PORT: 25
EMAIL_SUBJECT_PREFIX: ''
EMAIL_USE_TLS: False
EMAIL_USE_SSL: False
EMAIL_SSL_CERTFILE:
EMAIL_SSL_KEYFILE:
EMAIL_TIMEOUT:

EMAIL_BACKEND: 'django.core.mail.backends.smtp.EmailBackend'

MANAGEMENT_ENABLED: True

# Your Postgres Database credentials
DATABASES:
    default:
        'ENGINE': 'django.db.backends.postgresql_psycopg2'
        'NAME': 'YourPostgresDatabase'
        'USER': 'YourPostgresUser'
        'PASSWORD': 'YourPostgresPassword'
        'HOST': 'YourPostgresHost'
        'PORT': 'YourPostgresPort'

# Your path to your templates folder
TEMPLATES: [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': ['$INSTALL_DIR/psono/templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

EOF

    sed -i'' -e "s,WEB_CLIENT_URL: 'http://example.com',WEB_CLIENT_URL: '$PSONO_PROTOCOL$PSONO_WEBDOMAIN',g" $INSTALL_DIR/psono/config/settings.yaml
    sed -i'' -e "s,HOST_URL: 'http://example.com/server',HOST_URL: '$PSONO_PROTOCOL$PSONO_WEBDOMAIN/server',g" $INSTALL_DIR/psono/config/settings.yaml
    sed -i'' -e "s,ALLOWED_DOMAINS: \['example.com'],ALLOWED_DOMAINS: ['$PSONO_USERDOMAIN'],g" $INSTALL_DIR/psono/config/settings.yaml
    sed -i'' -e "s,EMAIL_HOST: 'localhost',EMAIL_HOST: 'mail',g" $INSTALL_DIR/psono/config/settings.yaml
    sed -i'' -e "s,YourPostgresDatabase,$PSONO_POSTGRES_DB,g" $INSTALL_DIR/psono/config/settings.yaml
    sed -i'' -e "s,YourPostgresUser,$PSONO_POSTGRES_USER,g" $INSTALL_DIR/psono/config/settings.yaml
    sed -i'' -e "s,YourPostgresPassword,$PSONO_POSTGRES_PASSWORD,g" $INSTALL_DIR/psono/config/settings.yaml
    sed -i'' -e "s,YourPostgresHost,$PSONO_POSTGRES_HOST,g" $INSTALL_DIR/psono/config/settings.yaml
    sed -i'' -e "s,YourPostgresPort,$PSONO_POSTGRES_PORT,g" $INSTALL_DIR/psono/config/settings.yaml

    pushd $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX> /dev/null
    docker-compose run psono-server /bin/sh -c "sleep 20 && python3 psono/manage.py migrate"
    if [ ! -f $INSTALL_DIR/.psono_server_keys ]; then
        docker-compose run psono-server /bin/sh -c "sleep 20 && python3 psono/manage.py generateserverkeys" > $INSTALL_DIR/.psono_server_keys
    fi
    popd> /dev/null

    sed -i '/^SECRET_KEY:/d' $INSTALL_DIR/psono/config/settings.yaml
    sed -i '/^ACTIVATION_LINK_SECRET:/d' $INSTALL_DIR/psono/config/settings.yaml
    sed -i '/^DB_SECRET:/d' $INSTALL_DIR/psono/config/settings.yaml
    sed -i '/^EMAIL_SECRET_SALT:/d' $INSTALL_DIR/psono/config/settings.yaml
    sed -i '/^PRIVATE_KEY:/d' $INSTALL_DIR/psono/config/settings.yaml
    sed -i '/^PUBLIC_KEY:/d' $INSTALL_DIR/psono/config/settings.yaml

    echo -e "$(cat $INSTALL_DIR/.psono_server_keys)\n$(cat $INSTALL_DIR/psono/config/settings.yaml)" > $INSTALL_DIR/psono/config/settings.yaml
    echo "Create settings.yml for the server ... finished"
}

create_settings_fileserver_yaml () {
    echo "Create settings.yml for the fileserver"
    mkdir -p $INSTALL_DIR/psono/config
    cat <<EOF > $INSTALL_DIR/psono/config/settings-fileserver.yaml

SERVER_URL: 'https://example.com/server'
ALLOWED_HOSTS: ['*']
HOST_URL: 'https://example.com/fileserver01'

EOF

    sed -i'' -e "s,SERVER_URL: 'https://example.com/server',SERVER_URL: 'http://psono-server',g" $INSTALL_DIR/psono/config/settings-fileserver.yaml
    sed -i'' -e "s,HOST_URL: 'https://example.com/fileserver01',HOST_URL: '$PSONO_PROTOCOL$PSONO_WEBDOMAIN/fileserver',g" $INSTALL_DIR/psono/config/settings-fileserver.yaml

    pushd $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX> /dev/null
    docker-compose run psono-server /bin/sh -c "sleep 20 && python3 psono/manage.py fsclustercreate 'Test Cluster' --fix-cluster-id=d5d8fea5-3c9c-4a3c-97db-8d50dd2f473c && python3 psono/manage.py fsshardcreate 'Test Shard' 'Test Shard Description' --fix-shard-id=5575b1a3-0d99-41bb-aa76-8277236ba90b && python3 psono/manage.py fsshardlink d5d8fea5-3c9c-4a3c-97db-8d50dd2f473c 5575b1a3-0d99-41bb-aa76-8277236ba90b  --fix-link-id=324ebf85-09fe-4172-87c6-09fdf7a7c108"
    docker-compose run psono-server /bin/sh -c "sleep 20 && python3 psono/manage.py fsclustershowconfig d5d8fea5-3c9c-4a3c-97db-8d50dd2f473c" > $INSTALL_DIR/.psono_fileserver_server_keys
    popd> /dev/null

    sed -i '/^SERVER_URL:/d' $INSTALL_DIR/.psono_fileserver_server_keys

    echo -e "$(cat $INSTALL_DIR/.psono_fileserver_server_keys)\n$(cat $INSTALL_DIR/psono/config/settings-fileserver.yaml)" > $INSTALL_DIR/psono/config/settings-fileserver.yaml

    rm  $INSTALL_DIR/.psono_fileserver_server_keys
    echo "Create settings.yml for the fileserver ... finished"
}

configure_psono_proxy () {
    echo "Configure psono proxy"
    cat > $INSTALL_DIR/psono/config/psono_proxy_nginx.conf <<- "EOF"
worker_processes 1;

events { worker_connections 1024; }

http {

    sendfile on;

    server {
        listen 80;
    #     server_name _;
    #     return 301 https://$host$request_uri;
    # }

    # server {
    #     listen 443 ssl http2;

    #     ssl_protocols TLSv1.2 TLSv1.3;
    #     ssl_dhparam /etc/ssl/dhparam.pem;
    #     ssl_prefer_server_ciphers on;
    #     ssl_session_cache shared:SSL:10m;
    #     ssl_session_tickets off;
    #     ssl_stapling on;
    #     ssl_stapling_verify on;
    #     ssl_session_timeout 1d;
    #     resolver 8.8.8.8 8.8.4.4 valid=300s;
    #     resolver_timeout 5s;
    #     ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';

    #     # add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";

        add_header Referrer-Policy same-origin;
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Content-Security-Policy "default-src 'none'; manifest-src 'self'; connect-src 'self' https://static.psono.com https://storage.googleapis.com https://*.s3.amazonaws.com https://*.digitaloceanspaces.com https://api.pwnedpasswords.com; font-src 'self'; img-src 'self' www.google-analytics.com data:; script-src 'self' www.google-analytics.com; style-src 'self' 'unsafe-inline'; object-src 'self'; form-action 'self'";

        # ssl_certificate /etc/ssl/public.crt;
        # ssl_certificate_key /etc/ssl/private.key;

        gzip on;
        gzip_disable "msie6";

        gzip_vary on;
        gzip_proxied any;
        gzip_comp_level 6;
        gzip_buffers 16 8k;
        gzip_http_version 1.1;
        gzip_min_length 256;
        gzip_types text/plain text/css application/json application/x-javascript application/javascript text/xml application/xml application/xml+rss text/javascript application/vnd.ms-fontobject application/x-font-ttf font/opentype image/svg+xml image/x-icon;

        client_max_body_size 200m;

        root /var/www/html;
        location ~ /.well-known {
            allow all;
        }

        location /server {
            rewrite ^/server/(.*) /$1 break;
            proxy_set_header        Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto $scheme;

            proxy_pass              http://psono-server:80;
        }

        location ~* ^/portal.*\.(?:ico|css|js|gif|jpe?g|png|eot|woff|woff2|ttf|svg|otf)$ {
            expires 30d;
            add_header              Pragma public;
            add_header              Cache-Control "public";
            proxy_set_header        Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto $scheme;
                
            proxy_pass              http://psono-admin-client:80;
        }
        
        location /portal {
            proxy_set_header        Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto $scheme;
            
            proxy_read_timeout      90;
            
            proxy_pass              http://psono-admin-client:80;
        }

        location /fileserver {
            rewrite ^/fileserver/(.*) /$1 break;
            proxy_set_header        Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto $scheme;

            proxy_pass              http://psono-fileserver:80;
        }

        location / {
            proxy_set_header        Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto $scheme;

            proxy_pass              http://psono-client:80;
            proxy_read_timeout      90;

            proxy_redirect          http://psono-client:80 /;
        }
    }

}

EOF
    echo "Configure psono proxy... finished"
}

start_stack () {
    echo "Start the stack"

    pushd $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX> /dev/null

    docker-compose up -d

    popd> /dev/null

    echo "Start the stack ... finished"
}

install_alias () {
    echo "Install alias"

    if [ ! -f $INSTALL_DIR/.bash_aliases ]; then
        touch $INSTALL_DIR/.bash_aliases
    fi

    sed -i '/^alias psonoctl=/d' $INSTALL_DIR/.bash_aliases

    alias psonoctl='cd $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX && docker-compose'
    echo -e "alias psonoctl='cd $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX && docker-compose'\n$(cat $INSTALL_DIR/.bash_aliases)" > $INSTALL_DIR/.bash_aliases

    echo "Install alias ... finished"
}

detect_os () {
    echo "Start detect OS"
    if [ `which lsb_release 2>/dev/null` ]; then
        DIST=`lsb_release -c | cut -f2`
        OS=`lsb_release -i | cut -f2 | awk '{ print tolower($1) }'`
    else
        echo "Unknown OS" >&2
        exit 1
    fi
    if [ "$OS" != "ubuntu" ] && [ "$OS" != "debian" ]; then
        echo "Unsupported OS" >&2
        exit 1
    fi

    echo "Detected $OS: $DIST"

    echo "Start detect OS ... finished"
}

main() {

    detect_os

    install_base_dependencies
    
    rm -Rf $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX
    mkdir -p $INSTALL_DIR/psono/$PSONO_DOCKER_PREFIX

    install_docker_if_not_exists

    install_docker_compose_if_not_exists

    ask_parameters

    craft_docker_compose_file

    stop_container_if_running

    test_if_ports_are_free

    for dir in html postgresql mail shard; do
        mkdir -p $INSTALL_DIR/psono/$dir
    done

    if [ "$PSONO_VERSION" == "DEV" ]; then

        install_git

        echo "Checkout psono-server git repository"
        if [ ! -d "$INSTALL_DIR/psono/psono-server" ]; then
            git clone https://gitlab.com/psono/psono-server.git $INSTALL_DIR/psono/psono-server
        fi
        echo "Checkout psono-server git repository ... finished"
        echo "Checkout psono-client git repository"
        if [ ! -d "$INSTALL_DIR/psono/psono-client" ]; then
            git clone https://gitlab.com/psono/psono-client.git $INSTALL_DIR/psono/psono-client
        fi
        echo "Checkout psono-client git repository ... finished"
        echo "Checkout psono-fileserver git repository"
        if [ ! -d "$INSTALL_DIR/psono/psono-fileserver" ]; then
            git clone https://gitlab.com/psono/psono-fileserver.git $INSTALL_DIR/psono/psono-fileserver
        fi
        echo "Checkout psono-fileserver git repository ... finished"
    fi


    create_dhparam_if_not_exists

    create_openssl_conf

    create_self_signed_certificate_if_not_exists

    create_config_json

    docker_compose_pull

    create_settings_server_yaml

    create_settings_fileserver_yaml

    configure_psono_proxy

    start_stack

    install_acme

    install_alias

    echo ""
    echo "========================="
    echo "CLIENT URL : https://$PSONO_WEBDOMAIN"
    echo "ADMIN URL : https://$PSONO_WEBDOMAIN/portal/"
    echo ""
    echo "USER1: demo1@$PSONO_USERDOMAIN"
    echo "PASSWORD: demo1"
    echo ""
    echo "USER2: demo2@$PSONO_USERDOMAIN"
    echo "PASS: demo2"
    echo ""
    echo "ADMIN: admin@$PSONO_USERDOMAIN"
    echo "PASS: admin"
    echo "========================="
    echo ""
}

main
