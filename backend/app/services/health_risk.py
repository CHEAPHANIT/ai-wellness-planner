from app.schemas.ai import HealthRiskRequest, HealthRiskResponse


class HealthRiskService:
    def predict(self, payload: HealthRiskRequest) -> HealthRiskResponse:
        bmi = payload.bmi or self._calculate_bmi(payload.weight_kg, payload.height_cm)
        habits = payload.eating_habits.lower()
        exercise = payload.exercise_frequency.lower()

        score = 0
        if bmi >= 30:
            score += 3
        elif bmi >= 25:
            score += 2
        elif bmi < 18.5:
            score += 1

        if any(term in habits for term in ["high sugar", "fast food", "processed", "overeating"]):
            score += 2
        if any(term in exercise for term in ["none", "rare", "sedentary"]):
            score += 2
        elif "daily" in exercise or "5" in exercise:
            score -= 1

        if score >= 5:
            level = "High Risk"
        elif score >= 3:
            level = "Medium Risk"
        else:
            level = "Low Risk"

        recommendations = [
            "Track meals for at least two weeks to identify calorie and protein patterns.",
            "Add vegetables or fruit to at least two meals per day.",
            "Aim for 150 minutes of moderate activity per week when medically appropriate.",
        ]
        if bmi >= 30:
            recommendations.append("Consider discussing weight-management options with a healthcare professional.")

        return HealthRiskResponse(risk_level=level, bmi=round(bmi, 1), recommendations=recommendations)

    def _calculate_bmi(self, weight_kg: float, height_cm: float) -> float:
        height_m = height_cm / 100
        return weight_kg / (height_m * height_m)
