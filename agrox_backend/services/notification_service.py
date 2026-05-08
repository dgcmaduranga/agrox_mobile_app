import os
from typing import Optional, Dict, Any, List

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
# Helpers
# =====================================================

def _safe_text(value: Any, fallback: str) -> str:
    if value is None:
        return fallback

    text = str(value).strip()
    return text if text else fallback


def _title_text(value: Any, fallback: str) -> str:
    return _safe_text(value, fallback).replace("_", " ").title()


def _normalize_level(value: Any) -> str:
    level = _safe_text(value, "Low").lower()

    if "high" in level or "severe" in level:
        return "High"

    if "medium" in level or "moderate" in level:
        return "Medium"

    return "Low"


def _should_send_risk_notification(risk_level: Any) -> bool:
    level = _normalize_level(risk_level)
    return level in ["High", "Medium"]


def _clean_data(data: Optional[Dict[str, Any]]) -> Dict[str, str]:
    """
    FCM data payload must be Dict[str, str].
    """
    if not data:
        return {}

    return {str(k): "" if v is None else str(v) for k, v in data.items()}


def _format_percent(risk_percent: Optional[Any]) -> str:
    if risk_percent is None:
        return ""

    try:
        value = float(risk_percent)

        if 0 < value <= 1:
            value = value * 100

        return f"{value:.0f}%"
    except Exception:
        return str(risk_percent)


def _risk_sort_value(risk: Dict[str, Any]) -> int:
    level = _normalize_level(
        risk.get("risk_level")
        or risk.get("riskLevel")
        or risk.get("severity")
        or "Low"
    )

    if level == "High":
        return 3

    if level == "Medium":
        return 2

    return 1


def _extract_risk_percent_value(risk: Dict[str, Any]) -> float:
    raw_value = (
        risk.get("risk_percent")
        or risk.get("riskPercent")
        or risk.get("percent")
        or risk.get("score")
        or 0
    )

    try:
        value = float(raw_value)

        if 0 < value <= 1:
            value = value * 100

        return value
    except Exception:
        return 0.0


def _extract_disease_name(risk: Dict[str, Any]) -> str:
    return (
        risk.get("disease_name")
        or risk.get("diseaseName")
        or risk.get("name")
        or risk.get("disease")
        or "Disease Risk"
    )


def _extract_risk_level(risk: Dict[str, Any]) -> str:
    return (
        risk.get("risk_level")
        or risk.get("riskLevel")
        or risk.get("severity")
        or "Low"
    )


def _sort_risks(risks: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    return sorted(
        risks,
        key=lambda item: (
            _risk_sort_value(item),
            _extract_risk_percent_value(item),
        ),
        reverse=True,
    )


# =====================================================
# Send Notification to One Device
# =====================================================

def send_push_notification(
    token: str,
    title: str,
    body: str,
    data: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Send Firebase Cloud Messaging notification to one device token.
    """
    try:
        init_firebase_admin()

        token = _safe_text(token, "")

        if not token:
            return {
                "success": False,
                "message": "FCM token is missing",
            }

        message = messaging.Message(
            token=token,
            notification=messaging.Notification(
                title=_safe_text(title, "AgroX Alert"),
                body=_safe_text(body, "New AgroX notification available."),
            ),
            data=_clean_data(data),
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="risk_alerts",
                    priority="high",
                    default_sound=True,
                    default_vibrate_timings=True,
                ),
            ),
            apns=messaging.APNSConfig(
                headers={
                    "apns-priority": "10",
                },
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound="default",
                        badge=1,
                        content_available=True,
                    )
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
    risk_percent: Optional[Any] = None,
) -> Dict[str, Any]:
    """
    Send high / medium disease risk alert notification.
    Low risk notifications are skipped.
    """
    level_text = _normalize_level(risk_level)
    severity_text = _normalize_level(severity or risk_level)

    if not _should_send_risk_notification(level_text):
        return {
            "success": False,
            "skipped": True,
            "message": "Low risk notification skipped",
            "risk_level": level_text,
        }

    crop_text = _title_text(crop, "Crop")
    disease_text = _title_text(disease_name, "Disease Risk")
    percent_text = _format_percent(risk_percent)

    if level_text == "High":
        title = f"⚠️ High Risk Alert - {crop_text}"
    else:
        title = f"⚠️ Medium Risk Alert - {crop_text}"

    if percent_text:
        body = (
            f"{disease_text} risk is {severity_text} ({percent_text}). "
            f"Check AgroX for recommended actions."
        )
    else:
        body = (
            f"{disease_text} risk is {severity_text}. "
            f"Check AgroX for recommended actions."
        )

    data = {
        "type": "risk_alert",
        "crop": crop_text,
        "disease_name": disease_text,
        "risk_level": level_text,
        "severity": severity_text,
        "risk_percent": percent_text,
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
    }

    return send_push_notification(
        token=token,
        title=title,
        body=body,
        data=data,
    )


# =====================================================
# Send Multiple Risk Alerts to One Device
# =====================================================

def send_multiple_risk_alerts(
    token: str,
    risks: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """
    Send separate notifications for each high / medium crop risk.
    Low risks are skipped.
    High risks are sent first, then medium risks.
    """
    try:
        token = _safe_text(token, "")

        if not token:
            return {
                "success": False,
                "message": "FCM token is missing",
            }

        if not risks:
            return {
                "success": False,
                "message": "No risks found",
            }

        sorted_risks = _sort_risks(risks)

        sent_results = []
        skipped_results = []

        for risk in sorted_risks:
            crop = risk.get("crop", "Crop")
            disease_name = _extract_disease_name(risk)
            risk_level = _extract_risk_level(risk)
            severity = risk.get("severity", risk_level)

            risk_percent = (
                risk.get("risk_percent")
                or risk.get("riskPercent")
                or risk.get("percent")
                or risk.get("score")
            )

            normalized_level = _normalize_level(risk_level)

            if not _should_send_risk_notification(normalized_level):
                skipped_results.append({
                    "crop": crop,
                    "disease_name": disease_name,
                    "risk_level": normalized_level,
                    "risk_percent": _format_percent(risk_percent),
                    "message": "Low risk skipped",
                })
                continue

            result = send_risk_alert_notification(
                token=token,
                crop=crop,
                disease_name=disease_name,
                risk_level=normalized_level,
                severity=severity,
                risk_percent=risk_percent,
            )

            sent_results.append({
                "crop": crop,
                "disease_name": disease_name,
                "risk_level": normalized_level,
                "risk_percent": _format_percent(risk_percent),
                "result": result,
            })

        return {
            "success": True,
            "message": "Risk alert processing completed",
            "sent_count": len(sent_results),
            "skipped_count": len(skipped_results),
            "sent": sent_results,
            "skipped": skipped_results,
        }

    except Exception as e:
        print(f"Multiple risk alert error: {e}")
        return {
            "success": False,
            "message": str(e),
        }


# =====================================================
# Send Notification to Multiple Devices
# =====================================================

def send_multicast_notification(
    tokens: List[str],
    title: str,
    body: str,
    data: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Send notification to multiple FCM tokens.
    """
    try:
        init_firebase_admin()

        valid_tokens = [str(t).strip() for t in tokens if str(t).strip()]

        if not valid_tokens:
            return {
                "success": False,
                "message": "No valid FCM tokens found",
            }

        message = messaging.MulticastMessage(
            tokens=valid_tokens,
            notification=messaging.Notification(
                title=_safe_text(title, "AgroX Alert"),
                body=_safe_text(body, "New AgroX notification available."),
            ),
            data=_clean_data(data),
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="risk_alerts",
                    priority="high",
                    default_sound=True,
                    default_vibrate_timings=True,
                ),
            ),
            apns=messaging.APNSConfig(
                headers={
                    "apns-priority": "10",
                },
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound="default",
                        badge=1,
                        content_available=True,
                    )
                ),
            ),
        )

        response = messaging.send_each_for_multicast(message)

        failures = []

        for index, resp in enumerate(response.responses):
            if not resp.success:
                failures.append({
                    "token": valid_tokens[index],
                    "error": str(resp.exception),
                })

        return {
            "success": True,
            "message": "Multicast notification sent",
            "success_count": response.success_count,
            "failure_count": response.failure_count,
            "failures": failures,
        }

    except Exception as e:
        print(f"Multicast notification error: {e}")
        return {
            "success": False,
            "message": str(e),
        }


# =====================================================
# Send Risk Alert to Multiple Devices
# =====================================================

def send_risk_alert_to_multiple_devices(
    tokens: List[str],
    crop: str,
    disease_name: str,
    risk_level: str,
    severity: Optional[str] = None,
    risk_percent: Optional[Any] = None,
) -> Dict[str, Any]:
    """
    Send one crop risk alert to multiple devices.
    Low risk notifications are skipped.
    """
    level_text = _normalize_level(risk_level)
    severity_text = _normalize_level(severity or risk_level)

    if not _should_send_risk_notification(level_text):
        return {
            "success": False,
            "skipped": True,
            "message": "Low risk notification skipped",
            "risk_level": level_text,
        }

    crop_text = _title_text(crop, "Crop")
    disease_text = _title_text(disease_name, "Disease Risk")
    percent_text = _format_percent(risk_percent)

    if level_text == "High":
        title = f"⚠️ High Risk Alert - {crop_text}"
    else:
        title = f"⚠️ Medium Risk Alert - {crop_text}"

    if percent_text:
        body = (
            f"{disease_text} risk is {severity_text} ({percent_text}). "
            f"Check AgroX for recommended actions."
        )
    else:
        body = (
            f"{disease_text} risk is {severity_text}. "
            f"Check AgroX for recommended actions."
        )

    data = {
        "type": "risk_alert",
        "crop": crop_text,
        "disease_name": disease_text,
        "risk_level": level_text,
        "severity": severity_text,
        "risk_percent": percent_text,
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
    }

    return send_multicast_notification(
        tokens=tokens,
        title=title,
        body=body,
        data=data,
    )


# =====================================================
# Send Multiple Risk Alerts to Multiple Devices
# =====================================================

def send_multiple_risk_alerts_to_multiple_devices(
    tokens: List[str],
    risks: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """
    Send separate high / medium risk alerts to multiple devices.
    Low risks are skipped.
    High risks are sent first, then medium risks.
    """
    try:
        valid_tokens = [str(t).strip() for t in tokens if str(t).strip()]

        if not valid_tokens:
            return {
                "success": False,
                "message": "No valid FCM tokens found",
            }

        if not risks:
            return {
                "success": False,
                "message": "No risks found",
            }

        sorted_risks = _sort_risks(risks)

        sent_results = []
        skipped_results = []

        for risk in sorted_risks:
            crop = risk.get("crop", "Crop")
            disease_name = _extract_disease_name(risk)
            risk_level = _extract_risk_level(risk)
            severity = risk.get("severity", risk_level)

            risk_percent = (
                risk.get("risk_percent")
                or risk.get("riskPercent")
                or risk.get("percent")
                or risk.get("score")
            )

            normalized_level = _normalize_level(risk_level)

            if not _should_send_risk_notification(normalized_level):
                skipped_results.append({
                    "crop": crop,
                    "disease_name": disease_name,
                    "risk_level": normalized_level,
                    "risk_percent": _format_percent(risk_percent),
                    "message": "Low risk skipped",
                })
                continue

            result = send_risk_alert_to_multiple_devices(
                tokens=valid_tokens,
                crop=crop,
                disease_name=disease_name,
                risk_level=normalized_level,
                severity=severity,
                risk_percent=risk_percent,
            )

            sent_results.append({
                "crop": crop,
                "disease_name": disease_name,
                "risk_level": normalized_level,
                "risk_percent": _format_percent(risk_percent),
                "result": result,
            })

        return {
            "success": True,
            "message": "Multiple risk alert processing completed",
            "sent_count": len(sent_results),
            "skipped_count": len(skipped_results),
            "sent": sent_results,
            "skipped": skipped_results,
        }

    except Exception as e:
        print(f"Multiple risk alerts to multiple devices error: {e}")
        return {
            "success": False,
            "message": str(e),
        }