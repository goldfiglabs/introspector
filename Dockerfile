FROM python:3.7-slim

ADD https://github.com/amacneil/dbmate/releases/download/v1.11.0/dbmate-linux-amd64 /app/dbmate
RUN chmod a+x /app/dbmate
COPY requirements.txt /app/
COPY migrations /app/migrations
WORKDIR /app/
RUN pip install -r requirements.txt
EXPOSE 5000/tcp
COPY goldfig.py /app/
COPY goldfig /app/goldfig
LABEL goldfig-cli=0.0.1

ENTRYPOINT ["/app/goldfig.py", "serve"]