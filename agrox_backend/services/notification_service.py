import os
from typing import Optional, Dict, Any

import firebase_admin
from firebase_admin import credentials, messaging


# =====================================================
# Firebase Admin Initialization
# =====================================================

def init_firebase_admin() -> None:
    """
    Initialize Firebase Admin SDK only once.
    firebase_key.json must be in agrox_backend root folder.
    """
    if firebase_admin._apps:
        return

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    firebase_key_path = os.path.join(base_dir, "firebase_key.json")

    if not os.path.exists(firebase_key_path):
        raise FileNotFoundError(
            f"Firebase service account file not found: {firebase_key_path}"
        )

    cred = credentials.Certificate(firebase_key_path)
    firebase_admin.initialize_app(cred)


# =====================================================
# Send Notification to One Device
# =====================================================

def send_push_notification(
    token: str,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None,
) -> Dict[str, Any]:
    """
    Send Firebase Cloud Messaging notification to one device token.
    Works even when app is background / closed.
    """
    try:
        init_firebase_admin()

        if not token:
            return {
                "success": False,
                "message": "FCM token is missing",
            }

        message = messaging.Message(
            token=token,
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="risk_alerts",
                    priority="high",
                    default_sound=True,
                    default_vibrate_timings=True,
                ),
            ),
        )

        response = messaging.send(message)

        return {
            "success": True,
            "message": "Notification sent successfully",
            "response": response,
        }

    except Exception as e:
        print(f"Notification send error: {e}")
        return {
            "success": False,
            "message": str(e),
        }


# =====================================================
# Send Risk Alert Notification
# =====================================================

def send_risk_alert_notification(
    token: str,
    crop: str,
    disease_name: str,
    risk_level: str,
    severity: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Send high / medium disease risk alert notification.
    """

    crop_text = crop.title() if crop else "Crop"
    disease_text = disease_name.title() if disease_name else "Disease Risk"
    level_text = risk_level.title() if risk_level else "Risk Alert"
    severity_text = severity.title() if severity else level_text

    title = f"⚠️ {level_text} Detected"
    body = f"{crop_text}: {disease_text} risk is {severity_text}. Please check AgroX."

    data = {
        "type": "risk_alert",
        "crop": crop_text,
        "disease_name": disease_text,
        "risk_level": level_text,
        "severity": severity_text,
    }

    return send_push_notification(
        token=token,
        title=title,
        body=body,
        data=data,
    )


# =====================================================
# Send Notification to Multiple Devices
# =====================================================

def send_multicast_notification(
    tokens: list[str],
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None,
) -> Dict[str, Any]:
    """
    Send notification to multiple FCM tokens.
    """
    try:
        init_firebase_admin()

        valid_tokens = [t for t in tokens if t]

        if not valid_tokens:
            return {
                "success": False,
                "message": "No valid FCM tokens found",
            }

        message = messaging.MulticastMessage(
            tokens=valid_tokens,
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="risk_alerts",
                    priority="high",
                    default_sound=True,
                    default_vibrate_timings=True,
                ),
            ),
        )

        response = messaging.send_multicast(message)

        return {
            "success": True,
            "message": "Multicast notification sent",
            "success_count": response.success_count,
            "failure_count": response.failure_count,
        }

    except Exception as e:
        print(f"Multicast notification error: {e}")
        return {
            "success": False,
            "message": str(e),
        }