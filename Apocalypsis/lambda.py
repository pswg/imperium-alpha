"""TODO: docstring
"""

import uuid
import os
import datetime
import boto3
import pytds
import rhapsodia.vacui

def handler(event, context):
  """TODO: docstring
  """

  instance_id = str(uuid.uuid4())
  name = os.environ['instance_name']
  server = os.environ['instance_server']
  database = os.environ['instance_database']
  username = os.environ['instance_username']
  password = os.environ['instance_password']

  with pytds.connect(server, database, username, password) as conn:
    with conn.cursor() as cur:
      cur.execute("SELECT 1")
      cur.fetchall()

  return "It is done."

handler(None, None)