import os
from botocore.exceptions import ClientError


def _client():
    import boto3
    return boto3.client(
        's3',
        aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
        aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
        region_name=os.getenv('AWS_REGION', 'ap-northeast-2'),
    )


def is_configured() -> bool:
    return bool(os.getenv('AWS_ACCESS_KEY_ID') and os.getenv('S3_BUCKET_NAME'))


def upload_file(file_bytes: bytes, s3_key: str, content_type: str = 'image/jpeg') -> str:
    """S3에 파일을 업로드하고 s3_key를 반환합니다."""
    bucket = os.getenv('S3_BUCKET_NAME', '')
    _client().put_object(
        Bucket=bucket,
        Key=s3_key,
        Body=file_bytes,
        ContentType=content_type,
    )
    return s3_key


def get_presigned_url(s3_key: str, expires_in: int = 3600) -> str | None:
    """S3 객체의 pre-signed URL을 생성합니다 (기본 1시간)."""
    bucket = os.getenv('S3_BUCKET_NAME', '')
    if not bucket or not s3_key:
        return None
    try:
        url = _client().generate_presigned_url(
            'get_object',
            Params={'Bucket': bucket, 'Key': s3_key},
            ExpiresIn=expires_in,
        )
        return url
    except ClientError:
        return None


def delete_file(s3_key: str) -> None:
    """S3에서 파일을 삭제합니다."""
    bucket = os.getenv('S3_BUCKET_NAME', '')
    if not bucket or not s3_key:
        return
    try:
        _client().delete_object(Bucket=bucket, Key=s3_key)
    except ClientError:
        pass
