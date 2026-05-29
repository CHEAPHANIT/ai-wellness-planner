from app.core.config import settings
from app.schemas.ai import ChatRequest, ChatResponse


class NutritionChatbot:
    def answer(self, payload: ChatRequest) -> ChatResponse:
        question = payload.question.lower()
        if settings.openai_api_key:
            # Hook point for OpenAI, Gemini, or Claude integration in production.
            return ChatResponse(
                answer=self._rule_based_answer(question),
                source="configured-ai-fallback",
            )
        return ChatResponse(answer=self._rule_based_answer(question), source="local-rule-based")

    def _rule_based_answer(self, question: str) -> str:
        if "pizza" in question and ("diet" in question or "weight" in question):
            return "Yes, but keep the portion controlled and balance it with lean protein, vegetables, and your daily calorie target."
        if "protein" in question:
            return "Most active adults do well with a protein target around 1.6 to 2.2 grams per kilogram of body weight, depending on goals."
        if "lose weight" in question or "fat loss" in question:
            return "Use a moderate calorie deficit, keep protein high, train consistently, and track progress weekly rather than daily."
        if "diabetes" in question:
            return "Choose high-fiber carbohydrates, distribute carbs across meals, and discuss personal targets with a qualified clinician."
        return "Focus on total calories, protein, fiber, hydration, and consistency. For medical conditions, use this app as support and confirm decisions with a health professional."

