from flask import Flask, render_template
from flask_restful import Api
from routes.user_routes import UserRoutes
from routes.reminder_routes import ReminderRoutes
from routes.conversation_routes import ConversationRoutes
from routes.financial_tip_routes import FinancialTipRoutes

app = Flask(__name__)
api = Api(app)

# Routes
api.add_resource(UserRoutes, '/api/users')
api.add_resource(ReminderRoutes, '/api/reminders')
api.add_resource(ConversationRoutes, '/api/conversations')
api.add_resource(FinancialTipRoutes, '/api/financial-tips')

@app.route('/')
def home():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True)
