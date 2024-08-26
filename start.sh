#!/bin/bash

# Создаем директорию для логов, если её нет
mkdir -p /var/log/my_services
mkdir /workspace/test_folder

# Функция для записи в лог
log() {
    echo "$(date) - $1" >> "$2"
}

# Запуск Nginx
log "Запуск Nginx" "/var/log/my_services/nginx.log"
service nginx start >> "/var/log/my_services/nginx.log" 2>&1
sleep 2

# Запуск MariaDB
log "Запуск MariaDB" "/var/log/my_services/mariadb.log"
mysqld_safe >> "/var/log/my_services/mariadb.log" 2>&1 &
sleep 2

# Запуск настройки конфигурации Pydio
log "Запуск настройки конфигурации Pydio" "/var/log/my_services/pydio_config.log"
/opt/pydio/bin/cells configure --yaml /etc/pydio-cells-config.yaml >> "/var/log/my_services/pydio_config.log" 2>&1 &
sleep 2

# Запуск Pydio Cells
log "Запуск Pydio Cells" "/var/log/my_services/pydio_cells.log"
/opt/pydio/bin/cells start --log debug >> "/var/log/my_services/pydio_cells.log" 2>&1 &
sleep 2

# Запуск JupyterLab из папки workspace и базовым URL /jupyterlab/
log "Запуск JupyterLab" "/var/log/my_services/jupyterlab.log"
jupyter lab --no-browser --ip=0.0.0.0 --port 8888 --allow-root --NotebookApp.token='' --notebook-dir=/workspace --LabApp.base_url='/jupyterlab/' >> "/var/log/my_services/jupyterlab.log" 2>&1 &
sleep 2

# Запуск Netdata
log "Запуск Netdata" "/var/log/my_services/netdata.log"
/usr/sbin/netdata -D >> "/var/log/my_services/netdata.log" 2>&1 &
sleep 2

# Запуск VS Code Server из папки workspace
log "Запуск VS Code Server" "/var/log/my_services/code_server.log"
code-server /workspace --port 8080 >> "/var/log/my_services/code_server.log" 2>&1 &
sleep 2

# Ожидание завершения всех процессов
wait
