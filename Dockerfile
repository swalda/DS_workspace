# Используем официальный образ Ubuntu
FROM ubuntu:latest

# Устанавливаем необходимые зависимости
RUN apt-get update -o Acquire::http::Pipeline-Depth=200 && apt-get install -y \
    wget \
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
    mariadb-server \
    unzip \
    netdata \
    nginx\
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Генерируем и устанавливаем локаль UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Устанавливаем Python 3.9 и необходимые библиотеки
RUN add-apt-repository ppa:deadsnakes/ppa && apt-get update -o Acquire::http::Pipeline-Depth=200 && apt-get install -y \
    python3.9 \
    python3.9-venv \
    python3.9-dev \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем Python-библиотеки через pip
RUN pip install --break-system-packages \
    fastapi \
    uvicorn \
    aiofiles \
    jupyterlab \
    jupyterlab-materialdarker \
    jupyterlab-lsp \
    'python-lsp-server[all]'

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

# Устанавливаем btop (системный мониторинг)
RUN wget https://github.com/aristocratos/btop/releases/latest/download/btop-x86_64-linux-musl.tbz -O /tmp/btop.tbz \
    && mkdir /tmp/btop \
    && tar -xvf /tmp/btop.tbz -C /tmp/btop \
    && cd /tmp/btop/btop \
    && make install \
    && rm -rf /tmp/btop.tbz /tmp/btop

# Устанавливаем Netdata и настраиваем его
RUN sed -i 's/bind socket to IP = 127.0.0.1/bind socket to IP = 0.0.0.0/' /etc/netdata/netdata.conf

# Устанавливаем Code Server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Настройка Code Server: слушать на 0.0.0.0 и отключение пароля
RUN mkdir -p /root/.config/code-server && \
    echo "bind-addr: 0.0.0.0:8080" > /root/.config/code-server/config.yaml && \
    echo "auth: none" >> /root/.config/code-server/config.yaml && \
    echo "cert: false" >> /root/.config/code-server/config.yaml

# Создаем директорию для Pydio Cells и других данных
RUN mkdir -p /opt/pydio/bin /workspace /var/cells /root/.config/pydio/cells/data /var/www/html/static/js

ENV CELLS_WORKING_DIR=/var/cells

# Устанавливаем Pydio Cells
RUN wget https://download.pydio.com/latest/cells/release/{latest}/linux-amd64/pydio-cells-{latest}-linux-amd64.zip -O /tmp/pydio-cells.zip \
    && unzip /tmp/pydio-cells.zip -d /opt/pydio/bin/ \
    && chmod +x /opt/pydio/bin/cells /opt/pydio/bin/cells-fuse \
    && ln -s /opt/pydio/bin/cells /usr/local/bin/cells \
    && rm /tmp/pydio-cells.zip

# Конфигурация базы данных для Pydio Cells
RUN service mariadb start \
    && mysql -u root -e "CREATE DATABASE cells;" \
    && mysql -u root -e "CREATE USER 'pydio'@'localhost' IDENTIFIED BY 'pydio_password';" \
    && mysql -u root -e "GRANT ALL PRIVILEGES ON cells.* TO 'pydio'@'localhost';" \
    && mysql -u root -e "FLUSH PRIVILEGES;"

# Загрузка и установка jQuery
RUN wget https://code.jquery.com/jquery-3.6.0.min.js -O /var/www/html/static/js/jquery.min.js

# Копируем файлы конфигурации, веб-приложения и иконки
COPY nginx.conf /etc/nginx/sites-available/default
COPY index.html theme.css /var/www/html/
COPY start.sh /usr/local/bin/start.sh
COPY pydio-cells-config.yaml /etc/pydio-cells-config.yaml

COPY jupyter.png /var/www/html/static/icons/jupyter-icon.png
COPY code-server.png /var/www/html/static/icons/code-server-icon.png
COPY netdata.png /var/www/html/static/icons/netdata-icon.png

# Делаем скрипт исполняемым
RUN chmod +x /usr/local/bin/start.sh

# Открываем порты для всех сервисов
EXPOSE 80 19999 8888 8080 8085

# Запускаем скрипт запуска
CMD ["/usr/local/bin/start.sh"]
