import json
import boto3
import os
import yaml
import subprocess


ENV_SECRETS_PREFIX = 'GDP_SECRET'


class FormatDumper(yaml.SafeDumper):
    """
    Format Dumper with indentations and blank spaces for better readability
    """

    def write_line_break(self, data=None):
        super().write_line_break(data)

        if len(self.indents) == 1:
            super().write_line_break()

    def increase_indent(self, flow=False, indentless=False):
        return super().increase_indent(flow, False)


class Command:
    FILE_LOCATION = os.environ.get('TFSTATE_FILE_LOCATION', None)

    BUCKET_NAME = os.environ.get('TFSTATE_BUCKET_NAME', None)
    ENDPOINT_URL = os.environ.get('TFSTATE_ENDPOINT_URL', None)
    REGION = os.environ.get('TFSTATE_REGION', None)
    ACCESS_KEY_ID = os.environ.get('TFSTATE_ACCESS_KEY_ID', None)
    ACCESS_SECRET_KEY = os.environ.get('TFSTATE_ACCESS_SECRET_KEY', None)
    KEY = os.environ.get('TFSTATE_KEY', None)

    VALUES_FILEPATH = os.environ.get('VALUES_FILENAME')

    def __init__(self):
        if not self.FILE_LOCATION:
            client = boto3.client(
                service_name='s3',
                region_name=self.REGION,
                endpoint_url=self.ENDPOINT_URL,
                aws_access_key_id=self.ACCESS_KEY_ID,
                aws_secret_access_key=self.ACCESS_SECRET_KEY
            )

            tfstate = client.get_object(Bucket=self.BUCKET_NAME, Key=self.KEY)['Body'].read()
        else:
            with open(self.FILE_LOCATION) as f:
                tfstate = f.read()

        self.obj = json.loads(tfstate)

    def seal_secret(self, value):
        proc = subprocess.Popen(
            ["kubeseal", "--raw", "--scope", "namespace-wide", "--from-file=/dev/stdin", "--cert=/home/eggsy/study/t/game-data-platform/deploy/scripts/cert.pem"],
            stdout=subprocess.PIPE,
            stdin=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        out = proc.communicate(input=value)[0]
        return out

    def prepare_secrets(self, variables: dict):
        def build_env_map(d, divided_key, v):
            for key_part in divided_key[:-1]:
                d = d.setdefault(key_part, {})
            d[divided_key[-1]] = v

        env_vars = []
        prepared_secrets = {}
        for key in variables:
            sealed = self.seal_secret(variables[key])
            env_vars.append((key.replace(f'{ENV_SECRETS_PREFIX}__', '').split('__', 1), sealed))

        for keys, value in env_vars:
            build_env_map(prepared_secrets, keys, value)

        return prepared_secrets

    @staticmethod
    def add_env_variables(variables):
        for key, v in os.environ.items():
            if key.startswith(ENV_SECRETS_PREFIX):
                variables[key] = v

    def add_kafka_variables(self, variables):
        name_prefix = self.obj['outputs']['name_prefix']['value']
        kafka_users = self.obj['outputs']['kafka_users']['value']
        kafka_flink_user = list(filter(lambda u: u['login'] == f'{name_prefix}-flink', kafka_users))
        if kafka_flink_user:
            variables[f'{ENV_SECRETS_PREFIX}__FLINK__KAFKA__PASSWORD'] = kafka_flink_user[0]['login']
            variables[f'{ENV_SECRETS_PREFIX}__FLINK__KAFKA__LOGIN'] = kafka_flink_user[0]['password']

        if self.obj['outputs']['kafka_hosts']['value']:
            variables[f'{ENV_SECRETS_PREFIX}__FLINK__KAFKA__HOSTS'] = json.dumps(self.obj['outputs']['kafka_hosts']['value'])

    def add_clickhouse_variables(self, variables):
        name_prefix = self.obj['outputs']['name_prefix']['value']
        clickhouse_users = self.obj['outputs']['clickhouse_users']['value']
        clickhouse_flink_user = list(filter(lambda u: u['user'] == f'{name_prefix}-flink', clickhouse_users))
        if clickhouse_flink_user:
            variables[f'{ENV_SECRETS_PREFIX}__FLINK__CLICKHOUSE__PASSWORD'] = clickhouse_flink_user[0]['user']
            variables[f'{ENV_SECRETS_PREFIX}__FLINK__CLICKHOUSE__LOGIN'] = clickhouse_flink_user[0]['password']

        if self.obj['outputs'].get('clickhouse_hosts', {}):
            variables[f'{ENV_SECRETS_PREFIX}__FLINK__CLICKHOUSE__HOSTS'] = json.dumps(self.obj['outputs']['clickhouse_hosts']['value'][0])

    def prepare_manifests(self):
        with open(self.VALUES_FILEPATH) as f:
            values = yaml.safe_load(f)

        variables = {}
        self.add_env_variables(variables)
        self.add_clickhouse_variables(variables)
        self.add_kafka_variables(variables)
        secrets = self.prepare_secrets(variables)

        # Remove old secrets
        values['secrets'] = {}
        for for_component_key in secrets:
            if not values['secrets'].get(for_component_key):
                values['secrets'][for_component_key] = {}
            for k, v in secrets[for_component_key].items():
                values['secrets'][for_component_key][k] = v

        values['deployments'] = [{
            'zone': z,
        } for z in self.obj['outputs']['flink_availability_zones']['value']]

        with open(self.VALUES_FILEPATH, 'w') as f:
            yaml.dump(values, f, Dumper=FormatDumper, default_flow_style=False, sort_keys=False)


if __name__ == '__main__':
    Command().prepare_manifests()
