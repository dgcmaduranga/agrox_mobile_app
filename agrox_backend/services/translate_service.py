from deep_translator import GoogleTranslator

# =========================
# 🌍 TRANSLATE FUNCTION
# =========================
def translate_text(text, lang):
    """
    Translate any given text to target language

    :param text: string to translate
    :param lang: target language (en / si / ta)
    :return: translated string
    """

    # ✅ If English → skip translation (fast)
    if lang == "en":
        return text

    # ✅ If empty or None → return as it is
    if not text:
        return text

    try:
        # 🔥 Translate using Google (no API key needed)
        translated = GoogleTranslator(
            source='auto',   # auto detect source language
            target=lang      # target: si / ta / en
        ).translate(text)

        return translated

    except Exception as e:
        # ❌ Fail safe (important)
        print("❌ Translate Error:", e)
        return text