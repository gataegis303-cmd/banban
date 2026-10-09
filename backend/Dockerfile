#  Dockerfile
#  BanBan 后端镜像：uv 管理依赖，非 root 运行

FROM python:3.12-slim

# 安装 uv（依赖管理器）
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

WORKDIR /app

# 先复制依赖清单，利用 Docker 层缓存
COPY pyproject.toml ./
RUN uv sync --no-dev --no-install-project

# 复制应用代码
COPY . .

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
