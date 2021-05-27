import json
import boto3
import os

dynamo_db = os.environ.get('DYNAMO_DB')
s3_bucket = os.environ.get('S3_BUCKET')
ecs_cluster = os.environ.get('ECS_CLUSTER')
ecs_task = os.environ.get('ECS_TASK')
ecs_container = os.environ.get('ECS_CONTAINER')
ecs_capacity_provider = os.environ.get('ECS_CAPACITY_PROVIDER') 


# create or update db entry, create s3 object
def set_camera(cam_id,metadata):

    s3 = boto3.resource('s3')
    file_name = cam_id+'.json'
    s3.Object(s3_bucket,file_name).put(Body=json.dumps(metadata))
    s3_path='s3://' + s3_bucket + "/" + file_name
    
    #check if item exists
    client=boto3.client('dynamodb')
    response = client.query(
        TableName= dynamo_db,
        ExpressionAttributeNames= {
            '#CAMID': 'cam_id',
        },
        ExpressionAttributeValues={
            ':v1': {
                'S': cam_id
            },
        },
        KeyConditionExpression= '#CAMID = :v1'
    )
    
    if response['Count'] != 0:
        sentinel_id = response['Items'][0]['sentinel_id']['S']
    else :
        sentinel_id = ''

    # create or update item in db
    response = client.put_item(
        TableName=dynamo_db,
        Item={
            'cam_id': {
                'S': cam_id
            },
            'sentinel_id': {
                'S': sentinel_id
            },
            'metadata':  {
                'S': str(metadata)
            },
            's3_path' : {
                'S' : s3_path
            }
        }
    )
        
    result = {
        'cam_id' : cam_id,
        'sentinel_id' : sentinel_id,
        's3_object' : s3_path
    }
    return result
    
# update sentinel id in db
def update_camera(cam_id, sentinel_id):
    client=boto3.client('dynamodb')
    response = client.update_item(
        TableName= dynamo_db,
        Key={
            'cam_id': {
                'S': cam_id
            }
        },
        ExpressionAttributeNames={
            '#SENTINEL': 'sentinel_id',
        },
        ExpressionAttributeValues={
            ':v1': {
                "S": sentinel_id            }
        },
        UpdateExpression='SET #SENTINEL = :v1',
        ReturnValues='ALL_NEW',
    )
    return None
    
# start sentinel; return sentinel  id
def start_sentinel(s3_object):
    client = boto3.client('ecs')
    response = client.run_task(
        cluster=ecs_cluster,
        capacityProviderStrategy=[
            {
            'capacityProvider': ecs_capacity_provider,
            'weight': 1,
            'base': 0
            }
        ],
        taskDefinition=ecs_task,
        overrides={
            'containerOverrides': [
                {
                'name': ecs_container,
                'environment': [
                    {
                        'name': 'S3_METADATA',
                        'value': s3_object
                    }
                ]
             }
         ]
     }                   
    )
    return response['tasks'][0]['taskArn']

# stop sentinel
def stop_sentinel(sentinel_id):
    client = boto3.client('ecs')
    response = client.stop_task(
        cluster=ecs_cluster,
        task=sentinel_id
    )
    return None

def lambda_handler(event, context):
    
    print(event)
    print('DYNAMO_DB: %s' % dynamo_db)
    print('S3_BUCKET: %s' % s3_bucket)
    print('ECS_CLUSTER: %s ' % ecs_cluster)
    print('ECS_TASK: %s' % ecs_task)
    print('ECS_CONTAINER: %s' % ecs_container)
    print('ECS_CAPACITY_PROVIDER: %s' % ecs_capacity_provider)

    cam_id = event['cam_id']    
    metadata = event['metadata']

    response = set_camera(cam_id,metadata )
    if response['sentinel_id']!='':
        stop_sentinel(response['sentinel_id'])
    sen_id=start_sentinel(response['s3_object'])
    update_camera(cam_id,sen_id)

    return {
        'statusCode': 200
    }
