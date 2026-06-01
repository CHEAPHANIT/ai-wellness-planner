from app.schemas.ai import CaloriePredictionRequest, CaloriePredictionResponse


class CaloriePredictionService:
    activity_multipliers = {
        "sedentary": 1.2,
        "light": 1.375,
        "moderate": 1.55,
        "active": 1.725,
        "very_active": 1.9,
    }

    goal_adjustments = {
        "lose_weight": -450,
        "weight_loss": -450,
        "maintain": 0,
        "gain_muscle": 300,
        "gain_weight": 400,
    }

    def predict(self, payload: CaloriePredictionRequest) -> CaloriePredictionResponse:
        gender = payload.gender.lower()
        if gender in {"male", "man"}:
            bmr = 10 * payload.weight_kg + 6.25 * payload.height_cm - 5 * payload.age + 5
        else:
            bmr = 10 * payload.weight_kg + 6.25 * payload.height_cm - 5 * payload.age - 161

        multiplier = self.activity_multipliers.get(payload.activity_level.lower(), 1.375)
        adjustment = self.goal_adjustments.get(payload.goal.lower(), 0)
        maintenance = round(bmr * multiplier)
        calories = max(1200, round(maintenance + adjustment))
        bmi = payload.weight_kg / ((payload.height_cm / 100) ** 2)
        return CaloriePredictionResponse(
            recommended_daily_calories=calories,
            bmr=round(bmr),
            bmi=round(bmi, 2),
            bmi_status=self._bmi_status(bmi),
            maintenance_calories=maintenance,
            explanation="Prediction uses BMI and a Mifflin-St Jeor BMR baseline with activity and goal adjustments.",
        )

    def _bmi_status(self, bmi: float) -> str:
        if bmi < 18.5:
            return "Underweight"
        if bmi < 25:
            return "Normal"
        if bmi < 30:
            return "Overweight"
        return "Obese"
