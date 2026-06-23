from app.schemas.ai import HealthRiskRequest, HealthRiskResponse


class HealthRiskService:
    def predict(self, payload: HealthRiskRequest) -> HealthRiskResponse:
        # Weight and height are required, so use their internally consistent BMI
        # rather than trusting a separately supplied value.
        bmi = self._calculate_bmi(payload.weight_kg, payload.height_cm)
        habits = payload.eating_habits
        exercise = payload.exercise_frequency

        score = 0
        if bmi >= 30:
            score += 3
        elif bmi >= 25:
            score += 2
        elif bmi < 18.5:
            score += 1

        less_supportive_habits = any(
            term in habits
            for term in ["high sugar", "fast food", "processed", "overeating", "sugary drink"]
        )
        if less_supportive_habits:
            score += 2

        inactive = any(term in exercise for term in ["none", "rare", "sedentary", "0 day"])
        highly_active = any(term in exercise for term in ["daily", "5 day", "6 day", "7 day"])
        if inactive:
            score += 2
        elif highly_active:
            score -= 1

        if score >= 5:
            level = "High Health Risk"
        elif score >= 3:
            level = "Medium Health Risk"
        else:
            level = "Low Health Risk"

        recommendations = [
            "Use this screening result as a prompt to review habits, not as a diagnosis.",
            "Aim for at least 150 minutes of moderate activity per week when medically appropriate.",
        ]
        if less_supportive_habits:
            recommendations.append("Replace one highly processed or sugary choice each day with a minimally processed meal or water.")
        else:
            recommendations.append("Keep meals balanced with protein, vegetables or fruit, and high-fiber carbohydrates.")
        if inactive:
            recommendations.append("Start with short, manageable walks and increase activity gradually.")
        if bmi >= 30:
            recommendations.append("Consider discussing weight-management and metabolic screening with a healthcare professional.")
        elif bmi < 18.5:
            recommendations.append("Discuss unintended low weight or weight loss with a healthcare professional.")
        if payload.goal in {"lose_weight", "weight_loss"}:
            recommendations.append("Prefer a moderate calorie deficit and monitor the weekly trend instead of restricting aggressively.")

        return HealthRiskResponse(
            risk_level=level,
            bmi=round(bmi, 1),
            recommendations=list(dict.fromkeys(recommendations)),
        )

    def _calculate_bmi(self, weight_kg: float, height_cm: float) -> float:
        height_m = height_cm / 100
        return weight_kg / (height_m * height_m)
