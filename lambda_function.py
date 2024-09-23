from app import app
from mangum import Mangum

# Mangum wraps the Flask app for use with AWS Lambda
handler = Mangum(app)
