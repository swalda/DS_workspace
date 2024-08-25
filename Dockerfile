# Используем официальный образ Ubuntu
FROM ubuntu:latest

# Устанавливаем необходимые зависимости
RUN apt-get update && apt-get install -y \
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
    nginx \
    nodejs \
    npm \
    netdata \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Генерируем и устанавливаем локаль UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Устанавливаем Python 3.9 и необходимые библиотеки
RUN add-apt-repository ppa:deadsnakes/ppa && apt-get update && apt-get install -y \
    python3.9 \
    python3.9-venv \
    python3.9-dev \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем Python-библиотеки через pip с параметром --break-system-packages
RUN pip install --break-system-packages \
    fastapi \
    uvicorn \
    aiofiles \
    jupyterlab \
    jupyterlab-materialdarker \
    jupyterlab-lsp \
    'python-lsp-server[all]'

# Устанавливаем и настраиваем elFinder
RUN npm install -g elfinder

# Устанавливаем btop (системный мониторинг)
RUN wget https://github.com/aristocratos/btop/releases/latest/download/btop-x86_64-linux-musl.tbz -O /tmp/btop.tbz \
    && mkdir /tmp/btop \
    && tar -xvf /tmp/btop.tbz -C /tmp/btop \
    && cd /tmp/btop/btop \
    && make install \
    && rm -rf /tmp/btop.tbz /tmp/btop

# Настройка Netdata для прослушивания всех интерфейсов
RUN sed -i 's/bind socket to IP = 127.0.0.1/bind socket to IP = 0.0.0.0/' /etc/netdata/netdata.conf

# Устанавливаем Code Server для удаленной разработки
RUN curl -fsSL https://code-server.dev/install.sh | sh \
    && mkdir -p /root/.config/code-server \
    && echo "bind-addr: 0.0.0.0:8080" > /root/.config/code-server/config.yaml \
    && echo "auth: none" >> /root/.config/code-server/config.yaml \
    && echo "cert: false" >> /root/.config/code-server/config.yaml

# Копируем файлы конфигурации, веб-приложения и иконки
COPY nginx.conf /etc/nginx/sites-available/default
COPY index.html theme.css /var/www/html/
COPY start.sh /usr/local/bin/start.sh
COPY app.py /app/app.py
COPY jupyter.png /var/www/html/static/icons/jupyter-icon.png
COPY code-server.png /var/www/html/static/icons/code-server-icon.png
COPY netdata.png /var/www/html/static/icons/netdata-icon.png

# Удаляем дефолтную страницу Nginx
RUN rm /var/www/html/index.nginx-debian.html

# Делаем скрипт и FastAPI приложение исполняемыми
RUN chmod +x /usr/local/bin/start.sh /app/app.py

# Открываем порты для всех сервисов
EXPOSE 80 19999 8888 8080

# Запускаем скрипт запуска
CMD ["/usr/local/bin/start.sh"]
