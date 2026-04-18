import io
from PIL import Image


def extract_text(image_bytes: bytes) -> str:
    """이미지에서 텍스트를 추출합니다. pytesseract가 없으면 빈 문자열을 반환합니다."""
    try:
        import pytesseract
        image = Image.open(io.BytesIO(image_bytes))
        try:
            text = pytesseract.image_to_string(image, lang='kor+eng')
        except Exception:
            text = pytesseract.image_to_string(image)
        return text.strip()
    except ImportError:
        return ""
    except Exception:
        return ""
