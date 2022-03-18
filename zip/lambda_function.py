import boto3
import os
import json
import base64
import gzip
import datetime
from io import BytesIO

S3_BUCKET_NAME = os.getenv("S3_BUCKET_NAME")
PROJECT_NAME = os.getenv("PROJECT_NAME")

client_s3 = boto3.client('s3')

def lambda_handler(event, context):
  data = str(event)
  try:
      current_time = datetime.datetime.now()
      cw_data = str(event['awslogs']['data'])
      cw_logs = gzip.GzipFile(fileobj=BytesIO(base64.b64decode(cw_data, validate=True))).read()
      log_events = json.loads(cw_logs)
      s3_delivery = json.dumps(log_events['logEvents'], indent=2).encode('utf-8')

      if log_events['logGroup'][0] == '/':
          PREFIX_LOG = log_events['logGroup']
      else:
          PREFIX_LOG = '/' + log_events['logGroup']

      key_def = PROJECT_NAME + '/AWSLogs/' + log_events['owner']  +'/CloudWatch' + PREFIX_LOG + '/' + client_s3.meta.region_name +'/' + current_time.strftime("%Y/%m/%d") + '/' + log_events['logStream'][-32:] + '_' + current_time.strftime("%H%M%S") + '.json'
      resp = client_s3.put_object(Bucket=S3_BUCKET_NAME,Body=s3_delivery,Key=key_def,ACL='bucket-owner-full-control')
      print(log_events)
  except Exception as e:
      raise Exception("Could not record link! " % e)
