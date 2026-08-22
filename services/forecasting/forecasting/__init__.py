"""PLC Election Intelligence — forecasting engine.

Composed of: polling_average (Model A), monte_carlo (Model A+C combined —
see monte_carlo.py module docstring for what is and isn't implemented),
candidate_forecast (closed-list seat probability), and coalition (majority
feasibility + auto-generated scenarios).
"""
