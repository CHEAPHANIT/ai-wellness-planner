import logging

import httpx

from app.core.config import settings
from app.models.user import User
from app.schemas.ai import ChatRequest, ChatResponse

logger = logging.getLogger(__name__)


class NutritionChatbot:
    def answer(self, payload: ChatRequest, user: User | None = None, today_calories: float | None = None) -> ChatResponse:
        question = payload.question.strip()
        context_parts: list[str] = []
        if user and user.profile:
            preference = user.profile.food_preference or user.profile.dietary_preference or "balanced eating"
            context_parts.append(f"your preference is {preference}")
            if user.profile.weight_kg:
                context_parts.append(f"weight is {user.profile.weight_kg:g} kg")
            if user.profile.height_cm:
                context_parts.append(f"height is {user.profile.height_cm:g} cm")
            if user.profile.health_conditions:
                context_parts.append(f"health notes: {user.profile.health_conditions}")
        if user and user.goal:
            if user.goal.goal_type:
                context_parts.append(f"goal is {user.goal.goal_type}")
            if user.goal.daily_calorie_target:
                context_parts.append(f"daily calorie target is {round(user.goal.daily_calorie_target)} kcal")
            if user.goal.protein_target_g:
                context_parts.append(f"daily protein target is {round(user.goal.protein_target_g)} g")
        if user and user.allergies:
            allergy_names = [allergy.ingredient for allergy in user.allergies if allergy.ingredient]
            if allergy_names:
                context_parts.append(f"known allergies are {', '.join(allergy_names)}")
        context = ""
        if today_calories is not None:
            context_parts.append(f"today's logged calories are about {round(today_calories)}")
        if context_parts:
            context = "User context: " + "; ".join(context_parts) + "."
        for provider in self._provider_order():
            response = (
                self._try_ollama_answer(question, context)
                if provider == "ollama"
                else self._try_openai_answer(question, context)
            )
            if response is not None:
                return response
        return ChatResponse(
            answer=self._rule_based_answer(question.lower(), today_calories),
            source="local-rule-based",
        )

    def _provider_order(self) -> list[str]:
        provider = settings.ai_provider.strip().lower()
        has_openai_key = bool(settings.openai_api_key and settings.openai_api_key.strip())
        if provider in {"local", "rule-based", "none", "disabled"}:
            return []
        if provider == "ollama":
            return ["ollama"]
        if provider == "openai":
            return ["openai"] if has_openai_key else []
        if provider == "auto":
            return ["ollama", "openai"] if has_openai_key else ["ollama"]
        logger.warning("Unknown AI_PROVIDER %r; using the local fallback", settings.ai_provider)
        return []

    def _try_openai_answer(self, question: str, context: str) -> ChatResponse | None:
        try:
            return ChatResponse(
                answer=self._openai_answer(question, context),
                source=f"openai:{settings.openai_model}",
            )
        except httpx.HTTPStatusError as error:
            logger.warning("OpenAI chatbot request failed with HTTP %s; using fallback", error.response.status_code)
        except Exception as error:
            logger.warning("OpenAI chatbot request failed (%s); using fallback", type(error).__name__)
        return None

    def _try_ollama_answer(self, question: str, context: str) -> ChatResponse | None:
        try:
            return ChatResponse(
                answer=self._ollama_answer(question, context),
                source=f"ollama:{settings.ollama_model}",
            )
        except httpx.HTTPStatusError as error:
            logger.warning("Ollama chatbot request failed with HTTP %s; using fallback", error.response.status_code)
        except Exception as error:
            logger.warning("Ollama chatbot request failed (%s); using fallback", type(error).__name__)
        return None

    def _system_prompt(self) -> str:
        return (
            "You are NutriAI, a friendly nutrition assistant inside a meal-planning app. "
            "Answer the user's exact question with practical, specific advice. "
            "Use the provided user context when relevant, but do not invent medical facts or pretend to diagnose. "
            "Never recommend a food that conflicts with a known allergy in the user context. "
            "For medical conditions, allergies, pregnancy, eating disorders, severe symptoms, or medication questions, "
            "give general nutrition support and recommend a qualified clinician. "
            "Keep answers concise, conversational, and useful. Prefer bullets only when they improve clarity. "
            "If the user asks for foods or meals, give concrete examples, including Cambodian/local foods when appropriate."
        )

    def _user_content(self, question: str, context: str) -> str:
        return question if not context else f"{context}\n\nQuestion: {question}"

    def _openai_answer(self, question: str, context: str) -> str:
        system_prompt = (
            self._system_prompt()
        )
        user_content = self._user_content(question, context)
        url = f"{settings.openai_base_url.rstrip('/')}/chat/completions"
        headers = {
            "Authorization": f"Bearer {settings.openai_api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": settings.openai_model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_content},
            ],
            "temperature": 0.45,
            "max_tokens": 450,
        }
        with httpx.Client(timeout=self._timeout()) as client:
            response = client.post(url, headers=headers, json=payload)
            response.raise_for_status()
        data = response.json()
        answer = (
            data.get("choices", [{}])[0]
            .get("message", {})
            .get("content", "")
            .strip()
        )
        if not answer:
            raise RuntimeError("OpenAI response did not include answer text")
        return answer

    def _ollama_answer(self, question: str, context: str) -> str:
        url = f"{settings.ollama_base_url.rstrip('/')}/api/chat"
        payload = {
            "model": settings.ollama_model,
            "messages": [
                {"role": "system", "content": self._system_prompt()},
                {"role": "user", "content": self._user_content(question, context)},
            ],
            "stream": False,
            "options": {
                "temperature": 0.45,
                "num_predict": 450,
            },
        }
        with httpx.Client(timeout=self._timeout()) as client:
            response = client.post(url, json=payload)
            response.raise_for_status()
        data = response.json()
        answer = data.get("message", {}).get("content", "").strip()
        if not answer:
            raise RuntimeError("Ollama response did not include answer text")
        return answer

    def _timeout(self) -> httpx.Timeout:
        return httpx.Timeout(
            settings.ai_response_timeout_seconds,
            connect=settings.ai_connect_timeout_seconds,
        )

    def _rule_based_answer(self, question: str, today_calories: float | None = None) -> str:
        if self._contains_any(question, ["fried", "fry", "deep fry", "crispy"]):
            return (
                "Yes, you can include fried food sometimes, but I would treat it as a planned choice rather than the main pattern. "
                "Pick one fried item, keep the portion moderate, and pair it with vegetables plus a lean protein so the meal is more filling. "
                "For example: grilled or fried fish with rice and a big salad, chicken with vegetables, or a small portion of fried rice with extra egg/chicken and cucumber. "
                "If your goal is weight loss, avoid adding sugary drinks or extra sauces because those can push calories up quickly."
            )
        if "pizza" in question:
            return (
                "Pizza can fit in a diet. The practical move is portion control: have 1-2 slices, add a salad or lean protein, and skip sugary drinks. "
                "Thin crust, vegetable toppings, chicken, or seafood are usually easier to fit than extra cheese and processed meats."
            )
        if self._contains_any(question, ["what food", "which food", "food should", "food i should", "should eat", "eat today", "eat for today", "recommend", "suggest", "breakfast", "lunch", "dinner", "snack"]):
            return (
                "For today, choose simple meals with protein, vegetables or fruit, and a steady carbohydrate. "
                "Breakfast: eggs or Greek yogurt with oatmeal and banana. "
                "Lunch: grilled fish or chicken with rice and vegetables. "
                "Dinner: tofu vegetable stir fry, soup, or chicken breast with brown rice. "
                "Snack: fruit, yogurt, boiled eggs, or nuts/seeds if you are not allergic. "
                "If your goal is weight loss, keep fried/oily portions smaller and avoid sugary drinks."
            )
        if self._contains_any(question, ["analyze", "diet", "today", "eating"]):
            logged = f"You have logged about {round(today_calories)} calories today. " if today_calories is not None else ""
            return (
                f"{logged}For a useful diet check, look at four things: calories, protein, vegetables/fiber, and hydration. "
                "If calories are low but protein is also low, add foods like chicken, fish, tofu, eggs, or Greek yogurt. "
                "If meals feel heavy, reduce fried/oily portions and add vegetables or soup. "
                "A balanced day usually has protein at each meal, mostly whole carbs, and enough water."
            )
        if self._contains_any(question, ["meal plan", "meals", "plan my meals", "weekly"]):
            return (
                "A simple weekly meal plan should repeat reliable meals and vary proteins. "
                "Use this structure: breakfast with protein, lunch with rice or whole carbs plus protein, dinner lighter with vegetables, and one planned snack. "
                "For Cambodian-style meals, you could rotate grilled fish, chicken, tofu stir fry, kuy teav-style soup, steamed rice, and vegetables."
            )
        if "protein" in question:
            return (
                "Good protein choices include chicken breast, fish, eggs, tofu, Greek yogurt, beans, and lean pork or beef. "
                "For breakfast, try eggs with vegetables, Greek yogurt with fruit, tofu scramble, or oatmeal with yogurt. "
                "For active adults, a common target is about 1.6-2.2 g protein per kg body weight, adjusted for goals."
            )
        if self._contains_any(question, ["lose weight", "weight loss", "fat loss", "deficit"]):
            return (
                "For weight loss, aim for a moderate calorie deficit rather than eating as little as possible. "
                "Keep protein high, include vegetables or soup for fullness, limit liquid calories, and track your weekly weight trend. "
                "A practical target is losing about 0.25-1% of body weight per week."
            )
        if self._contains_any(question, ["water", "hydration", "drink"]):
            return (
                "A good daily water target is often around 30-35 ml per kg body weight, more if you sweat or exercise. "
                "Spread it across the day: one glass after waking, one with each meal, and one around exercise. "
                "Pale yellow urine and steady energy are practical signs you are close."
            )
        if self._contains_any(question, ["exam", "study", "focus", "energy", "tired"]):
            return (
                "For exam or study days, choose meals that give steady energy instead of a quick sugar spike. "
                "Try rice or oats plus eggs, fish, chicken, tofu, or Greek yogurt, and add fruit or vegetables for fiber. "
                "Keep water nearby, limit very oily meals before studying, and use small snacks like banana, yogurt, nuts/seeds if safe, or boiled eggs."
            )
        if self._contains_any(question, ["allergy", "allergic", "nuts", "peanut", "milk", "fish", "shellfish"]):
            return (
                "For allergies, avoid the trigger completely and check sauces, packaged foods, and cross-contamination. "
                "Use safe substitutes: soy/oat milk for dairy, seeds instead of peanuts, tofu/chicken instead of fish, or rice/noodles with safe proteins. "
                "If reactions are severe, follow medical advice and carry prescribed medication."
            )
        if self._contains_any(question, ["calorie", "calories", "kcal"]):
            return (
                "Calories depend on portion size and cooking method. Fried and oily foods add calories fast because oil is calorie dense. "
                "For better estimates, log the food, serving size, and whether it was grilled, steamed, stir-fried, or deep-fried."
            )
        if "diabetes" in question:
            return (
                "For diabetes-friendly meals, choose high-fiber carbohydrates, spread carbs across the day, pair carbs with protein, and limit sugary drinks. "
                "Personal carb targets should be confirmed with a clinician."
            )
        return (
            "Tell me the food, your goal, and the portion size, and I can give more specific advice. "
            "In general, build meals around protein, vegetables, smart carbs, hydration, and consistency."
        )

    def _contains_any(self, value: str, keywords: list[str]) -> bool:
        return any(keyword in value for keyword in keywords)
