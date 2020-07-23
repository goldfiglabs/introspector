FROM python:3.7-slim

COPY requirements.txt /app/
WORKDIR /app/
RUN pip install -r requirements.txt
EXPOSE 5000/tcp
COPY goldfig.py /app/
COPY goldfig /app/goldfig
COPY schema-docs /app/schema-docs
LABEL goldfig-cli=0.0.1

ENTRYPOINT ["/app/goldfig.py", "serve"]