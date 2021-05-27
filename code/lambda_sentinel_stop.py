import boto3
import os

dynamo_db = os.environ.get('DYNAMO_DB')
ecs_cluster = os.environ.get('ECS_CLUSTER')

# get sentinel_id from db
def get_sentinel(cam_id):
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
    
    return sentinel_id


# update sentinel id in db
def update_camera(cam_id):
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
                "S": ''
            }
        },
        UpdateExpression='SET #SENTINEL = :v1',
        ReturnValues='ALL_NEW',
    )
    return None


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
    print('ECS_CLUSTER: %s ' % ecs_cluster)
    
    cam_id = event['cam_id']   
    
    sentinel_id=get_sentinel(cam_id)
    if sentinel_id !='':
        stop_sentinel(sentinel_id)
        update_camera(cam_id)
    
    
    return {
        'statusCode': 200
    }
