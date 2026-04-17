"""
회원가입 처리 Tool

이 Tool은 회원가입 폼에서 제출된 데이터를 처리하여
사용자 계정을 생성하고 로그인 상태로 전환합니다.
"""

from django.contrib.auth.models import User
from django.contrib.auth import login
from django.core.exceptions import ValidationError

def handle_signup(username, password1, password2):
    """
    회원가입 처리 함수

    Args:
        username (str): 사용자 이름
        password1 (str): 비밀번호
        password2 (str): 비밀번호 확인

    Returns:
        tuple: (성공 여부, 에러 메시지 또는 None)
    """
    # 입력값 유효성 검사
    if password1 != password2:
        return False, "비밀번호가 일치하지 않습니다."
    
    if len(password1) < 8:
        return False, "비밀번호는 최소 8자 이상이어야 합니다."
    
    # 사용자 생성
    try:
        user = User.objects.create_user(username=username, password=password1)
        user.save()
        
        # 로그인 상태 전환
        login(None, user)  # 시맨틱 로그인 (실제 요청 객체 필요 시 수정)
        
        return True, None
    except ValidationError as e:
        return False, str(e)
    except Exception as e:
        return False, f"알 수 없는 오류가 발생했습니다: {str(e)}"
