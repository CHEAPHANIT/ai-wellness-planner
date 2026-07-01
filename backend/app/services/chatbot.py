import logging
import re

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
            answer=self._rule_based_answer(question.lower(), today_calories, user),
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

    def _rule_based_answer(
        self,
        question: str,
        today_calories: float | None = None,
        user: User | None = None,
    ) -> str:
        known_allergies = self._known_allergies(question, user)
        allergy_note = self._allergy_note(known_allergies)
        safe_proteins = self._safe_proteins(known_allergies)
        safe_snacks = self._safe_snacks(known_allergies)
        safe_carbs = self._safe_carbs(known_allergies)
        safe_fats = self._safe_fats(known_allergies)
        safe_proteins = self._ensure_choices(safe_proteins, "a protein food you know is safe for you", 4)
        safe_snacks = self._ensure_choices(safe_snacks, "fruit or another snack you know is safe for you", 4)
        safe_carbs = self._ensure_choices(safe_carbs, "a carbohydrate food you know is safe for you", 4)
        safe_fats = self._ensure_choices(safe_fats, "a healthy fat you know is safe for you", 2)
        goal = self._goal_from_question_or_user(question, user)
        asks_food_advice = self._asks_food_advice(question)
        meal = self._mentioned_meal(question)

        if self._contains_any(question, ["fried", "fry", "deep fry", "crispy"]):
            protein_examples = ", ".join(safe_proteins[:3])
            goal_tip = (
                "For weight gain, keep the portion reasonable but add extra rice or a safe smoothie if you need more calories."
                if goal == "gain_weight"
                else "For weight loss, keep fried/oily portions smaller and avoid sugary drinks."
            )
            return (
                "Yes, you can include fried food sometimes, but I would treat it as a planned choice rather than the main pattern. "
                "Pick one fried item, keep the portion moderate, and pair it with vegetables plus a lean protein so the meal is more filling. "
                f"For example: rice with vegetables and {protein_examples}, or a small portion of fried rice with extra safe protein and cucumber. "
                f"{allergy_note}{goal_tip}"
            )
        if "pizza" in question:
            topping_examples = ", ".join(safe_proteins[:2])
            cheese_note = "Choose little/no cheese or a dairy-free option. " if self._is_allergic_to(known_allergies, {"milk", "dairy", "cheese"}) else ""
            return (
                "Pizza can fit in a diet. The practical move is portion control: have 1-2 slices, add a salad or lean protein, and skip sugary drinks. "
                f"{cheese_note}Thin crust, vegetable toppings, or safe proteins like {topping_examples} are usually easier to fit than extra cheese and processed meats. "
                f"{allergy_note}"
            )

        if asks_food_advice:
            return self._food_advice(goal, meal, allergy_note, safe_proteins, safe_carbs, safe_fats, safe_snacks)

        if self._contains_any(question, ["analyze", "diet", "today", "eating"]):
            logged = f"You have logged about {round(today_calories)} calories today. " if today_calories is not None else ""
            goal_tip = self._goal_tip(goal)
            return (
                f"{logged}For a useful diet check, look at four things: calories, protein, vegetables/fiber, and hydration. "
                f"If calories are low but protein is also low, add safe foods like {', '.join(safe_proteins)}. "
                "If meals feel heavy, reduce fried/oily portions and add vegetables or soup. "
                f"{goal_tip} {allergy_note}"
            )
        if self._contains_any(question, ["meal plan", "meals", "plan my meals", "weekly"]):
            return (
                "A simple weekly meal plan should repeat reliable meals and vary proteins. "
                f"Use this structure: breakfast with {safe_proteins[0]} plus {safe_carbs[0]}, lunch with {safe_carbs[1]} and {safe_proteins[1]}, dinner with vegetables and {safe_proteins[2]}, and one planned snack. "
                f"For Cambodian-style meals, rotate safe proteins like {', '.join(safe_proteins[:3])}, kuy teav-style soup, steamed rice, and vegetables. "
                f"{self._goal_tip(goal)} {allergy_note}"
            )
        if "protein" in question:
            return (
                f"Good protein choices include {', '.join(safe_proteins)}. "
                "For breakfast, try a safe protein with fruit, vegetables, oats, rice, or potatoes. "
                f"For active adults, a common target is about 1.6-2.2 g protein per kg body weight, adjusted for goals. {allergy_note}"
            )
        if goal == "gain_weight":
            return self._goal_answer("gain_weight", allergy_note, safe_proteins, safe_carbs, safe_fats, safe_snacks)
        if goal == "lose_weight":
            return self._goal_answer("lose_weight", allergy_note, safe_proteins, safe_carbs, safe_fats, safe_snacks)
        if self._contains_any(question, ["water", "hydration", "drink"]):
            return (
                "A good daily water target is often around 30-35 ml per kg body weight, more if you sweat or exercise. "
                "Spread it across the day: one glass after waking, one with each meal, and one around exercise. "
                "Pale yellow urine and steady energy are practical signs you are close."
            )
        if self._contains_any(question, ["exam", "study", "focus", "energy", "tired"]):
            return (
                "For exam or study days, choose meals that give steady energy instead of a quick sugar spike. "
                f"Try rice or oats plus safe protein such as {', '.join(safe_proteins[:3])}, and add fruit or vegetables for fiber. "
                f"Keep water nearby, limit very oily meals before studying, and use small snacks like {', '.join(safe_snacks[:3])}."
            )
        if self._contains_any(
            question,
            ["allergy", "allergic", "chicken", "egg", "nuts", "peanut", "milk", "dairy", "fish", "shellfish", "soy"],
        ):
            return (
                f"{allergy_note or 'For allergies, avoid the trigger completely and check sauces, packaged foods, and cross-contamination. '}"
                f"Use safe substitutes such as {', '.join(safe_proteins)} for protein and {', '.join(safe_snacks)} for snacks. "
                "If reactions are severe, follow medical advice and carry prescribed medication."
            )
        if self._contains_any(question, ["calorie", "calories", "kcal"]):
            goal_tip = self._goal_tip(goal)
            return (
                "Calories depend on portion size and cooking method. Fried and oily foods add calories fast because oil is calorie dense. "
                f"For better estimates, log the food, serving size, and whether it was grilled, steamed, stir-fried, or deep-fried. {goal_tip}"
            )
        if "diabetes" in question:
            return (
                "For diabetes-friendly meals, choose high-fiber carbohydrates, spread carbs across the day, pair carbs with protein, and limit sugary drinks. "
                "Personal carb targets should be confirmed with a clinician."
            )
        return (
            f"Based on your question, start with a safe balanced meal: {safe_proteins[0]}, {safe_carbs[0]}, vegetables or fruit, and water. "
            f"{self._goal_tip(goal)} {allergy_note}"
        )

    def _contains_any(self, value: str, keywords: list[str]) -> bool:
        return any(keyword in value for keyword in keywords)

    def _known_allergies(self, question: str, user: User | None) -> list[str]:
        allergies = {
            allergy.ingredient.strip().lower()
            for allergy in (user.allergies if user else [])
            if allergy.ingredient and allergy.ingredient.strip()
        }
        for allergen in [
            "chicken",
            "egg",
            "milk",
            "dairy",
            "cheese",
            "yogurt",
            "nuts",
            "peanut",
            "fish",
            "shellfish",
            "shrimp",
            "crab",
            "soy",
            "tofu",
            "wheat",
            "gluten",
        ]:
            if allergen in question:
                allergies.add(allergen)
        allergy_match = re.search(
            r"(?:allergic|allergy|allergies)\s+(?:to|with|for)?\s+([a-zA-Z][a-zA-Z\s,/-]{0,60})",
            question,
        )
        if allergy_match:
            raw_terms = re.split(r",|/|\band\b|\bor\b|\bso\b|\bwhat\b|\bwhich\b|\bshould\b", allergy_match.group(1))
            for term in raw_terms:
                cleaned = term.strip(" .?!-").lower()
                if 2 <= len(cleaned) <= 30 and cleaned not in {"food", "foods", "meal", "meals"}:
                    allergies.add(cleaned)
        return sorted(allergies)

    def _allergy_note(self, allergies: list[str]) -> str:
        if not allergies:
            return ""
        return f"Avoid {', '.join(allergies)} completely because of your allergy. "

    def _safe_proteins(self, allergies: list[str]) -> list[str]:
        options = ["eggs", "fish", "tofu", "beans or lentils", "lean beef or pork", "Greek yogurt", "shrimp", "chicken breast"]
        return self._without_blocked(options, allergies)

    def _safe_snacks(self, allergies: list[str]) -> list[str]:
        options = ["banana", "avocado", "boiled eggs", "oat smoothie", "seeds", "rice cakes with peanut butter", "fruit with yogurt"]
        return self._without_blocked(options, allergies)

    def _safe_carbs(self, allergies: list[str]) -> list[str]:
        options = ["rice", "noodles", "potatoes", "oats", "whole-grain bread", "corn", "sweet potato"]
        safe = self._without_blocked(options, allergies)
        return safe or ["a carbohydrate food you know is safe for you"]

    def _safe_fats(self, allergies: list[str]) -> list[str]:
        options = ["avocado", "olive oil", "seeds", "nuts", "peanut butter"]
        safe = self._without_blocked(options, allergies)
        return safe or ["a healthy fat you know is safe for you"]

    def _without_blocked(
        self,
        options: list[str],
        allergies: list[str],
    ) -> list[str]:
        aliases = {
            "milk": {"milk", "dairy", "cheese", "yogurt", "greek yogurt"},
            "dairy": {"milk", "dairy", "cheese", "yogurt", "greek yogurt"},
            "cheese": {"cheese", "dairy"},
            "yogurt": {"yogurt", "dairy", "greek yogurt"},
            "egg": {"egg", "eggs", "boiled eggs"},
            "nuts": {"nuts", "peanut", "peanut butter"},
            "peanut": {"peanut", "peanut butter"},
            "fish": {"fish"},
            "shellfish": {"shellfish", "shrimp", "crab"},
            "shrimp": {"shrimp", "shellfish"},
            "crab": {"crab", "shellfish"},
            "soy": {"soy", "tofu"},
            "tofu": {"tofu", "soy"},
            "wheat": {"wheat", "bread", "noodles"},
            "gluten": {"wheat", "bread", "noodles"},
        }
        blocked_terms: set[str] = set()
        for allergy in allergies:
            blocked_terms.update(aliases.get(allergy, {allergy}))
        return [
            option
            for option in options
            if not any(term in option.lower() for term in blocked_terms)
        ]

    def _asks_food_advice(self, question: str) -> bool:
        return self._contains_any(
            question,
            [
                "what food",
                "which food",
                "food should",
                "food i should",
                "should eat",
                "eat today",
                "eat for today",
                "recommend",
                "suggest",
                "breakfast",
                "lunch",
                "dinner",
                "snack",
                "meal",
                "recipe",
            ],
        )

    def _mentioned_meal(self, question: str) -> str:
        for meal in ["breakfast", "lunch", "dinner", "snack"]:
            if meal in question:
                return meal
        return "meal"

    def _goal_from_question_or_user(self, question: str, user: User | None) -> str:
        if self._contains_any(question, ["gain weight", "gaining weight", "gaint weight", "gainst weight", "bulk", "increase weight"]):
            return "gain_weight"
        if self._contains_any(question, ["lose weight", "weight loss", "fat loss", "deficit", "slim"]):
            return "lose_weight"
        if self._contains_any(question, ["muscle", "build muscle"]):
            return "gain_weight"
        goal_type = user.goal.goal_type.lower() if user and user.goal and user.goal.goal_type else ""
        if goal_type in {"gain_weight", "weight_gain", "muscle_gain", "bulk"}:
            return "gain_weight"
        if goal_type in {"lose_weight", "weight_loss", "fat_loss"}:
            return "lose_weight"
        return "maintain"

    def _food_advice(
        self,
        goal: str,
        meal: str,
        allergy_note: str,
        proteins: list[str],
        carbs: list[str],
        fats: list[str],
        snacks: list[str],
    ) -> str:
        meal_prefix = {
            "breakfast": f"For breakfast, try {proteins[0]} with {carbs[0]} and fruit.",
            "lunch": f"For lunch, try {proteins[1]} with {carbs[1]} and vegetables.",
            "dinner": f"For dinner, try {proteins[2]} with soup or vegetables and {carbs[0]}.",
            "snack": f"For snacks, try {', '.join(snacks[:4])}.",
            "meal": f"Build meals from safe protein like {', '.join(proteins[:4])}, carbs like {', '.join(carbs[:4])}, vegetables or fruit, and water.",
        }[meal]
        if goal == "gain_weight":
            return (
                f"{allergy_note}{meal_prefix} For weight gain, increase portions of {carbs[0]} or {carbs[1]}, add {fats[0]}, and include an extra snack such as {snacks[0]}. "
                "Increase slowly and track your weekly weight trend."
            )
        if goal == "lose_weight":
            return (
                f"{allergy_note}{meal_prefix} For weight loss, keep protein high, fill half the plate with vegetables or soup, use moderate portions of carbs, and limit sugary drinks."
            )
        return (
            f"{allergy_note}{meal_prefix} For maintenance, keep portions steady and include protein, carbs, vegetables or fruit, and water at most meals."
        )

    def _goal_answer(
        self,
        goal: str,
        allergy_note: str,
        proteins: list[str],
        carbs: list[str],
        fats: list[str],
        snacks: list[str],
    ) -> str:
        if goal == "gain_weight":
            return (
                f"{allergy_note}For weight gain, aim for a small daily calorie surplus. "
                f"Use bigger portions of {', '.join(carbs[:3])}, add calorie-dense safe fats like {', '.join(fats[:2])}, and include protein such as {', '.join(proteins[:4])}. "
                f"Add one extra snack, for example {snacks[0]}, then adjust based on your weekly weight trend."
            )
        return (
            f"{allergy_note}For weight loss, aim for a moderate calorie deficit rather than eating as little as possible. "
            f"Keep protein high with safe options like {', '.join(proteins[:4])}, add vegetables or soup for fullness, limit liquid calories, and track your weekly weight trend."
        )

    def _goal_tip(self, goal: str) -> str:
        if goal == "gain_weight":
            return "Because your goal is weight gain, add calories with bigger carb portions, safe fats, or one extra snack."
        if goal == "lose_weight":
            return "Because your goal is weight loss, keep protein high and portions controlled without skipping meals."
        return "For maintenance, keep portions consistent and focus on balanced meals."

    def _is_allergic_to(self, allergies: list[str], terms: set[str]) -> bool:
        return bool(set(allergies) & terms)

    def _ensure_choices(self, options: list[str], fallback: str, count: int) -> list[str]:
        choices = options or [fallback]
        while len(choices) < count:
            choices.append(fallback)
        return choices
