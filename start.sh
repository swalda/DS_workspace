#!/bin/bash

# Создаем директорию для логов, если её нет
mkdir -p /var/log/my_services

# Функция для записи в лог
log() {
    echo "$(date) - $1" >> /var/log/my_services/startup.log
}

# Запуск JupyterLab из папки workspace с темой materialdarker и базовым URL /jupyterlab/
log "Запуск JupyterLab"
exec jupyter lab --no-browser --ip=0.0.0.0 --port=8888 --allow-root --NotebookApp.token='' --notebook-dir=/workspace --LabApp.base_url='/jupyterlab/' --LabApp.default_url='/lab?theme=JupyterLab%20Material%20Darker' >> /var/log/my_services/jupyter.log 2>&1 &

# Запуск Netdata
log "Запуск Netdata"
exec /usr/sbin/netdata -D >> /var/log/my_services/netdata.log 2>&1 &

# Запуск VS Code Server из папки workspace
log "Запуск VS Code Server"
exec code-server /workspace --port 8080 >> /var/log/my_services/code-server.log 2>&1 &

# Запуск Nginx
log "Запуск Nginx"
service nginx start

# Ожидание завершения всех процессов
wait
