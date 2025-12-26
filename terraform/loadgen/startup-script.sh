#!/bin/bash

set -e

echo "=== Load Generator VM Startup Script ==="

# Wait for Docker to be ready (Container-Optimized OS has it pre-installed)
echo "Waiting for Docker to be ready..."
while ! docker info > /dev/null 2>&1; do
  sleep 2
done

echo "Docker is ready!"

# Create working directory
mkdir -p /tmp/loadgen
cd /tmp/loadgen

# Create locustfile.py
cat > locustfile.py << 'LOCUSTFILE'
#!/usr/bin/python

import random
from locust import FastHttpUser, TaskSet, between
from faker import Faker
import datetime
fake = Faker()

products = [
    '0PUK6V6EV0',
    '1YMWWN1N4O',
    '2ZYFJ3GM2N',
    '66VCHSJNUP',
    '6E92ZMYYFZ',
    '9SIQT8TOJO',
    'L9ECAV7KIM',
    'LS4PSXUNUM',
    'OLJCESPC7Z']

def index(l):
    l.client.get("/")

def setCurrency(l):
    currencies = ['EUR', 'USD', 'JPY', 'CAD', 'GBP', 'TRY']
    l.client.post("/setCurrency",
        {'currency_code': random.choice(currencies)})

def browseProduct(l):
    l.client.get("/product/" + random.choice(products))

def viewCart(l):
    l.client.get("/cart")

def addToCart(l):
    product = random.choice(products)
    l.client.get("/product/" + product)
    l.client.post("/cart", {
        'product_id': product,
        'quantity': random.randint(1,10)})

def checkout(l):
    addToCart(l)
    current_year = datetime.datetime.now().year+1
    l.client.post("/cart/checkout", {
        'email': fake.email(),
        'street_address': fake.street_address(),
        'zip_code': fake.zipcode(),
        'city': fake.city(),
        'state': fake.state_abbr(),
        'country': fake.country(),
        'credit_card_number': fake.credit_card_number(card_type="visa"),
        'credit_card_expiration_month': random.randint(1, 12),
        'credit_card_expiration_year': random.randint(current_year, current_year + 70),
        'credit_card_cvv': f"{random.randint(100, 999)}",
    })

class UserBehavior(TaskSet):

    def on_start(self):
        index(self)

    tasks = {index: 1,
        setCurrency: 2,
        browseProduct: 10,
        addToCart: 2,
        viewCart: 3,
        checkout: 1}

class WebsiteUser(FastHttpUser):
    tasks = [UserBehavior]
    wait_time = between(1, 10)
LOCUSTFILE

# Create Dockerfile
cat > Dockerfile << 'DOCKERFILE'
FROM python:3.12-slim

WORKDIR /loadgen

RUN pip install --no-cache-dir locust faker

COPY locustfile.py .

ENV GEVENT_SUPPORT=True

ENTRYPOINT ["sh", "-c", "locust --host=http://$${FRONTEND_ADDR} --web-host=0.0.0.0 --web-port=8089"]
DOCKERFILE

echo "Building Docker image..."
docker build -t loadgenerator:automated .

echo "Running load generator container..."
docker run -d \
  --name loadgenerator \
  --restart unless-stopped \
  -p 8089:8089 \
  -e FRONTEND_ADDR=${frontend_ip} \
  loadgenerator:automated

echo "=== Load generator deployed successfully! ==="
echo "Frontend IP: ${frontend_ip}"
echo "Locust users: ${locust_users}"
echo "Spawn rate: ${locust_rate}"
echo "Container status:"
docker ps

echo "=== Startup complete ==="
