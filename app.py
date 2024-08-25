from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import os

app = FastAPI()

# Маршрут для файлового менеджера
@app.get("/api/files/")
def get_files():
    # Логика работы с файлами
    pass

@app.post("/api/files/upload")
async def upload_file():
    # Логика загрузки файла
    pass

@app.get("/api/metrics/")
def get_metrics():
    # Логика получения метрик от Netdata
    pass

@app.post("/api/service/restart")
def restart_service(service_name: str):
    # Логика перезапуска сервисов
    pass

# Прокси elFinder файлового менеджера
app.mount("/static", StaticFiles(directory="static"), name="static")
