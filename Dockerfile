# Используем официальный образ Ubuntu
FROM ubuntu:latest

# Устанавливаем необходимые зависимости
RUN apt-get update && apt-get install -y wget \
    tar \
    make \
    locales \
    software-properties-common \
    curl \
    gnupg \
    net-tools \
    build-essential \
    python3-pip \
    htop \
    ncdu \
    vim \
    git \
    iputils-ping \
    dnsutils \
    unzip \
    zip \
    sudo \
    lsof \
    tcpdump \
    screen \
    tmux \
    man \
    strace \
    gdb \
    openssl \
    rsync \
    tree \
    jq \
    less \
    moreutils \
    silversearcher-ag \
    lsb-release \
    bash-completion \
    cmake \
    gcc \
    g++ \
    tzdata \
    xz-utils \
    bzip2 \
    apt-transport-https \
    gnupg-agent \
    rsyslog \
    locate \
    cron \
    procps \
    whois \
    traceroute \
    nmap \
    iproute2 \
    iftop \
    iotop \
    sysstat \
    socat \
    ethtool \
    nginx \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Генерируем и устанавливаем локаль UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Устанавливаем Python 3.9
RUN add-apt-repository ppa:deadsnakes/ppa && apt-get update
RUN apt-get install -y python3.9 python3.9-venv python3.9-dev

# Устанавливаем Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p /opt/conda \
    && rm /tmp/miniconda.sh

# Устанавливаем JupyterLab через pip с параметром --break-system-packages
RUN pip install jupyterlab --break-system-packages

# Устанавливаем тему jupyterlab_materialdarker с параметром --break-system-packages
RUN pip install jupyterlab_materialdarker --break-system-packages

# Устанавливаем jupyterlab-lsp и базовый Python Language Server
RUN pip install jupyterlab-lsp 'python-lsp-server[all]' --break-system-packages

# Добавляем Miniconda в PATH
ENV PATH="/opt/conda/bin:${PATH}"

# Устанавливаем nvm для управления Node.js
ENV NVM_DIR="/root/.nvm"
RUN mkdir -p $NVM_DIR \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install 18.17.0 \
    && nvm alias default 18.17.0 \
    && nvm use default

# Добавляем nvm и node в PATH для следующих команд
ENV PATH="$NVM_DIR/versions/node/v18.17.0/bin:$PATH"

# Устанавливаем btop
RUN wget https://github.com/aristocratos/btop/releases/latest/download/btop-x86_64-linux-musl.tbz -O /tmp/btop.tbz \
    && mkdir /tmp/btop \
    && tar -xvf /tmp/btop.tbz -C /tmp/btop \
    && cd /tmp/btop/btop \
    && make install \
    && rm -rf /tmp/btop.tbz /tmp/btop

# Устанавливаем Netdata
RUN apt-get install -y netdata

# Настройка Netdata для прослушивания всех интерфейсов
RUN sed -i 's/bind socket to IP = 127.0.0.1/bind socket to IP = 0.0.0.0/' /etc/netdata/netdata.conf

# Устанавливаем Code Server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Создаем директорию workspace в корне
RUN mkdir -p /workspace

# Настройка Code Server: слушать на 0.0.0.0 и отключение пароля
RUN mkdir -p /root/.config/code-server && \
    echo "bind-addr: 0.0.0.0:8080" > /root/.config/code-server/config.yaml && \
    echo "auth: none" >> /root/.config/code-server/config.yaml && \
    echo "cert: false" >> /root/.config/code-server/config.yaml

# Копируем файлы конфигурации Nginx и домашнюю страницу
COPY nginx.conf /etc/nginx/sites-available/default
COPY index.html /var/www/html/index.html

# Удаляем дефолтную страницу Nginx
RUN rm /var/www/html/index.nginx-debian.html

# Копируем скрипт запуска
COPY start.sh /usr/local/bin/start.sh

# Делаем скрипт исполняемым
RUN chmod +x /usr/local/bin/start.sh

# Открываем порты для всех сервисов
EXPOSE 80 19999 8888 8080

# Запускаем скрипт запуска
CMD ["/usr/local/bin/start.sh"]
