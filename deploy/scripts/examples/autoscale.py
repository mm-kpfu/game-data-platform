import requests
import time
import jwt
import json
import os
import datetime
import sys
import subprocess

# Authorization json file https://yandex.cloud/ru/docs/iam/operations/authorized-key/create
with open('/home/eggsy/Downloads/authorized_key.json', 'r') as f:
    obj = json.load(f)

folder_id = os.environ.get('YANDEX__KAFKA__FOLDER_ID', "b1gjkor5me1p843e7gkt")
resource_id = os.environ.get('YANDEX__KAFKA__RESOURCE_ID', "c9qmu2pk75cbluv9ubi0")
private_key = obj['private_key']
key_id = obj['id']
service_account_id = obj['service_account_id']

now = int(time.time())
payload = {
        'aud': 'https://iam.api.cloud.yandex.net/iam/v1/tokens',
        'iss': service_account_id,
        'iat': now,
        'exp': now + 3600
      }

encoded_token = jwt.encode(
    payload,
    private_key,
    algorithm='PS256',
    headers={'kid': key_id}
  )

iam_token = requests.post(
    "https://iam.api.cloud.yandex.net/iam/v1/tokens",
    json={"jwt": encoded_token}
).json()["iamToken"]

MAX_RAM_USAGE_BYTES_FOR_INCREASE_PARALLELISM = 10 * 1024 * 1024 * 1024
MIN_RAM_USAGE_BYTES_FOR_DECREASE_PARALLELISM = 1 * 1024 * 1024 * 1024
PARALLELISM = os.environ.get('DEFAULT__PARALLELISM', 1)
INCREASE_BY = os.environ.get('INCREASE_BY', 2)
JOB_PATHS = json.loads(os.environ.get('JOBS__PATHS'))
jobs = sys.argv[1:]

while True:
    now = datetime.datetime.utcnow()
    metrics = requests.post(
        "https://monitoring.api.cloud.yandex.net/monitoring/v2/data/read",
        params={"folderId": folder_id},
        headers={
            "Authorization": f"Bearer {iam_token}",
            "Content-Type": "application/json",
        },
        json={
            "query": f"mem.used_bytes{{service=\"managed-kafka\", resource_id=\"{resource_id}\"}}",
            "fromTime": (now - datetime.timedelta(seconds=60)).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "toTime": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
        }
    ).json()
    time.sleep(60)

    if metrics["metrics"][0]["timeseries"]["doubleValues"][0] > MAX_RAM_USAGE_BYTES_FOR_INCREASE_PARALLELISM:
        PARALLELISM += INCREASE_BY
        for job in jobs:
            subprocess.run(f'flink stop {job} &', check=True, shell=True)

        for job in JOB_PATHS:
            subprocess.run(f'flink run {job} --parallelism {PARALLELISM}')

        time.sleep(1800)
    elif metrics["metrics"][0]["timeseries"]["doubleValues"][0] < MIN_RAM_USAGE_BYTES_FOR_DECREASE_PARALLELISM:
        PARALLELISM -= INCREASE_BY
        for job in jobs:
            subprocess.run(f'flink stop {job} &', check=True, shell=True)

        for job in JOB_PATHS:
            subprocess.run(f'flink run {job} --parallelism {PARALLELISM}')

        time.sleep(600)
