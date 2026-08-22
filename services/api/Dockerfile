FROM python:3.12-slim

WORKDIR /srv

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev curl \
    && rm -rf /var/lib/apt/lists/*

COPY packages/election_rules_py /srv/packages/election_rules_py
COPY services/forecasting /srv/services/forecasting
COPY services/api/requirements.txt /srv/services/api/requirements.txt

RUN pip install --no-cache-dir -r /srv/services/api/requirements.txt

COPY services/api /srv/services/api
WORKDIR /srv/services/api

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
