#FROM python:3.11-slim

FROM python:3.9
WORKDIR /app
COPY app.py .
RUN pip install flask
CMD ["python", "app.py"]
EXPOSE 5000
