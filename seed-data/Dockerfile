FROM python:3.11-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends apache2-utils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /seed
COPY . .

RUN python make-data.py

 RUN chmod +x generate-votes.sh

CMD ["./generate-votes.sh"]
